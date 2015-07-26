import Prelude
import qualified Setup
import KoL.Util
import qualified System.Environment (getArgs)
import qualified System.IO

main = Setup.initializeThenDo $ do
	System.IO.hSetBuffering System.IO.stdout System.IO.LineBuffering
	args <- System.Environment.getArgs
	case args of
		["--runbotscript", botscriptfilename] -> Setup.runbot botscriptfilename
		_ -> Setup.runKolproxy
	putInfoStrLn $ "Done! (main finished)"
	return ()
