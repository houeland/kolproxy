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
import qualified System.Directory (doesFileExist, createDirectoryIfMissing)
import qualified System.Environment (getArgs)
import qualified System.IO

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
	Server.runProxyServer Server.kolProxyHandler Server.kolProxyHandlerChat portnum) `catch` (\e -> putDebugStrLn ("runKolproxy exception: " ++ show (e :: Control.Exception.SomeException)))

main = PlatformLowlevel.platform_init $ do
	System.IO.hSetBuffering System.IO.stdout System.IO.LineBuffering
	args <- System.Environment.getArgs
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
