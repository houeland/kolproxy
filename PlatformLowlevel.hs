{-# LANGUAGE CPP #-}

module PlatformLowlevel where

import Prelude
import KoL.Util
import Control.Applicative
import Control.Exception
import Control.Monad
import Network
import System.Directory
import System.IO
import System.Process
import qualified Codec.Compression.BZip
import qualified Data.ByteString.Lazy.Char8

#if defined(__windows__)

#define platform_windows
import qualified System.Win32.File (copyFile)
platform_name = "windows"
kolproxy_open_url_command = "start"
do_handle_signals = return ()
do_change_directory = return ()
do_copy_file old new = System.Win32.File.copyFile old new False

#elif defined(__macosx__)

#define platform_macosx
import System.Environment.FindBin
import System.Posix.Signals (installHandler, sigPIPE, Handler(Ignore))
platform_name = "macosx"
kolproxy_open_url_command = "open"
do_handle_signals = void $ installHandler sigPIPE Ignore Nothing
do_change_directory = do
	binp <- getProgPath
	setCurrentDirectory (binp ++ "/../Resources")
do_copy_file = copyFile

#else

#define platform_linux
import System.Posix.Signals (installHandler, sigPIPE, Handler(Ignore))
platform_name = "linux"
kolproxy_open_url_command = "xdg-open"
do_handle_signals = void $ installHandler sigPIPE Ignore Nothing
do_change_directory = return ()
do_copy_file = copyFile

#endif

platform_init x = do
	do_handle_signals
	do_change_directory
	withSocketsDo x

platform_launch portnum = void $ createProcess (shell $ kolproxy_open_url_command ++ " http://localhost:" ++ show portnum ++ "/")

-- TODO: Move to another file
best_effort_atomic_file_write path basedir filedata = do
	(fp, h) <- openBinaryTempFile basedir "temp-file.tmp"
	hSetEncoding h utf8
	hSetBinaryMode h True
	hPutStrLn h filedata
	hClose h
	(renameFile fp path) `catch` (\e -> do
		putWarningStrLn $ "File write error: " ++ show (e :: SomeException)
		putWarningStrLn $ "  Performing an unsafe non-atomic write instead..."
		writeFile path (filedata ++ "\n")
		removeFile fp)

copyLogFile path compressed = do
	let templogfilepath = "cache/files/temp-logparse-file.sqlite3"
	case compressed of
		True -> withBinaryFile templogfilepath WriteMode $ \handle_out -> do
			withBinaryFile path ReadMode $ \handle_in -> do
				Codec.Compression.BZip.decompress <$> Data.ByteString.Lazy.Char8.hGetContents handle_in >>= Data.ByteString.Lazy.Char8.hPut handle_out
		False -> do_copy_file path templogfilepath
	return templogfilepath
