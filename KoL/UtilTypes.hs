{-# LANGUAGE DeriveDataTypeable #-}

module KoL.UtilTypes where

import Prelude hiding (read, catch)
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.Time
import Data.Typeable
import Network.URI
import System.IO
import qualified Data.ByteString
import qualified Data.Map
import qualified Database.SQLite3
import qualified Network.HTTP
import qualified Scripting.LuaModded

-- TODO: make this a record with named fields instead of a tuple?
type DiscerningStateIdentifier = (String, Integer, Integer, String) -- name, ascension, rollover, sessid

-- TODO: make this a record with named fields instead of a tuple?
type StateType = (Data.Map.Map String String, Data.Map.Map String String, Data.Map.Map String String, Data.Map.Map String String, Data.Map.Map String String)

data LuaScriptType = WHENEVER | PROCESS | PRINTER | AUTOMATE | INTERCEPT
	deriving (Show, Ord, Eq)

-- This entire thing should be locked up into DiscerningStateIdentifier. log/state actions don't really belong.
data SessionDataType = SessionDataType {
	jsonStatusPageMVarRef_ :: IORef (MVar (Maybe String)),
	latestRawJsonText_ :: IORef (Maybe String),
	itemData_ :: IORef (Maybe (Int -> Maybe [(String, String)], String -> Maybe [(String, String)])),
	doDbLogAction_ :: RefType -> (Database.SQLite3.Database -> IO ()) -> IO (),
	doStateAction_ :: RefType -> (Database.SQLite3.Database -> IO ()) -> IO (),
	stateData_ :: IORef (Maybe (DiscerningStateIdentifier, StateType)),
	luaInstances_ :: IORef (Data.Map.Map (String, LuaScriptType) (MVar Scripting.LuaModded.LuaState)),
	lastStoredState_ :: IORef (Maybe String)
}

type ConnChanActionType = MVar (Either SomeException (URI, Data.ByteString.ByteString, [(String, String)], Network.HTTP.ResponseCode, Network.HTTP.Response Data.ByteString.ByteString))
type ConnChanType = Chan (URI, Network.HTTP.Request Data.ByteString.ByteString, ConnChanActionType, RefType)

data ServerSessionType = ServerSessionType {
	wheneverConnection_ :: ConnChanType,
	sequenceConnection_ :: ConnChanType,
	wheneverLastRetrieve_  :: IORef UTCTime,
	sequenceLastRetrieve_  :: IORef UTCTime,
	sessConnData_ :: SessionDataType
}

-- TODO: connLogSymbol should be in the log structure chan
data ConnectionType = ConnectionType {
	cookie_ :: Maybe String,
	useragent_ :: String,
	hostUri_ :: URI,
	lastRetrieve_ :: IORef UTCTime,
	connLogSymbol_ :: String,
	getconn_ :: ConnChanType
}

data LogRefStuff = LogRefStuff {
	logchan_ :: Chan (IO ()),
	solid_logchan_ :: Chan (IO ())
}

data ProcessingRefStuff = ProcessingRefStuff {
	processPage_ :: RefType -> URI -> Maybe [(String, String)] -> IO (IO (Either (Data.ByteString.ByteString, URI, [(String, String)]) (Data.ByteString.ByteString, URI, [(String, String)]))),
	rawRetrievePage_ :: RefType -> URI -> Maybe [(String, String)] -> IO (IO (Data.ByteString.ByteString, URI, [(String, String)]), IO (MVar (Maybe String))),
	nochangeRawRetrievePageFunc_ :: RefType -> URI -> Maybe [(String, String)] -> Bool -> IO (IO (Data.ByteString.ByteString, URI, [(String, String)]), IO (MVar (Maybe String))),
	getstatusfunc_ :: RefType -> IO (IO String)
}

data GlobalRefStuff = GlobalRefStuff {
	logindents_ :: IORef Integer,
	blocking_lua_scripting_ :: IORef Bool,
	h_files_downloaded_ :: Handle,
	h_timing_log_ :: Handle,
	h_lua_log_ :: Handle,
	h_http_log_ :: Handle,
	shutdown_secret_ :: String,
	shutdown_ref_ :: IORef Bool
}

data OtherRefStuff = OtherRefStuff {
	connection_ :: ConnectionType,
	sessionData_ :: SessionDataType
}

data RefType = RefType {
	logstuff_ :: LogRefStuff,
	processingstuff_ :: ProcessingRefStuff,
	otherstuff_ :: OtherRefStuff,
	stateValid_ :: Bool,
	globalstuff_ :: GlobalRefStuff
}

getlogchan ref = logchan_ $ logstuff_ $ ref
processPage ref = processPage_ $ processingstuff_ $ ref
rawRetrievePage ref = rawRetrievePage_ $ processingstuff_ $ ref
nochangeRawRetrievePageFunc ref = nochangeRawRetrievePageFunc_ $ processingstuff_ $ ref
getstatusfunc ref = (getstatusfunc_ $ processingstuff_ $ ref) ref
readstatus ref = join $ getstatusfunc ref
refreshstatus ref = void $ join $ getstatusfunc ref

connection ref = connection_ $ otherstuff_ $ ref
state ref = if stateValid_ ref
	then stateData_ $ sessionData $ ref
	else throw $ InternalError $ "Invalid state while trying to read"
sessionData ref = sessionData_ $ otherstuff_ $ ref
logindents ref = logindents_ $ globalstuff_ $ ref
blocking_lua_scripting ref = blocking_lua_scripting_ $ globalstuff_ $ ref

doDbLogAction ref action = (doDbLogAction_ $ sessionData $ ref) ref action
doStateAction ref action = (doStateAction_ $ sessionData $ ref) ref action

-- TODO: Use a better name. Split into different types?
data ConnectionException = UrlMismatchException String URI | NotLoggedInException | ApiPageException String | HttpRequestException URI SomeException | StateException
	deriving (Typeable)

instance Exception ConnectionException

instance Show ConnectionException where
	show (UrlMismatchException urlstr goturi) = "Error loading URL: " ++ urlstr ++ ", received: " ++ (show goturi)
	show (NotLoggedInException) = "Not logged in"
	show (ApiPageException pagestr) = "Error loading API, page returned: " ++ pagestr
	show (HttpRequestException uri err) = "Network connection error while loading " ++ uriPath uri ++ " (exception: " ++ show err ++ ")"
	show (StateException) = "Error loading state"

data InternalError = InternalError String
	deriving (Typeable)

instance Exception InternalError

instance Show InternalError where
	show (InternalError str) = "Internal error: " ++ str
