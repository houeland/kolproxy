import Prelude hiding (read, catch)
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
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List (intercalate)
import Data.Maybe
import Data.Time
import Network.CGI (formEncode)
import Network.URI
import System.Directory (doesFileExist, createDirectoryIfMissing)
--import System.Environment (getArgs)
import System.IO
import qualified Data.ByteString.Char8
import qualified Data.Map

get_the_state ref = do
	cr <- canReadState ref
	if cr
		then do
			Just (_, y) <- readIORef (state ref)
			return $ Just y
		else return Nothing

doProcessPage ref uri params = do
	status_before_func <- getstatusfunc ref
	log_time <- getZonedTime -- TODO: ask CDM for rightnow in API

	state_before <- get_the_state ref

	log_file_retrieval ref uri params

	(xf, mvf) <- (nochangeRawRetrievePageFunc ref) ref uri params True

	let status_after_func = do
		readMVar =<< mvf

	mv <- newEmptyMVar

	forkIO_ "proxy:process" $ do
		x <- try $ do
			(pagetext, effuri, hdrs) <- log_time_interval ref ("fetchpage: " ++ (show uri)) $ xf

			let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
			y <- log_time_interval ref ("processing: " ++ (show uri)) $ runProcessScript ref uri effuri pagetext allparams

			state_after <- get_the_state ref

			-- TODO: Make sure this is definitely the very next thing logged. Make a channel for logging and write to it
			forkIO_ "proxy:logresult" $ (do
				status_before <- status_before_func
				status_after <- status_after_func
				log_page_result ref (Right status_before) log_time state_before uri params effuri (Data.ByteString.Char8.unpack pagetext) status_after state_after
				return ()) `catch` (\e -> putStrLn $ "processpage logging error: " ++ (show (e :: KolproxyException)))

			return (y, pagetext, effuri, hdrs)
		putMVar mv =<< case x of
			Right (Right msg, _, effuri, hdrs) -> do
				return $ Right (msg, effuri, hdrs)
			Right (Left (msg, trace), pagetext, effuri, hdrs) -> do
				putStrLn $ "Error processing page[" ++ show uri ++ "]: " ++ msg ++ "\n" ++ trace
				return $ Left (add_error_message_to_page ("process-page.lua error: " ++ msg ++ "\n" ++ trace) pagetext, effuri, hdrs)
			Left e -> do
				putStrLn $ "Exception while processing page[" ++ show uri ++ "]: " ++ (show (e :: SomeException))
				return $ Left (add_error_message_to_page ("process-page.lua exception: " ++ (show e)) (Data.ByteString.Char8.pack "{ Kolproxy page processing. }"), mkuri "/error", [])

	return $ do
		readMVar mv

doProcessPageWhenever ref uri params = do
	xf <- fst <$> internalKolRequest_pipelining ref uri params False
	return $ do
		Right <$> xf

statusfunc ref = do
	mv <- readIORef $ jsonStatusPageMVarRef_ $ sessionData $ ref
	return $ do
		x <- readMVar mv
		case x of
			Right r -> return r
			Left err -> throwIO err

-- TODO: Redo how scripts are run and used to do chat, make it more similar to normal pages
kolProxyHandlerWhenever uri params baseref = do
	let ref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPageWhenever,
			nochangeRawRetrievePageFunc_ = internalKolRequest_pipelining,
			getstatusfunc_ = statusfunc
		}
	}
	Right (text, effuri, _hdrs) <- case uriPath uri of -- TODO: handle Left here?
		"/submitnewchat.php" -> do
			let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]
			let handle_normally msguri msgparams = do
				y <- join $ (processPage ref) ref msguri msgparams
				case y of
					Right (msg, _, _) -> do
						log_chat_messages ref (Data.ByteString.Char8.unpack msg)
						runSentChatScript ref msg
					_ -> return ()
				return y
			x <- runSendChatScript ref uri allparams
			case x of
				Right msg -> do
					if msg == Data.ByteString.Char8.pack ""
						then handle_normally uri params
						else if Data.ByteString.Char8.isPrefixOf (Data.ByteString.Char8.pack "//kolproxy:sendgraf:") msg
							then do
								let Just uriparams = decodeUrlParams uri
								let newgraf = Data.ByteString.Char8.drop 20 msg
								let newuriparams = map (\(x, y) -> (x, if x == "graf" then Data.ByteString.Char8.unpack newgraf else y)) uriparams
								let newuri = uri { uriQuery = "?" ++ (formEncode newuriparams) }
								let newparams = params
--								putStrLn $ "DEBUG: send chat uri: " ++ show newuri
--								putStrLn $ "DEBUG: send chat params: " ++ show newparams
--								putStrLn $ "DEBUG:   want to graf: " ++ show (Data.ByteString.Char8.drop 20 msg)
								handle_normally newuri newparams
							else return $ Right (msg, uri, [])
				Left (msg, trace) -> do
					putStrLn $ "sendchat error: " ++ (msg ++ "\n" ++ trace)
					handle_normally uri params
		_ -> join $ (processPage ref) ref uri params
	resptext <- case uriPath uri of
		"/newchatmessages.php" -> do
			log_chat_messages ref (Data.ByteString.Char8.unpack text)
			let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
			x <- runChatScript ref uri effuri text allparams
			case x of
				Right msg -> return msg
				Left (msg, trace) -> do
					putStrLn $ "chat error: " ++ (msg ++ "\n" ++ trace)
					return text
		_ -> return text
	makeResponseWithNoExtraHeaders resptext effuri [("Content-Type", "application/json; charset=UTF-8"), ("Cache-Control", "no-cache")]

handleRequest ref uri effuri headers params pagetext = do
	let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]

	xresptext <- if skipRunningPrinters_ ref
		then return $ Right $ pagetext
		else log_time_interval ref ("printing: " ++ (show uri)) $ runPrinterScript ref uri effuri pagetext allparams

	let resptext = case xresptext of
		Right msg -> msg
		Left (msg, trace) -> add_error_message_to_page ("printer.lua error: " ++ msg ++ "\n" ++ trace) pagetext

	log_time_interval ref ("making response") $ makeResponse resptext effuri headers


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
			load_api_status_to_mv ref mv
		force_latest_status_parse ref
		void $ loadState ref
		return True) `catch` (\e -> do
			putStrLn $ "loadstate exception: " ++ show (e :: SomeException)
			return False)
	return ref { stateValid_ = state_is_ok }

kolProxyHandler uri params baseref = do
	let _fake_log_ref = baseref
	forkIO_ "proxy:updatedatafiles" $ update_data_files -- TODO: maybe not for *every single page*?

	origref <- log_time_interval _fake_log_ref ("make ref for: " ++ (show uri)) $ make_ref baseref

	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]

	let check_pwd_for action = Just $ do
		ai <- getApiInfo origref
		if lookup "pwd" allparams == Just (pwd ai)
			then action
			else makeResponse (Data.ByteString.Char8.pack $ "Invalid pwd field") uri []

	let handle_login p_sensitive = do
		loginrequestfunc <- case lookup "password" p_sensitive of
			Just "" -> do
				putStrLn $ "Logging in..."
				return internalKolRequest
			_ -> do
				putStrLn $ "Logging in over https..."
				return internalKolHttpsRequest
		(pt, effuri, allhdrs) <- loginrequestfunc uri (Just p_sensitive) (Nothing, useragent_ $ connection $ origref, hostUri_ $ connection $ origref, Nothing) True
		let hdrs = filter (\(x, _y) -> (x == "Set-Cookie" || x == "Location")) allhdrs
		putStrLn $ "DEBUG: Login requested " ++ (show $ uriPath uri) ++ ", got " ++ (show $ uriPath effuri)
		putStrLn $ "  hdrs: " ++ show hdrs
		let new_cookie = case filter (\(a, _b) -> a == "Set-Cookie") hdrs of
			[] -> Nothing
			(x:xs) -> Just $ intercalate "; " (map ((takeWhile (/= ';')) . snd) (x:xs)) -- TODO: Make readable
		putStrLn $ "  old_cookie = " ++ (show $ cookie_ $ connection $ origref)
		putStrLn $ "  new_cookie = " ++ (show new_cookie)
		if isNothing new_cookie
			then do
				putStrLn $ "Error: No cookie from logging in!"
				putStrLn $ "  headers: " ++ (show hdrs)
				putStrLn $ "  url: " ++ (show effuri)
				handleRequest origref uri effuri hdrs params pt
			else (do
				newref <- do
					mv <- newEmptyMVar
					writeIORef (jsonStatusPageMVarRef_ $ sessionData $ origref) mv
					writeIORef (latestRawJson_ $ sessionData $ origref) Nothing
					writeIORef (latestValidJson_ $ sessionData $ origref) Nothing
					make_ref $ baseref { otherstuff_ = (otherstuff_ origref) { connection_ = (connection_ $ otherstuff_ $ origref) { cookie_ = new_cookie } } }
				putStrLn $ "INFO: login.php -> getting server state"
				ai <- getApiInfo newref
				putStrLn $ "INFO: Logging in as " ++ (charName ai) ++ " (ascension " ++ (show $ ascension ai) ++ ")"
				what <- loadSettingsFromServer newref
				putStrLn $ "INFO: settings loaded: " ++ (fromMaybe "nothing" what)

				forkIO_ "proxy:compresslogs" $ compressLogs (charName ai) (ascension ai)

				putStrLn $ "DEBUG login.php contents: " ++ (Data.ByteString.Char8.unpack pt)
				makeRedirectResponse pt uri hdrs) `catch` (\e -> do
					putStrLn $ "Error: Failed to log in. Exception: " ++ (show (e :: Control.Exception.SomeException))
					-- TODO: Eeek! When this happens, there's no proper session, stuff gets fucked
					makeResponse pt uri hdrs)
-- 					return $ Response (5,0,0) "" (hdrs ++ [Header HdrContentType "text/html; charset=UTF-8", Header HdrCacheControl "no-cache"]) "Error: Failed to log in. This can happen if you try to log in for the first time in a day while in combat, in a choice adventure or in valhalla.")

	let response = case uriPath uri of
		"/login.php" -> fmap handle_login params

-- TODO: intercept if logged in before page. automate if logged in after page. support logging both.

		"/custom-clear-lua-script-cache" -> check_pwd_for $ do
			writeIORef (luaInstances_ $ sessionData $ origref) Data.Map.empty
			writeIORef (blocking_lua_scripting origref) False
			makeResponse (Data.ByteString.Char8.pack $ "Cleared Lua script cache.") uri []

		"/custom-logs" -> check_pwd_for $ do
			pt <- showLogs (lookup "which" allparams) (fromJust $ lookup "pwd" allparams)
			makeResponse (Data.ByteString.Char8.pack pt) uri []

		"/custom-settings" -> check_pwd_for $ do
			case lookup "action" allparams of
				Nothing -> return ()
				Just "set state" -> do
					case (lookup "stateset" allparams, lookup "name" allparams, lookup "value" allparams) of
						(Just stateset, Just name, Just value) -> setState origref stateset name value
						_ -> return () -- TODO: Handle as error?
				Just x -> throwIO $ InternalError $ "Custom settings action not recognized: " ++ x
			handleRequest origref uri uri [] params (Data.ByteString.Char8.pack "Empty page.")

		"/kolproxy-automation-script" -> check_pwd_for $ do
			(pt, effuri, hdrs) <- do
				let reqtype = if isJust params then "POST" else "GET"
				zz <- runInterceptScript origref uri allparams reqtype
				case zz of
					Right (text, effuri) -> return (text, effuri, [])
					Left (msg, trace) -> do
						putStrLn $ "intercept.lua error: " ++ msg ++ "\n" ++ trace
						return (add_error_message_to_page ("intercept.lua error: " ++ msg ++ "\n" ++ trace) (Data.ByteString.Char8.pack "{ Kolproxy automation script. }"), mkuri "/error", [])
			handleRequest origref uri effuri hdrs params pt
		_ -> Nothing

	let getpage = join $ (processPage origref) origref uri params

	retresp <- log_time_interval origref ("run handler for: " ++ (show uri)) $ case response of
		Just r -> do
			canread <- canReadState origref
			if and [not canread, uriPath uri /= "/login.php", uriPath uri /= "/afterlife.php"]
				then do
					-- TODO: Can this still be reached?
					putStrLn $ "Error: Can't read state! Don't log in for the first time in a day while in a fight or choice noncombat, and don't log in while in valhalla!"
					gp <- getpage
					case gp of
						Left (pt, effuri, _hdrs) -> makeResponse pt effuri []
						Right (pt, effuri, hdrs) -> if (uriPath effuri) `elem` ["/fight.php", "/choice.php"]
							then makeResponse (add_error_message_to_page "Error: kolproxy can't read state!" pt) effuri []
							else handleRequest origref uri effuri hdrs params pt
				else r
		Nothing -> do
-- 			putStrLn $ "DEBUG: not specifically handled: " ++ show uri
			canread_before <- canReadState origref
-- 			putStrLn $ "canread_before: " ++ show (uri, canread_before)

			-- TODO: Move to specific handler? Remove entirely?
			when (uriPath uri == "/logout.php" && canread_before) $ storeSettingsOnServer origref "logging out"

			-- TODO: redo this stuff. Simple case is when we're connected both before and after
			let should_run_intercept_script = canread_before

			downloaded_page <- if should_run_intercept_script
				then do
					let reqtype = if isJust params then "POST" else "GET"
					zz <- log_time_interval origref ("intercepting: " ++ (show uri)) $ runInterceptScript origref uri allparams reqtype
					case zz of
						Right (pt, effuri) -> return $ Right (pt, effuri, [])
						Left (msg, trace) -> do
							putStrLn $ "intercept.lua error: " ++ msg ++ "\n" ++ trace
							return $ Left (add_error_message_to_page ("intercept.lua error: " ++ msg ++ "\n" ++ trace) (Data.ByteString.Char8.pack "{ No page loaded. }"), mkuri "/error", [])
				else log_time_interval origref ("run getpage for: " ++ (show uri)) $ getpage

			(new_page, newref) <- case downloaded_page of
				Left dl -> return (Left dl, origref)
				Right (pt, effuri, hdrs) -> do
					newref <- if canread_before && (uriPath effuri /= "/afterlife.php")
						then return origref
						else log_time_interval _fake_log_ref ("make ref-2 for: " ++ (show uri)) $ make_ref baseref
					canread_after <- canReadState newref
-- 					putStrLn $ "canread_after: " ++ show (uri, canread_after)
					let should_run_automate_script = canread_after
					x <- if should_run_automate_script
						then do
							y <- log_time_interval newref ("automating: " ++ (show uri)) $ runAutomateScript newref uri effuri pt allparams
							case y of
								Right autotext -> return $ Right (autotext, effuri, hdrs)
								Left (msg, trace) -> do
									putStrLn $ "automate.lua error: " ++ msg ++ "\n" ++ trace
									return $ Left (add_error_message_to_page ("automate.lua error: " ++ msg ++ "\n" ++ trace) pt, effuri, hdrs)
						else return $ Right (pt, effuri, hdrs)
					return (x, newref)

			case new_page of
				Left (pt, effuri, _hdrs) -> makeResponse pt effuri []
				Right (pt, effuri, _hdrs) -> log_time_interval newref ("run handle request for: " ++ (show uri)) $ handleRequest newref uri effuri [] params pt
	return retresp

runKolproxy = do
	have_process_page <- doesFileExist "scripts/process-page.lua"
	if have_process_page
		then do
			putStrLn $ "INFO: Starting..."
			createDirectoryIfMissing True "cache"
			createDirectoryIfMissing True "cache/data"
			createDirectoryIfMissing True "cache/files"
			createDirectoryIfMissing True "logs"
			createDirectoryIfMissing True "logs/chat"
			createDirectoryIfMissing True "logs/scripts"
			createDirectoryIfMissing True "logs/info"
			createDirectoryIfMissing True "logs/parsed"
		else do
			putStrLn $ "WARNING: Trying to start without required files in the \"scripts\" directory."
			putStrLn $ "         Did you unzip the files correctly?"
	portenv <- getEnvironmentSetting "KOLPROXY_PORT"
	let portnum = case portenv of
		Just x -> fromJust $ read_as x :: Integer
		Nothing -> 18481
	runProxyServer kolProxyHandler kolProxyHandlerWhenever portnum `catch` (\e -> putStrLn ("mainError: " ++ show (e :: Control.Exception.SomeException)))

main = platform_init $ do
	hSetBuffering stdout LineBuffering
--	args <- getArgs
	let args = []
	case args of
		[] -> runKolproxy
		["--runbotscript", botscriptfilename] -> do
			botscriptcode <- readFile botscriptfilename
			runBotScript botscriptcode
		_ -> do
			putStrLn $ "ERROR: Unsupported command-line options!"
	putStrLn $ "INFO: Done! (main finished)"
	return ()
