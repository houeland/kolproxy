{-# LANGUAGE ForeignFunctionInterface, BangPatterns #-}

module Lua where

import Prelude
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
import Data.Time.Clock
import Data.Time.LocalTime
--import Data.Time.Format
import Network.URI
import Network.CGI
import System.IO.Error (isUserError, ioeGetErrorString)
import Text.JSON
import Text.XML.Light
import qualified Data.ByteString.Char8
import qualified Data.Map
import qualified Database.SQLite3Modded
import qualified Scripting.LuaModded as Lua

-- TODO: Remove type-based Lua.peek/Lua.push

local_maybepeek l n test peek = do
	v <- test l n
	if v
		then liftM Just (peek l n)
		else return Nothing

instance Lua.StackValue Integer where
	push l x = Lua.pushinteger l x
	peek l1 n = local_maybepeek l1 n Lua.isnumber (\l2 n2 -> liftM fromIntegral (Lua.tointeger l2 n2))
	valuetype _ = Lua.TNUMBER

instance Lua.StackValue Data.ByteString.Char8.ByteString where
	push l x = Lua.pushbytestring l x
	peek l1 n1 = local_maybepeek l1 n1 Lua.isstring (\l2 n2 -> Lua.tobytestring l2 n2)
	valuetype _ = Lua.TSTRING

instance Lua.StackValue JSValue where
	push l x = push_jsvalue l x
	peek _l _n = throwIO $ LuaError $ "ERROR: Attempting to peek a jsvalue from Lua"
	valuetype _ = Lua.TTABLE

instance Lua.StackValue Element where
	push l x = push_simplexmldata l x
	peek _l _n = throwIO $ LuaError $ "ERROR: Attempting to peek an Element from Lua"
	valuetype _ = Lua.TTABLE

failLua msg = throwIO $ LuaError $ msg

-- TODO: Remove
__peekJust l idx = do
	x <- Lua.peek l idx
	case x of
		Just v -> return v
		_ -> failLua $ "Wrong parameter " ++ show idx

peekJustString l idx = (__peekJust l idx) :: IO String
peekJustInteger l idx = (__peekJust l idx) :: IO Integer
peekJustDouble l idx = (__peekJust l idx) :: IO Double

get_current_kolproxy_version = return $ kolproxy_version_number :: IO String

get_latest_kolproxy_version = do
	version <- getHTTPFileData "http://www.houeland.com/kolproxy/latest-version.json"
	if (length version <= 1000)
		then return version
		else return "?"

set_state_processpage ref l = do
	stateset <- peekJustString l 1
	var <- peekJustString l 2
	canread <- canReadState ref
	unless canread $ failLua $ "Error: Trying to set state \"" ++ var ++ "\" before state is available."
	unless (stateset `elem` ["character", "ascension", "day", "fight", "session"]) $ failLua $ "cannot write to stateset " ++ (show $ stateset)
	oldvalue <- getState ref stateset var
	newvalue <- do
		isempty <- Lua.isnoneornil l 3
		if isempty
			then return Nothing
			else Just <$> peekJustString l 3
	when (oldvalue /= newvalue) $ case newvalue of
		Just value -> setState ref stateset var value
		Nothing -> unsetState ref stateset var
	return 0

set_state_browserrequest ref l = do
	x <- set_state_processpage ref l
	checkServerState ref
	return x

get_state ref l = do
	stateset <- peekJustString l 1
	var <- peekJustString l 2
	canread <- canReadState ref
	unless canread $ failLua $ "Error: Trying to get state \"" ++ var ++ "\" before state is available."
	unless (stateset `elem` ["character", "ascension", "day", "fight", "session"]) $ failLua $ "cannot read stateset " ++ (show $ stateset)
	maybevalue <- getState ref stateset var
	case maybevalue of
		Just value -> Lua.pushbytestring l (Data.ByteString.Char8.pack value) >> return 1
		_ -> return 0

-- TODO: Check if this is really OK. It's not in valhalla!
get_ref_playername ref = KoL.Api.charName <$> KoL.Api.getApiInfo ref

set_chat_state ref l = do
	var <- peekJustString l 1
	value <- peekJustString l 2
	charname <- get_ref_playername ref
	chatmap <- Data.Map.insert var value <$> readMapFromFile ("chat-" ++ charname ++ ".state")
	writeMapToFile ("chat-" ++ charname ++ ".state") chatmap
	return 0

get_chat_state ref l = do
	var <- peekJustString l 1
	charname <- get_ref_playername ref
	chatmap <- readMapFromFile ("chat-" ++ charname ++ ".state")
	Lua.pushstring l $ fromMaybe "" (Data.Map.lookup var chatmap)
	return 1

-- TODO: handle in Lua
get_player_id ref l = do
	name <- peekJustString l 1
	pid <- KoL.Api.getPlayerId name ref
	case pid of
		Just x -> do
			Lua.pushinteger l x
			return 1
		Nothing -> return 0

-- TODO: remove
parse_request_param_string _ref l = do
	str <- peekJustString l 1
	case read_as str :: Maybe [(String, String)] of
		Just xs -> do
			let pushkeyvalue (idx, (x, y)) = do
				Lua.pushinteger l idx
				Lua.newtable l
				Lua.pushstring l "key"
				Lua.pushstring l x
				Lua.settable l (-3)
				Lua.pushstring l "value"
				Lua.pushstring l y
				Lua.settable l (-3)
				Lua.settable l (-3)

			Lua.newtable l
			mapM_ pushkeyvalue (zip ([1..] :: [Integer]) xs)
			return 1
		_ -> return 0

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

get_submit_uri_params_DEBUG _ref method inputuristr params = do
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
										_ -> failLua $ "submit page error: uri " ++ (show testuri) ++ " not recognized."
						"POST" -> do
							case params of
								Just p -> return (uriPath inputuri, Just p)
								_ -> failLua $ "submit page error: parameters " ++ (show params) ++ " not recognized."
						_ -> failLua $ "submit page error: unknown method " ++ (show method) ++ ", should be GET or POST"
				_ -> failLua $ "submit page error: unknown url " ++ (show inputuri)
		_ -> failLua $ "submit page error: unknown url " ++ (show inputuristr)

async_submit_page_DEBUG ref method inputuristr params = do
	(final_url, final_params) <- get_submit_uri_params_DEBUG ref method inputuristr params
	xf <- (processPage ref) ref (mkuri final_url) final_params
	return xf

__push_table_contents_with l tbl f1 f2 = do
	Lua.newtable l
	mapM_ (\(x, y) -> do
		f1 l x
		f2 l y
		Lua.settable l (-3)) tbl

push_table_contents_integer_integer l tbl = __push_table_contents_with l tbl Lua.pushinteger Lua.pushinteger
push_table_contents_integer_boolean l tbl = __push_table_contents_with l tbl Lua.pushinteger Lua.pushboolean
push_table_contents_string_string l tbl = __push_table_contents_with l tbl Lua.pushstring Lua.pushstring
push_table_contents_string_json l tbl = __push_table_contents_with l tbl Lua.pushstring push_jsvalue
push_table_contents_stringlist l tbl = __push_table_contents_with l (zip [1..] tbl) Lua.pushinteger Lua.pushstring
push_table_contents_jsonlist l tbl = __push_table_contents_with l (zip [1..] tbl) Lua.pushinteger push_jsvalue
push_table_contents_xmllist l tbl = __push_table_contents_with l (zip [1..] tbl) Lua.pushinteger push_simplexmldata

push_jsvalue l jsval = do
	case jsval of
		JSNull -> Lua.pushnil l
		JSBool b -> Lua.pushboolean l b
		JSRational _ r -> Lua.pushnumber l (fromRational r)
		JSString jss -> Lua.pushbytestring l $ Data.ByteString.Char8.pack $ fromJSString $ jss
		JSArray jsarr -> push_table_contents_jsonlist l jsarr
		JSObject jsobj -> push_table_contents_string_json l $ fromJSObject jsobj

array_tbl_to_jsvalue l = do
	let get_more n initlist = do
		Lua.pushinteger l n
		Lua.rawget l (-2)
		isempty <- Lua.isnoneornil l (-1)
		if isempty
			then do
				Lua.pop l 1
				return (n - 1, initlist)
			else do
				v <- lua_to_jsvalue l
				get_more (n + 1) (v:initlist)
	(arraylen, valuelist) <- get_more 1 []
	let array_recur = do
		nonempty <- Lua.next l (-2)
		when nonempty $ do
			t <- Lua.ltype l (-2)
			case t of
				Lua.TNUMBER -> return ()
				_ -> failLua ("JSON array keys must be integers, got type: " ++ show t)
			k <- Lua.tointeger l (-2)
			Lua.pop l 1
			when ((k < 1) || (k > arraylen)) $ failLua ("Non-sequential JSON array key: " ++ show k)
			array_recur
	Lua.pushnil l
	array_recur
	return $ JSArray $ reverse $ valuelist

stringobj_tbl_to_jsvalue l = do
	let strobj_recur curmap = do
		nonempty <- Lua.next l (-2)
		if nonempty
			then do
				t <- Lua.ltype l (-2)
				case t of
					Lua.TSTRING -> return ()
					_ -> failLua ("JSON object keys must be strings, got type: " ++ show t)
				k <- Lua.tostring l (-2)
				v <- lua_to_jsvalue l
				strobj_recur $ Data.Map.insert k v curmap
			else return curmap
	Lua.pushnil l
	objmap <- strobj_recur Data.Map.empty
	return $ JSObject $ toJSObject $ Data.Map.assocs $ objmap

lua_to_jsvalue l = do
	t <- Lua.ltype l (-1)
	!val <- case t of
		Lua.TTABLE -> do
			Lua.pushinteger l 1
			Lua.rawget l (-2)
			isempty1idx <- Lua.isnoneornil l (-1)
			Lua.pop l 1
			if isempty1idx
				then stringobj_tbl_to_jsvalue l
				else array_tbl_to_jsvalue l
		Lua.TSTRING -> JSString <$> toJSString <$> Lua.tostring l (-1)
		Lua.TNUMBER -> JSRational False <$> toRational <$> Lua.tonumber l (-1)
		Lua.TBOOLEAN -> JSBool <$> Lua.toboolean l (-1)
		Lua.TNIL -> return JSNull
		_ -> failLua ("Unhandled type for lua_to_jsvalue: " ++ show t)
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
	push_table_contents_xmllist l $ elChildren xmlval
	Lua.settable l (-3)

push_function l1 f identifier = do
	let f_final l2 = (catchJust (\e -> if isUserError e then Just e else Nothing)
		(f l2)
		(\e -> do
			putStrLn $ "ERROR: Lua.hs IOerror in " ++ identifier ++ ": " ++ ioeGetErrorString e
			Lua.pushstring l2 $ "Haskell exception in " ++ identifier ++ " (" ++ ioeGetErrorString e ++ ")"
			return (-1))) `catch` (\e -> do
				putStrLn $ "ERROR: Lua.hs error in " ++ identifier ++ ": " ++ (show e)
				Lua.pushstring l2 $ "Haskell exception in " ++ identifier ++ ": " ++ show (e :: SomeException)
				return (-1))

	Lua.pushhsfunction_raw l1 f_final

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
					_ -> failLua $ "Table keys/values are not strings: " ++ (show $ (t1, t2))
				Lua.pop l 1
				more <- get_more
				return $ (k, v) : more
			else return []
	Lua.pushnil l
	get_more

-- TODO: redo parameters in simpler way?
parse_keyvalue_luatbl l idx = do
	let get_more n = do
		Lua.pushinteger l n
		Lua.rawget l idx
		t <- Lua.ltype l (-1)
		case t of
			Lua.TTABLE -> do
				topidx <- Lua.gettop l
				tbl <- luatbl_to_stringmap l topidx
				(k, v) <- case (lookup "key" tbl, lookup "value" tbl) of
					(Just k, Just v) -> return (k, v)
					_ -> failLua "key or value missing from param table"
				Lua.pop l 1
				more <- get_more (n + 1)
				return $ (k, v) : more
			Lua.TNIL -> return []
			Lua.TNONE -> return []
			_ -> failLua "Wrong types for params table"
	isnil <- Lua.isnoneornil l idx
	istbl <- Lua.istable l idx
	if isnil
		then return Nothing
		else if istbl
			then Just <$> get_more 1
			else do
				t <- Lua.ltype l idx
				failLua $ "ERROR: param " ++ show idx ++ " not a table parameter (" ++ show t ++ ")"

show_blocked_page_info ref l = do
	pwdstr <- KoL.Api.pwd <$> KoL.Api.getApiInfo ref
	Lua.pushstring l $ "<html><body><tt style=\"color: darkorange\">Page loading blocked.</tt><br><br><a href=\"/custom-clear-lua-script-cache?pwd=" ++ pwdstr ++ "\" style=\"color: green\">Reset</a></body></html>"
	Lua.pushstring l "/kolproxy-page-loading-blocked"
	return 2

async_submit_page_func_DEBUG ref l1 = do
	lua_log_line ref "> async_submit_page_func" (return ())
	shouldstop <- readIORef (blocking_lua_scripting ref)
	if shouldstop
		then do
			push_function l1 (show_blocked_page_info ref) "async_submit_page_callback"
			return 1
		else do
			top <- Lua.gettop l1
			if top < 2
				then failLua "Not enough parameters to async_submit_page"
				else do
					one <- peekJustString l1 1
					two <- peekJustString l1 2
					params <- parse_keyvalue_luatbl l1 3
					f <- async_submit_page_DEBUG ref one two params
					lua_log_line ref "< async_submit_page_func requested" (return ())
					push_function l1 (\l2 -> do
						ret <- f
						case ret of
							Right (pt, puri, _hdrs, _code) -> do
								lua_log_line ref ("< async_submit_page_func result " ++ (show puri)) (return ())
								Lua.pushbytestring l2 pt
								Lua.pushstring l2 (show puri)
								return 2
							Left (pt, puri, _hdrs, _code) -> do
								Lua.pushnil l2
								let newtext = Data.ByteString.Char8.concat [pt, (Data.ByteString.Char8.pack "<br><br>{&nbsp;<a href=\"/kolproxy-troubleshooting\">Click here for kolproxy troubleshooting.</a>&nbsp;}")]
								Lua.pushbytestring l2 newtext
								Lua.pushstring l2 (show puri)
								return 3) "async_submit_page_callback"
					return 1

make_href _ref l = do
	inputuristr <- peekJustString l 1
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
								_ -> failLua $ "make_href error: uri " ++ (show testuri) ++ " not recognized."
					Lua.pushstring l href
					return 1
				_ -> failLua $ "make_href error: unknown url " ++ (show inputuri)
		_ -> failLua $ "make_href error: unknown url " ++ (show inputuristr)

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
						Lua.pushinteger l choicenum
						push_table_contents_stringlist l spoilers
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
		push_table_contents_integer_boolean l $ zip items (repeat True)
		Lua.settable l gidx

		Lua.settable l topidx

	mapM_ add_group (zip [1..] groups)
	return 1

get_api_itemid_info ref l1 = do
	itemid <- peekJustInteger l1 1
	f <- KoL.Api.asyncGetItemInfoObj itemid ref
	let callback_f l2 = do
		push_jsvalue l2 =<< f
		return 1
	push_function l1 callback_f "get_api_itemid_info_callback"
	return 1

kolproxycore_enumerate_state ref l = do
	canread <- canReadState ref
	unless canread $ failLua $ "Error: Trying to enumerate state before state is available."
	statekeys <- uglyhack_enumerateState ref
	Lua.newtable l
	mapM_ (\(statename, keylist) -> do
		Lua.pushstring l statename
		push_table_contents_stringlist l keylist
		Lua.settable l (-3)) statekeys
	return 1

fromjson l = do
	jsonstr <- peekJustString l 1
	case decode jsonstr of
		Ok jsonobj -> do
			push_jsvalue l jsonobj
			return 1
		_ -> do
			putStrLn $ "DEBUG invalid JSON: " ++ jsonstr
			failLua "Invalid JSON"

tojson l = do
	jsonobj <- lua_to_jsvalue l
	Lua.pushstring l $ encode jsonobj
	return 1

decode_uri_query l = do
	querystr <- peekJustString l 1
	let Just uri = parseURIReference querystr
	case decodeUrlParams uri of
		Just vars -> push_table_contents_string_string l vars >> return 1
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
			push_table_contents_integer_integer l =<< KoL.Api.getInventoryCounts ref
			return 1

		register_function "get_status_info" $ \ref l -> do
			push_jsvalue l =<< KoL.Api.getCharStatusObj ref
			return 1

		register_function "fromjson" $ \_ref l -> fromjson l
		register_function "tojson" $ \_ref l -> tojson l

		register_function "kolproxycore_decode_uri_query" $ \_ref l -> decode_uri_query l

		register_function "kolproxy_md5" $ \_ref l -> do
			str <- peekJustString l 1
			Lua.pushstring l $ get_md5 str
			return 1

		register_function "kolproxy_list_ascension_logs" $ \_ref l -> do
			playerid <- peekJustInteger l 1
			secretkey <- peekJustString l 2
			Lua.pushstring l =<< postHTTPFileData "http://www.houeland.com/kolproxy/ascension-log" [("action", "list"), ("playerid", show playerid), ("secretkey", secretkey)]
			return 1

		register_function "simplexmldata_to_table" $ \_ref l -> do
			xmlstr <- peekJustString l 1
			let Just xmldoc = parseXMLDoc xmlstr
			push_simplexmldata l xmldoc
			return 1

		register_function "get_fallback_choicespoilers" $ get_fallback_choicespoilers

		register_function "get_pulverize_groups" get_pulverize_groups

		register_function "get_current_kolproxy_version" $ \_ref l -> do
			Lua.pushstring l =<< get_current_kolproxy_version
			return 1

		register_function "get_latest_kolproxy_version" $ \_ref l -> do
			versionstr <- get_latest_kolproxy_version
			case decodeStrict versionstr of
				Ok jsonobj -> do
					push_jsvalue l jsonobj
					return 1
				_ -> return 0

		register_function "get_shutdown_secret_key" $ \ref l -> do
			Lua.pushstring l (shutdown_secret_ $ globalstuff_ $ ref)
			return 1

		register_function "get_slow_http_setting" $ \ref l -> do
			slowconn <- readIORef $ use_slow_http_ref_ $ globalstuff_ $ ref
			Lua.pushboolean l slowconn
			return 1

		register_function "kolproxy_log_time_interval" $ \ref l -> do
			desc <- Lua.tostring l 1
			Lua.remove l 1
			isok <- log_time_interval ref ("lua:" ++ desc) $ Lua.pcall l 0 Lua.multret 0
			case isok of
				0 -> fromIntegral <$> Lua.gettop l
				_ -> throwIO =<< LuaError <$> Lua.tostring l (-1)

		register_function "kolproxy_can_read_state" $ \ref l -> do
			x <- canReadState ref
			Lua.pushboolean l x
			return 1

		register_function "kolproxy_is_listening_publicly" $ \ref l -> do
			Lua.pushboolean l $ listen_public ref
			return 1

		register_function "list_custom_autoload_script_files" $ \_ref l -> do
			filenames <- get_custom_autoload_script_files
			push_table_contents_stringlist l filenames
			return 1

		register_function "block_lua_scripting" $ \ref _l -> do
			writeIORef (blocking_lua_scripting ref) True
			return 0

		register_function "parse_request_param_string" parse_request_param_string

		case level of
			CHAT -> do
				register_function "kolproxycore_async_submit_page" async_submit_page_func_DEBUG
				register_function "get_character_name" $ \ref l -> do
					Lua.pushstring l =<< get_ref_playername ref
					return 1
				register_function "get_player_id" get_player_id
				register_function "set_chat_state" set_chat_state
				register_function "get_chat_state" get_chat_state
			PROCESS -> do
				register_function "set_state" set_state_processpage
				register_function "get_state" get_state
				register_function "reset_fight_state" $ \ref _l -> do
					uglyhack_resetFightState ref
					return 0
				register_function "get_api_itemid_info" get_api_itemid_info
			BROWSERREQUEST -> do
				register_function "set_state" set_state_browserrequest
				register_function "get_state" get_state
				register_function "reset_fight_state" $ \ref _l -> do
					uglyhack_resetFightState ref
					return 0
				register_function "get_api_itemid_info" get_api_itemid_info
				register_function "kolproxycore_enumerate_state" kolproxycore_enumerate_state
				register_function "kolproxycore_async_submit_page" async_submit_page_func_DEBUG
				register_function "kolproxycore_splituri" $ \_ref l -> do
					uristr <- peekJustString l 1
					let uri = mkuri uristr
					Lua.pushstring l $ uriPath uri
					Lua.pushstring l $ uriQuery uri
					return 2
			BOTSCRIPT -> do
				register_function "get_api_itemid_info" get_api_itemid_info
				register_function "kolproxycore_enumerate_state" kolproxycore_enumerate_state
				register_function "kolproxycore_async_submit_page" async_submit_page_func_DEBUG
				register_function "kolproxycore_sleep" $ \_ref l -> do
					delay <- peekJustDouble l 1
					threadDelay $ round $ delay * 1000000
					return 0

		--Lua.registerhsfunction lstate "kolproxy_debug_print" (\x -> lua_log_line setupref ("kolproxy_debug_print: " ++ x) (return ()))

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
					putStrLn $ "lualoadcall error!"
					top <- Lua.gettop l
					putStrLn $ "lualoadcall error, top = " ++ (show top)
					err <- Lua.tostring l (-1)
					putStrLn $ "lualoadcall error: " ++ err
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
	canread <- canReadState ref
	-- TODO: Wrap in MVar instead of IORef?
	insts <- readIORef (luaInstances_ $ sessionData $ ref)
	case Data.Map.lookup (canread, filename, level) insts of
		-- Using MVar to only run one piece of code in an instance at a time, e.g. sequence one processor after another serially.
		-- TODO: Use a Chan to enforce order?
		Just existingmv -> withMVar existingmv runcodebit
		_ -> do
			either_l_setup <- do
				putStrLn $ "DEBUG: making lua instance: " ++ show (canread, filename, level)
				log_time_interval ref ("setup lua instance: " ++ filename ++ "|" ++ show level) $ setup_lua_instance level filename ref
			case either_l_setup of
				Right l_setup -> do
					mv_l <- newMVar l_setup
					let newinsts = Data.Map.insert (canread, filename, level) mv_l insts
					writeIORef (luaInstances_ $ sessionData $ ref) newinsts
					withMVar mv_l runcodebit
				Left err -> return $ Left err

run_lua_code_ ref l dosetvars filename = do
	log_time_interval ref "prepare for lua code" $ do
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

run_lua_code level filename ref dosetvars = do
	get_cached_lua_instance_for_code level filename ref $ \l -> run_lua_code_ ref l dosetvars filename

setvars vars text allparams l = do
	push_table_contents_string_string l vars
	Lua.pushstring l "text"
	Lua.pushbytestring l text
	Lua.settable l (-3)
	-- TODO: store as table
	Lua.pushstring l "raw_input_params"
	Lua.pushstring l (show (allparams :: [(String, String)]))
	Lua.settable l (-3)
	return ()

runProcessScript ref uri effuri pagetext allparams = do
	let vars = [("path", uriPath effuri), ("query", uriQuery effuri), ("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
	rets <- run_lua_code PROCESS "scripts/kolproxy-internal/process-page.lua" ref (setvars vars pagetext allparams)
	return $ case rets of
		Right [Just t] -> Right $ t
		Right xs -> Left ("Lua process call error, return values = " ++ (show xs), "")
		Left err -> Left err

--runChatScript ref uri effuri pagetext allparams = do
--	let vars = [("path", uriPath effuri), ("query", uriQuery effuri), ("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
--	rets <- run_lua_code CHAT "scripts/kolproxy-internal/chat.lua" ref (setvars vars pagetext allparams)
--	return $ case rets of
--		Right [Just t] -> Right $ t
--		Right xs -> Left ("Lua chat call error, return values = " ++ (show xs), "")
--		Left err -> Left err

--runSendChatScript ref uri allparams = do
--	let vars = [("requestpath", uriPath uri), ("requestquery", uriQuery uri)]
--	rets <- run_lua_code CHAT "scripts/kolproxy-internal/sendchat.lua" ref (setvars vars (Data.ByteString.Char8.pack "") allparams)
--	return $ case rets of
--		Right [Just t] -> Right $ t
--		Right xs -> Left ("Lua chat call error, return values = " ++ (show xs), "")
--		Left err -> Left err

runChatRequestScript ref uri allparams = do
	let vars = [("request_path", uriPath uri), ("request_query", uriQuery uri)]
	rets <- run_lua_code CHAT "scripts/kolproxy-internal/chat-request.lua" ref (setvars vars (Data.ByteString.Char8.pack "") allparams)
	return $ case rets of
		Right [Just t, Just u, Just ct] -> Right (t, mkuri $ Data.ByteString.Char8.unpack $ u, Data.ByteString.Char8.unpack ct)
		Right xs -> Left (Data.ByteString.Char8.pack $ ("Lua chat request call error, return values = " ++ (show xs)), "")
		Left (err, extra) -> Left (Data.ByteString.Char8.pack $ err, extra)

runBrowserRequestScript ref uri allparams reqtype = do
	let vars = [("request_path", uriPath uri), ("request_query", uriQuery uri), ("request_type", reqtype)]
	rets <- run_lua_code BROWSERREQUEST "scripts/kolproxy-internal/browser-request.lua" ref (setvars vars (Data.ByteString.Char8.pack "") allparams)
	return $ case rets of
		Right [Just t, Just u, Just ct] -> Right (t, mkuri $ Data.ByteString.Char8.unpack $ u, Data.ByteString.Char8.unpack ct)
		Right xs -> Left (Data.ByteString.Char8.pack $ ("Lua browser request call error, return values = " ++ (show xs)), "")
		Left (err, extra) -> Left (Data.ByteString.Char8.pack $ err, extra)

runBotScript baseref filename = do
	run_lua_code BOTSCRIPT filename baseref (setvars [] (Data.ByteString.Char8.pack "") [])
	return ()

runLogParsingScript filename = do
	log_db <- Database.SQLite3Modded.open filename
	code <- readFile "scripts/kolproxy-internal/parselog.lua"
	ret <- runLogScript log_db code
	Database.SQLite3Modded.close log_db
	return ret

runLogScript log_db code = do
	lstate <- Lua.newstate
	Lua.openlibs lstate

	let register_function name f = do
		push_function lstate f name
		Lua.setglobal lstate name

	register_function "fromjson" fromjson
	register_function "tojson" tojson

	register_function "get_log_lines" $ \l -> do
		s <- Database.SQLite3Modded.prepare log_db "SELECT idx FROM pageloads;"
		Lua.newtable l
		let process tblidx = do
			sr <- Database.SQLite3Modded.step s
			case sr of
				Database.SQLite3Modded.Row -> do
					[Database.SQLite3Modded.SQLInteger lidx] <- Database.SQLite3Modded.columns s
					Lua.pushinteger l tblidx
					Lua.pushinteger l (fromIntegral lidx)
					Lua.settable l (-3)
					process (tblidx + 1)
				Database.SQLite3Modded.Done -> return ()
		process 1
		Database.SQLite3Modded.finalize s
		return 1

	register_function "get_line_text" $ \l -> do
		whichidx <- peekJustInteger l 1
		whichfield <- peekJustString l 2
		s <- Database.SQLite3Modded.prepare log_db ("SELECT " ++ whichfield ++ " FROM pageloads WHERE idx == " ++ (show whichidx) ++ ";") -- TODO: make safe?
		sr <- Database.SQLite3Modded.step s
		retvals <- case sr of
			Database.SQLite3Modded.Row -> do
				row <- Database.SQLite3Modded.columns s
				case row of
					[Database.SQLite3Modded.SQLText str] -> do
						Lua.pushbytestring l str
						return 1
					_ -> return 0
			Database.SQLite3Modded.Done -> return 0
		Database.SQLite3Modded.finalize s
		return retvals

	register_function "get_line_allparams" $ \l -> do
		whichidx <- peekJustInteger l 1
		s <- Database.SQLite3Modded.prepare log_db ("SELECT requestedurl, retrievedurl, parameters FROM pageloads WHERE idx == " ++ (show whichidx) ++ ";")
		sr <- Database.SQLite3Modded.step s
		retvals <- case sr of
			Database.SQLite3Modded.Row -> do
				[Database.SQLite3Modded.SQLText requestedurlstr, Database.SQLite3Modded.SQLText retrievedurlstr, paramthing] <- Database.SQLite3Modded.columns s
-- 				putStrLn $ "params: " ++ show paramthing
				let Just uri = parseURIReference $ Data.ByteString.Char8.unpack $ requestedurlstr
				let Just effuri = parseURIReference $ Data.ByteString.Char8.unpack $ retrievedurlstr
				let params = case paramthing of
					Database.SQLite3Modded.SQLText parametersstr -> read_as $ Data.ByteString.Char8.unpack $ parametersstr
					_ -> Nothing
				let allparams = concat $ catMaybes $ [decodeUrlParams uri, decodeUrlParams effuri, params]
-- 				putStrLn $ "allparams: " ++ show allparams
				push_table_contents_string_string l allparams
				return 1
			Database.SQLite3Modded.Done -> return 0
		Database.SQLite3Modded.finalize s
		return retvals

	loginforef <- newIORef Nothing
	register_function "set_log_info" $ \l -> do
		playerid <- peekJustInteger l 1
		charname <- peekJustString l 2
		ascnum <- peekJustInteger l 3
		secretkey <- peekJustString l 4
		writeIORef loginforef $ Just (playerid, charname, ascnum, get_md5 $ secretkey)
		return 0

	register_function "get_url_path" $ \l -> do
		urlstr <- peekJustString l 1
		case parseURIReference urlstr of
			Just uri -> do
				Lua.pushstring l (uriPath uri)
				return 1
			_ -> return 0

	utc_arbitrary_epoch <- zonedTimeToUTC <$> getZonedTime

	register_function "time_to_number" $ \l -> do
		timestr <- peekJustString l 1
		let utc_time = zonedTimeToUTC $ read timestr
		let diff = diffUTCTime utc_time utc_arbitrary_epoch
		Lua.pushnumber l $ realToFrac diff
		return 1

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
			putStrLn $ "lualog error!"
			top <- Lua.gettop l
			putStrLn $ "lualog error, top = " ++ (show top)
			err <- Lua.tostring l (-1)
			putStrLn $ "lualog error: " ++ err
			Lua.getglobal l "kolproxy_debug_traceback" -- load traceback on stack=3
			traceback <- Lua.tostring l 3
			putStrLn $ "traceback: " ++ traceback
			return ""

	Lua.close l

	maybeloginfo <- readIORef loginforef

	return (jsonstr, maybeloginfo)

run_datafile_parsers = do
	code <- readFile "scripts/kolproxy-internal/update-datafiles.lua"

	lstate <- Lua.newstate
	Lua.openlibs lstate

	let register_function name f = do
		push_function lstate f name
		Lua.setglobal lstate name

	register_function "fromjson" fromjson
	register_function "tojson" tojson

	register_function "simplexmldata_to_table" $ \l -> do
		xmlstr <- peekJustString l 1
		let Just xmldoc = parseXMLDoc xmlstr
		push_simplexmldata l xmldoc
		return 1

	-- TODO: handle return value?
	void $ Lua.safeloadstring lstate "local dtb = debug.traceback; return function(e) kolproxy_debug_traceback = dtb(\"\", 2) return e end"
	-- TODO: handle return value?
	void $ Lua.pcall lstate 0 1 0 -- put error handling function on stack=1

	c <- Lua.safeloadstring lstate code
	-- TODO: Check that it loads correctly?

	when (c /= 0) $ do
		putStrLn $ "luadatafileload error!"
		top <- Lua.gettop lstate
		putStrLn $ "luadatafileload error, top = " ++ (show top)
		err <- Lua.tostring lstate (-1)
		putStrLn $ "luadatafileload error: " ++ err

	retcode <- Lua.pcall lstate 0 Lua.multret 1 -- returns on stack=2+
	case retcode of
		0 -> Lua.close lstate
		_ -> do
			putStrLn $ "luadatafile error!"
			top <- Lua.gettop lstate
			putStrLn $ "luadatafile error, top = " ++ (show top)
			err <- Lua.tostring lstate (-1)
			putStrLn $ "luadatafile error: " ++ err
			Lua.getglobal lstate "kolproxy_debug_traceback" -- load traceback on stack=3
			traceback <- Lua.tostring lstate 3
			putStrLn $ "traceback: " ++ traceback
			Lua.close lstate
			throwIO $ InternalError err
