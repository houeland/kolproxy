import Prelude
import HardcodedGameStuff
import KolproxyServer
import Logging
import LogParser
import Lua
import PlatformLowlevel
import State
import KoL.Api
import KoL.Http
import KoL.Util
import KoL.UtilTypes
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List (intercalate)
import Data.Maybe
import Data.Time
import Network.URI
import System.Directory (doesFileExist, createDirectoryIfMissing)
import System.Environment (getArgs)
import System.IO
import Text.Regex.TDFA
import qualified Data.ByteString.Char8

get_the_state ref = do
	cr <- canReadState ref
	if cr
		then do
			(_, y) <- readIORef (state ref)
			return $ Just y
		else return Nothing

doProcessPage ref uri params = do
	status_before_func <- getstatusfunc ref
	log_time <- getZonedTime -- TODO: ask CDM for rightnow in API

	state_before <- get_the_state ref

	log_file_retrieval ref uri params

	(xf, mvf) <- (nochangeRawRetrievePageFunc ref) ref uri params True
	when ((uriPath uri) == "/actionbar.php") $ do
		putDebugStrLn $ "requested actionbar: " ++ show uri ++ " | " ++ show params
		writeIORef (cachedActionbar_ $ sessionData $ ref) Nothing

	let status_after_func = do
		readMVar =<< mvf

	mv <- newEmptyMVar

	forkIO_ "proxy:process" $ do
		x <- try $ do
			(pagetext, effuri, hdrs, code) <- log_time_interval ref ("fetchpage: " ++ (show uri)) $ xf

			let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
			y <- log_time_interval ref ("processing: " ++ (show uri)) $ runProcessScript ref uri effuri pagetext allparams

			state_after <- get_the_state ref

			log_page_result ref status_before_func log_time state_before uri params effuri pagetext status_after_func state_after

			return (y, pagetext, effuri, hdrs, code)
		putMVar mv =<< case x of
			Right (Right msg, _, effuri, hdrs, code) -> do
				return $ Right (msg, effuri, hdrs, code)
			Right (Left (msg, trace), pagetext, effuri, hdrs, code) -> do
				putErrorStrLn $ "Error processing page[" ++ show uri ++ "]: " ++ msg ++ "\n" ++ trace
				return $ Left (add_error_message_to_page ("process-page.lua error: " ++ msg ++ "\n" ++ trace) pagetext, effuri, hdrs, code)
			Left e -> do
				putErrorStrLn $ "Exception while processing page[" ++ show uri ++ "]: " ++ (show (e :: SomeException))
				return $ Left (add_error_message_to_page ("process-page.lua exception: " ++ (show e)) (Data.ByteString.Char8.pack "{ Kolproxy page processing. }"), mkuri "/error", [], 500)

	return $ do
		readMVar mv

doProcessPageChat ref uri params = do
	mv <- newEmptyMVar

	forkIO_ "proxy:processchat" $ do
		x <- try $ do
			(xf, _) <- internalKolRequest_pipelining ref uri params False
			xf
		putMVar mv =<< case x of
			Right (pagetext, effuri, hdrs, code) -> do
				case uriPath effuri of
					-- TODO: Make sure they're logged in order!
					"/newchatmessages.php" -> log_chat_messages ref pagetext
					"/submitnewchat.php" -> log_chat_messages ref pagetext
					_ -> return () -- TODO: Log this too?
				return $ Right (pagetext, effuri, hdrs, code)
			Left e -> do
				return $ Left (add_error_message_to_page ("processchat exception: " ++ (show (e :: SomeException))) (Data.ByteString.Char8.pack "{ Kolproxy page processing. }"), mkuri "/error", [], 500)
	return $ do
		readMVar mv

statusfunc ref = do
	mv <- readIORef $ jsonStatusPageMVarRef_ $ sessionData $ ref
	return $ ((do
		x <- readMVar mv
		case x of
			Right r -> return r
			Left err -> throwIO err) `catch` (\e -> do
				putDebugStrLn $ "statusfunc exception: " ++ show (e :: SomeException)
				throwIO e))

kolProxyHandlerChat uri params baseref = do
	let ref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPageChat,
			nochangeRawRetrievePageFunc_ = internalKolRequest_pipelining,
			getstatusfunc_ = statusfunc
		}
	}
	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]
	x <- case uriPath uri of
		"/favicon.ico" -> do
			Right (x, u, _, _) <- join $ (processPage ref) ref uri params
			return $ Right (x, u, "text/html; charset=UTF-8")
		_ -> runChatRequestScript ref uri allparams
	case x of
		Right (msg, u, ct) -> do
			makeResponseWithNoExtraHeaders msg u [("Content-Type", ct), ("Cache-Control", "no-cache")]
		Left (msg, trace) -> do
			putWarningStrLn $ "chat error: " ++ (show msg ++ "\n" ++ trace)
			makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack "") uri [("Cache-Control", "no-cache")]

make_ref baseref = do
	let ref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPage,
			nochangeRawRetrievePageFunc_ = internalKolRequest_pipelining,
			getstatusfunc_ = statusfunc
		}
	}
	state_is_ok <- (do
		mjs <- readIORef (latestRawJson_ $ sessionData $ ref)
		when (isNothing mjs) $ do
			mv <- readIORef (jsonStatusPageMVarRef_ $ sessionData $ ref)
			apixf <- load_api_status_to_mv_mkapixf ref
			load_api_status_to_mv ref mv apixf
		force_latest_status_parse ref
		ensureLoadedState ref
		return True) `catch` (\e -> do
			putWarningStrLn $ "loadstate exception: " ++ show (e :: SomeException)
			return False)
	return ref { stateValid_ = state_is_ok }

kolProxyHandler uri params baseref = do
	t <- getCurrentTime
	tlast <- readIORef (lastDatafileUpdate_ $ globalstuff_ $ baseref)
	when (diffUTCTime t tlast > 10 * 60) $ do
		writeIORef (lastDatafileUpdate_ $ globalstuff_ $ baseref) t
		forkIO_ "proxy:updatedatafiles" $ update_data_files -- TODO: maybe not for *every single page*?

	origref <- log_time_interval baseref ("make ref for: " ++ (show uri)) $ make_ref baseref

	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]

	let check_pwd_for action = do
		ai <- getApiInfo origref
		if lookup "pwd" allparams == Just (pwd ai)
			then return action
			else return $ Just $ makeErrorResponse (Data.ByteString.Char8.pack $ "Invalid pwd field") uri []

	let handle_login (pt, effuri, allhdrs, code) = do
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
--				handleRequest origref uri effuri hdrs params pt
				makeErrorResponse pt effuri hdrs
			else (do
				newref <- do
					mv <- newEmptyMVar
					writeIORef (jsonStatusPageMVarRef_ $ sessionData $ origref) mv
					writeIORef (latestRawJson_ $ sessionData $ origref) Nothing
					writeIORef (latestValidJson_ $ sessionData $ origref) Nothing
					make_ref $ baseref { otherstuff_ = (otherstuff_ origref) { connection_ = (connection_ $ otherstuff_ $ origref) { cookie_ = new_cookie } } }
				putInfoStrLn $ "login.php -> getting server state"
				ai <- getApiInfo newref
				putInfoStrLn $ "Logging in as " ++ (charName ai) ++ " (ascension " ++ (show $ ascension ai) ++ ")"
				loadSettingsFromServer newref

				forkIO_ "proxy:compresslogs" $ compressLogs (charName ai) (ascension ai)

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
						return internalKolRequest
					_ -> do
						putInfoStrLn $ "Logging in over https..."
						return internalKolHttpsRequest
				(pt, effuri, allhdrs, code) <- loginrequestfunc uri (Just p_sensitive) (Nothing, useragent_ $ connection $ origref, hostUri_ $ connection $ origref, Nothing) True
				handle_login (pt, effuri, allhdrs, code)

		"/custom-clear-lua-script-cache" -> check_pwd_for $ Just $ do
			reset_lua_instances origref
			writeIORef (blocking_lua_scripting origref) False
			makeResponse (Data.ByteString.Char8.pack $ "Cleared Lua script cache.") uri []

		"/custom-logs" -> check_pwd_for $ Just $ do
			pt <- showLogs (lookup "which" allparams) (fromJust $ lookup "pwd" allparams)
			makeResponse (Data.ByteString.Char8.pack pt) uri []

		"/kolproxy-automation-script" -> check_pwd_for $ Nothing
		"/kolproxy-script" -> check_pwd_for $ Nothing

		"/kolproxy-fileserver" -> check_pwd_for $ Just $ do
			resp <- case lookup "filename" allparams of
				Just p -> if (p =~ "[a-z]+/[A-Za-z_]+\\.?[A-Za-z_]*")
					then do
						exists <- doesFileExist ("fileserver/" ++ p)
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

	retresp <- log_time_interval origref ("run handler for: " ++ (show uri)) $ case response of
		Just r -> r
		Nothing -> do
			when (uriPath uri == "/logout.php") $ do
				canread_before <- canReadState origref
				when canread_before $ storeSettings origref
			let reqtype = if isJust params then "POST" else "GET"
			response <- log_time_interval origref ("browser request: " ++ (show uri)) $ runBrowserRequestScript origref uri allparams reqtype
			case response of
				Left (pt, effuri) -> makeErrorResponse pt effuri []
				Right (pt, effuri, ct) -> makeResponseWithNoExtraHeaders pt effuri [("Content-Type", ct), ("Cache-Control", "no-cache")]
	return retresp

runKolproxy = (do
	have_process_page <- doesFileExist "scripts/kolproxy-internal/process-page.lua"
	if have_process_page
		then do
			putInfoStrLn $ "Starting..."
			createDirectoryIfMissing True "cache"
			createDirectoryIfMissing True "cache/data"
			createDirectoryIfMissing True "cache/files"
			createDirectoryIfMissing True "logs"
			createDirectoryIfMissing True "logs/chat"
			createDirectoryIfMissing True "logs/scripts"
			createDirectoryIfMissing True "logs/info"
			createDirectoryIfMissing True "logs/parsed"
			createDirectoryIfMissing True "logs/api"
			createDirectoryIfMissing True "scripts/custom-autoload"
		else do
			putWarningStrLn $ "Trying to start without required files in the \"scripts\" directory."
			putWarningStrLn $ "  Did you unzip the files correctly?"
			-- TODO: give error message in browser
	portenv <- getEnvironmentSetting "KOLPROXY_PORT"
	let portnum = case portenv of
		Just x -> fromJust $ read_as x :: Integer
		Nothing -> 18481
	runProxyServer kolProxyHandler kolProxyHandlerChat portnum) `catch` (\e -> putDebugStrLn ("runKolproxy exception: " ++ show (e :: Control.Exception.SomeException)))

main = platform_init $ do
	hSetBuffering stdout LineBuffering
	args <- getArgs
	case args of
		["--runbotscript", botscriptfilename] -> runbot botscriptfilename
		_ -> runKolproxy
	putInfoStrLn $ "Done! (main finished)"
	return ()

runbot filename = do
	(logchan, dropping_logchan, globalref) <- kolproxy_setup_refstuff

	let login_useragent = kolproxy_version_string ++ " (" ++ platform_name ++ ")" ++ " BotScript/0.1 (" ++ filename ++ ")"
	let login_host = fromJust $ parseURI $ "http://www.kingdomofloathing.com/"

	sc <- make_sessionconn globalref "http://www.kingdomofloathing.com/" (error "dblogstuff")

	Just username <- getEnvironmentSetting "KOLPROXY_BOTSCRIPT_USERNAME"
	Just passwordmd5hash <- getEnvironmentSetting "KOLPROXY_BOTSCRIPT_PASSWORDMD5HASH"

	cookie <- login (login_useragent, login_host) username passwordmd5hash

	let baseref = RefType {
		logstuff_ = LogRefStuff { logchan_ = dropping_logchan, solid_logchan_ = logchan },
		processingstuff_ = error "processing",
		otherstuff_ = OtherRefStuff {
			connection_ = ConnectionType {
				cookie_ = cookie,
				useragent_ = login_useragent,
				hostUri_ = login_host,
				lastRetrieve_ = sequenceLastRetrieve_ sc,
				connLogSymbol_ = "b",
				getconn_ = sequenceConnection_ sc
			},
			sessionData_ = sessConnData_ sc
		},
		stateValid_ = False,
		globalstuff_ = globalref
	}

	let okref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPageChat,
			nochangeRawRetrievePageFunc_ = internalKolRequest_pipelining,
			getstatusfunc_ = statusfunc
		},
		stateValid_ = False
	}

	runBotScript okref filename
