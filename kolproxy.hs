import Prelude
import qualified Handlers
import qualified HardcodedGameStuff
import qualified Lua
import qualified PlatformLowlevel
import qualified Server
import qualified KoL.Http
import qualified KoL.HttpLowlevel
import KoL.Util
import KoL.UtilTypes
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.Maybe
import Data.Time
import Network.URI
import qualified System.Directory (doesFileExist, createDirectoryIfMissing)
import qualified System.Environment (getArgs)
import qualified System.IO
import qualified System.Random
import qualified Data.Map


make_globalref = do
	environment_settings <- do
		let checkenv defaultvalue setting = do
			value <- getEnvironmentSetting setting
			case value of
				Just "1" -> return True
				Just "0" -> return False
				_ -> return defaultvalue
		listenpublic <- checkenv False "KOLPROXY_LISTEN_PUBLIC"
		actionbarstate <- checkenv True "KOLPROXY_STORE_STATE_IN_ACTIONBAR"
		localstate <- checkenv (not listenpublic) "KOLPROXY_STORE_STATE_LOCALLY"
		launchbrowser <- checkenv (not listenpublic) "KOLPROXY_LAUNCH_BROWSER"
		return $ EnvironmentSettings {
			store_state_in_actionbar_ = actionbarstate,
			store_state_locally_ = localstate,
			store_ascension_logs_ = not listenpublic,
			store_chat_logs_ = not listenpublic,
			store_info_logs_ = not listenpublic,
			listen_public_ = listenpublic,
			launch_browser_ = launchbrowser
		}
	let openlog filename = do
		h <- System.IO.openFile ("logs/info/" ++ filename) System.IO.AppendMode
		System.IO.hSetBuffering h System.IO.LineBuffering
		return h
	indentref <- newIORef 0
	blockluaref <- newIORef False
	hfiles <- openlog "files-downloaded.txt"
	htiming <- openlog "timing-log.txt"
	hhttp <- openlog "http-log.txt"
	shutdown_secret <- get_md5 <$> show <$> (System.Random.randomIO :: IO Integer)
	chatopendb <- create_db "sqlite3 chatlog" "chat-log.sqlite3"
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS public(mid INTEGER PRIMARY KEY NOT NULL, time INTEGER NOT NULL, channel TEXT NOT NULL, playerid INTEGER NOT NULL, msg TEXT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS private(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, time INTEGER NOT NULL, playerid INTEGER NOT NULL, msg TEXT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS other(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, time INTEGER NOT NULL, msg TEXT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS unrecognized(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, rawjson TEXT NOT NULL);" []
	do_db_query_ chatopendb "CREATE TABLE IF NOT EXISTS oldchat(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, text TEXT NOT NULL);" []
	chatlogchan <- newChan
	forkIO_ "kps:chatlogchan" $ forever $ do
		chanaction <- readChan chatlogchan
		chanaction chatopendb
	use_slow_http_ref <- newIORef =<< do
		envhttp10 <- getEnvironmentSetting "KOLPROXY_USE_HTTP10"
		case envhttp10 of
			Just "1" -> return True
			Just "0" -> return False
			_ -> KoL.HttpLowlevel.check_for_http10
	tnow <- getCurrentTime
	last_datafile_update_ref <- newIORef $ addUTCTime (fromInteger (-60000)) tnow
	return GlobalRefStuff {
		logindents_ = indentref,
		blocking_lua_scripting_ = blockluaref,
		h_files_downloaded_ = hfiles,
		h_timing_log_ = htiming,
		h_http_log_ = hhttp,
		shutdown_secret_ = shutdown_secret,
		doChatLogAction_ = \action -> writeChan chatlogchan action,
		use_slow_http_ref_ = use_slow_http_ref,
		lastDatafileUpdate_ = last_datafile_update_ref,
		environment_settings_ = environment_settings
	}

kolproxy_setup_refstuff = do
	(logchan, dropping_logchan) <- do
		dropping_logchan <- newChan
		forkIO_ "kps:droplogchan" $ forever $ readChan dropping_logchan
		logchan <- newChan
		forkIO_ "kps:logchan" $ forever $ debug_do "writelog" $ join $ readChan $ logchan
		return (logchan, dropping_logchan)
	globalref <- make_globalref
	return (logchan, dropping_logchan, globalref)

runProxyServer portnum = do
	(logchan, dropping_logchan, globalref) <- kolproxy_setup_refstuff
	-- TODO: get rid of fakeref here!
	let _fake_other = OtherRefStuff { connection_ = undefined, sessionData_ = undefined }
	let logref = LogRefStuff { logchan_ = logchan, solid_logchan_ = logchan }
	let _log_fakeref = RefType { logstuff_ = logref, processPage_ = undefined, otherstuff_ = _fake_other, stateValid_ = undefined, globalstuff_ = globalref }

	(mvsequence, mvchat) <- Server.setupHandlerChannels _log_fakeref

	sessionmastermv <- newMVar Data.Map.empty
	dblogmapmv <- newMVar Data.Map.empty
	let dblogstuff filename action = do
		chan <- modifyMVar dblogmapmv $ \m -> do
			case Data.Map.lookup filename m of
				Just x -> return (m, x)
				Nothing -> do
					putStrLn $ "DB: Opening log database: " ++ filename
					opendb <- create_db "sqlite3 log" filename
					do_db_query_ opendb "CREATE TABLE IF NOT EXISTS pageloads(idx INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, time TEXT NOT NULL, statusbefore TEXT, statusafter TEXT, statebefore TEXT, stateafter TEXT, sessionid TEXT NOT NULL, requestedurl TEXT NOT NULL, parameters TEXT, retrievedurl TEXT, pagetext TEXT);" []
					x <- newChan
					forkIO_ "kps:dblogchan" $ forever $ do
						chanaction <- readChan x
						chanaction opendb
					return (Data.Map.insert filename x m, x)
		writeChan chan action
	sock <- KoL.HttpLowlevel.mklistensocket (listen_public _log_fakeref) portnum
	forkIO_ "kps:updatedatafiles" $ HardcodedGameStuff.update_data_files
	when (launch_browser_ $ environment_settings_ $ globalref) $ forkIO_ "kps:launchkolproxy" $ PlatformLowlevel.platform_launch portnum
	let runLoop f = do
		cont <- f
		when cont $ runLoop f
	debug_do "do_loop" $ runLoop $ Server.handleConnection globalref (sessionmastermv, dblogstuff) sock (portnum, mvsequence, mvchat, logchan, dropping_logchan)
	putStrLn "Shutting down."

runKolproxy = (do
	have_process_page <- System.Directory.doesFileExist "scripts/kolproxy-internal/process-page.lua"
	if have_process_page
		then do
			putInfoStrLn $ "Starting..."
			System.Directory.createDirectoryIfMissing True "cache"
			System.Directory.createDirectoryIfMissing True "cache/data"
			System.Directory.createDirectoryIfMissing True "cache/files"
			System.Directory.createDirectoryIfMissing True "logs"
			System.Directory.createDirectoryIfMissing True "logs/chat"
			System.Directory.createDirectoryIfMissing True "logs/scripts"
			System.Directory.createDirectoryIfMissing True "logs/info"
			System.Directory.createDirectoryIfMissing True "logs/parsed"
			System.Directory.createDirectoryIfMissing True "logs/api"
			System.Directory.createDirectoryIfMissing True "scripts/custom-autoload"
		else do
			putWarningStrLn $ "Trying to start without required files in the \"scripts\" directory."
			putWarningStrLn $ "  Did you unzip the files correctly?"
			-- TODO: give error message in browser
	portenv <- getEnvironmentSetting "KOLPROXY_PORT"
	let portnum = case portenv of
		Just x -> fromJust $ read_as x :: Integer
		Nothing -> 18481
	runProxyServer portnum) `catch` (\e -> putDebugStrLn ("runKolproxy exception: " ++ show (e :: Control.Exception.SomeException)))

main = PlatformLowlevel.platform_init $ do
	System.IO.hSetBuffering System.IO.stdout System.IO.LineBuffering
	args <- System.Environment.getArgs
	case args of
		["--runbotscript", botscriptfilename] -> runbot botscriptfilename
		_ -> runKolproxy
	putInfoStrLn $ "Done! (main finished)"
	return ()

runbot filename = do
	(logchan, dropping_logchan, globalref) <- kolproxy_setup_refstuff

	let login_useragent = kolproxy_version_string ++ " (" ++ PlatformLowlevel.platform_name ++ ")" ++ " BotScript/0.1 (" ++ filename ++ ")"
	let login_host = fromJust $ parseURI $ "http://www.kingdomofloathing.com/"

	sc <- Server.make_sessionconn globalref "http://www.kingdomofloathing.com/" (error "dblogstuff")

	Just username <- getEnvironmentSetting "KOLPROXY_BOTSCRIPT_USERNAME"
	Just passwordmd5hash <- getEnvironmentSetting "KOLPROXY_BOTSCRIPT_PASSWORDMD5HASH"

	cookie <- KoL.Http.login (login_useragent, login_host) username passwordmd5hash

	let ref = RefType {
		logstuff_ = LogRefStuff { logchan_ = dropping_logchan, solid_logchan_ = logchan },
		processPage_ = Handlers.doProcessPageChat,
		otherstuff_ = OtherRefStuff {
			connection_ = ConnectionType {
				cookie_ = cookie,
				useragent_ = login_useragent,
				hostUri_ = login_host,
				lastRetrieve_ = sequenceLastRetrieve_ sc,
				connLogSymbol_ = "b",
				getconn_ = sequenceConnection_ sc
			},
			sessionData_ = sessConnData_ sc
		},
		stateValid_ = False,
		globalstuff_ = globalref
	}

	Lua.runBotScript ref filename
