import Prelude

import Kolproxy.Util (putInfoStrLn)
import qualified Kolproxy.Setup

import qualified System.Environment (getArgs)
import qualified System.IO

main = Kolproxy.Setup.initializeThenDo $ do
	System.IO.hSetBuffering System.IO.stdout System.IO.LineBuffering
	args <- System.Environment.getArgs
	case args of
		["--runbotscript", botscriptfilename] -> Kolproxy.Setup.runbot botscriptfilename
		_ -> Kolproxy.Setup.runKolproxy
	putInfoStrLn $ "Done! (main finished)"
	return ()
