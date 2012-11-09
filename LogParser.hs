module LogParser (showLogs, compressLogs) where

import Prelude hiding (read, catch)
import Lua
import PlatformLowlevel
import KoL.Http
import KoL.Util
import Control.Concurrent
import Control.Monad
import Data.List
import Data.Maybe
import System.Directory
import System.IO
import qualified Codec.Compression.BZip
import qualified Codec.Compression.GZip
import qualified Data.ByteString.Lazy.Char8
import qualified Data.ByteString.Lazy.Internal
import qualified Database.SQLite3

scan_through_database_lua_logparse filename basefilename = do
	log_db <- Database.SQLite3.open filename
	(jsonlog, maybeloginfo) <- runLogParsingScript log_db
	Database.SQLite3.close log_db

	putStrLn $ show $ maybeloginfo
	case maybeloginfo of
		Just (playerid, name, ascnum, secretkey) -> do
			writeFile ("logs/parsed/parsed-log-" ++ basefilename ++ ".json") jsonlog
			let gzippedjsonlog = Data.ByteString.Lazy.Char8.unpack $ Codec.Compression.GZip.compress $ Data.ByteString.Lazy.Char8.pack $ jsonlog
			ret <- postHTTPFileData kolproxy_version_string (mkuri "http://www.houeland.com/kolproxy/ascension-log") [("action", "store"), ("playerid", show playerid), ("secretkey", secretkey), ("charactername", name), ("ascensionnumber", show ascnum), ("gzippedjsonlog", gzippedjsonlog)]
			putStrLn $ "ret: " ++ ret
			case matchGroups "logid: ([0-9a-z]{40})" ret of
				[[logid]] -> do
					let logurl = "http://www.houeland.com/kol/viewlog?logid=" ++ logid
					return $ "<html><body><p>Log uploaded to server with ID: <tt>" ++ logid ++ "</tt></p><p>Link to view log: <a href=\"" ++ logurl ++ "\">" ++ logurl ++ "</a></p></body></html>"
				_ -> return "??? Failed to upload parsed log ???"
		_ -> return "Log parsing error: No ascension turns found"

scan_through_database = scan_through_database_lua_logparse

yielding_bs_eval Data.ByteString.Lazy.Internal.Empty = return Data.ByteString.Lazy.Internal.Empty
yielding_bs_eval (Data.ByteString.Lazy.Internal.Chunk x y) = do
	threadDelay 100000 -- delay to allow other things to run
	yy <- yielding_bs_eval y
	return $ Data.ByteString.Lazy.Internal.Chunk x yy

showLogs fn pwd = do
	case fn of
		Just basefilename -> do
			bz2path <- getDirectoryPath "sqlite3 log" (basefilename ++ ".ascension-log.sqlite3.bz2")
			bz2exists <- doesFileExist bz2path
			htmltext <- case bz2exists of
				False -> do
					path <- getDirectoryPath "sqlite3 log" (basefilename ++ ".ascension-log.sqlite3")
					putStrLn $ "processing " ++ path
					templogfilepath <- copyLogFile path False
					putStrLn $ "  parsing log"
					scan_through_database templogfilepath basefilename
				True -> do
					putStrLn $ "processing compressed " ++ bz2path
					templogfilepath <- copyLogFile bz2path True
					putStrLn $ "  parsing log"
					scan_through_database templogfilepath basefilename
-- 			writeFile ("parsed-log-" ++ basefilename ++ ".html") htmltext
			putStrLn $ "log parsing done!"
			return htmltext
		_ -> do
			basedir <- getBaseDirectory "sqlite3 log"
			filenames <- getDirectoryContents basedir
			let describe x =
				case matchGroups "^(.+)-([0-9]+)(.ascension-log.sqlite3|.ascension-log.sqlite3.bz2)$" x of
					[[charname, ascnum, ".ascension-log.sqlite3"]] -> Just (charname, fromJust $ read_as ascnum :: Integer, False)
					[[charname, ascnum, ".ascension-log.sqlite3.bz2"]] -> Just (charname, fromJust $ read_as ascnum :: Integer, True)
					_ -> Nothing
			let ascs = sortBy (\(achar, aasc, _) (bchar, basc, _) -> compare (achar, (-aasc)) (bchar, (-basc))) $ mapMaybe describe filenames
			let desc_asc_link (charname, ascnum, compressed) = case compressed of
					True -> "<small>" ++ link ++ "</small>"
					False -> link
				where
					link = "<a href=\"custom-logs?which=" ++ (charname ++ "-" ++ show ascnum) ++ "&pwd=" ++ pwd ++ "\">" ++ (show ascnum) ++ "</a>"
			let group_to_row x = case x of
				[] -> ""
				(achar, _, _):_ -> "<tr><td>" ++ achar ++ "</td><td>" ++ (intercalate ", " (map desc_asc_link x)) ++ "</td></tr>\n"
			let grouped = groupBy (\(achar, _, _) (bchar, _, _) -> achar == bchar) ascs
			let rowtexts = map group_to_row grouped
			let pt = "<html><body>Click on a log to parse it. Parsing a log takes several minutes, and the format and features are still being developed.<table>\n" ++ (concat rowtexts) ++ "</table></body></html>"
			return pt

compressFile path = do
	let bz2path = path ++ ".bz2"
	bz2exists <- doesFileExist bz2path
	if bz2exists
		then putStrLn $ "Error: " ++ (show bz2path) ++ " already exists."
		else do
			putStrLn $ "INFO: compressing " ++ path
			contents <- Data.ByteString.Lazy.Char8.readFile path
			compressed_contents <- yielding_bs_eval $ Codec.Compression.BZip.compress contents
			h <- openFile bz2path WriteMode
			Data.ByteString.Lazy.Char8.hPut h compressed_contents
			hClose h
			putStrLn $ "INFO: compressed " ++ path

			test_uncompressed <- Data.ByteString.Lazy.Char8.readFile path
			test_compressed <- Data.ByteString.Lazy.Char8.readFile bz2path
			decompressed <- yielding_bs_eval test_compressed >>= return . Codec.Compression.BZip.decompress
			if test_uncompressed == decompressed
				then do
					putStrLn $ "INFO: compression ok, removing file " ++ path
					removeFile path
				else putStrLn $ "ERROR: compressed file is different from the original."

compressLogs charname asc = forM_ [1..(asc - 1)] $ \x -> do
	path <- getDirectoryPath "sqlite3 log" (charname ++ "-" ++ (show x) ++ ".ascension-log.sqlite3")
	exists <- doesFileExist path
-- 	putStrLn $ "check " ++ show (path, exists)
	when exists $ compressFile path
