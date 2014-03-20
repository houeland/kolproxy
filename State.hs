module State where

-- State should be: Character, Acension, Day. Gamesession, kolproxysession, pageload.

-- TODO: Change fight to be an actual separate state table?

import Prelude
import PlatformLowlevel
import Logging
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
import Data.Time.Clock.POSIX
import System.IO.Error (isDoesNotExistError)
import Text.JSON
import Text.Printf
import qualified Data.Map
import qualified Data.ByteString.Char8

get_stid ref = do
	ai <- getApiInfo ref
	case get_sessid ref of
		Just sessid -> return (charName ai, ascension ai, daysthisrun ai, sessid)
		_ -> throwIO $ StateException

loadState ref = do
	newstid <- get_stid ref
	stv <- readIORef $ stateData_ $ sessionData $ ref
	let usable_old_st = case stv of
		Just (stid, oldst) -> if stid == newstid then Just oldst else Nothing
		Nothing -> Nothing
	case usable_old_st of
		Just x -> return x
		Nothing -> log_time_interval ref "read state from db" $ do
			putStrLn $ "INFO: Loading local state from database..."
			mv <- newEmptyMVar
			-- TODO: Don't spin this off to another thread?
			doStateAction ref $ \db -> do
				putMVar mv =<< (try $ do
					let readMapFromDB base_tablename = do
						tablename <- get_state_tablename ref base_tablename
						do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
						rs <- do_db_query db ("SELECT name, value FROM " ++ tablename ++ ";") []
						let mapper x = case x of
							[Just name, Just value] -> (Data.ByteString.Char8.unpack name, Data.ByteString.Char8.unpack value)
							_ -> throw $ InternalError $ "Error loading state from database"
						return $ Data.Map.fromList $ map mapper rs

					dbsessionmap <- readMapFromDB "session"
					sessionmap <- if Data.Map.member "character" dbsessionmap
						then return dbsessionmap
						else do
							-- TODO: Remove this default sessiondata, API in Lua should be used instead
							putStrLn $ "  DB: Creating session data..."
							ai <- getApiInfo ref
							putStrLn $ "    API: Retrieved name = " ++ (charName ai)
							return $ Data.Map.fromList [("character", show $ charName ai), ("pwd", show $ pwd ai), ("ascension number", show $ ascension ai), ("day", show $ daysthisrun ai)]

					requestmap <- return Data.Map.empty
					charmap <- readMapFromDB "character"
					ascmap <- readMapFromDB "ascension"
					daymap <- readMapFromDB "day"
					return (requestmap, sessionmap, charmap, ascmap, daymap))
			maybenewst <- takeMVar mv
			case maybenewst of
				Right newst -> do
					writeIORef (luaInstances_ $ sessionData $ ref) Data.Map.empty
					writeIORef (stateData_ $ sessionData $ ref) $ Just (newstid, newst)
					return newst
				Left err -> do
					putStrLn $ "DEBUG loadState exception: " ++ show err
					throwIO (err :: SomeException)

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
			putStrLn $ "State file " ++ filename ++ " does not already exist."
			return Data.Map.empty)

writeMapToFile filename m = do
	let filedata = show m
	path <- getDirectoryPath "state" filename
	basedir <- getBaseDirectory "state"
	best_effort_atomic_file_write path basedir filedata

get_state_tablename ref stateset = do
	let Just sessid = get_sessid ref
	ai <- getApiInfo ref
	case stateset of
		"session" -> return $ printf "session_%d_%d_%s" (ascension ai) (daysthisrun ai) sessid
		"character" -> return "character"
		"ascension" -> return $ "ascension_" ++ (show $ ascension ai)
		"day" -> return $ "day_" ++ (show $ ascension ai) ++ "_" ++ (show $ daysthisrun ai)
		_ -> throwIO $ InternalError $ "Invalid state table type: " ++ stateset

registerUpdatedState ref stateset var = do
-- 	putStrLn $ "DEBUG: updstate " ++ stateset ++ "." ++ var

	putDebugStrLn $ "Updated state: " ++ stateset ++ "/" ++ var

	when (stateset `elem` ["character", "ascension", "day"]) $ do
		storeSettingsOnServer ref ("wrote " ++ stateset ++ "/" ++ var)

	-- TODO: How should more-recent changes for things that are not stored on the server be handled
	-- TODO: Only do this for the same things as above, when the settings are stored?
	-- TODO: store number of writes like in json

	ai <- getApiInfo ref
	tablename <- get_state_tablename ref "character"
	doStateAction ref $ \db -> do
		do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
		do_db_query_ db ("INSERT OR REPLACE INTO " ++ tablename ++ "(name, value) VALUES(?, ?);") [Just $ Data.ByteString.Char8.pack $ "turnsplayed last state change", Just $ Data.ByteString.Char8.pack $ show $ turnsplayed ai]

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
-- 		"fight" ->
		_ -> throw $ InternalError $ "Invalid state table type: " ++ stateset
	writeIORef (state ref) $ Just (stid, newstate)
	tablename <- get_state_tablename ref stateset
	doStateAction ref $ \db -> do
		do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
		do_db_query_ db ("DELETE FROM " ++ tablename ++ " WHERE name = ?;") [Just $ Data.ByteString.Char8.pack $ var]
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
-- 		"fight" ->
		_ -> throw $ InternalError $ "Invalid state table type: " ++ stateset
	writeIORef (state ref) $ Just (stid, newstate)
	tablename <- get_state_tablename ref stateset
	doStateAction ref $ \db -> do
		do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
		do_db_query_ db ("INSERT OR REPLACE INTO " ++ tablename ++ "(name, value) VALUES(?, ?);") [Just $ Data.ByteString.Char8.pack $ var, Just $ Data.ByteString.Char8.pack $ value]
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
-- 		"fight" ->
		_ -> throw $ InternalError $ "Invalid state table type: " ++ stateset

uglyhack_resetFightState ref = do
	Just (_stid, (_requestmap, _sessionmap, _charmap, _ascmap, daymap)) <- readIORef (state ref)
	let fight_keys = Data.Map.toList $ Data.Map.filterWithKey (\x _y -> isPrefixOf "fight." x) daymap
	mapM_ (\(x, _y) -> unsetState ref "day" x) fight_keys

uglyhack_enumerateState ref = do
	Just (_stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	return [("request", Data.Map.keys requestmap), ("session", Data.Map.keys sessionmap), ("character", Data.Map.keys charmap), ("ascension", Data.Map.keys ascmap), ("day", Data.Map.keys daymap)]

makeStateJSON_new ref newstateid = do
	ai <- getApiInfo ref

	Just (_stid, (_requestmap, _sessionmap, charmap, ascmap, extra_daymap)) <- readIORef (state ref)
	let daymap = Data.Map.filterWithKey (\x _y -> not $ isPrefixOf "fight." x) extra_daymap

	jsondied <- newIORef False
	let maptojson name value statemap = do
		let remapx (name, jsonstr) = case decode jsonstr of
			Ok y -> return $ Just (name, y)
			_ -> do
				putStrLn $ "ERROR: could not convert JSON: " ++ show (name, jsonstr)
				writeIORef jsondied True
				return Nothing
		jsonlist <- mapM remapx $ Data.Map.toList statemap
		return $ toJSObject [(name, JSString $ toJSString $ value), ("state", JSObject $ toJSObject $ catMaybes $ jsonlist)]

	char <- maptojson "name" (charName ai) charmap
	asc <- maptojson "ascension" (show $ ascension $ ai) ascmap
	day <- maptojson "ascension-day" ((show $ ascension ai) ++ "-" ++ (show $ daysthisrun ai)) daymap
	timestamp <- return $ toJSObject [("turnsplayed", JSRational True $ toRational $ fst $ newstateid), ("writes", JSRational True $ toRational $ snd $ newstateid)]
-- 	putStrLn $ "new server settings timestamp: " ++ show timestamp

	hasdied <- readIORef jsondied
	when hasdied $ do
		putStrLn $ "ERROR: Error(s) converting JSON"
--		throwIO $ InternalError "Error converting JSON"

	return $ toJSObject [("character", JSObject char), ("ascension", JSObject asc), ("day", JSObject day), ("timestamp", JSObject timestamp)]

loadStateJSON_new ref jsobj = do
	ai <- getApiInfo ref
	let stuff = fromJSObject $ jsobj
	Just (stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	lstp <- getState ref "character" "turnsplayed last state change"

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
					then putStrLn $ "INFO: server settings are recent " ++ show (tserver, lstp)
					else putStrLn $ "WARNING: server settings are old " ++ show (tserver, lstp)
				return should_use_server_data
			_ -> do
				putStrLn $ "INFO: no turnsplayed timestamp for server settings"
				return False

	if should_use_server_data
		then do
			putStrLn $ "  loading character state"
			let Just charlist = lookupjsobj "character"
			(what, newstate) <- if (lookupjsstr "name" charlist) == (Just $ charName $ ai)
				then do
					let storedcharmap = decodestate $ lookup "state" charlist
					putStrLn $ "  loading ascension state"
					let Just asclist = lookupjsobj "ascension"
					if (Just $ show $ ascension $ ai) == (lookupjsstr "ascension" asclist)
						then do
							let storedascmap = decodestate $ lookup "state" asclist
							putStrLn $ "  loading day state"
							let Just daylist = lookupjsobj "day"
							if (lookupjsstr "ascension-day" daylist) == (Just $ (show $ ascension $ ai) ++ "-" ++ (show $ daysthisrun $ ai))
								then do
									let storeddaymap = decodestate $ lookup "state" daylist
									return (["character", "ascension", "day"], (requestmap, sessionmap, storedcharmap, storedascmap, storeddaymap))
								else return (["character", "ascension"], (requestmap, sessionmap, storedcharmap, storedascmap, daymap))
						else return (["character"], (requestmap, sessionmap, storedcharmap, ascmap, daymap))
				else return (["Nothing"], (requestmap, sessionmap, charmap, ascmap, daymap))
			writeIORef (state ref) $ Just (stid, newstate)
			return what
		else return ["Nothing"]

mirrorStateIntoDatabase ref = do
	Just (_, (_requestmap, _sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	-- TODO: Again, should this really be spun off into another thread?
	mv <- newEmptyMVar
	doStateAction ref $ \db -> do
		do_db_query_ db "BEGIN" []
		let save_tbl base_tablename contents = do
			tablename <- get_state_tablename ref base_tablename
			do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
			do_db_query_ db ("DELETE FROM " ++ tablename ++ ";") []
			mapM_ (\(x, y) -> do_db_query_ db ("INSERT OR REPLACE INTO " ++ tablename ++ "(name, value) VALUES(?, ?);") [Just $ Data.ByteString.Char8.pack $ x, Just $ Data.ByteString.Char8.pack $ y]) $ Data.Map.toList contents
		save_tbl "character" charmap
		save_tbl "ascension" ascmap
		save_tbl "day" daymap
		do_db_query_ db "COMMIT" []
		putStrLn $ "INFO: stored loaded settings in database."
		putMVar mv ()
	void $ takeMVar mv

download_actionbar ref = do
	json <- nochangeGetPageRawNoScripts ("/actionbar.php?action=fetch&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json") ref
	t <- getPOSIXTime
	writeFile ("logs/api/actionbar-data-" ++ show t ++ ".json") json
	return json

storeSettingsOnServer ref store_reason = when (store_state_in_actionbar ref) $ do
	Just (_, (_requestmap, _sessionmap, charmap, ascmap, extra_daymap)) <- readIORef (state ref)
	let daymap = Data.Map.filterWithKey (\x _y -> not $ isPrefixOf "fight." x) extra_daymap
	let statedesc = show (charmap, ascmap, daymap)
	laststored <- readIORef (lastStoredState_ $ sessionData $ ref)
	when (laststored /= Just statedesc) $ do
		ai <- getApiInfo ref -- TODO: make this the correct timed api load, or just the fastest possible. latest valid cached one?
		(oldturns, oldid) <- readIORef (storedStateId_ $ sessionData $ ref)
		newstateid <- if oldturns == turnsplayed ai
			then return (turnsplayed ai, oldid + 1)
			else return (turnsplayed ai, 1)
		cachedactionbar <- readIORef (cachedActionbar_ $ sessionData $ ref)
		json <- case cachedactionbar of
			Just x -> return x
			_ -> download_actionbar ref
		let Ok storedjslist = fromJSObject <$> decodeStrict json
		stateobj_new <- makeStateJSON_new ref newstateid
		let newjson = encodeStrict $ toJSObject $ filter (\(x, _) -> x /= "kolproxy state" && x /= "kolproxy json state") storedjslist ++ [("kolproxy json state", JSObject stateobj_new)]
		void $ postPageRawNoScripts "/actionbar.php" [("action", "set"), ("for", "kolproxy " ++ kolproxy_version_number ++ " by Eleron"), ("format", "json"), ("bar", newjson), ("pwd", pwd ai)] ref
		putStrLn $ "INFO: stored settings on server (" ++ (show $ length newjson) ++ " bytes.) because: " ++ store_reason
		writeIORef (cachedActionbar_ $ sessionData $ ref) (Just newjson)
		writeIORef (lastStoredState_ $ sessionData $ ref) (Just statedesc)
		writeIORef (storedStateId_ $ sessionData $ ref) newstateid

loadSettingsFromServer ref = do
	json <- download_actionbar ref
	case fromJSObject <$> decodeStrict json of
		Ok list -> case (lookup "kolproxy json state" list :: Maybe JSValue) of
			Just (JSObject x) -> do
				what_list <- loadStateJSON_new ref x
				mirrorStateIntoDatabase ref
				return $ Just $ show what_list ++ " (JSON format)"
			_ -> return Nothing
		Error err -> do
			putStrLn $ "ERROR: Invalid actionbar data: " ++ err
			putStrLn $ "  Your server data was most likely corrupted by a buggy GreaseMonkey script."
			putStrLn $ "  To reset it, first turn on the combat bar by going to KoL options -> Combat -> Enable Combat Bar."
			putStrLn $ "  Then, fight a monster, drag some skills onto the combat bar, win the fight, and log out. That should fix it."
			-- TODO: Wipe the actionbar?
			throwIO StateException
