module HardcodedGameStuff where

import Prelude hiding (read, catch)
import PlatformLowlevel
import KoL.Http
import KoL.Util
import KoL.UtilTypes
import Control.Applicative
import Control.Exception
import Control.Monad
import Data.Char
import Data.List
import Data.Maybe
import Data.Time.Clock
import System.Directory
import Text.Regex.TDFA
import qualified Data.ByteString.Char8

doWriteDataFile filename filedata = best_effort_atomic_file_write filename "." filedata

get_monsterdata [] _ = []
get_monsterdata (x:xs) ys =
	case x of
		"<monsterdata>" -> get_monsterdata xs [x]
		"</monsterdata>" -> [concat $ ys ++ [x]] ++ (get_monsterdata xs [])
		_ -> get_monsterdata xs (ys ++ [x])

get_current_kolproxy_version = return $ kolproxy_version_number :: IO String

get_latest_kolproxy_version = do
	version <- (filter (not . isSpace)) <$> getHTTPFileData kolproxy_version_string (mkuri "http://www.houeland.com/kolproxy/latest-version")
	if (length version <= 100) && (version =~ "^[0-9A-Za-z.-]+$")
		then return version
		else return "?"

load_data_file url backupurl = ((do
	t <- getHTTPFileData kolproxy_version_string $ mkuri url
	return t) `catch` (\e -> do
		putStrLn $ "load_data_file exception: " ++ (show (e::SomeException))
		getHTTPFileData kolproxy_version_string $ mkuri backupurl))

raw_load_mafia_file url = do
	load_data_file ("http://kolmafia.svn.sourceforge.net/viewvc/kolmafia/src/data/" ++ url) ("http://www.houeland.com/kolproxy/files/data-mirror/" ++ url)

load_mafia_file url func = do
	text <- raw_load_mafia_file url
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
				Nothing -> putStrLn $ "Downloading data files..."
				Just x -> putStrLn $ "Updating data files... [" ++ show x ++ " old]"
			writeFile "cache/data/last_attempt" (show (kolproxy_version_string, t))
			(do
				init_data_files
				writeFile "cache/data/last_update" (show (kolproxy_version_string, t))
				putStrLn $ "Data files updated.") `catch` (\e -> do
					putStrLn $ "Failed to update data files: " ++ (show (e :: SomeException))
					writeFile "cache/data/last_update" "failed"
					return ())

init_data_files = do
	do
		itemdescs <- load_mafia_file "items.txt" (\x -> case x of
			id_str:name:_ -> case read_as id_str of
				Just itemid -> Just (itemid :: Integer, name)
				_ -> Nothing
			_ -> Nothing)
		fullness <- load_mafia_file "fullness.txt" (\x -> case x of
			name:fullness_str:_ -> case read_as fullness_str of
				Just fullness -> Just (map toLower name, fullness :: Integer)
				_ -> Nothing
			_ -> Nothing)
		inebriety <- load_mafia_file "inebriety.txt" (\x -> case x of
			name:inebriety_str:_ -> case read_as inebriety_str of
				Just inebriety -> Just (map toLower name, inebriety :: Integer)
				_ -> Nothing
			_ -> Nothing)
		spleenhit <- load_mafia_file "spleenhit.txt" (\x -> case x of
			name:spleenhit_str:_ -> case read_as spleenhit_str of
				Just spleenhit -> Just (map toLower name, spleenhit :: Integer)
				_ -> Nothing
			_ -> Nothing)
		let items = map (\(itemid, name) -> [("name", name), ("id", show itemid)] ++
			(case lookup (map toLower name) fullness of
					Just f -> [("fullness", show f)]
					_ -> []) ++
			(case lookup (map toLower name) inebriety of
					Just f -> [("drunkenness", show f)]
					_ -> []) ++
			(case lookup (map toLower name) spleenhit of
					Just f -> [("spleen", show f)]
					_ -> [])) itemdescs
		if (isJust $ find (\x -> lookup "name" x == Just "Orcish Frat House blueprints") items) && (isJust $ find (\x -> lookup "name" x == Just "Boris's Helm") items)
			then doWriteDataFile "cache/data/items" (show items)
			else do
				putStrLn $ "  ---   "
				putStrLn $ "Error parsing item names!"
				putStrLn $ "  ---   "
				putStrLn $ "  " ++ (show (length items)) ++ " items, data:"
				putStrLn $ "      " ++ (show items)
				putStrLn $ "  ---   "
				putStrLn $ "Error parsing item names!"
				putStrLn $ "  ---   "

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
		semirares <- do
			javatext <- load_data_file "http://kolmafia.svn.sourceforge.net/viewvc/kolmafia/src/net/sourceforge/kolmafia/KoLmafia.java" "http://www.houeland.com/kolproxy/files/data-mirror/KoLmafia.java"
			let xs = lines javatext
			let fx x = case matchGroups "{ *\"(.*)\", *EncounterTypes.SEMIRARE *}" x of
				[] -> Nothing
				[[y]] -> Just y
				_ -> throw $ InternalError $ "Error parsing semirare data"
			return $ mapMaybe fx xs
		if "All The Rave" `elem` semirares
			then doWriteDataFile "cache/data/semirares" (show semirares)
			else putStrLn $ "Error parsing semirares!"

	do
		choicespoilers <- do
			jstext <- load_data_file "http://userscripts.org/scripts/source/68727.user.js" "http://www.houeland.com/kolproxy/files/data-mirror/68727.user.js"
			let choices = takeWhile (\x -> not (x =~ "};")) $ dropWhile (\x -> not (x =~ "var advOptions")) $ (lines jstext)
			let fx y = case matchGroups "([0-9]+):(\\[.*\\])," y of
				[] -> Nothing
				[[choicenum, spoilers]] -> case read_as spoilers of
					Just (_:xs) -> Just [("choice number", choicenum), ("spoilers", show $ (xs :: [String]))]
					_ -> Nothing
				_ -> throw $ InternalError $ "Error parsing choice spoiler data"
			return $ mapMaybe fx choices
		doWriteDataFile "cache/data/choice-spoilers" (show choicespoilers)

	do
		pulverizegroups <- do
			jstext <- load_data_file "http://userscripts.org/scripts/source/67792.user.js" "http://www.houeland.com/kolproxy/files/data-mirror/67792.user.js"
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

	do
		faxbotlist <- do
			xmltext <- load_data_file "http://www.hogsofdestiny.com/faxbot/faxbot.xml" "http://www.houeland.com/kolproxy/files/data-mirror/faxbot.xml"
			let monsterdatas = get_monsterdata (lines xmltext) []
			let extract_data md =
					[("name", name), ("command", command), ("category", category), ("description", description)]
				where
					[[name]] = matchGroups "<actual_name>([^<]*)</actual_name>" md
					[[command]] = matchGroups "<command>([^<]*)</command>" md
					[[category]] = matchGroups "<category>([^<]*)</category>" md
					[[description]] = matchGroups "<name>([^<]*)</name>" md
			return $ map extract_data monsterdatas
		doWriteDataFile "cache/data/faxbot-monsterlist" (show faxbotlist)

	raw_load_mafia_file "modifiers.txt" >>= doWriteDataFile "cache/files/modifiers.txt"
	raw_load_mafia_file "equipment.txt" >>= doWriteDataFile "cache/files/equipment.txt"
	raw_load_mafia_file "outfits.txt" >>= doWriteDataFile "cache/files/outfits.txt"
	raw_load_mafia_file "familiars.txt" >>= doWriteDataFile "cache/files/familiars.txt"

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
