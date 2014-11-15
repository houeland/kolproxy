{-# LANGUAGE CPP #-}

module KolproxyServer where

import Prelude
import HardcodedGameStuff
import Logging
import PlatformLowlevel
import KoL.Api
import KoL.HttpLowlevel
import KoL.Util
import KoL.UtilTypes
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List
import Data.Maybe
import Data.Time
import Network.CGI (formDecode)
import Network.HTTP
import Network.Stream (ConnError (ErrorClosed))
import Network.URI
import System.IO
import System.Random
import Text.Regex.TDFA
import qualified Data.ByteString.Char8
import qualified Data.Map
import qualified Network.Socket

doSERVER_DEBUG _ = return ()
--doSERVER_DEBUG x = putStrLn $ "SERVER DEBUG: " ++ x

make_sessionconn globalref kolproxy_direct_connection dblogstuff statestuff = do
	slowconn <- readIORef $ use_slow_http_ref_ $ globalref
	mkconnthing <- if slowconn
		then do
			putStrLn $ "INFO: Using slow server connections"
			return $ debug_do "making slow connection" $ slow_mkconnthing kolproxy_direct_connection
		else do
			putStrLn $ "INFO: Using fast server connections"
			return $ debug_do "making fast connection" $ fast_mkconnthing kolproxy_direct_connection
	cs <- mkconnthing
	cw <- mkconnthing
	jspmvref <- newIORef =<< newEmptyMVar
	lrjref <- newIORef Nothing
	lvjref <- newIORef Nothing
	tnow <- getCurrentTime
	lrs <- newIORef tnow
	lrw <- newIORef tnow
	statedata <- newIORef Nothing
	-- TODO: Change this raw API decoding business?
	let dologaction ref action = do
		doSERVER_DEBUG "dologaction"
		Just jsonobj <- readIORef (latestValidJson_ $ sessionData $ ref)
		let ai = rawDecodeApiInfo jsonobj
		dblogstuff ((charName ai) ++ "-" ++ (show $ ascension ai) ++ ".ascension-log.sqlite3") action
	let dostateaction ref action = do
		doSERVER_DEBUG "dostateaction"
		Just jsonobj <- readIORef (latestValidJson_ $ sessionData $ ref)
		let ai = rawDecodeApiInfo jsonobj
		statestuff ("character-" ++ (charName ai) ++ ".state-json.sqlite3") action
	luainstancesref <- newIORef $ Data.Map.empty
	laststoredstateref <- newIORef Nothing
	processpagestorestatereasonref <- newIORef Nothing
	storedstateidref <- newIORef (-1, -1)
	actionbarref <- newIORef Nothing
	return ServerSessionType {
		sequenceConnection_ = cs,
		chatConnection_ = cw,
		sequenceLastRetrieve_ = lrs,
		chatLastRetrieve_ = lrw,
		sessConnData_ = SessionDataType {
			jsonStatusPageMVarRef_ = jspmvref,
			latestRawJson_ = lrjref,
			latestValidJson_ = lvjref,
			doDbLogAction_ = dologaction,
			doStateAction_ = dostateaction,
			stateData_ = statedata,
			luaInstances_ = luainstancesref,
			lastStoredState_ = laststoredstateref,
			processPageStoreStateReason_ = processpagestorestatereasonref,
			storedStateId_ = storedstateidref,
			cachedActionbar_ = actionbarref
		}
	}

handle_kol_request sessionmastermv mvsequence mvchat logchan dropping_logchan dblogstuff statestuff globalref req send_response = do
	let cookie = findHeader HdrCookie req
	let Just uri = parseURIReference $ modded (show $ rqURI req)
		where modded x = if "//" `isPrefixOf` x then modded (tail x) else x
	let params = case rqBody req of
		"" -> Nothing
		x -> Just $ formDecode $ x

	kolproxy_host <- fromMaybe "http://www.kingdomofloathing.com/" <$> getEnvironmentSetting "KOLPROXY_SERVER"

	sc <- modifyMVar sessionmastermv $ \m -> do
		use_proxy <- getEnvironmentSetting "KOLPROXY_USE_PROXY_SERVER" -- TODO: merge with doHTTPreq code
		let kolproxy_direct_connection = case use_proxy of
			Nothing -> kolproxy_host
			Just p -> "proxy://" ++ p ++ "/"
		let m_id = (cookie_to_sessid cookie, kolproxy_direct_connection)
		doSERVER_DEBUG $ "m: " ++ (show $ Data.Map.keys m)
		case Data.Map.lookup m_id m of
			Just x -> do
				doSERVER_DEBUG $ "returning (m, x) " ++ show m_id
				return (m, x)
			Nothing -> do
				doSERVER_DEBUG $ "+++ making new (m, x) +++ " ++ show m_id
				sessionconn <- make_sessionconn globalref kolproxy_direct_connection dblogstuff statestuff
				return (Data.Map.insert m_id sessionconn m, sessionconn)

	let isChat = (uriPath uri) `elem` ["/favicon.ico", "/newchatmessages.php", "/submitnewchat.php"]

	let useragent = kolproxy_version_string ++ " (" ++ platform_name ++ ")" ++ case findHeader HdrUserAgent req of
		Just browseragent -> if (browseragent =~ "Safari") && (not (browseragent =~ "Chrome"))
			then " " ++ browseragent ++ " NginxSafariBugWorkaround/1.0 (Faking Chrome/version)"
			else " " ++ browseragent
		_ -> ""

	-- TODO: merge the isChat parts: logchan, lastRetreieve, connLogSymbol, getconn, mvseq
	let baseref = RefType {
		logstuff_ = LogRefStuff { logchan_ = if isChat then dropping_logchan else logchan, solid_logchan_ = logchan },
		processingstuff_ = undefined,
		otherstuff_ = OtherRefStuff {
			connection_ = ConnectionType {
				cookie_ = cookie,
				useragent_ = useragent,
				hostUri_ = fromJust $ parseURI kolproxy_host,
				lastRetrieve_ = if isChat then chatLastRetrieve_ sc else sequenceLastRetrieve_ sc,
				connLogSymbol_ = if isChat then "c" else "s",
				getconn_ = if isChat then chatConnection_ sc else sequenceConnection_ sc
			},
			sessionData_ = sessConnData_ sc
		},
		stateValid_ = False,
		globalstuff_ = globalref
	}

	writeChan (if isChat then mvchat else mvsequence) (uri, params, baseref, send_response)

data HandleConnectionResult = PlainResult String String | HtmlResult String String Bool | KolRequest (Request String)

handle_connection globalref recvdata sessionmastermv = do
	doSERVER_DEBUG "> got request"
	case recvdata of
		Left err -> do
			if err == ErrorClosed
				then putStrLn $ "INFO: Web browser closed connection before completing page request."
				else putStrLn $ "WARNING: Error receiving browser request: " ++ (show err)
			return $ PlainResult ("Error getting request from browser: " ++ show err) "/kolproxy-error"
		Right req -> do
			let uri = uriPath $ rqURI $ req
			let send_plain str = return $ PlainResult str uri
			let send_html str = return $ HtmlResult str uri False
			case uri of
				"/kolproxy-test" -> send_plain "Kolproxy is alive."
				"/kolproxy-network-test" -> do
					let test url = do
						putStrLn $ "Testing slow: " ++ url
						(effuri, body, hdrs, code) <- doHTTPreq (mkreq True "kolproxy-network-test" Nothing (mkuri url) Nothing True)
						putStrLn $ "  result: " ++ (show (effuri, Data.ByteString.Char8.length $ body, code))
						putStrLn $ "  headers: " ++ show hdrs

						putStrLn $ "Testing fast: " ++ url
						(effuri, body, hdrs, code) <- doHTTPreq (mkreq False "kolproxy-network-test" Nothing (mkuri url) Nothing True)
						putStrLn $ "  result: " ++ (show (effuri, Data.ByteString.Char8.length $ body, code))
						putStrLn $ "  headers: " ++ show hdrs
					test "http://www.houeland.com/kolproxy/latest-version"
					test "http://www.kingdomofloathing.com/sendjickmail.php"
					test "http://www.kingdomofloathing.com/login.php"
					send_plain "Simple network is OK?"
				"/kolproxy-secretkey" -> send_plain ("Kolproxy session key: " ++ (show $ shutdown_secret_ $ globalref))
				"/kolproxy-use-slow-http" -> do
					let maybeparams = decodeUrlParams $ rqURI $ req
					if (lookup "secretkey" =<< maybeparams) == Just (shutdown_secret_ $ globalref)
						then do
							writeIORef (use_slow_http_ref_ globalref) ((lookup "enable" =<< maybeparams) /= Just "yes")
							modifyMVar sessionmastermv $ \_m -> return (Data.Map.empty, "Modified.")
							send_html "<html><body>Switched to slower HTTP/1.0 compatibility mode.<br><br><a href=\"/\">Back to login</a>.</body></html>"
						else send_html "<html><body><p style=\"color: darkorange\">Denied.</p></body></html>"
				"/kolproxy-troubleshooting" -> do
					let line1 = "Badly behaving network equipment, firewalls, or anti-virus are frequent sources of kolproxy problems.<br>"
					let line2 = "<a href=\"/kolproxy-use-slow-http?secretkey=" ++ (shutdown_secret_ $ globalref) ++ "\">Click here to try using slower HTTP/1.0 requests instead, which might help.</a>"
					send_html $ line1 ++ line2
				"/kolproxy-shutdown" -> do
					let maybeparams = decodeUrlParams $ rqURI $ req
					if (lookup "secretkey" =<< maybeparams) == Just (shutdown_secret_ $ globalref)
						then return $ HtmlResult "<html><body><p style=\"color: green\">Closing.</p></body></html>" uri True
						else send_html "<html><body><p style=\"color: darkorange\">Denied.</p></body></html>"
				_ -> return $ KolRequest req

make_globalref = do
	environment_settings <- do
		listenpublic <- getEnvironmentSetting "KOLPROXY_LISTEN_PUBLIC"
		actionbarstate <- getEnvironmentSetting "KOLPROXY_STORE_STATE_IN_ACTIONBAR"
		localstate <- getEnvironmentSetting "KOLPROXY_STORE_STATE_LOCALLY"
		return $ EnvironmentSettings {
			store_state_in_actionbar_ = (actionbarstate /= Just "0"),
			store_state_locally_ = (localstate /= Just "0"),
			store_ascension_logs_ = True,
			store_chat_logs_ = True,
			store_info_logs_ = True,
			listen_public_ = (listenpublic == Just "1")
		}

	let openlog filename = do
		h <- openFile ("logs/info/" ++ filename) AppendMode
		hSetBuffering h LineBuffering
		return h

	indentref <- newIORef 0
	blockluaref <- newIORef False
	hfiles <- openlog "files-downloaded.txt"
	htiming <- openlog "timing-log.txt"
	hlua <- openlog "lua-log.txt"
	hhttp <- openlog "http-log.txt"
	shutdown_secret <- get_md5 <$> show <$> (randomIO :: IO Integer)

	chatopendb <- create_db "sqlite3 chatlog" "chat-log.sqlite3"
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS public(mid INTEGER PRIMARY KEY NOT NULL, time INTEGER NOT NULL, channel TEXT NOT NULL, playerid INTEGER NOT NULL, msg TEXT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS private(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, time INTEGER NOT NULL, playerid INTEGER NOT NULL, msg TEXT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS other(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, time INTEGER NOT NULL, msg TEXT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS unrecognized(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS oldchat(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, text TEXT NOT NULL);" []

	chatlogchan <- newChan
	forkIO_ "kps:chatlogchan" $ forever $ do
		chanaction <- readChan chatlogchan
		chanaction chatopendb

	use_slow_http_ref <- newIORef =<< do
		envhttp10 <- getEnvironmentSetting "KOLPROXY_USE_HTTP10"
		case envhttp10 of
			Just "1" -> return True
			Just "0" -> return False
			_ -> check_for_http10
	have_logged_in_ref <- newIORef False
	tnow <- getCurrentTime
	last_datafile_update_ref <- newIORef $ addUTCTime (fromInteger (-60000)) tnow

	return GlobalRefStuff {
		logindents_ = indentref,
		blocking_lua_scripting_ = blockluaref,
		h_files_downloaded_ = hfiles,
		h_timing_log_ = htiming,
		h_lua_log_ = hlua,
		h_http_log_ = hhttp,
		shutdown_secret_ = shutdown_secret,
		doChatLogAction_ = \action -> writeChan chatlogchan action,
		use_slow_http_ref_ = use_slow_http_ref,
		have_logged_in_ref_ = have_logged_in_ref,
		lastDatafileUpdate_ = last_datafile_update_ref,
		environment_settings_ = environment_settings
	}

kolproxy_setup_refstuff = do
	(logchan, dropping_logchan) <- do
		dropping_logchan <- newChan
		forkIO_ "kps:droplogchan" $ forever $ readChan dropping_logchan
		logchan <- newChan
		forkIO_ "kps:logchan" $ forever $ debug_do "writelog" $ join $ readChan $ logchan
		return (logchan, dropping_logchan)

	globalref <- make_globalref

	return (logchan, dropping_logchan, globalref)

runProxyServer r rchat portnum = do
	(logchan, dropping_logchan, globalref) <- kolproxy_setup_refstuff

	-- TODO: get rid of fakeref here!
	let _fake_other = OtherRefStuff {
		connection_ = undefined,
		sessionData_ = undefined
	}
	let logref = LogRefStuff { logchan_ = logchan, solid_logchan_ = logchan }
	let _log_fakeref = RefType { logstuff_ = logref, processingstuff_ = undefined, otherstuff_ = _fake_other, stateValid_ = undefined, globalstuff_ = globalref }

	let try_handling send_response x = do
		result <- try x
		(send_response $ case result of
			Right resp -> resp
			Left err -> mkResponse (5,0,0) [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")] $ Data.ByteString.Char8.pack $ "Error:\n\n" ++ show (err :: SomeException)) `catch` (\e -> do
				putWarningStrLn $ "send_response exception: " ++ show (e :: SomeException))

	mvsequence <- newChan
	forkIO_ "kps:mvseq" $ forever $ do
		(uri, params, cookie, send_response) <- readChan mvsequence
		try_handling send_response $ debug_do ("sequence response for: " ++ show uri) $ do
			log_file_retrieval _log_fakeref ("proxy:" ++ show uri) params
			log_time_uri _log_fakeref "request" uri
			resp <- log_time_interval _log_fakeref ("creating response for: " ++ show uri) $ r uri params cookie
			return resp
	mvchat <- newChan
	forkIO_ "kps:mvchat" $ forever $ do
		(uri, params, cookie, send_response) <- readChan mvchat
		forkIO_ "kps:mvchattry" $ do -- Serve asynced, possible private-message loss until server is fixed
-- 		do -- Serve synced, possible hang on timeouts, still can't guarantee private-messages
			try_handling send_response $ debug_do ("chat response for: " ++ show uri) $ rchat uri params cookie

	sessionmastermv <- newMVar Data.Map.empty

	dblogmapmv <- newMVar Data.Map.empty
	let dblogstuff filename action = do
		chan <- modifyMVar dblogmapmv $ \m -> do
			case Data.Map.lookup filename m of
				Just x -> return (m, x)
				Nothing -> do
					putStrLn $ "DB: Opening log database: " ++ filename
					opendb <- create_db "sqlite3 log" filename
					do_db_query_ opendb "CREATE TABLE IF NOT EXISTS pageloads(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, time TEXT NOT NULL, statusbefore TEXT, statusafter TEXT, statebefore TEXT, stateafter TEXT, sessionid TEXT NOT NULL, requestedurl TEXT NOT NULL, parameters TEXT, retrievedurl TEXT, pagetext TEXT);" []
					x <- newChan
					forkIO_ "kps:dblogchan" $ forever $ do
						chanaction <- readChan x
						chanaction opendb
					return (Data.Map.insert filename x m, x)
		writeChan chan action

	statemapmv <- newMVar Data.Map.empty
	let statestuff filename action = do
		chan <- modifyMVar statemapmv $ \m -> do
			case Data.Map.lookup filename m of
				Just x -> return (m, x)
				Nothing -> do
					putStrLn $ "  DB: Opening state database: " ++ filename
					statedb <- create_db "state" filename
					putStrLn $ "  DB: State database loaded."
					x <- newChan
					forkIO_ "kps:dbstatechan" $ forever $ do
						chanaction <- readChan x
						chanaction statedb
					return (Data.Map.insert filename x m, x)
		writeChan chan action

	sock <- mklistensocket (listen_public _log_fakeref) portnum

	forkIO_ "kps:updatedatafiles" $ do
		update_data_files
	forkIO_ "kps:launchkolproxy" $ do
		envlaunch <- getEnvironmentSetting "KOLPROXY_LAUNCH_BROWSER"
		when (envlaunch /= Just "0") $ do
			platform_launch portnum

	let do_loop = do
		doSERVER_DEBUG "listening on socket"
		(sh, _) <- debug_do "accept socket" $ Network.Socket.accept sock
		h <- debug_do "socket connection" $ socketConnection "???" (fromIntegral portnum) sh
		doSERVER_DEBUG $ "doing socket:" ++ (show sh)

		let send_response resp = do
			send_http_response h resp
			end_http h

		recvdata <- debug_do "receive HTTP" $ kolproxy_receiveHTTP h
		hcr <- handle_connection globalref recvdata sessionmastermv
		case hcr of
			PlainResult pt uri -> do
				resp <- makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack pt) uri [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")]
				send_response resp
				do_loop
			HtmlResult pt uri shutdown -> do
				resp <- makeResponse (Data.ByteString.Char8.pack pt) uri []
				send_response resp
				when (not shutdown) $ do_loop
			KolRequest req -> do
				handle_kol_request sessionmastermv mvsequence mvchat logchan dropping_logchan dblogstuff statestuff globalref req send_response
				do_loop

	debug_do "do_loop" do_loop

	putStrLn "Shutting down."

mkResponse code hdrs text = Response code "" (map (\(x,y) -> mkHeader (HdrCustom x) y) hdrs) text

makeResponse text _effuri headers = return $ mkResponse (2,0,0) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) text

makeErrorResponse text _effuri headers = do
	let newtext = Data.ByteString.Char8.concat [text, (Data.ByteString.Char8.pack "<br><br>{&nbsp;<a href=\"/kolproxy-troubleshooting\">Click here for kolproxy troubleshooting.</a>&nbsp;}")]
	return $ mkResponse (2,0,0) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) newtext

makeResponseWithNoExtraHeaders text _effuri headers = return $ mkResponse (2,0,0) headers text

makeRedirectResponse text _effuri headers = return $ mkResponse (3,0,2) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) text
