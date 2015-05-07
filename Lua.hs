{-# LANGUAGE ForeignFunctionInterface, BangPatterns #-}

module Lua where

import Prelude
import Logging
import LuaLibrary
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
import Data.Maybe
import Data.Time.Clock
import Data.Time.LocalTime
import Network.URI
import Text.JSON
import Text.XML.Light
import qualified Data.ByteString.Char8
import qualified Data.Map
import qualified Database.SQLite3Modded
import qualified Scripting.LuaModded as Lua

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
			-- TODO: This fails when not logged in. Maybe not throw exception?
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
				register_function "set_state" set_state
				register_function "get_state" get_state
				register_function "reset_fight_state" $ \ref _l -> do
					uglyhack_resetFightState ref
					return 0
				register_function "get_api_itemid_info" get_api_itemid_info
			BROWSERREQUEST -> do
				register_function "set_state" set_state
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

get_lua_instance_for_code level filename ref = do
	-- TODO! CLOSE LUA INSTANCES!!
	canread <- canReadState ref
	modifyMVar (luaInstances_ $ sessionData $ ref) $ \insts -> do
		case Data.Map.lookup (canread, filename, level) insts of
			Just existingmv -> return (insts, Right existingmv)
			_ -> do
				either_l_setup <- do
					putDebugStrLn $ "Making lua instance: " ++ show (canread, filename, level)
					log_time_interval ref ("setup lua instance: " ++ filename ++ "|" ++ show level) $ setup_lua_instance level filename ref
				case either_l_setup of
					Right l_setup -> do
						mv_l <- newMVar l_setup
						let newinsts = Data.Map.insert (canread, filename, level) mv_l insts
						return (newinsts, Right mv_l)
					Left err -> return (insts, Left err)

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
	runmv <- get_lua_instance_for_code level filename ref
	case runmv of
		Right mv -> withMVar mv $ \l -> run_lua_code_ ref l dosetvars filename
		Left err -> return $ Left err

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
