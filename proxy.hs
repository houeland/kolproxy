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
import System.Environment (getArgs)
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

			-- TODO: Make sure this is definitely the very next thing logged. Make a channel for logging and write to it
			forkIO_ "proxy:logresult" $ (do
				status_before <- status_before_func
				status_after <- status_after_func
				log_page_result ref (Right status_before) log_time state_before uri params effuri pagetext status_after state_after
				return ()) `catch` (\e -> putErrorStrLn $ "processpage logging exception: " ++ (show (e :: KolproxyException)))

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

doProcessPageWhenever ref uri params = do
	xf <- fst <$> internalKolRequest_pipelining ref uri params False
	return $ do
		Right <$> xf

statusfunc ref = do
	mv <- readIORef $ jsonStatusPageMVarRef_ $ sessionData $ ref
	return $ ((do
		x <- readMVar mv
		case x of
			Right r -> return r
			Left err -> throwIO err) `catch` (\e -> do
                        	putWarningStrLn $ "statusfunc exception: " ++ show (e :: SomeException)
                        	throwIO e))

-- TODO: Redo how scripts are run and used to do chat, make it more similar to normal pages
kolProxyHandlerWhenever uri params baseref = do
	let ref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPageWhenever,
			nochangeRawRetrievePageFunc_ = internalKolRequest_pipelining,
			getstatusfunc_ = statusfunc
		}
	}
	Right (text, effuri, _hdrs, _code) <- case uriPath uri of -- TODO: handle Left here?
		"/submitnewchat.php" -> do
			let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]
			let handle_normally msguri msgparams = do
				y <- join $ (processPage ref) ref msguri msgparams
				case y of
					Right (msg, _, _, _) -> do
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
--								putDebugStrLn $ "send chat uri: " ++ show newuri
--								putDebugStrLn $ "send chat params: " ++ show newparams
--								putDebugStrLn $ "  want to graf: " ++ show (Data.ByteString.Char8.drop 20 msg)
								handle_normally newuri newparams
							else return $ Right (msg, uri, [], 200)
				Left (msg, trace) -> do
					putWarningStrLn $ "sendchat error: " ++ (msg ++ "\n" ++ trace)
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
					putWarningStrLn $ "chat error: " ++ (msg ++ "\n" ++ trace)
					return text
		_ -> return text
	makeResponseWithNoExtraHeaders resptext effuri [("Content-Type", "application/json; charset=UTF-8"), ("Cache-Control", "no-cache")]

-- TODO: Remove
--handleRequest ref uri effuri headers params pagetext = do
--	let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
--
--	xresptext <- if skipRunningPrinters_ ref
--		then return $ Right $ pagetext
--		else log_time_interval ref ("printing: " ++ (show uri)) $ runPrinterScript ref uri effuri pagetext allparams
--
--	case xresptext of
--		Right msg -> log_time_interval ref ("making response") $ makeResponse msg effuri headers
--		Left (msg, trace) -> do
--			let pt = add_error_message_to_page ("printer.lua error: " ++ msg ++ "\n" ++ trace) pagetext
--			log_time_interval ref ("making response") $ makeErrorResponse pt effuri headers

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
		void $ loadState ref
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
				what <- loadSettingsFromServer newref
				putInfoStrLn $ "settings loaded: " ++ (fromMaybe "nothing" what)
				writeIORef (have_logged_in_ref_ $ globalstuff_ $ newref) True

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
			writeIORef (luaInstances_ $ sessionData $ origref) Data.Map.empty
			writeIORef (blocking_lua_scripting origref) False
			makeResponse (Data.ByteString.Char8.pack $ "Cleared Lua script cache.") uri []

		"/custom-logs" -> check_pwd_for $ Just $ do
			pt <- showLogs (lookup "which" allparams) (fromJust $ lookup "pwd" allparams)
			makeResponse (Data.ByteString.Char8.pack pt) uri []

--		"/custom-settings" -> check_pwd_for $ Just $ do
--			case lookup "action" allparams of
--				Nothing -> return ()
--				Just "set state" -> do
--					case (lookup "stateset" allparams, lookup "name" allparams, lookup "value" allparams) of
--						(Just stateset, Just name, Just value) -> setState origref stateset name value
--						_ -> return () -- TODO: Handle as error?
--				Just x -> throwIO $ InternalError $ "Custom settings action not recognized: " ++ x
--			makeResponse (Data.ByteString.Char8.pack $ "Empty page.") uri []

		"/kolproxy-automation-script" -> check_pwd_for $ Nothing
		"/kolproxy-script" -> check_pwd_for $ Nothing

		_ -> return Nothing

	retresp <- log_time_interval origref ("run handler for: " ++ (show uri)) $ case response of
		Just r -> r
		Nothing -> do
			canread_before <- canReadState origref

			-- TODO: Move to specific handler? Remove entirely?
			when (uriPath uri == "/logout.php" && canread_before) $ storeSettingsOnServer origref "logging out"

			let reqtype = if isJust params then "POST" else "GET"
			response <- log_time_interval origref ("browser request: " ++ (show uri)) $ runBrowserRequestScript origref uri allparams reqtype
			case response of
				Left (pt, effuri) -> makeErrorResponse pt effuri []
				Right (pt, effuri) -> makeResponse pt effuri []
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
			createDirectoryIfMissing True "scripts/custom-autoload"
		else do
			putWarningStrLn $ "Trying to start without required files in the \"scripts\" directory."
			putWarningStrLn $ "  Did you unzip the files correctly?"
			-- TODO: give error message in browser
	portenv <- getEnvironmentSetting "KOLPROXY_PORT"
	let portnum = case portenv of
		Just x -> fromJust $ read_as x :: Integer
		Nothing -> 18481
	runProxyServer kolProxyHandler kolProxyHandlerWhenever portnum) `catch` (\e -> putDebugStrLn ("runKolproxy exception: " ++ show (e :: Control.Exception.SomeException)))

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

	sc <- make_sessionconn globalref "http://www.kingdomofloathing.com/" (error "dblogstuff") (error "statestuff")

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
		globalstuff_ = globalref,
		skipRunningPrinters_ = True
	}

	let okref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPageWhenever,
			nochangeRawRetrievePageFunc_ = internalKolRequest_pipelining,
			getstatusfunc_ = statusfunc
		},
		stateValid_ = False
	}

	runBotScript okref filename
