module Kolproxy.LogParser (showLogs, compressLogs) where

import Prelude

import Kolproxy.Http
import Kolproxy.Lua
import Kolproxy.PlatformLowlevel
import Kolproxy.Util

import Control.Applicative
import Control.Concurrent
import Control.Monad
import Data.List
import Data.Maybe
import System.Directory
import System.IO
import qualified Codec.Compression.BZip
import qualified Codec.Compression.GZip
import qualified Data.ByteString
import qualified Data.ByteString.Base64
import qualified Data.ByteString.Char8
import qualified Data.ByteString.Lazy
import qualified Data.ByteString.Lazy.Char8
import qualified Data.ByteString.Lazy.Internal
import qualified Data.ByteString.UTF8

scan_through_database_lua_logparse filename basefilename = do
	(jsonlog, maybeloginfo) <- runLogParsingScript filename

	putStrLn $ show $ maybeloginfo
	case maybeloginfo of
		Just (playerid, name, ascnum, secretkey) -> do
			writeFile ("logs/parsed/parsed-log-" ++ basefilename ++ ".json") jsonlog
			let utf8bs = Data.ByteString.UTF8.fromString jsonlog
			let base64gzippedjsonlog = Data.ByteString.Char8.unpack $ Data.ByteString.Base64.encode $ Data.ByteString.concat $ Data.ByteString.Lazy.toChunks $ Codec.Compression.GZip.compress $ Data.ByteString.Lazy.fromChunks $ [utf8bs]
			ret <- postHTTPFileData "http://www.houeland.com/kolproxy/ascension-log" [("action", "store"), ("playerid", show playerid), ("secretkey", secretkey), ("charactername", name), ("ascensionnumber", show ascnum), ("base64gzippedjsonlog", base64gzippedjsonlog)]
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
			let list_parsed_link = "<a href=\"/kolproxy-automation-script?automation-script=view-ascension-logs&pwd=" ++ pwd ++ "\">View uploaded logs</a>"
			let pt = "<html><body>Click on a log to parse it. Parsing a log takes several minutes, and the format and features are still being developed.<br>" ++ list_parsed_link ++ "<table border=1>\n" ++ (concat rowtexts) ++ "</table></body></html>"
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
			decompressed <- Codec.Compression.BZip.decompress <$> yielding_bs_eval test_compressed
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
