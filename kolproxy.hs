import Prelude
import qualified Handlers
import qualified Lua
import qualified PlatformLowlevel
import qualified Server
import qualified KoL.Http
import KoL.Util
import KoL.UtilTypes
import Control.Exception
import Data.Maybe
import Network.URI
import System.Directory (doesFileExist, createDirectoryIfMissing)
import System.Environment (getArgs)
import System.IO

runKolproxy = (do
	have_process_page <- doesFileExist "scripts/kolproxy-internal/process-page.lua"
	if have_process_page
		then do
			putInfoStrLn $ "Starting..."
			createDirectoryIfMissing True "cache"
			createDirectoryIfMissing True "cache/data"
			createDirectoryIfMissing True "cache/files"
			createDirectoryIfMissing True "logs"
			createDirectoryIfMissing True "logs/chat"
			createDirectoryIfMissing True "logs/scripts"
			createDirectoryIfMissing True "logs/info"
			createDirectoryIfMissing True "logs/parsed"
			createDirectoryIfMissing True "logs/api"
			createDirectoryIfMissing True "scripts/custom-autoload"
		else do
			putWarningStrLn $ "Trying to start without required files in the \"scripts\" directory."
			putWarningStrLn $ "  Did you unzip the files correctly?"
			-- TODO: give error message in browser
	portenv <- getEnvironmentSetting "KOLPROXY_PORT"
	let portnum = case portenv of
		Just x -> fromJust $ read_as x :: Integer
		Nothing -> 18481
	Server.runProxyServer Handlers.kolProxyHandler Handlers.kolProxyHandlerChat portnum) `catch` (\e -> putDebugStrLn ("runKolproxy exception: " ++ show (e :: Control.Exception.SomeException)))

main = PlatformLowlevel.platform_init $ do
	hSetBuffering stdout LineBuffering
	args <- getArgs
	case args of
		["--runbotscript", botscriptfilename] -> runbot botscriptfilename
		_ -> runKolproxy
	putInfoStrLn $ "Done! (main finished)"
	return ()

runbot filename = do
	(logchan, dropping_logchan, globalref) <- Server.kolproxy_setup_refstuff

	let login_useragent = kolproxy_version_string ++ " (" ++ PlatformLowlevel.platform_name ++ ")" ++ " BotScript/0.1 (" ++ filename ++ ")"
	let login_host = fromJust $ parseURI $ "http://www.kingdomofloathing.com/"

	sc <- Server.make_sessionconn globalref "http://www.kingdomofloathing.com/" (error "dblogstuff")

	Just username <- getEnvironmentSetting "KOLPROXY_BOTSCRIPT_USERNAME"
	Just passwordmd5hash <- getEnvironmentSetting "KOLPROXY_BOTSCRIPT_PASSWORDMD5HASH"

	cookie <- KoL.Http.login (login_useragent, login_host) username passwordmd5hash

	let baseref = RefType {
		logstuff_ = LogRefStuff { logchan_ = dropping_logchan, solid_logchan_ = logchan },
		processingstuff_ = error "processing",
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

	let okref = baseref {
		processingstuff_ = ProcessingRefStuff {
			processPage_ = Handlers.doProcessPageChat,
			getstatusfunc_ = Handlers.statusfunc
		},
		stateValid_ = False
	}

	Lua.runBotScript okref filename
