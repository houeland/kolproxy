module KoL.Api where

import Prelude
import KoL.Util
import KoL.UtilTypes
import Control.Applicative
import Control.Exception
import Control.Monad
import Network.CGI (formEncode)
import Network.URI
import Text.JSON
import qualified Data.ByteString.Char8

readlateststatus ref = join $ getstatusfunc ref

getCharStatusObj ref = do
	jscomb <- readlateststatus ref
	let Ok jsobj = valFromObj "status" jscomb
	return jsobj

getInventoryObj ref = do
	jscomb <- readlateststatus ref
	let Ok jsobj = valFromObj "inventory" jscomb
	return jsobj

getInventoryCounts ref = do
	jsobj <- getInventoryObj ref
	let strcounts = fromJSObject jsobj
	let get_value name = i
		where i = case valFromObj name jsobj of
			Ok oki -> oki
			_ -> read_e j
				where Ok j = valFromObj name jsobj
	let counts = map (\(x, _y) -> (read_e x :: Integer, (get_value x) :: Integer)) strcounts
	return counts

data ApiInfo = ApiInfo {
	charName :: String,
	playerId :: Integer,
	turnsplayed :: Integer,
	ascension :: Integer,
	daysthisrun :: Integer,
	pwd :: String
}

rawDecodeApiInfo jscomb = do
		ApiInfo { charName = getstr "name", playerId = getnum "playerid", turnsplayed = getnum "turnsplayed", ascension = getnum "ascensions" + 1, daysthisrun = getnum "daysthisrun", pwd = getstr "pwd" }
	where
		Ok jsobj = valFromObj "status" jscomb
		getstr what = case valFromObj what jsobj of
			Ok (JSString s) -> fromJSString s
			_ -> throw $ InternalError $ "Error parsing API text " ++ what
		getnum what = case valFromObj what jsobj of
			Ok (JSString s) -> jss where
				Just jss = read_as (fromJSString s)
			Ok (JSRational _ r) -> round r
			_ -> throw $ InternalError $ "Error parsing API number " ++ what

getApiInfo ref = rawDecodeApiInfo <$> readlateststatus ref

force_latest_status_parse ref = readlateststatus ref

-- TODO: Do this in Lua instead?
asyncGetItemInfoObj itemid ref = do
	f <- rawAsyncNochangeGetPageRawNoScripts ("/api.php?what=item&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json&id=" ++ show itemid) ref
	return $ do
		jsonobj <- Data.ByteString.Char8.unpack <$> f
		case decodeStrict jsonobj :: Result JSValue of
			Ok x -> return x
			Error err -> do
				putDebugStrLn $ "Item API returned:\n  ===\n\n" ++ jsonobj ++ "\n\n  ===\n\n"
				throwIO $ ApiPageException err



-- Not in server API! From old Info.hs

getPlayerId name ref = do
	ai <- getApiInfo ref
	text <- nochangeGetPageRawNoScripts ("/submitnewchat.php?" ++ (formEncode [("pwd", pwd ai), ("graf", "/whois " ++ name)])) ref
	return $ case matchGroups "<a target=mainpane href=\"showplayer.php\\?who=([0-9]+)\">" text of
		[[x]] -> Just y
			where
				Just y = read_as x :: Maybe Integer
		_ -> Nothing



-- Downloading utility methods. TODO: put these elsewhere

postPageRawNoScripts url params ref = do
	(body, goturi, _, _) <- join $ fst <$> (nochangeRawRetrievePageFunc ref) ref (mkuri url) (Just params) True
	if ((uriPath goturi) == (uriPath $ mkuri url))
		then return body
		else do
			if uriPath goturi == "/login.php" || uriPath goturi == "/maint.php"
				then throwIO $ NotLoggedInException
				else do
					putInfoStrLn $ "got uri: " ++ (show goturi) ++ " when raw-getting " ++ (url)
					throwIO $ UrlMismatchException url goturi

rawAsyncNochangeGetPageRawNoScripts url ref = do
	f <- fst <$> (nochangeRawRetrievePageFunc ref) ref (mkuri url) Nothing False
	return $ do
		(body, goturi, _, _) <- f
		if ((uriPath goturi) == (uriPath $ mkuri url))
			then return body
			else do
				if uriPath goturi == "/login.php" || uriPath goturi == "/maint.php"
					then throwIO $ NotLoggedInException
					else do
						putInfoStrLn $ "got uri: " ++ (show goturi) ++ " when raw-getting " ++ (url)
						throwIO $ UrlMismatchException url goturi

nochangeGetPageRawNoScripts url ref = Data.ByteString.Char8.unpack <$> (join $ rawAsyncNochangeGetPageRawNoScripts url ref)
