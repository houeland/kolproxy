module Logging where

import Prelude hiding (catch, read)
import KoL.Util
import KoL.UtilTypes
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.Time
import Network.URI
import System.IO
import Text.Printf
import qualified Data.Map

data LogItem = LogItem {
	time :: ZonedTime,
	apiStatusBefore :: String,
	apiStatusAfter :: String,
	stateBefore :: Maybe StateType,
	stateAfter :: Maybe StateType,
	sessionId :: String,
	requestedUri :: URI,
	parameters :: Maybe [(String, String)],
	retrievedUri :: URI,
	pageText :: String
}

doLOGGING_DEBUG _ = return ()
-- doLOGGING_DEBUG x = putStrLn $ "LOGGING DEBUG: " ++ x

holdit ref action = writeChan (getlogchan ref) action

print_log_msg ref _file logdetails = do
	doLOGGING_DEBUG $ "print_log_msg start: " ++ (show $ time $ logdetails) ++ " | " ++ (show $ retrievedUri $ logdetails)
	doDbLogAction ref $ \db -> do
		doLOGGING_DEBUG $ "print_log_msg logaction: " ++ (show $ time $ logdetails) ++ " | " ++ (show $ retrievedUri $ logdetails)
-- 		putStrLn $ "writing to log db."
		let showstate s = case s of
			Just (_requestmap, _sessionmap, charmap, ascmap, daymap) -> show [("character", charmap), ("ascension", ascmap), ("day", daymap)]
			_ -> throw $ InternalError $ "Invalid state while logging"
		do_db_query_ db "INSERT INTO pageloads(time, statusbefore, statusafter, statebefore, stateafter, sessionid, requestedurl, parameters, retrievedurl, pagetext) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?);" [
			Just $ show $ time $ logdetails,
			Just $ apiStatusBefore $ logdetails,
			Just $ apiStatusAfter $ logdetails,
			Just $ showstate (stateBefore $ logdetails),
			Just $ showstate (stateAfter $ logdetails),
			Just $ sessionId $ logdetails,
			Just $ show $ requestedUri $ logdetails,
			show <$> (parameters $ logdetails),
			Just $ show $ retrievedUri $ logdetails,
			Just $ pageText $ logdetails]
		doLOGGING_DEBUG $ "print_log_msg logactiondone: " ++ (show $ time $ logdetails) ++ " | " ++ (show $ retrievedUri $ logdetails)
	doLOGGING_DEBUG $ "print_log_msg alldone: " ++ (show $ time $ logdetails) ++ " | " ++ (show $ retrievedUri $ logdetails)

appendline ref whichh msg = holdit ref $ do
	hPutStrLn (whichh $ globalstuff_ $ ref) msg

log_file_retrieval ref url params = appendline ref h_files_downloaded_ $ (show url) ++ "  " ++ (show params)

internal_log_time_msg ref msg = appendline ref h_timing_log_ msg

diffms before now = fromRational $ 1000 * toRational (diffUTCTime now before) :: Double

lua_log_line ref msg action = do
	start <- getCurrentTime
-- 	x <- log_time_interval ref ("lua:" ++ msg) $ action
	x <- action
	end <- getCurrentTime
	appendline ref h_lua_log_ $ printf "[%8.1fms] %s" (diffms start end) msg
	return x 

log_retrieval ref msg start end = do
	ct <- getCurrentTime
	let str = printf "[%-35s] %s [%8.1fms] %s" (show ct) (connLogSymbol_ $ connection $ ref) (diffms start end) msg
	writeChan (solid_logchan_ $ logstuff_ $ ref) $ do
		hPutStrLn (h_http_log_ $ globalstuff_ $ ref) str

-- TODO: Remove this?
log_time_uri ref msg uri = internal_log_time_msg ref (printf "%s: %s" msg (show uri))

-- TODO: Redo indenting?
log_time_interval ref name action = do
	time_pre <- getCurrentTime
	indents <- readIORef (logindents ref)
	let indent_text = replicate (fromIntegral indents) ':'
	internal_log_time_msg ref (printf "  [%-35s %s>] %s" (show time_pre) indent_text name)
	atomicModifyIORef (logindents ref) (\x -> (x + 1, ()))
	actionresult <- action `catch` (\e -> do
		putStrLn $ "log:" ++ name ++ " exception: " ++ (show (e :: SomeException))
		throwIO e)
	atomicModifyIORef (logindents ref) (\x -> (x - 1, ()))
	time_post <- getCurrentTime
	internal_log_time_msg ref (printf "  [%-35s %s<] %s (%7.1fms)" (show time_post) indent_text name (diffms time_pre time_post))
	return actionresult

log_time_interval_http _ref name action = action `catch` (\e -> do
	putStrLn $ "log_http:" ++ name ++ " exception: " ++ (show (e :: SomeException))
	throwIO e)

log_page_result ref status_before log_time state_before uri params effuri pagetext status_after state_after = do
	doLOGGING_DEBUG $ "log_page_result start: " ++ show log_time ++ " | " ++ show effuri
	(charname, charasc) <- do
		let getSessState var = do
			when (not $ stateValid_ $ ref) $ putStrLn $ "State invalid while logging and trying to get session state"
			Just (_, st) <- readIORef $ state ref
			let value = case st of
				(_requestmap, sessionmap, _charmap, _ascmap, _daymap) -> Data.Map.lookup var sessionmap
			return (value :: Maybe String)
		Just charname <- getSessState "character"
		Just charasc <- getSessState "ascension number"
		return (charname, charasc)
	let Just sessid = get_sessid ref
	print_log_msg ref (charname ++ "-" ++ charasc ++ "-detailed.txt") $ LogItem { time = log_time, apiStatusBefore = status_before, apiStatusAfter = status_after, stateBefore = state_before, stateAfter = state_after, sessionId = sessid, requestedUri = uri, parameters = params, retrievedUri = effuri, pageText = pagetext }
	doLOGGING_DEBUG $ "log_page_result done: " ++ show log_time ++ " | " ++ show effuri
