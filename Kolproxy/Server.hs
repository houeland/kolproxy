module Kolproxy.Server where

import Prelude

import Kolproxy.Util
import Kolproxy.UtilTypes
import qualified Kolproxy.Api
import qualified Kolproxy.Handlers
import qualified Kolproxy.HardcodedGameStuff
import qualified Kolproxy.Http
import qualified Kolproxy.HttpLowlevel
import qualified Kolproxy.Logging
import qualified Kolproxy.LogParser
import qualified Kolproxy.Lua
import qualified Kolproxy.PlatformLowlevel
import qualified Kolproxy.State

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
import Text.Regex.TDFA
import qualified Data.ByteString.Char8
import qualified Data.Map
import qualified Network.Socket
import qualified System.Directory (doesFileExist)

make_sessionconn globalref kolproxy_direct_connection dblogstuff = do
	slowconn <- readIORef $ use_slow_http_ref_ $ globalref
	mkconnthing <- if slowconn
		then do
			putStrLn $ "INFO: Using slow server connections"
			return $ debug_do "making slow connection" $ Kolproxy.HttpLowlevel.slow_mkconnthing kolproxy_direct_connection
		else do
			putStrLn $ "INFO: Using fast server connections"
			return $ debug_do "making fast connection" $ Kolproxy.HttpLowlevel.fast_mkconnthing kolproxy_direct_connection
	cs <- mkconnthing
	cw <- mkconnthing
	jspmvref <- newIORef =<< newEmptyMVar
	lrjref <- newIORef Nothing
	lvjref <- newIORef Nothing
	tnow <- getCurrentTime
	lrs <- newIORef tnow
	lrw <- newIORef tnow
	statedata <- newIORef (("", -1, -1, ""), (Data.Map.empty, Data.Map.empty, Data.Map.empty, Data.Map.empty, Data.Map.empty))
	-- TODO: Change this raw API decoding business?
	let dologaction ref action = when (store_ascension_logs_ $ environment_settings_ $ globalref) $ do
		Just jsonobj <- readIORef (latestValidJson_ $ sessionData $ ref)
		let ai = Kolproxy.Api.rawDecodeApiInfo jsonobj
		dblogstuff ((Kolproxy.Api.charName ai) ++ "-" ++ (show $ Kolproxy.Api.ascension ai) ++ ".ascension-log.sqlite3") action
	luainstancesref <- newMVar Data.Map.empty
	laststoredstateref <- newIORef Nothing
	laststoredtimeref <- newIORef tnow
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
			stateData_ = statedata,
			luaInstances_ = luainstancesref,
			lastStoredState_ = laststoredstateref,
			lastStoredTime_ = laststoredtimeref,
			storedStateId_ = storedstateidref,
			cachedActionbar_ = actionbarref
		}
	}

get_kolproxy_direct_connection_details = do
	kolproxy_host <- fromMaybe "https://www.kingdomofloathing.com/" <$> getEnvironmentSetting "KOLPROXY_SERVER"
	use_proxy <- getEnvironmentSetting "KOLPROXY_USE_PROXY_SERVER" -- TODO: merge with doHTTPreq code
	let kolproxy_direct_connection = case use_proxy of
		Nothing -> kolproxy_host
		Just p -> "proxy://" ++ p ++ "/"
	return (kolproxy_direct_connection, fromJust $ parseURI kolproxy_host)

get_sessionconn sessionmaster globalref cookie = do
	let (sessionmastermv, dblogstuff) = sessionmaster
	let sessid = cookie_to_sessid cookie
	(kolproxy_direct_connection, kolproxy_hostUri) <- get_kolproxy_direct_connection_details
	sc <- modifyMVar sessionmastermv $ \m -> do
		case Data.Map.lookup sessid m of
			Just x -> return (m, x)
			Nothing -> do
				sessionconn <- make_sessionconn globalref kolproxy_direct_connection dblogstuff
				return (Data.Map.insert sessid sessionconn m, sessionconn)
	return (sc, kolproxy_hostUri)

get_useragent agentHdr = kolproxy_version_string ++ " (" ++ Kolproxy.PlatformLowlevel.platform_name ++ ")" ++ case agentHdr of
	Just browseragent -> if (browseragent =~ "Safari") && (not (browseragent =~ "Chrome"))
		then " " ++ browseragent ++ " NginxSafariBugWorkaround/1.0 (Faking Chrome/version)"
		else " " ++ browseragent
	_ -> ""

handle_kol_request sessionmaster mvsequence mvchat logchan dropping_logchan globalref req send_response = do
	let cookie = findHeader HdrCookie req
	let Just uri = parseURIReference $ modded (show $ rqURI req)
		where modded x = if "//" `isPrefixOf` x then modded (tail x) else x
	let params = case rqBody req of
		"" -> Nothing
		x -> Just $ formDecode $ x

	(sc, kolproxy_hostUri) <- get_sessionconn sessionmaster globalref cookie

	let isChat = (uriPath uri) `elem` ["/favicon.ico", "/newchatmessages.php", "/submitnewchat.php"]

	let useragent = get_useragent $ findHeader HdrUserAgent req

	-- TODO: merge the isChat parts: logchan, lastRetreieve, connLogSymbol, getconn, mvseq
	let baseref = RefType {
		logstuff_ = LogRefStuff { logchan_ = if isChat then dropping_logchan else logchan, solid_logchan_ = logchan },
		processPage_ = undefined,
		otherstuff_ = OtherRefStuff {
			connection_ = ConnectionType {
				cookie_ = cookie,
				useragent_ = useragent,
				hostUri_ = kolproxy_hostUri,
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

handleConnection globalref sessionmaster sock (portnum, mvsequence, mvchat, logchan, dropping_logchan) = do
	(sh, _) <- debug_do "accept socket" $ Network.Socket.accept sock
	h <- debug_do "socket connection" $ socketConnection "???" (fromIntegral portnum) sh

	let send_response resp = do
		Kolproxy.HttpLowlevel.send_http_response h resp
		Kolproxy.HttpLowlevel.end_http h

	recvdata <- debug_do "receive HTTP" $ Kolproxy.HttpLowlevel.kolproxy_receiveHTTP h

	let send_plain str uri = do
		resp <- makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack str) uri [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")]
		send_response resp
	let send_html str uri = do
		resp <- makeResponse (Data.ByteString.Char8.pack str) uri []
		send_response resp
	case recvdata of
		Left err -> do
			if err == ErrorClosed
				then putStrLn $ "INFO: Web browser closed connection before completing page request."
				else putStrLn $ "WARNING: Error receiving browser request: " ++ (show err)
			send_plain ("Error getting request from browser: " ++ show err) "/kolproxy-error"
			return True
		Right req -> do
			let uri = uriPath $ rqURI $ req
			case uri of
				"/kolproxy-test" -> do
					send_plain "Kolproxy is alive." uri
					return True
				"/kolproxy-use-slow-http" -> do
					let maybeparams = decodeUrlParams $ rqURI $ req
					if (lookup "secretkey" =<< maybeparams) == Just (shutdown_secret_ $ globalref)
						then do
							writeIORef (use_slow_http_ref_ globalref) ((lookup "enable" =<< maybeparams) /= Just "yes")
							let (sessionmastermv, _) = sessionmaster
							modifyMVar_ sessionmastermv $ \_m -> return Data.Map.empty
							send_html "<html><body>Switched to slower HTTP/1.0 compatibility mode.<br><br><a href=\"/\">Back to login</a>.</body></html>" uri
						else send_html "<html><body><p style=\"color: darkorange\">Denied.</p></body></html>" uri
					return True
				"/kolproxy-troubleshooting" -> do
					let line1 = "Badly behaving network equipment, firewalls, or anti-virus are frequent sources of kolproxy problems.<br>"
					let line2 = "<a href=\"/kolproxy-use-slow-http?secretkey=" ++ (shutdown_secret_ $ globalref) ++ "\">Click here to try using slower HTTP/1.0 requests instead, which might help.</a>"
					send_html (line1 ++ line2) uri
					return True
				"/kolproxy-shutdown" -> do
					let maybeparams = decodeUrlParams $ rqURI $ req
					if (lookup "secretkey" =<< maybeparams) == Just (shutdown_secret_ $ globalref)
						then do
							send_html "<html><body><p style=\"color: green\">Closing.</p></body></html>" uri
							return False
						else do
							send_html "<html><body><p style=\"color: darkorange\">Denied.</p></body></html>" uri
							return True
				_ -> do
					handle_kol_request sessionmaster mvsequence mvchat logchan dropping_logchan globalref req send_response
					return True

mkResponse code hdrs text = Response code "" (map (\(x,y) -> mkHeader (HdrCustom x) y) hdrs) text

makeResponse text _effuri headers = return $ mkResponse (2,0,0) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) text

makeErrorResponse text _effuri headers = do
	let newtext = Data.ByteString.Char8.concat [text, (Data.ByteString.Char8.pack "<br><br>{&nbsp;<a href=\"/kolproxy-troubleshooting\">Click here for kolproxy troubleshooting.</a>&nbsp;}")]
	return $ mkResponse (2,0,0) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) newtext

makeResponseWithNoExtraHeaders text _effuri headers = return $ mkResponse (2,0,0) headers text

makeRedirectResponse text _effuri headers = return $ mkResponse (3,0,2) (headers ++ [("Content-Type", "text/html; charset=UTF-8"), ("Cache-Control", "no-cache")]) text




kolProxyHandlerChat uri params baseref = do
	let ref = baseref {
		processPage_ = Kolproxy.Handlers.doProcessPageChat
	}
	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]
	x <- case uriPath uri of
		"/favicon.ico" -> do
			Right pr <- join $ (processPage ref) ref uri params
			let (x, u) = (pageBody pr, pageUri pr)
			return $ Right (x, u, "image/vnd.microsoft.icon")
		_ -> Kolproxy.Lua.runChatRequestScript ref uri allparams
	case x of
		Right (msg, u, ct) -> do
			makeResponseWithNoExtraHeaders msg u [("Content-Type", ct), ("Cache-Control", "no-cache")]
		Left (msg, trace) -> do
			putWarningStrLn $ "chat error: " ++ (show msg ++ "\n" ++ trace)
			makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack "") uri [("Cache-Control", "no-cache")]

make_ref baseref = do
	let ref = baseref {
		processPage_ = Kolproxy.Handlers.doProcessPage
	}
	state_result <- try $ do
		mjs <- readIORef (latestRawJson_ $ sessionData $ ref)
		when (isNothing mjs) $ do
			mv <- readIORef (jsonStatusPageMVarRef_ $ sessionData $ ref)
			apixf <- Kolproxy.Http.load_api_status_to_mv_mkapixf ref
			Kolproxy.Http.load_api_status_to_mv ref mv apixf
		Kolproxy.Api.force_latest_status_parse ref
		Kolproxy.State.ensureLoadedState ref
	case state_result of
		Right _ -> do
			return ref { stateValid_ = True }
		Left err -> do
			putWarningStrLn $ "loadstate exception: " ++ show (err :: SomeException)
			return ref { stateValid_ = False }

kolProxyHandler uri params baseref = do
	t <- getCurrentTime
	tlast <- readIORef (lastDatafileUpdate_ $ globalstuff_ $ baseref)
	when (diffUTCTime t tlast > 10 * 60) $ do
		writeIORef (lastDatafileUpdate_ $ globalstuff_ $ baseref) t
		forkIO_ "proxy:updatedatafiles" $ Kolproxy.HardcodedGameStuff.update_data_files -- TODO: maybe not for *every single page*?

	origref <- Kolproxy.Logging.log_time_interval baseref ("make ref for: " ++ (show uri)) $ make_ref baseref

	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]

	let check_pwd_for action = do
		ai <- Kolproxy.Api.getApiInfo origref
		if lookup "pwd" allparams == Just (Kolproxy.Api.pwd ai)
			then return action
			else return $ Just $ makeErrorResponse (Data.ByteString.Char8.pack $ "Invalid pwd field") uri []

	let handle_login pr = do
		let (pt, effuri, allhdrs, code) = (pageBody pr, pageUri pr, pageHeaders pr, pageHttpCode pr)
		let hdrs = filter (\(x, _y) -> (x == "Set-Cookie" || x == "Location")) allhdrs
		putDebugStrLn $ "Login requested " ++ (show $ uriPath uri) ++ ", got " ++ (show $ uriPath effuri)
		putDebugStrLn $ "  HTTP headers: " ++ show allhdrs
		let new_cookie = case filter (\(a, _b) -> a == "Set-Cookie") hdrs of
			[] -> Nothing
			(x:xs) -> Just $ intercalate "; " (map ((takeWhile (/= ';')) . snd) (x:xs)) -- TODO: Make readable
		putDebugStrLn $ "  old cookie: " ++ (show $ cookie_ $ connection $ origref)
		putDebugStrLn $ "  new cookie: " ++ (show new_cookie)
		if isNothing new_cookie
			then do
				putErrorStrLn $ "No cookie from logging in!"
				putErrorStrLn $ "  headers: " ++ (show hdrs)
				putErrorStrLn $ "  url: " ++ (show effuri)
				makeErrorResponse pt effuri hdrs
			else (do
				newref <- do
					mv <- newEmptyMVar
					writeIORef (jsonStatusPageMVarRef_ $ sessionData $ origref) mv
					writeIORef (latestRawJson_ $ sessionData $ origref) Nothing
					writeIORef (latestValidJson_ $ sessionData $ origref) Nothing
					make_ref $ baseref { otherstuff_ = (otherstuff_ origref) { connection_ = (connection_ $ otherstuff_ $ origref) { cookie_ = new_cookie } } }
				putInfoStrLn $ "login.php -> getting server state"
				ai <- Kolproxy.Api.getApiInfo newref
				putInfoStrLn $ "Logging in as " ++ (Kolproxy.Api.charName ai) ++ " (ascension " ++ (show $ Kolproxy.Api.ascension ai) ++ ")"
				Kolproxy.State.loadSettingsFromServer newref

				forkIO_ "proxy:compresslogs" $ Kolproxy.LogParser.compressLogs (Kolproxy.Api.charName ai) (Kolproxy.Api.ascension ai)

				makeRedirectResponse pt uri hdrs) `catch` (\e -> do
					putErrorStrLn $ "Failed to log in. Exception: " ++ (show (e :: Control.Exception.SomeException))
					if (code >= 300 && code < 400)
						then makeRedirectResponse pt uri hdrs
						else makeResponse pt uri hdrs)

	response <- case uriPath uri of
		"/login.php" -> case params of
			Nothing -> return Nothing
			Just p_sensitive -> return $ Just $ do
				loginrequestfunc <- case lookup "password" p_sensitive of
					Just "" -> do
						putInfoStrLn $ "Logging in..."
						return Kolproxy.Http.internalKolRequest
					_ -> do
						putInfoStrLn $ "Logging in over https..."
						return Kolproxy.Http.internalKolHttpsRequest
				handle_login =<< loginrequestfunc uri (Just p_sensitive) (Nothing, useragent_ $ connection $ origref, hostUri_ $ connection $ origref, Nothing) True

		"/kolproxy-clear-lua-script-cache" -> check_pwd_for $ Just $ do
			reset_lua_instances origref
			writeIORef (blocking_lua_scripting origref) False
			makeResponse (Data.ByteString.Char8.pack $ "Cleared Lua script cache.") uri []

		"/kolproxy-logs" -> check_pwd_for $ Just $ do
			pt <- Kolproxy.LogParser.showLogs (lookup "which" allparams) (fromJust $ lookup "pwd" allparams)
			makeResponse (Data.ByteString.Char8.pack pt) uri []

		"/kolproxy-automation-script" -> check_pwd_for $ Nothing
		"/kolproxy-script" -> check_pwd_for $ Nothing

		"/kolproxy-fileserver" -> check_pwd_for $ Just $ do
			resp <- case lookup "filename" allparams of
				Just p -> if (p =~ "[a-z]+/[A-Za-z_]+\\.?[A-Za-z_]*")
					then do
						exists <- System.Directory.doesFileExist ("fileserver/" ++ p)
						if exists
							then do
								contents <- Data.ByteString.Char8.readFile ("fileserver/" ++ p)
								let ct = case matchGroups "\\.([A-Za-z_]+)$" p of
									[["css"]] -> "text/css; charset=UTF-8"
									[["html"]] -> "text/html; charset=UTF-8"
									[["js"]] -> "text/javascript; charset=UTF-8"
									_ -> "text/plain; charset=UTF-8"
								return $ Just (contents, ct)
							else return Nothing
					else return Nothing
				_ -> return Nothing
			case resp of
				Nothing -> makeResponse (Data.ByteString.Char8.pack $ "Invalid request.") uri []
				Just (x, y) -> makeResponseWithNoExtraHeaders x uri [("Content-Type", y), ("Cache-Control", "max-age=3600")]
		_ -> return Nothing

	retresp <- Kolproxy.Logging.log_time_interval origref ("run handler for: " ++ (show uri)) $ case response of
		Just r -> r
		Nothing -> do
			when (uriPath uri == "/logout.php") $ do
				canread_before <- runWithRef origref canReadState
				when canread_before $ Kolproxy.State.storeSettings origref
			let reqtype = if isJust params then "POST" else "GET"
			response <- Kolproxy.Logging.log_time_interval origref ("browser request: " ++ (show uri)) $ Kolproxy.Lua.runBrowserRequestScript origref uri allparams reqtype
			case response of
				Left (pt, effuri) -> makeErrorResponse pt effuri []
				Right (pt, effuri, ct) -> makeResponseWithNoExtraHeaders pt effuri [("Content-Type", ct), ("Cache-Control", "no-cache")]
	return retresp

setupHandlerChannels ref = do
	let try_handling send_response x = do
		let errhdrs = [("Content-Type", "text/plain; charset=UTF-8"), ("Cache-Control", "no-cache")]
		result <- try x
		(send_response $ case result of
			Right resp -> resp
			Left err -> Kolproxy.Server.mkResponse (5,0,0) errhdrs $ Data.ByteString.Char8.pack $ "Error:\n\n" ++ show (err :: SomeException)) `catch` (\e -> do
				putWarningStrLn $ "send_response exception: " ++ show (e :: SomeException))
	mvsequence <- newChan
	forkIO_ "kps:mvseq" $ forever $ do
		(uri, params, cookie, send_response) <- readChan mvsequence
		try_handling send_response $ debug_do ("sequence response for: " ++ show uri) $ do
			Kolproxy.Logging.log_file_retrieval ref ("proxy:" ++ show uri) params
			Kolproxy.Logging.log_time_uri ref "request" uri
			resp <- Kolproxy.Logging.log_time_interval ref ("creating response for: " ++ show uri) $ Kolproxy.Server.kolProxyHandler uri params cookie
			return resp
	mvchat <- newChan
	forkIO_ "kps:mvchat" $ forever $ do
		(uri, params, cookie, send_response) <- readChan mvchat
		forkIO_ "kps:mvchattry" $ do -- Serve asynced, possible private-message loss until server is fixed
--              do -- Serve synced, possible hang on timeouts, still can't guarantee private-messages
			try_handling send_response $ debug_do ("chat response for: " ++ show uri) $ Kolproxy.Server.kolProxyHandlerChat uri params cookie
	return (mvsequence, mvchat)

