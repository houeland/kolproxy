module Handlers where

import Prelude
import qualified HardcodedGameStuff
import qualified Logging
import qualified Lua
import qualified KoL.Http
import KoL.Util
import KoL.UtilTypes
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.Maybe
import Data.Time
import Network.URI
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
