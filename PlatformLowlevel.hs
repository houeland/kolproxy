{-# LANGUAGE CPP #-}

module PlatformLowlevel where

import Prelude hiding (read, catch)
import Control.Applicative
import Control.Monad
import System.Directory
import System.IO
import System.Process
import qualified Codec.Compression.BZip
import qualified Data.ByteString.Lazy.Char8


#if defined(__windows__)
#define platform_windows
#elif defined(__macosx__)
#define platform_macosx
#else
#define platform_linux
#endif

#ifdef platform_linux
import System.Posix.Signals (installHandler, sigPIPE, Handler(Ignore))
platform_name = "linux"
platform_init :: IO () -> IO ()
platform_init x = do
	void $ installHandler sigPIPE Ignore Nothing
	x
platform_launch :: Integer -> IO ()
platform_launch portnum = void $ createProcess (shell $ "xdg-open http://localhost:" ++ show portnum ++ "/")
#endif

#ifdef platform_macosx
import System.Posix.Signals (installHandler, sigPIPE, Handler(Ignore))
import System.Environment.FindBin
platform_name = "macosx"
platform_init :: IO () -> IO ()
platform_init x = do
	void $ installHandler sigPIPE Ignore Nothing
	binp <- getProgPath
	setCurrentDirectory (binp ++ "/../Resources")
	x
platform_launch :: Integer -> IO ()
platform_launch portnum = void $ createProcess (shell $ "open http://localhost:" ++ show portnum ++ "/")
#endif

#ifdef platform_windows
import Network
import Control.Exception
import qualified System.Win32.File (copyFile)
platform_name = "windows"
platform_init :: IO () -> IO ()
platform_init = withSocketsDo
platform_launch :: Integer -> IO ()
platform_launch portnum = void $ createProcess (shell $ "start http://localhost:" ++ show portnum ++ "/")
#endif

#ifndef platform_windows
best_effort_atomic_file_write path basedir filedata = do
-- 	writeFile path filedata
	(fp, h) <- openTempFile basedir "temp-file.tmp"
	hPutStrLn h filedata
	hClose h
	renameFile fp path -- atomic move, on POSIX. Something could of course happen between closing and moving
#else
best_effort_atomic_file_write path basedir filedata = do
-- 	writeFile path filedata
	(fp, h) <- openTempFile basedir "temp-file.tmp"
	hPutStrLn h filedata
	hClose h
	(renameFile fp path) `catch` (\e -> do
		putStrLn $ "windows file write error: " ++ show (e :: SomeException)
		putStrLn $ "  perfoming an unsafe non-atomic write instead"
		writeFile path (filedata ++ "\n")
		removeFile fp)
#endif

copyLogFile path compressed = do
	let templogfilepath = "cache/files/temp-logparse-file.sqlite3"
	case compressed of
		True -> withBinaryFile templogfilepath WriteMode $ \handle_out -> do
			withBinaryFile path ReadMode $ \handle_in -> do
				Codec.Compression.BZip.decompress <$> Data.ByteString.Lazy.Char8.hGetContents handle_in >>= Data.ByteString.Lazy.Char8.hPut handle_out
#ifndef platform_windows
		False -> copyFile path templogfilepath
#else
		False -> System.Win32.File.copyFile path templogfilepath False
#endif
	return templogfilepath
