module State where

-- State should be: Character, Acension, Day. Gamesession, kolproxysession, pageload.

-- TODO: Change fight to be an actual separate state table?

import Prelude hiding (read, catch)
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
import System.IO.Error (isDoesNotExistError)
import Text.JSON
import Text.Printf
import qualified Data.Map

get_stid ref = do
	ai <- getApiInfo ref
	let Just sessid = get_sessid ref
	return (charName ai, ascension ai, daysthisrun ai, sessid)

loadState ref = do
	newstid <- get_stid ref
-- 	log_time_interval ref "printing newstid line" $ putStrLn $ "loading state for... " ++ show newstid
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
					ai <- getApiInfo ref -- TODO: don't getapiinfo here?
					let readMapFromDB base_tablename = do
						tablename <- get_state_tablename ref base_tablename
						do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
						rs <- do_db_query db ("SELECT name, value FROM " ++ tablename ++ ";") []
						let mapper x = case x of
							[Just name, Just value] -> (name, value)
							_ -> throw $ InternalError $ "Error loading state from database"
						return $ Data.Map.fromList $ map mapper rs

					dbsessionmap <- readMapFromDB "session"
					sessionmap <- if Data.Map.member "character" dbsessionmap
						then return dbsessionmap
						else do
							-- TODO: Remove this default sessiondata, API in Lua should be used instead
							putStrLn $ "  DB: Retrieving session data..."
							putStrLn $ "  DB: retrieved name=" ++ (charName ai)
							return $ Data.Map.fromList [("character", charName ai), ("pwd", pwd ai), ("ascension number", show $ ascension ai), ("day", show $ daysthisrun ai)]

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

	when (stateset `elem` ["character", "ascension", "day"]) $ do
		storeSettingsOnServer ref ("wrote " ++ stateset ++ "/" ++ var)

	-- TODO: How should more-recent changes for things that are not stored on the server be handled
	-- TODO: Only do this for the same things as above, when the settings are stored?

	ai <- getApiInfo ref
	tablename <- get_state_tablename ref "character"
	doStateAction ref $ \db -> do
		do_db_query_ db ("CREATE TABLE IF NOT EXISTS " ++ tablename ++ "(name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name));") []
		do_db_query_ db ("INSERT OR REPLACE INTO " ++ tablename ++ "(name, value) VALUES(?, ?);") [Just "turnsplayed last state change", Just $ show $ turnsplayed ai]

remap_stateset input_stateset input_var = if input_stateset == "fight"
	then ("day", "fight." ++ input_var)
	else (input_stateset, input_var)

raw_unsetState ref input_stateset input_var = do
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
		do_db_query_ db ("DELETE FROM " ++ tablename ++ " WHERE name = ?;") [Just var]
	registerUpdatedState ref stateset var

raw_setState ref input_stateset input_var value = do
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
		do_db_query_ db ("INSERT OR REPLACE INTO " ++ tablename ++ "(name, value) VALUES(?, ?);") [Just var, Just value]
	registerUpdatedState ref stateset var

setState ref input_stateset input_var value = do
	if value == ""
		then raw_unsetState ref input_stateset input_var
		else raw_setState ref input_stateset input_var value

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
	mapM_ (\(x, _y) -> raw_unsetState ref "day" x) fight_keys

makeStateJSON ref = do
	ai <- getApiInfo ref

	Just (_stid, (_requestmap, _sessionmap, charmap, ascmap, extra_daymap)) <- readIORef (state ref)
	let daymap = Data.Map.filterWithKey (\x _y -> not $ isPrefixOf "fight." x) extra_daymap

	let char = [("name", charName ai), ("state", show charmap)]
	let asc = [("ascension", show $ ascension ai), ("state", show ascmap)]
	let day = [("ascension-day", (show $ ascension ai) ++ "-" ++ (show $ daysthisrun ai)), ("state", show daymap)]
	let timestamp = [("turnsplayed", show $ turnsplayed ai)]
-- 	putStrLn $ "new server settings timestamp: " ++ show (turnsplayed ai, timestamp)

	let makeobj strmap = JSObject $ toJSObject $ map (\(a, b) -> (a, JSString $ toJSString $ b)) strmap
	return $ toJSObject [("character", makeobj char), ("ascension", makeobj asc), ("day", makeobj day), ("timestamp", makeobj timestamp)]

loadStateJSON ref jsobj = do
	lstp <- getState ref "character" "turnsplayed last state change"
	ai <- getApiInfo ref
	Just (stid, (requestmap, sessionmap, charmap, ascmap, daymap)) <- readIORef (state ref)
	let Ok stuff = fromJSObject <$> readJSON jsobj

	case lookup "timestamp" stuff of
		Just tstampobj -> do
			let turnsplayedstr = fromJSString $ fromJust $ lookup "turnsplayed" $ fromJSObject tstampobj :: String
			let Just tserver = read_as $ turnsplayedstr :: Maybe Integer
			let should_use_server_data = case read_as =<< lstp :: Maybe Integer of
				Just tlocal -> (tserver >= tlocal)
				Nothing -> True
			if should_use_server_data
				then do
					putStrLn $ "INFO: server settings are recent " ++ show (turnsplayedstr, lstp)
					putStrLn $ "  loading character state"
					let charlist = fromJSObject $ fromJust $ lookup "character" stuff
					(what, newstate) <- if (fromJSString $ fromJust $ lookup "name" charlist) == (charName ai)
						then do
							let storedcharstatestr = fromJSString $ fromJust $ lookup "state" charlist
							let Just storedcharmap = read_as storedcharstatestr :: Maybe (Data.Map.Map String String)

							putStrLn $ "  loading ascension state"
							let asclist = fromJSObject $ fromJust $ lookup "ascension" stuff
							if (Just (ascension ai)) == (read_as (fromJSString $ fromJust $ lookup "ascension" asclist) :: Maybe Integer)
								then do
									let storedascstatestr = fromJSString $ fromJust $ lookup "state" asclist
									let Just storedascmap = read_as storedascstatestr :: Maybe (Data.Map.Map String String)

									putStrLn $ "  loading day state"
									let daylist = fromJSObject $ fromJust $ lookup "day" stuff
									if (fromJSString $ fromJust $ lookup "ascension-day" daylist) == ((show (ascension ai)) ++ "-" ++ (show (daysthisrun ai)))
										then do
											let storeddaystatestr = fromJSString $ fromJust $ lookup "state" daylist
											let Just storeddaymap = read_as storeddaystatestr :: Maybe (Data.Map.Map String String)
											return (["character", "ascension", "day"], (requestmap, sessionmap, storedcharmap, storedascmap, storeddaymap))
										else return (["character", "ascension"], (requestmap, sessionmap, storedcharmap, storedascmap, daymap))
								else return (["character"], (requestmap, sessionmap, storedcharmap, ascmap, daymap))
						else return (["Nothing"], (requestmap, sessionmap, charmap, ascmap, daymap))
					writeIORef (state ref) $ Just (stid, newstate)
					return what
				else do
					putStrLn $ "WARNING: server settings are old " ++ show (turnsplayedstr, lstp)
					return ["Nothing"]
		Nothing -> do
			putStrLn $ "INFO: no turnsplayed timestamp for server settings"
			return ["Nothing"]

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
			mapM_ (\(x, y) -> do_db_query_ db ("INSERT OR REPLACE INTO " ++ tablename ++ "(name, value) VALUES(?, ?);") [Just x, Just y]) $ Data.Map.toList contents
		save_tbl "character" charmap
		save_tbl "ascension" ascmap
		save_tbl "day" daymap
		do_db_query_ db "COMMIT" []
		putStrLn $ "INFO: stored loaded settings in database."
		putMVar mv ()
	void $ takeMVar mv

-- TODO: Move this to API? Elsewhere?
storeSettingsOnServer ref store_reason = do
	Just (_, (_requestmap, _sessionmap, charmap, ascmap, extra_daymap)) <- readIORef (state ref)
	let daymap = Data.Map.filterWithKey (\x _y -> not $ isPrefixOf "fight." x) extra_daymap
	let statedesc = show (charmap, ascmap, daymap)
	laststored <- readIORef (lastStoredState_ $ sessionData $ ref)
	when (laststored /= Just statedesc) $ do
		ai <- getApiInfo ref
		json <- nochangeGetPageRawNoScripts ("/actionbar.php?action=fetch&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json") ref
		let Ok storedjslist = fromJSObject <$> decodeStrict json
		stateobj <- makeStateJSON ref
		let newjson = encodeStrict $ toJSObject $ filter (\(x, _) -> x /= "kolproxy state") storedjslist ++ [("kolproxy state", JSObject stateobj)]
		void $ postPageRawNoScripts "/actionbar.php" [("action", "set"), ("for", "kolproxy " ++ kolproxy_version_number ++ " by Eleron"), ("format", "json"), ("bar", newjson), ("pwd", pwd ai)] ref
		putStrLn $ "INFO: stored settings on server (" ++ (show $ length newjson) ++ " bytes.) because: " ++ store_reason
		writeIORef (lastStoredState_ $ sessionData $ ref) (Just statedesc)

loadSettingsFromServer ref = do
	json <- nochangeGetPageRawNoScripts ("/actionbar.php?action=fetch&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json") ref
	case fromJSObject <$> decodeStrict json of
		Ok list -> case (lookup "kolproxy state" list) of
			Just x -> do
				what_list <- loadStateJSON ref x
				mirrorStateIntoDatabase ref
				return $ Just $ show what_list
			Nothing -> return Nothing
		Error err -> do
			putStrLn $ "ERROR: Invalid actionbar data: " ++ err
			putStrLn $ "  Your server data has most likely gotten corrupted by a buggy GreaseMonkey script."
			putStrLn $ "  To reset it, first turn on the combat bar by going to KoL options -> Combat -> Enable Combat Bar."
			putStrLn $ "  Then, fight a monster, drag some skills onto the combat bar, win the fight, and log out. That should fix it."
			writeFile "DEBUG-invalid-actionbar-data.json" json
			throwIO StateException
