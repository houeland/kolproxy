module Kolproxy.Http (getHTTPFileData, postHTTPFileData, parseUriServerBugWorkaround, internalKolHttpsRequest, internalKolRequest, load_api_status_to_mv_mkapixf, load_api_status_to_mv, internalKolRequest_pipelining, login) where

-- TODO: Merge with HttpLowlevel or at least restructure

import Prelude

import Kolproxy.HttpLowlevel
import Kolproxy.Logging
import Kolproxy.Util
import Kolproxy.UtilTypes

import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.List (intercalate)
import Data.Maybe
import Data.Time
import Data.Time.Clock.POSIX
import Network.URI
import Text.JSON
import qualified Data.ByteString.Char8
--import qualified Network.HTTP

getHTTPFileData url = do
	(_, body, _, _) <- doHTTPreq (mkreq True kolproxy_version_string Nothing (mkuri url) Nothing True)
	return $ Data.ByteString.Char8.unpack body

postHTTPFileData url params = do
	(_, body, _, _) <- doHTTPreq (mkreq True kolproxy_version_string Nothing (mkuri url) (Just params) True)
	return $ Data.ByteString.Char8.unpack body

parseUriServerBugWorkaround rawuri = do
	let remapper x
		| (x == ' ') = '+'
		| otherwise = x
	case parseURIReference rawuri of
		Just z -> return $ Just z
		_ -> do -- Workaround for broken KoL redirect, e.g. trade counter-offer doesn't urlencode()
			let newx = map remapper rawuri
			putInfoStrLn $ "KOL SERVER BUG: parse failure, invalid URL received from server: " ++ (show rawuri) ++ " (shout at Jick or CDMoyer)"
			putInfoStrLn $ "  using " ++ (show newx) ++ " instead"
			return $ parseURIReference newx

-- TODO: combine these three
internalKolHttpsRequest url params cu _noredirect = do
	let (cucookie, useragent, host, _getconn) = cu
	let reqabsuri = url `relativeTo` host
	(effuri, body, hdrs, code) <- doHTTPSreq (mkreq True useragent cucookie reqabsuri params True)
	return $ PageResult { pageBody = body, pageUri = effuri, pageHeaders = hdrs, pageHttpCode = code }

internalKolRequest url params cu noredirect = do
	let (cucookie, useragent, host, getconn) = cu
	let reqabsuri = url `relativeTo` host
-- 	putDebugStrLn $ "single-req " ++ show absuri
	(effuri, body, hdrs, code) <- doHTTPreq (mkreq True useragent cucookie reqabsuri params True)

	if noredirect || not (code >= 300 && code < 400)
		then return $ PageResult { pageBody = body, pageUri = effuri, pageHeaders = hdrs, pageHttpCode = code }
		else do
			putWarningStrLn $ "Redirecting from internalKolRequest"
			case lookup "Location" hdrs of
				Just lochdruri -> do
					cookie <- case lookup "Set-Cookie" hdrs of
						Just hdrstr -> do
							let cookie = takeWhile (/= ';') hdrstr
							putDebugStrLn $ "set-cookie_single: " ++ cookie
							return $ Just cookie
						Nothing -> return cucookie
					putDebugStrLn $ "  singlereq gotpage: " ++ show effuri
					putDebugStrLn $ "    hdrs: " ++ show hdrs
					putDebugStrLn $ "    constructed cookie: " ++ show cookie
					let addheaders = filter (\(x, _) -> x == "Set-Cookie") hdrs
					case parseURI lochdruri of
						Nothing -> do
							Just to <- parseUriServerBugWorkaround lochdruri
-- 							putDebugStrLn $ "--> redirected " ++ (show url) ++ " -> " ++ (show to)
							page_result <- internalKolRequest to Nothing (cookie, useragent, host, getconn) noredirect
							return $ page_result { pageHeaders = addheaders ++ (pageHeaders page_result) }
						Just to -> do
-- 							putDebugStrLn $ "==> redirected " ++ (show url) ++ " -> " ++ (show to)
							page_result <- internalKolRequest to Nothing (cookie, useragent, host, getconn) noredirect
							return $ page_result { pageHeaders = addheaders ++ (pageHeaders page_result) }
				_ -> throwIO $ InternalError $ "Error parsing redirect: No location header"

load_api_status_to_mv_mkapixf ref = do
	try $ internalKolRequest_pipelining ref (mkuri $ "/api.php?what=status,inventory&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json") Nothing False

load_api_status_to_mv ref mv apixf = do
	apires <- try $ do
		let xf = case apixf of
			Right (xf, _) -> xf
			Left err -> throwIO (err :: SomeException)
		(xraw, xuri) <- do
			pr <- xf
			return (pageBody pr, pageUri pr)
		jsobj <- case uriPath xuri of
			"/api.php" -> do
				let x = Data.ByteString.Char8.unpack $ xraw
				case decodeStrict x of
					Ok jsobj -> return jsobj
					Error err -> do
						t <- getPOSIXTime
						writeFile ("logs/api/invalid-api-result-" ++ show t ++ ".json") x
						throwIO $ ApiPageException err
			"/login.php" -> throwIO $ NotLoggedInException
			"/maint.php" -> throwIO $ NotLoggedInException
			"/afterlife.php" -> throwIO $ InValhallaException
			_ -> do
				putWarningStrLn $ "got uri: " ++ (show xuri) ++ " when raw-getting API"
				throwIO $ UrlMismatchException "/api.php" xuri
		return jsobj
	writeIORef (latestRawJson_ $ sessionData $ ref) (Just apires)
	case apires of
		Right js -> writeIORef (latestValidJson_ $ sessionData $ ref) (Just js)
		_ -> return ()
	putMVar mv apires

internalKolRequest_pipelining ref uri params should_invalidate_cache = privateKolRequest_pipelining ref uri params should_invalidate_cache []

privateKolRequest_pipelining ref uri params should_invalidate_cache extraHdrs = do
--	putDebugStrLn $ "pipeline-req " ++ show uri
	let host = hostUri_ $ connection $ ref

	curjsonmv <- if should_invalidate_cache
		then do
			newmv <- newEmptyMVar
			writeIORef (jsonStatusPageMVarRef_ $ sessionData $ ref) newmv
			return newmv
		else readIORef (jsonStatusPageMVarRef_ $ sessionData $ ref)
	retrieval_start <- getCurrentTime
	slowconn <- readIORef $ use_slow_http_ref_ $ globalstuff_ $ ref

	let new_cookie = case filter (\(a, _b) -> a == "Set-Cookie") extraHdrs of
		[] -> Nothing
		(x:xs) -> Just $ intercalate "; " (map ((takeWhile (/= ';')) . snd) (x:xs)) -- TODO: Make readable
	let old_cookie = cookie_ $ connection $ ref

	let cookie = case cookielist of
			[] -> Nothing
			(x:xs) -> Just $ intercalate "; " (x:xs)
		where
			cookielist = catMaybes [Just "appserver=www11", old_cookie, new_cookie]

--	putDebugStrLn $ "pipeline cookie: " ++ (show cookie)
	let (reqabsuri, r) = mkreq slowconn (useragent_ $ connection $ ref) cookie (uri `relativeTo` host) params True
--	putDebugStrLn $ "pipeline r request: " ++ (show r)
--	putDebugStrLn $ "split uri: " ++ (show (Network.HTTP.splitRequestURI (uri `relativeTo` host)))
	mv_x <- newEmptyMVar
	writeChan (getconn_ $ connection $ ref) (reqabsuri, r, mv_x, ref)

	when should_invalidate_cache $ do
		apixf <- load_api_status_to_mv_mkapixf ref
		forkIO_ "HTTP:load_api_status_to_mv" $ load_api_status_to_mv ref curjsonmv apixf

	mv_val <- newEmptyMVar
	forkIO_ "HTTP:mv_val" $ do
		putMVar mv_val =<< (try $ do
			page_result <- do
				x <- (readMVar mv_x) `catch` (\e -> do
					-- TODO: when does this happen?
					-- TODO: make it not happen
					putWarningStrLn $ "httpreq read exception for " ++ (uriPath reqabsuri) ++ ": " ++ (show (e :: SomeException))
					throwIO e)
--				putDebugStrLn $ "pipe result x: " ++ (show x)
				case x of
					Right (retabsuri, body, hdrs, code, _) -> return $ PageResult { pageBody = body, pageUri = retabsuri, pageHeaders = hdrs, pageHttpCode = code }
					Left e -> throwIO $ HttpRequestException reqabsuri e
			retrieval_end <- getCurrentTime
			prev_retrieval_end <- readIORef (lastRetrieve_ $ connection $ ref)
			writeIORef (lastRetrieve_ $ connection $ ref) retrieval_end
			let showurl = case params of
				Nothing -> show uri
				Just p -> show uri ++ " " ++ show p
			log_retrieval ref showurl (max retrieval_start prev_retrieval_end) retrieval_end

			let code = pageHttpCode page_result
			if (code >= 300 && code < 400)
				then do
					let hdrs = pageHeaders page_result
					let Just lochdruri = lookup "Location" hdrs
					Just touri <- case parseURI lochdruri of
						Nothing -> parseUriServerBugWorkaround lochdruri
						Just to -> return $ Just to
					let addheaders = filter (\(x, _y) -> (x == "Set-Cookie" || x == "Location")) hdrs
					-- TODO: respect new cookie header here?
--					putDebugStrLn $ "--> local redirected " ++ (show reqabsuri) ++ " -> " ++ (show touri)
--					putDebugStrLn $ "--> addheaders: " ++ (show addheaders)
					(y, mvy) <- privateKolRequest_pipelining ref touri Nothing should_invalidate_cache addheaders
					new_page_result <- y
					themv <- mvy
					return (new_page_result { pageHeaders = addheaders ++ (pageHeaders new_page_result) }, themv)
				else return (page_result, curjsonmv))

	let xf = do
		x <- readMVar mv_val
		case x of
			Right (rx, _) -> return rx
			Left e -> throwIO (e :: SomeException)

	let mvf = do
		x <- readMVar mv_val
		case x of
			Right (_, mv) -> return mv
			Left e -> throwIO (e :: SomeException)

	return (xf, mvf)

login (login_useragent, login_host) name pass = do
	text <- pageBody <$> internalKolRequest (mkuri "/") Nothing (Nothing, login_useragent, login_host, Nothing) False
	challenge <- case matchGroups "<input type=hidden name=challenge value=\"([0-9a-f]*)\">" (Data.ByteString.Char8.unpack text) of
		[[challenge]] -> return challenge
		_ -> throwIO $ NetworkError "No challenge found on login page. Down for maintenance?"
	let response = get_md5 (pass ++ ":" ++ challenge)
	let p_sensitive = [("loginname", name), ("challenge", challenge), ("response", response), ("secure", "1"), ("loggingin", "Yup.")]
	allhdrs <- pageHeaders <$> internalKolRequest (mkuri "/login.php") (Just p_sensitive) (Nothing, login_useragent, login_host, Nothing) True
	let hdrs = filter (\(x, _y) -> (x == "Set-Cookie" || x == "Location")) allhdrs
	let new_cookie = case filter (\(a, _b) -> a == "Set-Cookie") hdrs of
		[] -> Nothing
		(x:xs) -> Just $ intercalate "; " (map ((takeWhile (/= ';')) . snd) (x:xs)) -- TODO: Make readable
	return new_cookie
