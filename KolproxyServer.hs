{-# LANGUAGE CPP #-}

module KolproxyServer where

import Prelude hiding (read, catch)
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
-- doSERVER_DEBUG x = putStrLn $ "SERVER DEBUG: " ++ x

make_sessionconn kolproxy_direct_connection dblogstuff statestuff = do
	cs <- mkconnthing kolproxy_direct_connection
	cw <- mkconnthing kolproxy_direct_connection
	jspmvref <- newIORef =<< newEmptyMVar
	lrjref <- newIORef Nothing
	lvjref <- newIORef Nothing
	tnow <- getCurrentTime
	lrs <- newIORef tnow
	lrw <- newIORef tnow
	idata <- newIORef Nothing
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
		statestuff ("character-" ++ (charName ai) ++ ".state.sqlite3") action
	luainstancesref <- newIORef $ Data.Map.empty
	laststoredstateref <- newIORef Nothing
	return ServerSessionType {
		sequenceConnection_ = cs,
		wheneverConnection_ = cw,
		sequenceLastRetrieve_ = lrs,
		wheneverLastRetrieve_ = lrw,
		sessConnData_ = SessionDataType {
			jsonStatusPageMVarRef_ = jspmvref,
			latestRawJson_ = lrjref,
			latestValidJson_ = lvjref,
			itemData_ = idata,
			doDbLogAction_ = dologaction,
			doStateAction_ = dostateaction,
			stateData_ = statedata,
			luaInstances_ = luainstancesref,
			lastStoredState_ = laststoredstateref
		}
	}

handle_connection sessionmastermv mvsequence mvwhenever h logchan dropping_logchan sh dblogstuff statestuff globalref = do
	recvdata <- kolproxy_receiveHTTP h
	doSERVER_DEBUG "> got request"
	case recvdata of
		Left err -> do
			if err == ErrorClosed
				then putStrLn $ "INFO: browser closed request"
				else putStrLn $ "WARNING: error receiving browser request: " ++ (show err)
			makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack $ "Error getting request from browser: " ++ show err) "/kolproxy-error" [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")]
		Right req -> case uriPath $ rqURI $ req of
			"/kolproxy-test" -> do
				makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack "Kolproxy is alive.") "/kolproxy-test" [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")]
			"/kolproxy-shutdown" -> do
				let maybeparams = decodeUrlParams $ rqURI $ req
				if (lookup "secretkey" =<< maybeparams) == Just (shutdown_secret_ $ globalref)
					then do
						writeIORef (shutdown_ref_ $ globalref) True
						makeResponse (Data.ByteString.Char8.pack "<html><body><span style=\"color: green\">Closing.</span></body></html>") "/kolproxy-shutdown" []
					else do
						makeResponse (Data.ByteString.Char8.pack "<html><body><span style=\"color: darkorange\">Denied.</span></body></html>") "/kolproxy-shutdown" []
			_ -> do
				doSERVER_DEBUG $ "got request: " ++ (show $ rqURI req) ++ " [" ++ show sh ++ "]"
				let cookie = findHeader HdrCookie req
				let Just uri = parseURIReference $ modded (show $ rqURI req)
					where modded x = if "//" `isPrefixOf` x then modded (tail x) else x
				let params = case rqBody req of
					"" -> Nothing
					x -> Just $ formDecode $ x

				let skip_running_printers = False

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
							sessionconn <- make_sessionconn kolproxy_direct_connection dblogstuff statestuff
							return (Data.Map.insert m_id sessionconn m, sessionconn)

				let useWhenever = (uriPath uri) `elem` ["/favicon.ico", "/newchatmessages.php", "/submitnewchat.php"]

				let useragent = case findHeader HdrUserAgent req of
					Just browseragent -> if (browseragent =~ "Safari") && (not (browseragent =~ "Chrome"))
						then kolproxy_version_string ++ " (" ++ platform_name ++ ")" ++ " " ++ browseragent ++ " NginxSafariBugWorkaround/1.0 (Faking Chrome/version)"
						else kolproxy_version_string ++ " (" ++ platform_name ++ ")" ++ " " ++ browseragent
					_ -> kolproxy_version_string ++ " (" ++ platform_name ++ ")"

				let baseref = RefType {
					logstuff_ = LogRefStuff { logchan_ = if useWhenever then dropping_logchan else logchan, solid_logchan_ = logchan },
					processingstuff_ = undefined,
					otherstuff_ = OtherRefStuff {
						connection_ = ConnectionType {
							cookie_ = cookie,
							useragent_ = useragent,
							hostUri_ = fromJust $ parseURI kolproxy_host,
							lastRetrieve_ = if useWhenever then wheneverLastRetrieve_ sc else sequenceLastRetrieve_ sc,
							connLogSymbol_ = if useWhenever then "w" else "s",
							getconn_ = if useWhenever then wheneverConnection_ sc else sequenceConnection_ sc
						},
						sessionData_ = sessConnData_ sc
					},
					stateValid_ = False,
					globalstuff_ = globalref,
					skipRunningPrinters_ = skip_running_printers
				}

				mymv <- newEmptyMVar
				writeChan (if useWhenever then mvwhenever else mvsequence) (uri, params, baseref, mymv)
				eitherresp <- takeMVar mymv

				-- TODO: is this ever Left? When there are read errors from server?
				return $ case eitherresp of
					Right resp -> resp
					Left err -> mkResponse (5,0,0) [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")] $ Data.ByteString.Char8.pack $ "Error:\n\n" ++ show err

make_globalref = do
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
	shutdown_secret <- get_md5 <$> show <$> (randomIO :: IO Integer) -- TODO: Not really important, but use stronger randomness here?
	shutdown_ref <- newIORef False

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

	return GlobalRefStuff {
		logindents_ = indentref,
		blocking_lua_scripting_ = blockluaref,
		h_files_downloaded_ = hfiles,
		h_timing_log_ = htiming,
		h_lua_log_ = hlua,
		h_http_log_ = hhttp,
		shutdown_secret_ = shutdown_secret,
		shutdown_ref_ = shutdown_ref,
		doChatLogAction_ = \action -> writeChan chatlogchan action
	}

runProxyServer r rwhenever portnum = do
	(logchan, dropping_logchan) <- do
		dropping_logchan <- newChan
		forkIO_ "kps:droplogchan" $ forever $ readChan dropping_logchan
		v <- getEnvironmentSetting "KOLPROXY_DISABLE_LOGGING"
		case v of
			-- TODO: not right, we get code we need to run! Should just disable the actual file writing?
			Just "I_PROMISE_I_AM_REALLY_SURE_I_WANT_TO_DISABLE_LOGGING" -> return (dropping_logchan, dropping_logchan)
			_ -> do
				logchan <- newChan
				forkIO_ "kps:logchan" $ forever $ ((join $ readChan $ logchan) `catch` (\e -> do
					putStrLn $ "writelog error: " ++ (show (e :: SomeException))))
				return (logchan, dropping_logchan)

	globalref <- make_globalref

	-- TODO: get rid of fakeref here!
	let _fake_other = OtherRefStuff {
		connection_ = undefined,
		sessionData_ = undefined
	}
	let logref = LogRefStuff { logchan_ = logchan, solid_logchan_ = logchan }
	let _log_fakeref = RefType { logstuff_ = logref, processingstuff_ = undefined, otherstuff_ = _fake_other, stateValid_ = undefined, globalstuff_ = globalref, skipRunningPrinters_ = undefined }

	mvsequence <- newChan
	forkIO_ "kps:mvseq" $ forever $ do
		(uri, params, cookie, mvresp) <- readChan mvsequence
		putMVar mvresp =<< ((try $ do
			log_file_retrieval _log_fakeref ("proxy:" ++ show uri) params
			log_time_uri _log_fakeref "request" uri
			resp <- log_time_interval _log_fakeref ("creating response for: " ++ (show uri)) $ r uri params cookie
			return resp) :: IO (Either SomeException (Response Data.ByteString.Char8.ByteString)))
	mvwhenever <- newChan
	forkIO_ "kps:mvwhen" $ forever $ do
		(uri, params, cookie, mvresp) <- readChan mvwhenever
		forkIO_ "kps:mvwhentry" $ do -- Serve asynced, possible private-message loss until server is fixed
-- 		do -- Serve synced, possible hang on timeouts
			putMVar mvresp =<< (try $ rwhenever uri params cookie)

	sessionmastermv <- newMVar Data.Map.empty

	dblogmapmv <- newMVar Data.Map.empty
	let dblogstuff filename action = do
		chan <- modifyMVar dblogmapmv $ \m -> do
			case Data.Map.lookup filename m of
				Just x -> return (m, x)
				Nothing -> do
					putStrLn $ "opening log db: " ++ filename
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
					putStrLn $ "opening state db: " ++ filename
					statedb <- create_db "state" filename
					x <- newChan
					forkIO_ "kps:dbstatechan" $ forever $ do
						chanaction <- readChan x
						chanaction statedb
					return (Data.Map.insert filename x m, x)
		writeChan chan action

	launched_ref <- newIORef False
	forkIO_ "kps:updatedatafiles" $ do
		update_data_files
	forkIO_ "kps:launchkolproxy" $ do
		writeIORef launched_ref True
		envlaunch <- getEnvironmentSetting "KOLPROXY_LAUNCH_BROWSER"
		when (envlaunch /= Just "0") $ do
			platform_launch portnum

	sock <- bracketOnError mksocket Network.Socket.sClose $ \s -> do
		Network.Socket.setSocketOption s Network.Socket.ReuseAddr 1
		Network.Socket.bindSocket s (Network.Socket.SockAddrInet (fromIntegral portnum) Network.Socket.iNADDR_ANY)
		Network.Socket.listen s Network.Socket.maxListenQueue
		return s

	let do_loop = do
		should_stop <- readIORef $ shutdown_ref_ $ globalref
		unless should_stop $ do
			doSERVER_DEBUG "listening on socket"
			(sh, _) <- Network.Socket.accept sock
#if __GLASGOW_HASKELL__ <= 702
			h <- socketConnection "???" sh
#else
			h <- socketConnection "???" (fromIntegral portnum) sh
#endif
			doSERVER_DEBUG $ "doing socket:" ++ (show sh)
			launched <- readIORef launched_ref
			if launched
				then ((forkIO_ "kps:handleconn" $ do
					resp <- handle_connection sessionmastermv mvsequence mvwhenever h logchan dropping_logchan sh dblogstuff statestuff globalref
					send_http_response h resp
					end_http h) `catch` (\e -> do
						putStrLn $ "proxyError IO: " ++ (show (e :: IOException))) `catch` (\e -> do
							putStrLn $ "proxyError Some: " ++ (show (e :: SomeException))
							throwIO e))
				else do
					void $ kolproxy_receiveHTTP h
					let resp = mkResponse (5,0,3) [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")] $ Data.ByteString.Char8.pack "Error: Kolproxy is still loading data files. Try again in a minute."
					send_http_response h resp
					end_http h
			doSERVER_DEBUG "...done with socket"
			do_loop
	do_loop

	putStrLn "Shutting down."

mkResponse code hdrs text = Response code "" (map (\(x,y) -> mkHeader (HdrCustom x) y) hdrs) text

makeResponse text _effuri headers = return $ mkResponse (2,0,0) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) text

makeResponseWithNoExtraHeaders text _effuri headers = return $ mkResponse (2,0,0) headers text

makeRedirectResponse text _effuri headers = return $ mkResponse (3,0,2) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) text
