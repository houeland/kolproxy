module State where

import Prelude
import PlatformLowlevel
import KoL.Util
import KoL.UtilTypes
import KoL.Api
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List
import Data.Maybe
import Data.Time
import Data.Time.Clock.POSIX
import System.IO.Error (isDoesNotExistError)
import Text.JSON
import qualified Data.Map

get_stid ref = do
	ai <- getApiInfo ref
	case get_sessid ref of
		Just sessid -> return (charName ai, ascension ai, daysthisrun ai, sessid)
		_ -> throwIO $ StateException

-- TODO: Remove, replace with sqlite database for caching
readMapFromFile filename = do
	catchJust (\e -> if isDoesNotExistError e then Just e else Nothing)
		(do
			path <- getDirectoryPath "state" filename
			foo_raw_data <- readFile path
			foo_raw <- length foo_raw_data `seq` return foo_raw_data -- force file to be read before closing
			let Just foo = read_as foo_raw :: Maybe (Data.Map.Map String String)
			return foo)
		(\_e -> do
			putInfoStrLn $ "State file " ++ filename ++ " does not already exist."
			return Data.Map.empty)

writeStateToFile filename filedata = do
	path <- getDirectoryPath "state" filename
	basedir <- getBaseDirectory "state"
	best_effort_atomic_file_write path basedir filedata

registerUpdatedState ref stateset _var = do
	when (stateset `elem` ["character", "ascension", "day"]) $ do
		forkIO_ "delayedStoreSettings" $ do
			threadDelay $ 10 * 1000000
			last_store <- readIORef (lastStoredTime_ $ sessionData $ ref)
			tnow <- getCurrentTime
			when (diffUTCTime tnow last_store >= 10) $ storeSettings ref

remap_stateset input_stateset input_var = if input_stateset == "fight"
	then ("day", "fight." ++ input_var)
	else (input_stateset, input_var)

unsetState ref input_stateset input_var = do
	let (stateset, var) = remap_stateset input_stateset input_var
	Just (stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	let newstate = case stateset of
		"request" -> (Data.Map.delete var requestmap, sessionmap, charmap, ascmap, daymap)
		"session" -> (requestmap, Data.Map.delete var sessionmap, charmap, ascmap, daymap)
		"character" -> (requestmap, sessionmap, Data.Map.delete var charmap, ascmap, daymap)
		"ascension" -> (requestmap, sessionmap, charmap, Data.Map.delete var ascmap, daymap)
		"day" -> (requestmap, sessionmap, charmap, ascmap, Data.Map.delete var daymap)
		_ -> throw $ InternalError $ "Invalid state table type: " ++ stateset
	writeIORef (state ref) $ Just (stid, newstate)
	registerUpdatedState ref stateset var

setState ref input_stateset input_var value = do
	let (stateset, var) = remap_stateset input_stateset input_var
	Just (stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef $ state ref
	let newstate = case stateset of
		"request" -> (Data.Map.insert var value requestmap, sessionmap, charmap, ascmap, daymap)
		"session" -> (requestmap, Data.Map.insert var value sessionmap, charmap, ascmap, daymap)
		"character" -> (requestmap, sessionmap, Data.Map.insert var value charmap, ascmap, daymap)
		"ascension" -> (requestmap, sessionmap, charmap, Data.Map.insert var value ascmap, daymap)
		"day" -> (requestmap, sessionmap, charmap, ascmap, Data.Map.insert var value daymap)
		_ -> throw $ InternalError $ "Invalid state table type: " ++ stateset
	writeIORef (state ref) $ Just (stid, newstate)
	registerUpdatedState ref stateset var

getState ref input_stateset input_var = do
	let (stateset, var) = remap_stateset input_stateset input_var
	Just (_stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	return $ case stateset of
		"request" -> Data.Map.lookup var requestmap
		"session" -> Data.Map.lookup var sessionmap
		"character" -> Data.Map.lookup var charmap
		"ascension" -> Data.Map.lookup var ascmap
		"day" -> Data.Map.lookup var daymap
		_ -> throw $ InternalError $ "Invalid state table type: " ++ stateset

uglyhack_resetFightState ref = do
	Just (_stid, (_requestmap, _sessionmap, _charmap, _ascmap, daymap)) <- readIORef (state ref)
	let fight_keys = Data.Map.toList $ Data.Map.filterWithKey (\x _y -> isPrefixOf "fight." x) daymap
	mapM_ (\(x, _y) -> unsetState ref "day" x) fight_keys

uglyhack_enumerateState ref = do
	Just (_stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	return [("request", Data.Map.keys requestmap), ("session", Data.Map.keys sessionmap), ("character", Data.Map.keys charmap), ("ascension", Data.Map.keys ascmap), ("day", Data.Map.keys daymap)]

makeStateJSON ref newstateid = do
	ai <- getApiInfo ref

	Just (_stid, (_requestmap, _sessionmap, charmap, ascmap, extra_daymap)) <- readIORef (state ref)
	let daymap = Data.Map.filterWithKey (\x _y -> not $ isPrefixOf "fight." x) extra_daymap

	jsondied <- newIORef False
	let maptojson name value statemap = do
		let remapx (name, jsonstr) = case decode jsonstr of
			Ok y -> return $ Just (name, y)
			_ -> do
				putErrorStrLn $ "Could not convert JSON: " ++ show (name, jsonstr)
				writeIORef jsondied True
				return Nothing
		jsonlist <- mapM remapx $ Data.Map.toList statemap
		return $ toJSObject [(name, JSString $ toJSString $ value), ("state", JSObject $ toJSObject $ catMaybes $ jsonlist)]

	char <- maptojson "name" (charName ai) charmap
	asc <- maptojson "ascension" (show $ ascension $ ai) ascmap
	day <- maptojson "ascension-day" ((show $ ascension ai) ++ "-" ++ (show $ daysthisrun ai)) daymap
	timestamp <- return $ toJSObject [("turnsplayed", JSRational True $ toRational $ fst $ newstateid), ("writes", JSRational True $ toRational $ snd $ newstateid)]

	hasdied <- readIORef jsondied
	when hasdied $ putErrorStrLn $ "Error(s) converting JSON"

	return $ toJSObject [("character", JSObject char), ("ascension", JSObject asc), ("day", JSObject day), ("timestamp", JSObject timestamp)]

loadStateFromJson ref jsobj = do
	ai <- getApiInfo ref
	let stuff = fromJSObject $ jsobj
	Just (stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef $ stateData_ $ sessionData $ ref
	lstp <- return Nothing -- getState ref "character" "turnsplayed last state change"

--	timestamp_data = ... "timestamp"
--	character_data = ... "character-<playerid>"
--	ascension_data = ... "ascension-<ascensions+1>"
--	day_data = ... "day-<ascensions+1>-<daysthisrun>"

	let lookupjsobj which =
		case lookup which stuff of
			Just (JSObject jo) -> Just $ fromJSObject $ jo
			_ -> Nothing

	let lookupjsstr which obj =
		case lookup which obj of
			Just (JSString str) -> Just $ fromJSString str
			_ -> Nothing

	let decodestate xin = Data.Map.fromList remapped
		where
			Just (JSObject x) = xin
			list = fromJSObject x
			remapped = map (\(x, y) -> (x, encode y)) list

	should_use_server_data <- do
		case lookup "timestamp" stuff of
			Just (JSObject tstampobj) -> do
				let Just (JSRational _ jsr) = lookup "turnsplayed" $ fromJSObject $ tstampobj
				let tserver = round jsr
				let should_use_server_data = case read_as =<< lstp :: Maybe Integer of
					Just tlocal -> (tserver >= tlocal)
					Nothing -> True
				if should_use_server_data
					then putInfoStrLn $ "Server settings are recent " ++ show (tserver, lstp)
					else putWarningStrLn $ "Server settings are old " ++ show (tserver, lstp)
				return should_use_server_data
			_ -> do
				putInfoStrLn $ "No turnsplayed timestamp for server settings"
				return False

	if should_use_server_data
		then do
			putInfoStrLn $ "  loading character state"
			let Just charlist = lookupjsobj "character"
			(what, newstate) <- if (lookupjsstr "name" charlist) == (Just $ charName $ ai)
				then do
					let storedcharmap = decodestate $ lookup "state" charlist
					putInfoStrLn $ "  loading ascension state"
					let Just asclist = lookupjsobj "ascension"
					if (Just $ show $ ascension $ ai) == (lookupjsstr "ascension" asclist)
						then do
							let storedascmap = decodestate $ lookup "state" asclist
							putInfoStrLn $ "  loading day state"
							let Just daylist = lookupjsobj "day"
							if (lookupjsstr "ascension-day" daylist) == (Just $ (show $ ascension $ ai) ++ "-" ++ (show $ daysthisrun $ ai))
								then do
									let storeddaymap = decodestate $ lookup "state" daylist
									return (["character", "ascension", "day"], (requestmap, sessionmap, storedcharmap, storedascmap, storeddaymap))
								else return (["character", "ascension"], (requestmap, sessionmap, storedcharmap, storedascmap, daymap))
						else return (["character"], (requestmap, sessionmap, storedcharmap, ascmap, daymap))
				else return (["Nothing"], (requestmap, sessionmap, charmap, ascmap, daymap))
			writeIORef (stateData_ $ sessionData $ ref) $ Just (stid, newstate)
			return what
		else return ["Nothing"]

download_actionbar ref = nochangeGetPageRawNoScripts ("/actionbar.php?action=fetch&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json") ref

writeServerSettings ref = do
	ai <- getApiInfo ref -- TODO: make this is the correct timed api load, or just the fastest possible. latest valid cached one?
	(oldturns, oldid) <- readIORef (storedStateId_ $ sessionData $ ref)
	newstateid <- if oldturns == turnsplayed ai
		then return (turnsplayed ai, oldid + 1)
		else return (turnsplayed ai, 1)
	cachedactionbar <- readIORef (cachedActionbar_ $ sessionData $ ref)
	json <- case cachedactionbar of
		Just x -> return x
		_ -> download_actionbar ref
	storedjslist <- case fromJSObject <$> decodeStrict json of
		Ok sjsl -> return sjsl
		Error err -> do
			putWarningStrLn $ "Invalid actionbar data: " ++ err
			putWarningStrLn $ "  Your server data has most likely been corrupted by a buggy script."
			t <- round <$> getPOSIXTime
			writeFile ("invalid-actionbar-data-" ++ show t ++ ".json") json
			return []
	stateobj_new <- makeStateJSON ref newstateid
	let newjson = encodeStrict $ toJSObject $ filter (\(x, _) -> x /= "kolproxy state" && x /= "kolproxy json state") storedjslist ++ [("kolproxy json state", JSObject stateobj_new)]
	void $ postPageRawNoScripts "/actionbar.php" [("action", "set"), ("for", "kolproxy " ++ kolproxy_version_number ++ " by Eleron"), ("format", "json"), ("bar", newjson), ("pwd", pwd ai)] ref
	writeStateToFile ("state-" ++ (show $ playerId $ ai) ++ ".json") newjson
	putInfoStrLn $ "Stored settings on server (" ++ (show $ length newjson) ++ " bytes)."
	writeIORef (cachedActionbar_ $ sessionData $ ref) (Just newjson)
	writeIORef (storedStateId_ $ sessionData $ ref) newstateid

storeSettings ref = when (store_state_in_actionbar ref) $ do
	writeIORef (lastStoredTime_ $ sessionData $ ref) =<< getCurrentTime
	Just (_, (_requestmap, _sessionmap, charmap, ascmap, extra_daymap)) <- readIORef (state ref)
	let daymap = Data.Map.filterWithKey (\x _y -> not $ isPrefixOf "fight." x) extra_daymap
	let statedesc = show (charmap, ascmap, daymap)
	laststored <- readIORef (lastStoredState_ $ sessionData $ ref)
	when (laststored /= Just statedesc) $ do
		writeIORef (lastStoredState_ $ sessionData $ ref) (Just statedesc)
		writeServerSettings ref

initializeState ref = do
	ai <- getApiInfo ref
	newstid <- get_stid ref
	let requestmap = Data.Map.empty
	let sessionmap = Data.Map.fromList [("pwd", show $ pwd ai)]
	let charmap = Data.Map.empty
	let ascmap = Data.Map.empty
	let daymap = Data.Map.empty
	let newst = (requestmap, sessionmap, charmap, ascmap, daymap)
	writeIORef (stateData_ $ sessionData $ ref) $ Just (newstid, newst)
	return newst

ensureLoadedState ref = do
	stateval <- readIORef $ stateData_ $ sessionData $ ref
	case stateval of
		Just (_, _st) -> return ()
		_ -> loadSettingsFromServer ref
	Just (_, st) <- readIORef $ stateData_ $ sessionData $ ref
	return st

loadSettingsFromServer ref = do
	initializeState ref
	json <- download_actionbar ref
	case fromJSObject <$> decodeStrict json of
		Ok list -> case (lookup "kolproxy json state" list :: Maybe JSValue) of
			Just (JSObject x) -> do
				what_list <- loadStateFromJson ref x
				putInfoStrLn $ "settings loaded: " ++ show what_list
			_ -> return ()
		Error err -> do
			putWarningStrLn $ "Invalid actionbar data: " ++ err
			putWarningStrLn $ "  Your server data has most likely been corrupted by a buggy script."
