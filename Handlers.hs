module Handlers where

import Prelude
import qualified HardcodedGameStuff
import qualified Server
import qualified Logging
import qualified LogParser
import qualified Lua
import qualified State
import qualified KoL.Api
import qualified KoL.Http
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
import System.Directory (doesFileExist)
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

	Logging.log_file_retrieval ref uri params

	(xf, mvf) <- KoL.Http.internalKolRequest_pipelining ref uri params True
	when ((uriPath uri) == "/actionbar.php") $ do
		putDebugStrLn $ "requested actionbar: " ++ show uri ++ " | " ++ show params
		writeIORef (cachedActionbar_ $ sessionData $ ref) Nothing

	let status_after_func = do
		readMVar =<< mvf

	mv <- newEmptyMVar

	forkIO_ "proxy:process" $ do
		x <- try $ do
			pr <- Logging.log_time_interval ref ("fetchpage: " ++ (show uri)) $ xf
			let (pagetext, effuri) = (pageBody pr, pageUri pr)

			let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
			y <- Logging.log_time_interval ref ("processing: " ++ (show uri)) $ Lua.runProcessScript ref uri effuri pagetext allparams

			state_after <- get_the_state ref

			Logging.log_page_result ref status_before_func log_time state_before uri params effuri pagetext status_after_func state_after

			return (y, pr)
		putMVar mv =<< case x of
			Right (Right msg, pr) -> do
				return $ Right $ pr { pageBody = msg }
			Right (Left (msg, trace), pr) -> do
				putErrorStrLn $ "Error processing page[" ++ show uri ++ "]: " ++ msg ++ "\n" ++ trace
				return $ Left $ pr { pageBody = HardcodedGameStuff.add_error_message_to_page ("process-page.lua error: " ++ msg ++ "\n" ++ trace) $ pageBody pr }
			Left e -> do
				putErrorStrLn $ "Exception while processing page[" ++ show uri ++ "]: " ++ (show (e :: SomeException))
				return $ Left $ PageResult { pageBody = HardcodedGameStuff.add_error_message_to_page ("process-page.lua exception: " ++ (show e)) (Data.ByteString.Char8.pack "{ Kolproxy page processing. }"), pageUri = mkuri "/error", pageHeaders = [], pageHttpCode = 500 }

	return $ do
		readMVar mv

doProcessPageChat ref uri params = do
	mv <- newEmptyMVar

	forkIO_ "proxy:processchat" $ do
		x <- try $ do
			(xf, _) <- KoL.Http.internalKolRequest_pipelining ref uri params False
			xf
		putMVar mv =<< case x of
			Right pr -> do
				let (pagetext, effuri) = (pageBody pr, pageUri pr)
				case uriPath effuri of
					-- TODO: Make sure they're logged in order!
					"/newchatmessages.php" -> Logging.log_chat_messages ref pagetext
					"/submitnewchat.php" -> Logging.log_chat_messages ref pagetext
					_ -> return () -- TODO: Log this too?
				return $ Right pr
			Left e -> do
				return $ Left $ PageResult { pageBody = HardcodedGameStuff.add_error_message_to_page ("processchar exception: " ++ (show (e :: SomeException))) (Data.ByteString.Char8.pack "{ Kolproxy page processing. }"), pageUri = mkuri "/error", pageHeaders = [], pageHttpCode = 500 }
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
			getstatusfunc_ = statusfunc
		}
	}
	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]
	x <- case uriPath uri of
		"/favicon.ico" -> do
			Right pr <- join $ (processPage ref) ref uri params
			let (x, u) = (pageBody pr, pageUri pr)
			return $ Right (x, u, "image/vnd.microsoft.icon")
		_ -> Lua.runChatRequestScript ref uri allparams
	case x of
		Right (msg, u, ct) -> do
			Server.makeResponseWithNoExtraHeaders msg u [("Content-Type", ct), ("Cache-Control", "no-cache")]
		Left (msg, trace) -> do
			putWarningStrLn $ "chat error: " ++ (show msg ++ "\n" ++ trace)
			Server.makeResponseWithNoExtraHeaders (Data.ByteString.Char8.pack "") uri [("Cache-Control", "no-cache")]

make_ref baseref = do
	let ref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = doProcessPage,
			getstatusfunc_ = statusfunc
		}
	}
	state_result <- try $ do
		mjs <- readIORef (latestRawJson_ $ sessionData $ ref)
		when (isNothing mjs) $ do
			mv <- readIORef (jsonStatusPageMVarRef_ $ sessionData $ ref)
			apixf <- KoL.Http.load_api_status_to_mv_mkapixf ref
			KoL.Http.load_api_status_to_mv ref mv apixf
		KoL.Api.force_latest_status_parse ref
		State.ensureLoadedState ref
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
		forkIO_ "proxy:updatedatafiles" $ HardcodedGameStuff.update_data_files -- TODO: maybe not for *every single page*?

	origref <- Logging.log_time_interval baseref ("make ref for: " ++ (show uri)) $ make_ref baseref

	let allparams = concat $ catMaybes $ [decodeUrlParams uri, params]

	let check_pwd_for action = do
		ai <- KoL.Api.getApiInfo origref
		if lookup "pwd" allparams == Just (KoL.Api.pwd ai)
			then return action
			else return $ Just $ Server.makeErrorResponse (Data.ByteString.Char8.pack $ "Invalid pwd field") uri []

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
				Server.makeErrorResponse pt effuri hdrs
			else (do
				newref <- do
					mv <- newEmptyMVar
					writeIORef (jsonStatusPageMVarRef_ $ sessionData $ origref) mv
					writeIORef (latestRawJson_ $ sessionData $ origref) Nothing
					writeIORef (latestValidJson_ $ sessionData $ origref) Nothing
					make_ref $ baseref { otherstuff_ = (otherstuff_ origref) { connection_ = (connection_ $ otherstuff_ $ origref) { cookie_ = new_cookie } } }
				putInfoStrLn $ "login.php -> getting server state"
				ai <- KoL.Api.getApiInfo newref
				putInfoStrLn $ "Logging in as " ++ (KoL.Api.charName ai) ++ " (ascension " ++ (show $ KoL.Api.ascension ai) ++ ")"
				State.loadSettingsFromServer newref

				forkIO_ "proxy:compresslogs" $ LogParser.compressLogs (KoL.Api.charName ai) (KoL.Api.ascension ai)

				Server.makeRedirectResponse pt uri hdrs) `catch` (\e -> do
					putErrorStrLn $ "Failed to log in. Exception: " ++ (show (e :: Control.Exception.SomeException))
					if (code >= 300 && code < 400)
						then Server.makeRedirectResponse pt uri hdrs
						else Server.makeResponse pt uri hdrs)

	response <- case uriPath uri of
		"/login.php" -> case params of
			Nothing -> return Nothing
			Just p_sensitive -> return $ Just $ do
				loginrequestfunc <- case lookup "password" p_sensitive of
					Just "" -> do
						putInfoStrLn $ "Logging in..."
						return KoL.Http.internalKolRequest
					_ -> do
						putInfoStrLn $ "Logging in over https..."
						return KoL.Http.internalKolHttpsRequest
				handle_login =<< loginrequestfunc uri (Just p_sensitive) (Nothing, useragent_ $ connection $ origref, hostUri_ $ connection $ origref, Nothing) True

		"/custom-clear-lua-script-cache" -> check_pwd_for $ Just $ do
			reset_lua_instances origref
			writeIORef (blocking_lua_scripting origref) False
			Server.makeResponse (Data.ByteString.Char8.pack $ "Cleared Lua script cache.") uri []

		"/custom-logs" -> check_pwd_for $ Just $ do
			pt <- LogParser.showLogs (lookup "which" allparams) (fromJust $ lookup "pwd" allparams)
			Server.makeResponse (Data.ByteString.Char8.pack pt) uri []

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
				Nothing -> Server.makeResponse (Data.ByteString.Char8.pack $ "Invalid request.") uri []
				Just (x, y) -> Server.makeResponseWithNoExtraHeaders x uri [("Content-Type", y), ("Cache-Control", "max-age=3600")]
		_ -> return Nothing

	retresp <- Logging.log_time_interval origref ("run handler for: " ++ (show uri)) $ case response of
		Just r -> r
		Nothing -> do
			when (uriPath uri == "/logout.php") $ do
				canread_before <- canReadState origref
				when canread_before $ State.storeSettings origref
			let reqtype = if isJust params then "POST" else "GET"
			response <- Logging.log_time_interval origref ("browser request: " ++ (show uri)) $ Lua.runBrowserRequestScript origref uri allparams reqtype
			case response of
				Left (pt, effuri) -> Server.makeErrorResponse pt effuri []
				Right (pt, effuri, ct) -> Server.makeResponseWithNoExtraHeaders pt effuri [("Content-Type", ct), ("Cache-Control", "no-cache")]
	return retresp
