{-# LANGUAGE DeriveDataTypeable #-}

module KoL.UtilTypes where

import Prelude
import Control.Concurrent
import Control.Exception
import Data.IORef
import Data.Time
import Data.Typeable
import Network.URI
import Text.JSON
import System.IO
import qualified Data.ByteString
import qualified Data.Map
import qualified Database.SQLite3Modded
import qualified Network.HTTP
import qualified Scripting.LuaModded

-- Global state
--   Environment settings
--   Chat log
--   Info log
-- Session state
--   Ascension log
--   Request handler sequence
--   ascension/day/session Lua state
--   status/inventory cache

-- TODO: make this a record with named fields instead of a tuple?
type DiscerningStateIdentifier = (String, Integer, Integer, String) -- name, ascension, rollover, sessid

-- TODO: make this a record with named fields instead of a tuple?
type StateType = (Data.Map.Map String String, Data.Map.Map String String, Data.Map.Map String String, Data.Map.Map String String, Data.Map.Map String String)

data LuaScriptType = CHAT | PROCESS | BOTSCRIPT | BROWSERREQUEST
	deriving (Show, Ord, Eq)

-- This entire thing should be locked up into DiscerningStateIdentifier. log/state actions don't really belong.
data SessionDataType = SessionDataType {
	jsonStatusPageMVarRef_ :: IORef (MVar (Either SomeException (JSObject JSValue))),
	latestRawJson_ :: IORef (Maybe (Either SomeException (JSObject JSValue))),
	latestValidJson_ :: IORef (Maybe (JSObject JSValue)),
	doDbLogAction_ :: RefType -> (Database.SQLite3Modded.Database -> IO ()) -> IO (),
	stateData_ :: IORef (DiscerningStateIdentifier, StateType),
	luaInstances_ :: MVar (Data.Map.Map (Bool, String, LuaScriptType) (MVar Scripting.LuaModded.LuaState)),
	lastStoredState_ :: IORef (Maybe String),
	lastStoredTime_ :: IORef UTCTime,
	storedStateId_ :: IORef (Integer, Integer),
	cachedActionbar_ :: IORef (Maybe String)
}

type ConnChanActionType = (Either SomeException (URI, Data.ByteString.ByteString, [(String, String)], Integer, Network.HTTP.Response Data.ByteString.ByteString))
type ConnChanType = Chan (URI, Network.HTTP.Request Data.ByteString.ByteString, MVar ConnChanActionType, RefType)

-- TODO: pair connection and lastretrieve
data ServerSessionType = ServerSessionType {
	chatConnection_ :: ConnChanType,
	sequenceConnection_ :: ConnChanType,
	chatLastRetrieve_ :: IORef UTCTime,
	sequenceLastRetrieve_ :: IORef UTCTime,
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
	processPage_ :: RefType -> URI -> Maybe [(String, String)] -> IO (IO (Either (Data.ByteString.ByteString, URI, [(String, String)], Integer) (Data.ByteString.ByteString, URI, [(String, String)], Integer))),
	nochangeRawRetrievePageFunc_ :: RefType -> URI -> Maybe [(String, String)] -> Bool -> IO (IO (Data.ByteString.ByteString, URI, [(String, String)], Integer), IO (MVar (Either SomeException (JSObject JSValue)))),
	getstatusfunc_ :: RefType -> IO (IO (JSObject JSValue))
}

data EnvironmentSettings = EnvironmentSettings {
	store_state_in_actionbar_ :: Bool,
	store_state_locally_ :: Bool,
	store_ascension_logs_ :: Bool,
	store_chat_logs_ :: Bool,
	store_info_logs_ :: Bool,
	listen_public_ :: Bool,
	launch_browser_ :: Bool
}

data GlobalRefStuff = GlobalRefStuff {
	logindents_ :: IORef Integer,
	blocking_lua_scripting_ :: IORef Bool,
	h_files_downloaded_ :: Handle,
	h_timing_log_ :: Handle,
	h_lua_log_ :: Handle,
	h_http_log_ :: Handle,
	shutdown_secret_ :: String,
	use_slow_http_ref_ :: IORef Bool,
	lastDatafileUpdate_ :: IORef UTCTime,
	doChatLogAction_ :: (Database.SQLite3Modded.Database -> IO ()) -> IO (),
	environment_settings_ :: EnvironmentSettings
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
nochangeRawRetrievePageFunc ref = nochangeRawRetrievePageFunc_ $ processingstuff_ $ ref
getstatusfunc ref = (getstatusfunc_ $ processingstuff_ $ ref) ref

connection ref = connection_ $ otherstuff_ $ ref
state ref = if stateValid_ ref
	then stateData_ $ sessionData $ ref
	else throw $ InternalError $ "Invalid state while trying to read"
sessionData ref = sessionData_ $ otherstuff_ $ ref
logindents ref = logindents_ $ globalstuff_ $ ref
blocking_lua_scripting ref = blocking_lua_scripting_ $ globalstuff_ $ ref
listen_public ref = listen_public_ $ environment_settings_ $ globalstuff_ $ ref
store_state_in_actionbar ref = store_state_in_actionbar_ $ environment_settings_ $ globalstuff_ $ ref
store_state_locally ref = store_state_locally_ $ environment_settings_ $ globalstuff_ $ ref
store_ascension_logs ref = store_ascension_logs_ $ environment_settings_ $ globalstuff_ $ ref
store_chat_logs ref = store_chat_logs_ $ environment_settings_ $ globalstuff_ $ ref
store_info_logs ref = store_info_logs_ $ environment_settings_ $ globalstuff_ $ ref

doDbLogAction ref action = (doDbLogAction_ $ sessionData $ ref) ref action
doChatLogAction ref action = (doChatLogAction_ $ globalstuff_ $ ref) action
--doStateAction ref action = (doStateAction_ $ sessionData $ ref) ref action

data KolproxyException = UrlMismatchException String URI | NotLoggedInException | InValhallaException | ApiPageException String | HttpRequestException URI SomeException | StateException | InternalError String | LuaError String | NetworkError String
	deriving (Typeable)

instance Exception KolproxyException

instance Show KolproxyException where
	show (UrlMismatchException urlstr goturi) = "Error loading URL: " ++ urlstr ++ ", received: " ++ (show goturi)
	show (NotLoggedInException) = "Not logged in"
	show (InValhallaException) = "In valhalla"
	show (ApiPageException errstr) = "Error loading API: " ++ errstr
	show (HttpRequestException uri err) = "Network connection error while loading " ++ uriPath uri ++ " (exception: " ++ show err ++ ")"
	show (StateException) = "Error loading state"
	show (InternalError str) = "Internal error: " ++ str
	show (LuaError str) = "Lua error: " ++ str
	show (NetworkError str) = "Network error: " ++ str
