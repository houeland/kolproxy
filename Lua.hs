{-# LANGUAGE ForeignFunctionInterface, BangPatterns #-}

module Lua where

import Prelude hiding (read, catch)
import Logging
import State
import KoL.Http
import KoL.Util
import KoL.UtilTypes
import qualified KoL.Api
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List
import Data.Maybe
import Network.URI
import Network.CGI
import Text.JSON
import Text.Printf
import Text.Regex.TDFA
import Text.XML.Light
import qualified Data.ByteString.Char8
import qualified Data.Map
import qualified Database.SQLite3
import qualified Scripting.LuaModded as Lua

local_maybepeek l n test peek = do
	v <- test l n
	if v
		then liftM Just (peek l n)
		else return Nothing

instance Lua.StackValue Integer where
	push l x = Lua.pushinteger l (fromIntegral x)
	peek l1 n = local_maybepeek l1 n Lua.isnumber (\l2 n2 -> liftM fromIntegral (Lua.tointeger l2 n2))
	valuetype _ = Lua.TNUMBER

instance Lua.StackValue Data.ByteString.Char8.ByteString where
	push l x = Lua.pushbytestring l x
	peek l1 n1 = local_maybepeek l1 n1 Lua.isstring (\l2 n2 -> Lua.tobytestring l2 n2)
	valuetype _ = Lua.TSTRING

instance Lua.StackValue JSValue where
	push l x = push_jsvalue l x
	peek _l _n = throwIO $ userError $ "ERROR: Attempting to peek a jsvalue from Lua"
	valuetype _ = Lua.TTABLE

instance Lua.StackValue Element where
	push l x = push_simplexmldata l x
	peek _l _n = throwIO $ userError $ "ERROR: Attempting to peek an Element from Lua"
	valuetype _ = Lua.TTABLE


get_current_kolproxy_version = return $ kolproxy_version_number :: IO String

get_latest_kolproxy_version = do
	version <- getHTTPFileData kolproxy_version_string (mkuri "http://www.houeland.com/kolproxy/latest-version")
	if (length version <= 100) && (version =~ "^[0-9A-Za-z.-]+$")
		then return version
		else return "?"

set_state ref stateset var value = do
	canread <- canReadState ref
	unless canread $ fail $ "Error: Trying to set state \"" ++ var ++ "\" before state is available."
	if stateset `elem` ["ascension", "day", "fight", "session"]
		then setState ref stateset var value
		else fail $ "cannot write to stateset " ++ (show $ stateset)

get_state ref stateset var = do
	canread <- canReadState ref
	unless canread $ fail $ "Error: Trying to get state \"" ++ var ++ "\" before state is available."
	if stateset `elem` ["character", "ascension", "day", "fight", "session"]
		then fromMaybe "" <$> getState ref stateset var
		else fail $ "cannot read stateset " ++ (show $ stateset)

-- TODO: Check if this is really OK. It's not in valhalla!
get_ref_playername ref = KoL.Api.charName <$> KoL.Api.getApiInfo ref

set_state_whenever ref var value = void $ do
-- 	putStrLn $ "lua: set_state..." ++ (show $ (var, value))
	charname <- get_ref_playername ref
-- 	putStrLn $ "lua: setting state " ++ var ++ " => " ++ (show value) ++ " for " ++ charname
	chatmap <- Data.Map.insert var value <$> readMapFromFile ("chat-" ++ charname ++ ".state")
	writeMapToFile ("chat-" ++ charname ++ ".state") chatmap

get_state_whenever ref var = do
-- 	putStrLn $ "lua: get_state..." ++ (show $ (var))
	charname <- get_ref_playername ref
-- 	putStrLn $ "lua: getting " ++ (show var) ++ " for " ++ charname
	chatmap <- readMapFromFile ("chat-" ++ charname ++ ".state")
	return $ fromMaybe "" (Data.Map.lookup var chatmap)

-- TODO: change to return 0 and not handling it in lua
get_player_id ref l = do
	Just name <- Lua.peek l 1
	pid <- KoL.Api.getPlayerId name ref
	Lua.pushstring l =<< case pid of
		Just x -> return (show x)
		Nothing -> return "-1"
	return 1

-- TODO: create the table directly in haskell, remove eval from lua code
parse_table_string _ref l = do
	Just str <- Lua.peek l 1
	Lua.pushstring l =<< case read_as str :: Maybe [(String, String)] of
		Just xs -> do
			let luaxs = map (\(idx, (x,y)) -> printf "[%d] = { key = %s, value = %s }" (idx :: Integer) (show x) (show y)) (zip [1..] xs)
			return $ printf "return { %s }" $ intercalate ", " luaxs
		_ -> do
			putStrLn $ "parse_table_string error: " ++ (show str)
			return ""
	return 1

get_recipes _ref l = do
	Lua.pushstring l =<< readFile "cache/data/recipes"
	return 1

doReadDataFile filename = do
	filedata <- readFile filename
	case read_as filedata of
		Just x -> return x
		_ -> do
			putStrLn $ "=== ERROR ==="
			putStrLn $ "Error reading data file: " ++ filename
			putStrLn $ filedata
			putStrLn $ "=== ERROR ==="
			throwIO $ InternalError $ "Failed to read data file: " ++ filename

get_submit_uri_params _ref method inputuristr params = do
	case parseURIReference inputuristr of	
		Just inputuri -> do
			case (stripPrefix "/" (uriPath inputuri), uriQuery inputuri) of
				(Just _, "") -> do
					case method of
						"GET" -> do
							case params of
								Nothing -> return (uriPath inputuri, Nothing)
								Just p -> do
									let testurienc = (uriPath inputuri) ++ "?" ++ (formEncode p)
									let testuri = escapeURIString (\x -> x `notElem` "[]") testurienc
									case parseURIReference testuri of
										Just uri -> return (show uri, Nothing)
										_ -> fail $ "submit page error: uri " ++ (show testuri) ++ " not recognized."
						"POST" -> do
							case params of
								Just p -> return (uriPath inputuri, Just p)
								_ -> fail $ "submit page error: parameters " ++ (show params) ++ " not recognized."
						_ -> fail $ "submit page error: unknown method " ++ (show method) ++ ", should be GET or POST"
				_ -> fail $ "submit page error: unknown url " ++ (show inputuri)
		_ -> fail $ "submit page error: unknown url " ++ (show inputuristr)

async_submit_page ref method inputuristr params = do
	(final_url, final_params) <- get_submit_uri_params ref method inputuristr params
	xf <- (processPage ref) ref (mkuri final_url) final_params
	return $ do
		x <- xf
		return $ either id id x

add_table_contents l tbl = do
	mapM_ (\(x, y) -> do
		Lua.push l x
		Lua.push l y
		Lua.settable l (-3)) tbl

push_jsvalue l jsval = do
	case jsval of
		JSNull -> Lua.pushnil l
		JSBool b -> Lua.pushboolean l b
		JSRational _ r -> Lua.pushnumber l (fromRational r)
		JSString jss -> Lua.pushstring l (fromJSString jss)
		JSArray jsarr -> do
			Lua.newtable l
			add_table_contents l (zip ([1..] :: [Int]) jsarr)
		JSObject jsobj -> do
			let m = fromJSObject jsobj :: [(String, JSValue)]
			Lua.newtable l
			add_table_contents l m

array_tbl_to_jsvalue l = do
	let get_more n initlist = do
		Lua.pushinteger l n
		Lua.gettable l (-2)
		isempty <- Lua.isnoneornil l (-1)
		if isempty
			then do
				Lua.pop l 1
				return initlist
			else do
				v <- lua_to_jsvalue l
				get_more (n + 1) (initlist ++ [v])
	JSArray <$> get_more 1 []

stringobj_tbl_to_jsvalue l = do
	Lua.pushnil l
	let recur initlist = do
		nonempty <- Lua.next l (-2)
		if nonempty
			then do
				k <- Lua.tostring l (-2)
				v <- lua_to_jsvalue l
				recur $ initlist ++ [(k, v)]
			else return initlist
	JSObject <$> toJSObject <$> recur []

lua_to_jsvalue l = do
	t <- Lua.ltype l (-1)
	!val <- case t of
		Lua.TTABLE -> do
			Lua.pushinteger l 1
			Lua.gettable l (-2)
			isempty1idx <- Lua.isnoneornil l (-1)
			Lua.pop l 1
			if isempty1idx
				then do
					Lua.pushnil l
					nonempty <- Lua.next l (-2)
					if nonempty
						then do
							Lua.pop l 2
							stringobj_tbl_to_jsvalue l
						else array_tbl_to_jsvalue l
				else array_tbl_to_jsvalue l
		Lua.TSTRING -> JSString <$> toJSString <$> Lua.tostring l (-1)
		Lua.TNUMBER -> JSRational False <$> toRational <$> Lua.tonumber l (-1)
		Lua.TBOOLEAN -> JSBool <$> Lua.toboolean l (-1)
		Lua.TNIL -> return JSNull
		_ -> fail ("Unhandled type for lua_to_jsvalue: " ++ show t)
	Lua.pop l 1
	return val

push_simplexmldata l xmlval = do
	Lua.newtable l

	Lua.pushstring l "name"
	Lua.pushstring l $ showQName $ elName $ xmlval
	Lua.settable l (-3)

	Lua.pushstring l "text"
	Lua.pushstring l $ strContent $ xmlval
	Lua.settable l (-3)

	Lua.pushstring l "children"
	Lua.newtable l
	add_table_contents l (zip ([1..] :: [Int]) (elChildren xmlval))
	Lua.settable l (-3)

push_function l1 f identifier = do
	Lua.pushhsfunction_raw l1 (\l2 -> (f l2) `catch` (\e -> do
		putStrLn $ "ERROR: Lua.hs error in " ++ identifier ++ ": " ++ (show e)
		Lua.pushstring l2 (show (e :: SomeException))
		return (-1)))

-- TODO: Just use index 1 and 2, not "key" and "value"?

luatbl_to_stringmap l idx = do
	let get_more = do
		n <- Lua.next l idx
		if n
			then do
				t1 <- Lua.ltype l (-2)
				t2 <- Lua.ltype l (-1)
				(k, v) <- case (t1, t2) of
					(Lua.TSTRING, Lua.TSTRING) -> do
						k <- Lua.tostring l (-2)
						v <- Data.ByteString.Char8.unpack <$> Lua.tobytestring l (-1)
						return (k, v)
					_ -> fail $ "Table keys/values are not strings: " ++ (show $ (t1, t2))
				Lua.pop l 1
				more <- get_more
				return $ (k, v) : more
			else return []
	Lua.pushnil l
	get_more

parse_keyvalue_luatbl l idx = do
	let get_more n = do
		Lua.pushinteger l n
		Lua.gettable l idx
		t <- Lua.ltype l (-1)
		case t of
			Lua.TTABLE -> do
				topidx <- Lua.gettop l
				tbl <- luatbl_to_stringmap l topidx
				(k, v) <- case (lookup "key" tbl, lookup "value" tbl) of
					(Just k, Just v) -> return (k, v)
					_ -> fail "key or value missing from param table"
				Lua.pop l 1
				more <- get_more (n + 1)
				return $ (k, v) : more
			Lua.TNIL -> return []
			Lua.TNONE -> return []
			_ -> fail "Wrong types for params table"
	isnil <- Lua.isnoneornil l idx
	istbl <- Lua.istable l idx
	if isnil
		then return Nothing
		else if istbl
			then Just <$> get_more 1
			else do
				t <- Lua.ltype l idx
				fail $ "ERROR: param " ++ show idx ++ " not a table parameter (" ++ show t ++ ")"

show_blocked_page_info ref l = do
	pwdstr <- KoL.Api.pwd <$> KoL.Api.getApiInfo ref
	Lua.pushstring l $ "<html><body><tt style=\"color: darkorange\">Page loading blocked.</tt><br><br><a href=\"/custom-clear-lua-script-cache?pwd=" ++ pwdstr ++ "\" style=\"color: green\">Reset</a></body></html>"
	Lua.pushstring l "/kolproxy-page-loading-blocked"
	return 2

submit_page_func ref l = do
	lua_log_line ref "> submit_page_func" (return ())
	shouldstop <- readIORef (blocking_lua_scripting ref)
	if shouldstop
		then show_blocked_page_info ref l
		else do
			top <- Lua.gettop l
			if top < 2
				then fail "Not enough parameters to submit_page"
				else do
					m_one <- Lua.peek l 1
					m_two <- Lua.peek l 2
					case (m_one, m_two) of
						(Just one, Just two) -> do
							params <- parse_keyvalue_luatbl l 3
							(pt, puri, _hdrs) <- join $ async_submit_page ref one two params
							Lua.pushbytestring l pt
							Lua.pushstring l (show puri)
							lua_log_line ref ("< submit_page_func " ++ (show puri)) (return ())
							return 2
						_ -> fail "Wrong parameters to submit_page"

async_submit_page_func ref l1 = do
	lua_log_line ref "> async_submit_page_func" (return ())
	shouldstop <- readIORef (blocking_lua_scripting ref)
	if shouldstop
		then do
			push_function l1 (show_blocked_page_info ref) "async_submit_page_callback"
			return 1
		else do
			top <- Lua.gettop l1
			if top < 2
				then fail "Not enough parameters to async_submit_page"
				else do
					m_one <- Lua.peek l1 1
					m_two <- Lua.peek l1 2
					case (m_one, m_two) of
						(Just one, Just two) -> do
							params <- parse_keyvalue_luatbl l1 3
							f <- async_submit_page ref one two params
							lua_log_line ref "< async_submit_page_func requested" (return ())
							push_function l1 (\l2 -> do
								(pt, puri, _hdrs) <- f
								lua_log_line ref ("< async_submit_page_func result " ++ (show puri)) (return ())
								Lua.pushbytestring l2 pt
								Lua.pushstring l2 (show puri)
								return 2) "async_submit_page_callback"
							return 1
						_ -> fail "Wrong parameters to async_submit_page"


make_href _ref l = do
	m_one <- Lua.peek l 1
	case m_one of
		Just inputuristr -> do
			params <- parse_keyvalue_luatbl l 2
			case parseURIReference inputuristr of	
				Just inputuri -> do
					case (stripPrefix "/" (uriPath inputuri), uriQuery inputuri) of
						(Just _, "") -> do
							href <- case params of
								Nothing -> return (show inputuri)
								Just p -> do
									let testurienc = (uriPath inputuri) ++ "?" ++ (formEncode p)
									let testuri = escapeURIString (\x -> x `notElem` "[]") testurienc
									case parseURIReference testuri of
										Just uri -> return (show uri)
										_ -> fail $ "make_href error: uri " ++ (show testuri) ++ " not recognized."
							Lua.pushstring l href
							return 1
						_ -> fail $ "make_href error: unknown url " ++ (show inputuri)
				_ -> fail $ "make_href error: unknown url " ++ (show inputuristr)
		_ -> fail "Wrong parameters to make_href"

-- TODO: parse in lua
get_fallback_choicespoilers _ref l = do
	fallback_spoilers <- doReadDataFile "cache/data/choice-spoilers"
	Lua.newtable l
	topidx <- Lua.gettop l
	let add_line xs = do
		case (lookup "choice number" xs, lookup "spoilers" xs) of
			(Just choicenumstr, Just spoilersstr) -> do
				case (read_as choicenumstr, read_as spoilersstr) of
					(Just choicenum, Just spoilers) -> do
						Lua.pushinteger l (fromIntegral (choicenum :: Integer))
						Lua.newtable l
						add_table_contents l (zip [1..] spoilers :: [(Int, String)])
						Lua.settable l topidx
					_ -> throwIO $ InternalError $ "Invalid choice spoiler, id: " ++ show xs
			_ -> throwIO $ InternalError $ "Invalid choice spoiler, id: " ++ show xs
	mapM_ add_line fallback_spoilers
	return 1

-- TODO: parse in lua
get_pulverize_groups _ref l = do
	groups <- doReadDataFile "cache/data/pulverize-groups"
	Lua.newtable l
	topidx <- Lua.gettop l
	let add_group (trgidx, (label, items)) = do
		Lua.pushinteger l trgidx
		Lua.newtable l
		gidx <- Lua.gettop l

		Lua.pushstring l "label"
		Lua.pushstring l label
		Lua.settable l gidx

		Lua.pushstring l "items"
		Lua.newtable l
		add_table_contents l $ zip (items :: [Integer]) (repeat True)
		Lua.settable l gidx

		Lua.settable l topidx

	mapM_ add_group (zip [1..] groups)
	return 1

get_api_itemid_info ref l1 = do
	m_id <- Lua.peek l1 1 :: IO (Maybe Int)
	case m_id of
		Just itemid -> do
			f <- KoL.Api.asyncGetItemInfoObj itemid ref
			let callback_f l2 = do
				push_jsvalue l2 =<< f
				return 1
			push_function l1 callback_f "get_api_itemid_info_callback"
			return 1
		_ -> return 0

setup_lua_instance level filename setupref = do
	(l, c) <- log_time_interval setupref ("setup lua: " ++ filename) $ do
		code <- readFile filename

		lstate <- Lua.newstate
		Lua.openlibs lstate

		let register_function name f = do
			let log_f l = lua_log_line setupref name (f setupref l)
			push_function lstate log_f name
			Lua.setglobal lstate name

		register_function "raw_make_href" $ make_href

		register_function "get_inventory_counts" $ \ref l -> do
			Lua.newtable l
			add_table_contents l =<< KoL.Api.getInventoryCounts ref
			return 1

		register_function "get_status_info" $ \ref l -> do
			push_jsvalue l =<< KoL.Api.getCharStatusObj ref
			return 1

		register_function "json_to_table" $ \_ref l -> do
			Just jsonstr <- Lua.peek l 1
			let Ok jsonobj = decodeStrict jsonstr
			push_jsvalue l jsonobj
			return 1

		register_function "table_to_json" $ \_ref l -> do
			jsonobj <- lua_to_jsvalue l
			Lua.pushstring l (encodeStrict jsonobj)
			return 1

		register_function "simplexmldata_to_table" $ \_ref l -> do
			Just xmlstr <- Lua.peek l 1
			let Just xmldoc = parseXMLDoc (xmlstr :: String)
			push_simplexmldata l xmldoc
			return 1

		register_function "get_semirare_encounters" $ \_ref l -> do
			semis <- doReadDataFile "cache/data/semirares"
			Lua.newtable l
			add_table_contents l (zip [1..] semis :: [(Int, String)])
			return 1

		register_function "get_fallback_choicespoilers" $ get_fallback_choicespoilers

		register_function "get_pulverize_groups" get_pulverize_groups

		register_function "get_current_kolproxy_version" $ \_ref l -> do
			Lua.pushstring l =<< get_current_kolproxy_version
			return 1
		
		register_function "get_latest_kolproxy_version" $ \_ref l -> do
			Lua.pushstring l =<< get_latest_kolproxy_version
			return 1

		register_function "get_shutdown_secret_key" $ \ref l -> do
			Lua.pushstring l (shutdown_secret_ $ globalstuff_ $ ref)
			return 1

		register_function "kolproxy_log_time_interval" $ \ref l -> do
			desc <- Lua.tostring l 1
			Lua.remove l 1
			isok <- log_time_interval ref ("lua:" ++ desc) $ Lua.pcall l 0 Lua.multret 0
			case isok of
				0 -> fromIntegral <$> Lua.gettop l
				_ -> throwIO =<< userError <$> Lua.tostring l (-1)

		-- TODO: push true/false directly
		register_function "can_read_state" $ \ref l -> do
			x <- canReadState ref
			Lua.pushstring l $ if x then "yes" else "no"
			return 1

		register_function "block_lua_scripting" $ \ref _l -> do
			writeIORef (blocking_lua_scripting ref) True
			return 0

		register_function "parse_table_string" parse_table_string

		register_function "get_recipes" get_recipes

		--Lua.registerhsfunction l "get_raw_charpane_text" KoL.Api.getRawCharpaneText

		case level of
			WHENEVER -> do
				register_function "get_character_name" $ \ref l -> do
					Lua.pushstring l =<< get_ref_playername ref
					return 1
				register_function "get_player_id" get_player_id
				Lua.registerhsfunction lstate "set_chat_state" (set_state_whenever setupref)
				Lua.registerhsfunction lstate "get_chat_state" (get_state_whenever setupref)
			PROCESS -> do
				Lua.registerhsfunction lstate "set_state" (set_state setupref)
				Lua.registerhsfunction lstate "get_state" (get_state setupref)
				Lua.registerhsfunction lstate "reset_fight_state" (uglyhack_resetFightState setupref)
				register_function "get_api_itemid_info" get_api_itemid_info
			PRINTER -> do
				Lua.registerhsfunction lstate "get_state" (get_state setupref)
				Lua.registerhsfunction lstate "reset_fight_state" (uglyhack_resetFightState setupref)
				register_function "get_api_itemid_info" get_api_itemid_info
			AUTOMATE -> do
				Lua.registerhsfunction lstate "set_state" (set_state setupref)
				Lua.registerhsfunction lstate "get_state" (get_state setupref)
				register_function "raw_submit_page" submit_page_func
				register_function "raw_async_submit_page" async_submit_page_func
				register_function "get_api_itemid_info" get_api_itemid_info
			INTERCEPT -> do
				Lua.registerhsfunction lstate "set_state" (set_state setupref)
				Lua.registerhsfunction lstate "get_state" (get_state setupref)
				register_function "raw_submit_page" submit_page_func
				register_function "raw_async_submit_page" async_submit_page_func
				register_function "get_api_itemid_info" get_api_itemid_info

		Lua.registerhsfunction lstate "kolproxy_debug_print" (\x -> lua_log_line setupref ("kolproxy_debug_print: " ++ x) (return ()))

		-- TODO: handle return codes?
		void $ Lua.safeloadstring lstate "local dtb = debug.traceback; return function(e) kolproxy_debug_traceback = dtb(\"\", 2) return e end"
		void $ Lua.pcall lstate 0 1 0 -- put error handling function on stack=1

		c <- Lua.safeloadstring lstate code
		return (lstate, c)

	case c of
		0 -> do
			moo <- log_time_interval setupref ("do lua loading code: " ++ filename) $ Lua.pcall l 0 Lua.multret 1 -- returns on stack=2+
			case moo of
				0 -> do
					Lua.setglobal l "kolproxy_stored_wrapped_function"
					return $ Right l
				_ -> do
					putStrLn $ "lua error!"
					top <- Lua.gettop l
					putStrLn $ "lua error, top = " ++ (show top)
					err <- Lua.tostring l (-1)
					putStrLn $ "lua error: " ++ err
					Lua.getglobal l "kolproxy_debug_traceback" -- load traceback on stack=3
					traceback <- Lua.tostring l 3
					putStrLn $ "traceback: " ++ traceback
					return $ Left $ ("error running loading code (" ++ filename ++ "):\n" ++ err, traceback)
		errnum -> do
			putStrLn $ "luaload error!"
			top <- Lua.gettop l
			putStrLn $ "luaload error, top = " ++ (show top)
			err <- Lua.tostring l (-1)
			putStrLn $ "luaload error: " ++ err
			return $ Left $ ("error " ++ (show errnum) ++ " loading code (" ++ filename ++ "):\n" ++ err, "")

get_cached_lua_instance_for_code level filename ref runcodebit = do
	-- TODO! CLOSE LUA INSTANCES!!
	let make_lsetup = log_time_interval ref ("setup lua instance: " ++ filename ++ "|" ++ show level) $ setup_lua_instance level filename ref

	canread <- canReadState ref
	if canread || level == WHENEVER
		then do
			-- TODO: Wrap in MVar instead of IORef?
			insts <- readIORef (luaInstances_ $ sessionData $ ref)
			case Data.Map.lookup (filename, level) insts of
				-- Use MVar to only run one piece of code in an instance at a time, e.g. sequence one processor after another serially.
				-- TODO: Use a Chan to enforce order?
				Just existingmv -> withMVar existingmv runcodebit
				_ -> do
					either_l_setup <- make_lsetup
					case either_l_setup of
						Right l_setup -> do
							mv_l <- newMVar l_setup
							let newinsts = Data.Map.insert (filename, level) mv_l insts
							writeIORef (luaInstances_ $ sessionData $ ref) newinsts
							withMVar mv_l runcodebit
						Left err -> return $ Left err
		else do
-- 			putStrLn $ "DEBUG: not cached " ++ show (canread, level) ++ " | " ++ show filename
			either_l_setup <- make_lsetup
			case either_l_setup of
				Right l_setup -> do
					x <- runcodebit l_setup
					log_time_interval ref "close lua" $ Lua.close l_setup
					return x
				Left err -> return $ Left err

run_lua_code level filename ref dosetvars = do
	get_cached_lua_instance_for_code level filename ref $ \l -> do
-- 		case lookup "text" (vars :: [(String, String)]) of
-- 			Just text -> (lua_log_line ref ("run_lua_code:" ++ filename ++ " [" ++ (show $ lookup "path" vars) ++ ", param length " ++ (show $ length $ fromJust $ lookup "raw_input_params" vars) ++ ", text length " ++ (show $ length text) ++ "]") (return ())) `catch` (\e -> putStrLn $ "run_lua_code error: " ++ (show (e :: SomeException)))
-- 			_ -> (lua_log_line ref ("run_lua_code:" ++ filename ++ " [" ++ (show $ lookup "path" vars) ++ ", param length " ++ (show $ length $ fromJust $ lookup "raw_input_params" vars) ++ ", no text]") (return ())) `catch` (\e -> putStrLn $ "run_lua_code error: " ++ (show (e :: SomeException)))
-- 		putStrLn $ "> run_lua_code: " ++ (filename) ++ " [" ++ (show $ lookup "path" vars) ++ "]"

		log_time_interval ref "prepare for lua code" $ do
			top <- Lua.gettop l
			when (top > 1) $ do
				putStrLn $ "ERROR: Lua top is " ++ show top
				Lua.pop l (top - 1)
			Lua.getglobal l "kolproxy_stored_wrapped_function"
			void $ dosetvars l

		moo_two <- log_time_interval ref ("run lua code: " ++ filename) $ Lua.pcall l 1 Lua.multret 1 -- returns on stack=2+
		log_time_interval ref "retrieving results" $ case moo_two of
			0 -> do
				top <- Lua.gettop l
				rets <- mapM (\x -> do
					isstring <- Lua.isstring l x
					if isstring
						then Just <$> Lua.tobytestring l x
						else return Nothing) [2..top]
				Lua.pop l (top - 1)
				return $ Right rets
			_ -> do
				putStrLn $ "lua-call error!"
				top <- Lua.gettop l
				putStrLn $ "lua-call error, top = " ++ (show top)
				err <- Lua.tostring l (-1)
				putStrLn $ "lua-call error: " ++ err
				Lua.getglobal l "kolproxy_debug_traceback" -- load traceback on stack=3
				traceback <- Lua.tostring l 3
				putStrLn $ "call-traceback: " ++ traceback
				Lua.pop l (top - 1)
				return $ Left $ ("error running code (" ++ filename ++ "):\n" ++ err, traceback)

setvars vars text allparams l = do
	Lua.newtable l
	add_table_contents l (vars :: [(String, String)])
	Lua.pushstring l "text"
	Lua.push l text
	Lua.settable l (-3)
	Lua.pushstring l "raw_input_params"
	Lua.pushstring l (show (allparams :: [(String, String)]))
	Lua.settable l (-3)
	return ()

runProcessScript ref uri effuri pagetext allparams = do
	let vars = [("path", uriPath effuri), ("query", uriQuery effuri), ("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
	rets <- run_lua_code PROCESS "scripts/process-page.lua" ref (setvars vars pagetext allparams)
	return $ case rets of
		Right [Just t] -> Right $ t
		Right xs -> Left ("Lua process call error, return values = " ++ (show xs), "")
		Left err -> Left err

runPrinterScript ref uri effuri pagetext allparams = do
	let vars = [("path", uriPath effuri), ("query", uriQuery effuri), ("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
	rets <- run_lua_code PRINTER "scripts/printer.lua" ref (setvars vars pagetext allparams)
	return $ case rets of
		Right [Just t] -> Right $ t
		Right xs -> Left ("Lua printer call error, return values = " ++ (show xs), "")
		Left err -> Left err

runChatScript ref uri effuri pagetext allparams = do
	let vars = [("path", uriPath effuri), ("query", uriQuery effuri), ("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
	rets <- run_lua_code WHENEVER "scripts/chat.lua" ref (setvars vars pagetext allparams)
	return $ case rets of
		Right [Just t] -> Right $ t
		Right xs -> Left ("Lua chat call error, return values = " ++ (show xs), "")
		Left err -> Left err

runSendChatScript ref uri allparams = do
	let vars = [("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
	rets <- run_lua_code WHENEVER "scripts/sendchat.lua" ref (setvars vars "" allparams)
	return $ case rets of
		Right [Just t] -> Right $ t
		Right xs -> Left ("Lua chat call error, return values = " ++ (show xs), "")
		Left err -> Left err

runSentChatScript ref msg = do
	void $ run_lua_code WHENEVER "scripts/sentchat.lua" ref (setvars [] msg [])
	return ()

runAutomateScript ref uri effuri pagetext allparams = do
	let vars = [("path", uriPath effuri), ("query", uriQuery effuri), ("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
	rets <- run_lua_code AUTOMATE "scripts/automate.lua" ref (setvars vars pagetext allparams)
	return $ case rets of
		Right [Just t] -> Right t
		Right xs -> Left ("Lua automate call error, return values = " ++ (show xs), "")
		Left err -> Left err

runInterceptScript ref uri allparams reqtype = do
	let vars = [("requestpath", uriPath uri), ("requestquery", uriQuery uri), ("request_type", reqtype)]
	rets <- run_lua_code INTERCEPT "scripts/intercept.lua" ref (setvars vars "" allparams)
	return $ case rets of
		Right [Just t, Just u] -> Right (t, mkuri $ Data.ByteString.Char8.unpack $ u)
		Right xs -> Left ("Lua intercept call error, return values = " ++ (show xs), "")
		Left err -> Left err

runLogParsingScript log_db = do
	code <- readFile "scripts/parselog.lua"

	lstate <- Lua.newstate
	Lua.openlibs lstate

	let register_function name f = do
		push_function lstate f name
		Lua.setglobal lstate name

	register_function "json_to_table" $ \l -> do
		Just jsonstr <- Lua.peek l 1
		let Ok jsonobj = decodeStrict jsonstr
		push_jsvalue l jsonobj
		return 1

	register_function "get_log_lines" $ \l -> do
		s <- Database.SQLite3.prepare log_db "SELECT idx FROM pageloads;"
		Lua.newtable l
		let process tblidx = do
			sr <- Database.SQLite3.step s
			case sr of
				Database.SQLite3.Row -> do
					[Database.SQLite3.SQLInteger lidx] <- Database.SQLite3.columns s
					Lua.pushinteger l tblidx
					Lua.pushinteger l (fromIntegral lidx)
					Lua.settable l (-3)
					process (tblidx + 1)
				Database.SQLite3.Done -> return ()
		process 1
		Database.SQLite3.finalize s
		return 1

	register_function "get_line_text" $ \l -> do
		Just whichidx <- Lua.peek l 1 :: IO (Maybe Int)
		Just whichfield <- Lua.peek l 2
		s <- Database.SQLite3.prepare log_db ("SELECT " ++ whichfield ++ " FROM pageloads WHERE idx == " ++ show whichidx ++ ";") -- TODO: make safe?
		sr <- Database.SQLite3.step s
		retvals <- case sr of
			Database.SQLite3.Row -> do
				[Database.SQLite3.SQLText str] <- Database.SQLite3.columns s
				Lua.pushstring l str
				return 1
			Database.SQLite3.Done -> return 0
		Database.SQLite3.finalize s
		return retvals

--	register_function "get_line_json" $ \l -> do
--		Just whichidx <- Lua.peek l 1 :: IO (Maybe Int)
--		Just whichfield <- Lua.peek l 2
--		s <- Database.SQLite3.prepare log_db ("SELECT " ++ whichfield ++ " FROM pageloads WHERE idx == " ++ show whichidx ++ ";") -- TODO: make safe?
--		sr <- Database.SQLite3.step s
--		retvals <- case sr of
--			Database.SQLite3.Row -> do
--				[Database.SQLite3.SQLText jsonstr] <- Database.SQLite3.columns s
--				let Ok jsonobj = decodeStrict jsonstr
--				push_jsvalue l jsonobj
--				return 1
--			Database.SQLite3.Done -> return 0
--		Database.SQLite3.finalize s
--		return retvals

	register_function "get_line_allparams" $ \l -> do
		Just whichidx <- Lua.peek l 1 :: IO (Maybe Int)
		s <- Database.SQLite3.prepare log_db ("SELECT requestedurl, retrievedurl, parameters FROM pageloads WHERE idx == " ++ show whichidx ++ ";")
		sr <- Database.SQLite3.step s
		retvals <- case sr of
			Database.SQLite3.Row -> do
				[Database.SQLite3.SQLText requestedurlstr, Database.SQLite3.SQLText retrievedurlstr, paramthing] <- Database.SQLite3.columns s
-- 				putStrLn $ "params: " ++ show paramthing
				let Just uri = parseURIReference requestedurlstr
				let Just effuri = parseURIReference retrievedurlstr
				let params = case paramthing of
					Database.SQLite3.SQLText parametersstr -> read_as parametersstr
					_ -> Nothing
				let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
-- 				putStrLn $ "allparams: " ++ show allparams
				Lua.newtable l
				add_table_contents l allparams
				return 1
			Database.SQLite3.Done -> return 0
		Database.SQLite3.finalize s
		return retvals

	loginforef <- newIORef Nothing
	register_function "set_log_info" $ \l -> do
		Just playerid <- Lua.peek l 1
		Just charname <- Lua.peek l 2
		Just ascnum <- Lua.peek l 3
		Just secretkey <- Lua.peek l 4
		writeIORef loginforef $ Just (fromIntegral (playerid :: Int) :: Integer, charname :: String, fromIntegral (ascnum :: Int) :: Integer, get_md5 $ secretkey)
		return 0

	register_function "get_url_path" $ \l -> do
		m_url <- Lua.peek l 1
		case m_url of
			Just urlstr -> do
				case parseURIReference urlstr of
					Just uri -> do
						Lua.pushstring l (uriPath uri)
						return 1
					_ -> return 0
			_ -> return 0

	let l = lstate

	-- TODO: handle return value?
	void $ Lua.safeloadstring l "local dtb = debug.traceback; return function(e) kolproxy_debug_traceback = dtb(\"\", 2) return e end"
	-- TODO: handle return value?
	void $ Lua.pcall l 0 1 0 -- put error handling function on stack=1

	_c <- Lua.safeloadstring l code
	-- TODO: Check that it loads correctly?

	retcode <- Lua.pcall l 0 Lua.multret 1 -- returns on stack=2+
	jsonstr <- case retcode of
		0 -> do
			jsonstr <- encodeStrict <$> lua_to_jsvalue l
			putStrLn $ "json length: " ++ (show $ length $ jsonstr)
			return jsonstr
		_ -> do
			putStrLn $ "lua error!"
			top <- Lua.gettop l
			putStrLn $ "lua error, top = " ++ (show top)
			err <- Lua.tostring l (-1)
			putStrLn $ "lua error: " ++ err
			Lua.getglobal l "kolproxy_debug_traceback" -- load traceback on stack=3
			traceback <- Lua.tostring l 3
			putStrLn $ "traceback: " ++ traceback
			return ""

	Lua.close l

	maybeloginfo <- readIORef loginforef

	return (jsonstr, maybeloginfo)

run_datafile_parsers = do
	code <- readFile "scripts/update-datafiles.lua"

	lstate <- Lua.newstate
	Lua.openlibs lstate

	let register_function name f = do
		push_function lstate f name
		Lua.setglobal lstate name

	register_function "json_to_table" $ \l -> do
		Just jsonstr <- Lua.peek l 1
		let Ok jsonobj = decodeStrict jsonstr
		push_jsvalue l jsonobj
		return 1

	register_function "table_to_json" $ \l -> do
		jsonobj <- lua_to_jsvalue l
		Lua.pushstring l (encodeStrict jsonobj)
		return 1

	register_function "simplexmldata_to_table" $ \l -> do
		Just xmlstr <- Lua.peek l 1
		let Just xmldoc = parseXMLDoc (xmlstr :: String)
		push_simplexmldata l xmldoc
		return 1

	-- TODO: handle return value?
	void $ Lua.safeloadstring lstate "local dtb = debug.traceback; return function(e) kolproxy_debug_traceback = dtb(\"\", 2) return e end"
	-- TODO: handle return value?
	void $ Lua.pcall lstate 0 1 0 -- put error handling function on stack=1

	_c <- Lua.safeloadstring lstate code
	-- TODO: Check that it loads correctly?

	retcode <- Lua.pcall lstate 0 Lua.multret 1 -- returns on stack=2+
	case retcode of
		0 -> Lua.close lstate
		_ -> do
			putStrLn $ "lua error!"
			top <- Lua.gettop lstate
			putStrLn $ "lua error, top = " ++ (show top)
			err <- Lua.tostring lstate (-1)
			putStrLn $ "lua error: " ++ err
			Lua.getglobal lstate "kolproxy_debug_traceback" -- load traceback on stack=3
			traceback <- Lua.tostring lstate 3
			putStrLn $ "traceback: " ++ traceback
			Lua.close lstate
			throwIO $ InternalError err
