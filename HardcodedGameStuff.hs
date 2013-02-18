module HardcodedGameStuff where

import Prelude hiding (read, catch)
import Lua
import PlatformLowlevel
import KoL.Http
import KoL.Util
import KoL.UtilTypes
import Control.Exception
import Control.Monad
import Data.Maybe
import Data.Time.Clock
import System.Directory
import Text.Regex.TDFA
import qualified Data.ByteString.Char8

doWriteDataFile filename filedata = best_effort_atomic_file_write filename "." filedata

load_data_file url = getHTTPFileData kolproxy_version_string $ mkuri url

load_mafia_file url func = do
	text <- load_data_file ("http://kolmafia.svn.sourceforge.net/viewvc/kolmafia/src/data/" ++ url)
	let filtered = filter (\x -> case x of
		"" -> False
		'#':_ -> False
		_ -> True) (tail $ lines text)
	let split_line x = map head $ matchGroups "([^\t]*)\t" (x ++ "\t")
	let mapped = mapMaybe func $ map split_line filtered
	return mapped

-- TODO: gradual slowing
update_data_files = do
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
	do
		mix_concoctions <- load_mafia_file "concoctions.txt" (\x -> case x of
			name:"MIX":ingredients -> Just (name, [("type", "cocktailcrafting"), ("ingredients", show $ zip ([1..]::[Integer]) ingredients)])
			name:"ACOCK":ingredients -> Just (name, [("type", "cocktailcrafting"), ("ingredients", show $ zip ([1..]::[Integer]) ingredients)])
			name:"SCOCK":ingredients -> Just (name, [("type", "cocktailcrafting"), ("ingredients", show $ zip ([1..]::[Integer]) ingredients)])
			name:"BSTILL":[source] -> Just (name, [("type", "still"), ("ingredient", show source)])
			name:"MSTILL":[source] -> Just (name, [("type", "still"), ("ingredient", show source)])
			_ -> Nothing)
		doWriteDataFile "cache/data/recipes" (show mix_concoctions)

	do
		pulverizegroups <- do
			jstext <- load_data_file "http://userscripts.org/scripts/source/67792.user.js"
			let groupslines = takeWhile (\x -> not (x =~ "}\\);")) $ dropWhile (\x -> not (x =~ "var groupList")) $ lines jstext
			let groups = map head $ matchGroups "([0-9]+:\\[[0-9,]+\\])" $ concat groupslines
			let [groupnamesline] = filter (\x -> x =~ "var groupNames") $ lines jstext
			let groupnames = map head $ matchGroups "\"([^\"]+)\"" groupnamesline
			let worthlesslines = takeWhile (\x -> not (x =~ "}\\);")) $ dropWhile (\x -> not (x =~ "var worthless")) $ lines jstext
			let worthless = map head $ matchGroups "([0-9]+):1" $ concat worthlesslines
			let items = map (\x -> case matchGroups "([0-9]+):\\[([0-9]+)" x of
				[[ids, gs]] -> (a :: Integer, b :: Int)
					where
						(Just a, Just b) = (read_as ids, read_as gs)
				_ -> throw $ InternalError $ "Error parsing pulverize data") groups
			let regrouped = map (\(gx, y) -> (y, (mapMaybe (\(a,b) -> if b == gx
				then Just a
				else Nothing) items) ++
				if y == "Worthless"
					then map (\ix -> read_e ix :: Integer) worthless
					else [])) (zip [0..] groupnames)
			return regrouped
		doWriteDataFile "cache/data/pulverize-groups" (show pulverizegroups)

	let dldatafile x = do
		let [[basename]] = matchGroups ".*/([^/]+)$" x
		filedata <- load_data_file x
		doWriteDataFile ("cache/files/" ++ basename) filedata

	mapM_ (\x -> dldatafile ("http://svn.code.sf.net/p/kolmafia/code/src/data/" ++ x)) ["classskills.txt", "concoctions.txt", "equipment.txt", "familiars.txt", "foldgroups.txt", "fullness.txt", "inebriety.txt", "items.txt", "modifiers.txt", "monsters.txt", "npcstores.txt", "outfits.txt", "spleenhit.txt", "statuseffects.txt", "zapgroups.txt"]

	dldatafile "http://svn.code.sf.net/p/kolmafia/code/src/net/sourceforge/kolmafia/KoLmafia.java"

	dldatafile "http://www.hogsofdestiny.com/faxbot/faxbot.xml"

	dldatafile "http://userscripts.org/scripts/source/67792.user.js"
	dldatafile "http://userscripts.org/scripts/source/68727.user.js"

	dldatafile "http://www.houeland.com/kol/mallprices.json"
	dldatafile "http://www.houeland.com/kol/consumable-advgain.json"
	dldatafile "http://www.houeland.com/kol/zones.json"

	return ()

add_colored_message_to_page color msg pt =
	case matchGroups "^(.+)(<div style='overflow: auto'><center><table)(.+)(</body></html>)(.*)$" pt of
		[[pre, dv, mid, end, post]] ->
				pre ++ wrappedmsg ++ "<br>" ++ dv ++ mid ++ end ++ post
			where wrappedmsg = "<center><table width=95%><tr><td><pre style=\"color: " ++ color ++ "\">" ++ msg ++ "</pre></td></tr></table></center>"
		-- TODO: Add first in body if possible?
		_ -> "<pre style=\"color: " ++ color ++ "\">" ++ msg ++ "</pre>" ++ pt

add_error_message_to_page msg pt = Data.ByteString.Char8.pack $ add_colored_message_to_page "red" msg (Data.ByteString.Char8.unpack pt)

-- TODO: do in lua??
-- 			let inrunoption = case choice of
-- 				21 -> 2 -- not trapped in the wrong body
-- 				46 -> 3 -- fight vampire, maybe doubtful?
-- 				105 -> 1 -- gaze into mirror in bathroom
-- 				108 -> 4 -- walk away from craps
-- 				109 -> 1 -- fight hobo
-- 				110 -> 4 -- introduce them to avantgarde
-- 				113 -> 2 -- fight knob goblin chef
-- 				118 -> 2 -- don't do wounded guard quest
-- 				120 -> 4 -- ennui outta here
-- 				123 -> 2 -- raise your hands in hidden temple
-- 				177 -> 5 -- blackberry cobbler, leave
-- 				402 -> 2 -- don't hold a grudge in bathroom, gain myst
-- 				otherwise -> -1
-- 			let aftercoreoption = case choice of
-- 				9 -> 3 -- leave the wheel alone in the castle
-- 				10 -> 3 -- leave the wheel alone in the castle
-- 				11 -> 3 -- leave the wheel alone in the castle
-- 				12 -> 3 -- leave the wheel alone in the castle
-- 				21 -> -1 -- trapped in the wrong body?
-- 				26 -> 2 -- take the scorched path
-- 				28 -> 2 -- investigate the moist crater for spices
-- 				89 -> 2 -- fight TT knight in the gallery
-- 				90 -> 2 -- watch the dancers in ballroom
-- 				112 -> 2 -- no time for harold's bell
-- 				178 -> 2 -- blow popsicle stand in airship
-- 				182 -> 1 -- fight in the airship
-- 				207 -> 2 -- leave hot door alone in burnbarrel
-- 				213 -> 2 -- leave piping hot in burnbarrel
-- 				214 -> 1 -- kick stuff into the hole in the heap
-- 				216 -> 2 -- begone from the compostal service
-- 				otherwise -> inrunoption
-- 			-- TODO: 91 louvre needs special code
