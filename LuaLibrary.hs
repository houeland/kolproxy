{-# LANGUAGE ForeignFunctionInterface, BangPatterns #-}

module LuaLibrary where

import Prelude
import Logging
import State
import KoL.Http
import KoL.Util
import KoL.UtilTypes
import qualified KoL.Api
import Control.Applicative
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List
import Data.Maybe
import Network.HTTP.Base (urlEncodeVars)
import Network.URI
import System.IO.Error (isUserError, ioeGetErrorString)
import Text.JSON
import Text.XML.Light
import qualified Data.ByteString.Char8
import qualified Data.Map
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

set_state ref l = do
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
	writeStateToFile ("chat-" ++ charname ++ ".state") (show chatmap)
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
									let testurienc = (uriPath inputuri) ++ "?" ++ (urlEncodeVars p)
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
	-- TODO: Switch to putError if this is changed to not happen regularly (e.g. when not logged in)
	let f_final l2 = (catchJust (\e -> if isUserError e then Just e else Nothing)
		(f l2)
		(\e -> do
			putDebugStrLn $ "Lua.hs IOerror in " ++ identifier ++ ": " ++ ioeGetErrorString e
			Lua.pushstring l2 $ "Haskell exception in " ++ identifier ++ " (" ++ ioeGetErrorString e ++ ")"
			return (-1))) `catch` (\e -> do
				putDebugStrLn $ "Lua.hs error in " ++ identifier ++ ": " ++ (show e)
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
			-- TODO: combine decoding in make_href and submit_async
			case (stripPrefix "/" (uriPath inputuri), uriQuery inputuri) of
				(Just _, "") -> do
					href <- case params of
						Nothing -> return (show inputuri)
						Just p -> do
							let testurienc = (uriPath inputuri) ++ "?" ++ (urlEncodeVars p)
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
