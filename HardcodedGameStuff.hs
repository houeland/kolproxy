module HardcodedGameStuff where

import Prelude
import Lua
import PlatformLowlevel
import KoL.Http
import KoL.Util
import Control.Exception
import Control.Monad
import Data.Time.Clock
import System.Directory
import qualified Data.ByteString.Char8

update_data_files = do
	-- TODO: gradual slowing
	t <- getCurrentTime
	(should_refresh, difftime) <- do
		file_exists <- doesFileExist "cache/data/last_update"
		case file_exists of
			False -> return (True, Nothing)
			True -> do
				foo <- readFile "cache/data/last_update"
				lastupdate <- length foo `seq` return foo -- force file to be read before closing
				case read_as lastupdate of
					Just (x, y) -> do
						if (x == kolproxy_version_string) && (diffUTCTime t y < 24 * 60 * 60) -- less than 24 hours old
							then return (False, Just $ diffUTCTime t y)
							else return (True, Just $ diffUTCTime t y)
					_ -> return (True, Nothing)
-- 	putStrLn $ "data files: " ++ (show (should_refresh, difftime))
	when should_refresh $ do
		should_attempt <- do
			attempt_file_exists <- doesFileExist "cache/data/last_attempt"
			case attempt_file_exists of
				False -> return True
				True -> do
					foo <- readFile "cache/data/last_attempt"
					lastupdate <- length foo `seq` return foo -- force file to be read before closing
					case read_as lastupdate of
						Just (x, y) -> do
							if (x == kolproxy_version_string) && (diffUTCTime t y < 120 * 60) -- less than 120 minutes old
								then return False
								else return True
						_ -> return True
		when should_attempt $ do
			case difftime of
				Nothing -> putStrLn $ "INFO: Updating data files..."
				Just x -> putStrLn $ "INFO: Updating data files... [" ++ show x ++ " old]"
			writeFile "cache/data/last_attempt" (show (kolproxy_version_string, t))
			(do
				download_data_files
				putStrLn $ "  Parsing data files."
				run_datafile_parsers
				writeFile "cache/data/last_update" (show (kolproxy_version_string, t))
				putStrLn $ "  Data files updated.") `catch` (\e -> do
					putStrLn $ "WARNING: Failed to update data files: " ++ (show (e :: SomeException))
					writeFile "cache/data/last_update" "failed"
					return ())

download_data_files = do
	let dldatafile path basename = (do
		filedata <- getHTTPFileData $ path ++ basename
		best_effort_atomic_file_write ("cache/files/" ++ basename) "." filedata) `catch` (\e -> do
			putWarningStrLn $ "exception downloading datafile: " ++ basename ++ ": " ++ show (e :: SomeException)
			return ())


	let mafia_datafiles = ["adventures.txt", "classskills.txt", "coinmasters.txt", "concoctions.txt", "combats.txt", "encounters.txt", "equipment.txt", "familiars.txt", "foldgroups.txt", "fullness.txt", "inebriety.txt", "items.txt", "modifiers.txt", "monsters.txt", "npcstores.txt", "outfits.txt", "pulverize.txt", "spleenhit.txt", "statuseffects.txt", "zapgroups.txt"]

	forM_ mafia_datafiles $ \basename -> dldatafile "http://svn.code.sf.net/p/kolmafia/code/src/data/" basename

	dldatafile "http://www.hogsofdestiny.com/faxbot/" "faxbot.xml"

-- userscripts.org is down, scripts not yet available elsewhere(?)
--	dldatafile "http://userscripts.org/scripts/source/" "67792.user.js"
--	dldatafile "http://userscripts.org/scripts/source/" "68727.user.js"

	dldatafile "http://www.houeland.com/kol/" "mallprices.json"
	dldatafile "http://www.houeland.com/kol/" "consumable-advgain.json"

	return ()

add_colored_message_to_page color msg pt =
	case matchGroups "^(.+)(<div style='overflow: auto'><center><table)(.+)(</body></html>)(.*)$" pt of
		[[pre, dv, mid, end, post]] ->
				pre ++ wrappedmsg ++ "<br>" ++ dv ++ mid ++ end ++ post
			where wrappedmsg = "<center><table width=95%><tr><td><pre style=\"color: " ++ color ++ "\">" ++ msg ++ "</pre></td></tr></table></center>"
		-- TODO: Add first in body if possible?
		_ -> "<pre style=\"color: " ++ color ++ "\">" ++ msg ++ "</pre>" ++ pt

add_error_message_to_page msg pt = Data.ByteString.Char8.pack $ add_colored_message_to_page "red" msg (Data.ByteString.Char8.unpack pt)
