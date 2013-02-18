module KoL.Http where

-- TODO: Merge with HttpLowlevel or at least restructure

import Prelude hiding (read, catch)
import Logging
import KoL.HttpLowlevel
import KoL.Util
import KoL.UtilTypes
import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Data.Maybe
import Data.Time
import Network.URI
import Text.JSON
import qualified Data.ByteString.Char8

getHTTPFileData useragent url = do
	(_, body, _, _) <- doHTTPreq (mkreq useragent Nothing url Nothing True)
	return $ Data.ByteString.Char8.unpack body

postHTTPFileData useragent url params = do
	(_, body, _, _) <- doHTTPreq (mkreq useragent Nothing url (Just params) True)
	return $ Data.ByteString.Char8.unpack body

parseUriServerBugWorkaround rawuri = do
	let remapper x
		| (x == ' ') = '+'
		| otherwise = x
	case parseURIReference rawuri of
		Just z -> return $ Just z
		_ -> do -- Workaround for broken KoL redirect, e.g. trade counter-offer doesn't urlencode()
			let newx = map remapper rawuri
			putStrLn $ "KOL SERVER BUG: parse failure, invalid URL received from server: " ++ (show rawuri) ++ " (shout at Jick or CDMoyer)"
			putStrLn $ "  using " ++ (show newx) ++ " instead"
			return $ parseURIReference newx

-- TODO: combine these three
internalKolHttpsRequest url params cu _noredirect = do
	let (cucookie, useragent, host, _getconn) = cu
	let Just reqabsuri = url `relativeTo` host
	(effuri, body, hdrs, _code) <- doHTTPSreq (mkreq useragent cucookie reqabsuri params True)
	let addheaders = filter (\(x, _y) -> x == "Set-Cookie") hdrs
	return (body, effuri, addheaders)

internalKolRequest url params cu noredirect = do
	let (cucookie, useragent, host, getconn) = cu
	let Just reqabsuri = url `relativeTo` host
-- 	putStrLn $ "DEBUG: single-req " ++ show absuri
	(effuri, body, hdrs, code) <- doHTTPreq (mkreq useragent cucookie reqabsuri params True)

	if noredirect
		then return (body, effuri, hdrs)
		else case code of
			(3, _, _) -> do
				-- TODO: does this happen?
				case lookup "Location" hdrs of
					Just lochdruri -> do
						cookie <- case lookup "Set-Cookie" hdrs of
							Just hdrstr -> do
								let cookie = takeWhile (/= ';') hdrstr
								putStrLn $ "set-cookie_single: " ++ cookie
								return $ Just cookie
							Nothing -> return cucookie

						putStrLn $ "  DEBUG singlereq gotpage: " ++ show effuri
						putStrLn $ "    hdrs: " ++ show hdrs
						putStrLn $ "    constructed cookie: " ++ show cookie
						let addheaders = filter (\(x, _) -> x == "Set-Cookie") hdrs
						case parseURI lochdruri of
							Nothing -> do
								Just to <- parseUriServerBugWorkaround lochdruri
-- 								putStrLn $ "==> redirected " ++ (show url) ++ " -> " ++ (show to)
								(text, effurl, headers) <- internalKolRequest to Nothing (cookie, useragent, host, getconn) noredirect
								return (text, effurl, addheaders ++ headers)
							Just to -> do
-- 								putStrLn $ "==> redirected " ++ (show url) ++ " -> " ++ (show to)
								(text, effurl, headers) <- internalKolRequest to Nothing (cookie, useragent, host, getconn) noredirect
								return (text, effurl, addheaders ++ headers)
					_ -> throwIO $ InternalError $ "Error parsing redirect: No location header"
			_ -> return (body, effuri, hdrs)

load_api_status_to_mv ref mv = do
	apires <- (try $ do
		(xf, _) <- internalKolRequest_pipelining ref (mkuri $ "/api.php?what=status,inventory&for=kolproxy+" ++ kolproxy_version_number ++ "+by+Eleron&format=json") Nothing False
		(xraw, xuri, _) <- xf
		jsobj <- case uriPath xuri of
			"/api.php" -> do
				let x = Data.ByteString.Char8.unpack $ xraw
				case decodeStrict x of
					Ok jsobj -> return jsobj
					Error err -> do
						writeFile "DEBUG-invalid-api-result.json" x
						throwIO $ ApiPageException err
			"/login.php" -> throwIO $ NotLoggedInException
			"/maint.php" -> throwIO $ NotLoggedInException
			"/afterlife.php" -> throwIO $ InValhallaException
			_ -> do
				putStrLn $ "WARNING: got uri: " ++ (show xuri) ++ " when raw-getting API"
				throwIO $ UrlMismatchException "/api.php" xuri
		return jsobj)
	writeIORef (latestRawJson_ $ sessionData $ ref) (Just apires)
	case apires of
		Right js -> writeIORef (latestValidJson_ $ sessionData $ ref) (Just js)
		_ -> return ()
	putMVar mv apires

internalKolRequest_pipelining ref uri params should_invalidate_cache = do
-- 	putStrLn $ "DEBUG: pipeline-req " ++ show uri
	let host = hostUri_ $ connection $ ref

	curjsonmv <- if should_invalidate_cache
		then do
			newmv <- newEmptyMVar
			writeIORef (jsonStatusPageMVarRef_ $ sessionData $ ref) newmv
			return newmv
		else readIORef (jsonStatusPageMVarRef_ $ sessionData $ ref)
	retrieval_start <- getCurrentTime
	let (reqabsuri, r) = mkreq (useragent_ $ connection $ ref) (cookie_ $ connection $ ref) (fromJust $ uri `relativeTo` host) params True
	mv_x <- newEmptyMVar
	writeChan (getconn_ $ connection $ ref) (reqabsuri, r, mv_x, ref)

	when should_invalidate_cache $ forkIO_ "HTTP:load_api_status_to_mv" $ load_api_status_to_mv ref curjsonmv

	mv_val <- newEmptyMVar
	forkIO_ "HTTP:mv_val" $ do
		putMVar mv_val =<< (try $ do
			(retabsuri, body, hdrs, code, _) <- do
				x <- (readMVar mv_x) `catch` (\e -> do
					-- TODO: when does this happen?
					-- TODO: make it not happen
					putStrLn $ "WARNING: httpreq read exception for " ++ (uriPath reqabsuri) ++ ": " ++ (show (e :: SomeException))
					throwIO e)
				case x of
					Right rx -> return rx
					Left e -> throwIO $ HttpRequestException reqabsuri e
			retrieval_end <- getCurrentTime
			prev_retrieval_end <- readIORef (lastRetrieve_ $ connection $ ref)
			writeIORef (lastRetrieve_ $ connection $ ref) retrieval_end
			let showurl = case params of
				Nothing -> show uri
				Just p -> show uri ++ " " ++ show p
			log_retrieval ref showurl (max retrieval_start prev_retrieval_end) retrieval_end

			case code of
				(3, _, _) -> do
					let Just lochdruri = lookup "Location" hdrs
					let addheaders = filter (\(x, _y) -> (x == "Set-Cookie" || x == "Location")) hdrs
					-- TODO: respect new cookie header here?
					case parseURI lochdruri of
						Nothing -> do
							Just to <- parseUriServerBugWorkaround lochdruri
-- 							putStrLn $ "DEBUG --> local redirected " ++ (show retabsuri) ++ " -> " ++ (show to)
							(y, mvy) <- internalKolRequest_pipelining ref to Nothing should_invalidate_cache
							(a, b, c) <- y
							themv <- mvy
							return ((a, b, addheaders ++ c), themv)
						Just to -> do
							-- TODO: does this happen?
							putStrLn $ "DEBUG ==> remote redirected " ++ (show retabsuri) ++ " => " ++ (show to)
							-- TODO: make new getconn and use pipelining
							(a, b, c) <- internalKolRequest to Nothing (cookie_ $ connection $ ref, useragent_ $ connection $ ref, host, Nothing) False
							return ((a, b, c), curjsonmv)
				_ -> return ((body, retabsuri, hdrs), curjsonmv))

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
