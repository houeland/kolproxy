{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}

module KoL.HttpLowlevel where

import Prelude
import Logging
import KoL.Util
import KoL.UtilTypes
import Control.Applicative
import Control.Concurrent
import Control.Exception
import Control.Monad
import Crypto.Random.AESCtr (makeSystem)
import Data.Char
import Data.Maybe
import Data.IORef
import Data.Time.Clock
import Network.BSD
import Network.BufferType
import Network.CGI (formEncode)
import Network.HTTP
import Network.Socket
import Network.Stream (ConnError(..), failWith, fmapE)
import qualified Network.TLS
import qualified Network.TLS.Extra
import Network.URI
import Numeric (readHex)
import System.IO
import qualified Data.ByteString
import qualified Data.ByteString.Char8
import qualified Data.ByteString.Lazy
import qualified Data.ByteString.Lazy.Char8
import qualified Network.HTTP.HandleStream

-- TODO: Split into a ModdedHttp part for the modified Network.HTTP stuff and another kolproxy part

doHTTPLOWLEVEL_DEBUG _ = return ()
-- doHTTPLOWLEVEL_DEBUG x = putStrLn $ "HTTPlow DEBUG: " ++ x
doHTTPLOWLEVEL_DEBUGexception _ = return ()
--doHTTPLOWLEVEL_DEBUGexception x = putStrLn $ "HTTPlow DEBUGexc: " ++ x

class ConnFunctionsBundle a b | a -> b where
	connGetBlock :: a -> Int -> IO b
	connGetLine :: a -> IO String
	connPut :: a -> String -> IO ()
	connFlush :: a -> IO ()
	connGetContents :: a -> IO b

instance ConnFunctionsBundle Handle Data.ByteString.ByteString where
	connGetBlock conn size = Data.ByteString.hGet conn size

	connGetLine conn = do
		x <- Data.ByteString.hGetLine conn
-- 		putDebugStrLn $ "connGetLine: " ++ (Data.ByteString.Char8.unpack x)
		return $ (Data.ByteString.Char8.unpack x) ++ "\n"

	connPut conn d = Data.ByteString.hPut conn (Data.ByteString.Char8.pack $ d)

	connFlush conn = hFlush conn

	connGetContents conn = Data.ByteString.hGetContents conn

data SslConn = SslConn {
	sslconn_c :: Network.TLS.TLSCtx,
	sslconn_sendBuffer :: [Data.ByteString.Lazy.ByteString],
	sslconn_recvBuffer :: Data.ByteString.ByteString
}

instance ConnFunctionsBundle (MVar SslConn) Data.ByteString.ByteString where
	connGetBlock mvconn size = modifyMVar mvconn $ \conn -> do
		let f prebuild want rb
			| (want == 0) = return (prebuild, rb)
			| (Data.ByteString.null rb) = Network.TLS.recvData (sslconn_c conn) >>= f prebuild want
			| otherwise = do
				let (n, rest) = Data.ByteString.splitAt want rb
				f (n:prebuild) (want - Data.ByteString.length n) rest
		(ret, rb) <- f [] (fromIntegral size) (sslconn_recvBuffer conn)
		let newconn = conn { sslconn_recvBuffer = rb }
		return (newconn, Data.ByteString.concat $ reverse $ ret)

	connGetLine mvconn = modifyMVar mvconn $ \conn -> do
		let f prebuild rb
			| (Data.ByteString.null rb) = Network.TLS.recvData (sslconn_c conn) >>= f prebuild
			| otherwise = do
				let (n, rest) = Data.ByteString.Char8.break (== '\n') rb
				if Data.ByteString.null rest
					then f (n:prebuild) rest
					else return ((n:prebuild), Data.ByteString.Char8.tail rest)
		(ret, rb) <- f [] (sslconn_recvBuffer conn)
		let newconn = conn { sslconn_recvBuffer = rb }
		return (newconn, Data.ByteString.Char8.unpack (Data.ByteString.concat $ reverse $ (Data.ByteString.Char8.pack "\n"):ret))

	connPut mvconn d = modifyMVar mvconn $ \conn -> do
		let oldbuff = sslconn_sendBuffer conn
		let newconn = conn { sslconn_sendBuffer = oldbuff ++ [Data.ByteString.Lazy.Char8.pack d] }
		return (newconn, ())

	connFlush mvconn = modifyMVar mvconn $ \conn -> do
		let oldbuff = sslconn_sendBuffer conn
		Network.TLS.sendData (sslconn_c conn) $ Data.ByteString.Lazy.concat oldbuff
		let newconn = conn { sslconn_sendBuffer = [] }
		return (newconn, ())

	connGetContents mvconn = modifyMVar mvconn $ \conn -> do
		let recur prebuild = do
			mrb <- try $ Network.TLS.recvData (sslconn_c conn)
			case mrb of
				Right rb -> if (Data.ByteString.null rb)
					then return prebuild
					else recur (rb:prebuild)
				Left err -> do
					putErrorStrLn $ "connGetContents error: " ++ (show (err :: SomeException))
					return prebuild
		ret <- recur [sslconn_recvBuffer conn]
		let newconn = conn { sslconn_recvBuffer = Data.ByteString.empty }
		return (newconn, Data.ByteString.concat $ reverse $ ret)

read_till_empty conn = do
	x <- connGetLine conn
	if (length x == 2) && (x == "\r\n")
		then return $ [x]
		else do
			xs <- read_till_empty conn
			return $ [x] ++ xs

getResponseHead conn = parseResponseHead <$> read_till_empty conn

switchResponse _ _ _ (Left e) _ = return $ Left e
switchResponse conn allow_retry bdy_sent (Right (cd, rn, hdrs)) rqst = do
-- 	putDebugStrLn $ "switchResponse: " ++ (show (cd, rn, hdrs, rqst))
	x <- case matchResponse (rqMethod rqst) cd of
		Continue -> if bdy_sent
			then do {- keep waiting -}
				rsp <- getResponseHead conn
				switchResponse conn allow_retry bdy_sent rsp rqst
			else do {- Time to send the body -}
				connPut conn (Data.ByteString.Char8.unpack $ rqBody rqst)
				connFlush conn
				rsp <- getResponseHead conn
				switchResponse conn allow_retry True rsp rqst
		Retry -> do {- Request with "Expect" header failed. Trouble is the request contains Expects other than "100-Continue" -}
			connPut conn (show rqst)
			connPut conn (Data.ByteString.Char8.unpack $ rqBody rqst)
			connFlush conn
			rsp <- getResponseHead conn
			switchResponse conn False bdy_sent rsp rqst
		Done -> return $ Right $ Response cd rn hdrs (Data.ByteString.Char8.pack "")
		DieHorribly str -> return $ responseParseError "Invalid response:" str
		ExpectEntity -> do
			case lookupHeader HdrTransferEncoding hdrs of
				Just s -> case filter isAlphaNum $ map toLower s of
					"chunked" -> do
-- 						putDebugStrLn $ "chunked"
						let parse_chunks = do
							l <- connGetLine conn
							let size = case readHex l of
								(hexs, _):_ -> hexs
								_ -> 0
							if size > 0
								then do
-- 									putDebugStrLn $ "  get a chunk, size " ++ (show size) ++ "..."
									x <- connGetBlock conn size
									void $ connGetLine conn
									xs <- parse_chunks
									return $ Data.ByteString.append x xs
								else do
									-- ... read footers, TODO ERROR WRONG HACK: should store them ... --
									void $ read_till_empty conn
									return (Data.ByteString.Char8.pack "")
						bdy <- parse_chunks
						let ftrs = []
						return $ Right $ Response cd rn (hdrs ++ ftrs) bdy
					_ -> return $ responseParseError "switchResponse" "Unknown Transfer-Encoding"
				Nothing -> case lookupHeader HdrContentLength hdrs of
					Just x -> case read_as x of
						Just size -> do
-- 							putDebugStrLn $ "linear"
							bdy <- connGetBlock conn size
							return $ Right $ Response cd rn hdrs bdy
						_ -> return $ responseParseError "unrecognized content-length value" x
					Nothing -> do
						putWarningStrLn $ "No content-length header!"
						bdy <- connGetContents conn
						return $ Right $ Response cd rn hdrs bdy
-- 	putDebugStrLn $ "/switchResponse: " ++ (show (cd,rn,hdrs,rqst))
	return x

mkreq_slow useragent cookie absuri params forproxy =
		(returi, setRequestVersion "HTTP/1.0" req)
	where
		(returi, req) = mkreq_fast useragent cookie absuri params forproxy

mkreq_fast useragent cookie absuri params forproxy =
		(absuri, normalizeRequest defaultNormalizeRequestOptions { normForProxy = forproxy } $ case params of
			Nothing -> Request { rqURI = absuri, rqMethod = GET, rqHeaders = cookiehdr, rqBody = Data.ByteString.empty }
			Just p -> let enc = formEncode p in Request { rqURI = absuri, rqMethod = POST, rqHeaders = cookiehdr ++ [mkHeader HdrContentType "application/x-www-form-urlencoded", mkHeader HdrContentLength (show $ length enc)], rqBody = Data.ByteString.Char8.pack enc })
	where
		cookiehdr = case cookie of
			Nothing -> [mkHeader HdrUserAgent useragent] -- ++ [mkHeader HdrConnection "Keep-Alive"]
			Just x -> [mkHeader HdrCookie x, mkHeader HdrUserAgent useragent] -- ++ [mkHeader HdrConnection "Keep-Alive"]

mkreq isslow = if isslow then mkreq_slow else mkreq_fast

rewrite_headers hdrs = map (\(Header x y) -> (show x, y)) hdrs

simple_http_withproxy rq = do
	use_proxy <- getEnvironmentSetting "KOLPROXY_USE_PROXY_SERVER"
	auth <- case use_proxy of
		Nothing -> getAuth rq
		Just p -> getAuth $ Request { rqURI = fromJust $ parseURI $ ("proxy://" ++ p ++ "/"), rqMethod = GET, rqHeaders = [], rqBody = "" }
-- 	putDebugStrLn $ "rawsimple connecting to " ++ show auth
--	putDebugStrLn $ "  http to " ++ show (host auth)
	s <- openStream (host auth) $ fromMaybe 80 (port auth)
-- 	putDebugStrLn $ "  prenorm: " ++ show rq
	let nrq = normalizeRequest (defaultNormalizeRequestOptions { normDoClose = True, normForProxy = True }) rq
-- 	putDebugStrLn $ "  asking for " ++ show nrq
	Network.HTTP.HandleStream.sendHTTP s nrq

simple_https_direct rq = do
	auth <- getAuth rq

	s <- mkconnectsocket
	hostA <- head <$> Network.BSD.hostAddresses <$> Network.BSD.getHostByName (host auth)
--	putDebugStrLn $ "  https to " ++ show (host auth)
	let a = Network.Socket.SockAddrInet (toEnum 443) hostA
	Network.Socket.connect s a
	h <- Network.Socket.socketToHandle s ReadWriteMode
	rng <- makeSystem
	c <- Network.TLS.contextNewOnHandle h (Network.TLS.defaultParamsClient { Network.TLS.pCiphers = Network.TLS.Extra.ciphersuite_strong }) rng
	Network.TLS.handshake c

	mvc <- newMVar (SslConn { sslconn_c = c, sslconn_sendBuffer = [], sslconn_recvBuffer = Data.ByteString.empty })

	connPut mvc (show rq)
	connPut mvc (Data.ByteString.Char8.unpack $ rqBody rq)
	connFlush mvc

	rsp <- getResponseHead mvc
	resresp <- switchResponse mvc True False rsp rq

	Network.TLS.bye c

	return resresp

mkCode resp = case rspCode resp of
	(a, b, c) -> fromIntegral $ a * 100 + b * 10 + c

check_for_http10 = do
	use_proxy <- getEnvironmentSetting "KOLPROXY_USE_PROXY_SERVER"
	use_server <- getEnvironmentSetting "KOLPROXY_SERVER"
	let autodetect = do
		c <- kolproxy_openTCPConnection "http://www.kingdomofloathing.com/"
		let request = "GET /radio.php HTTP/1.1\r\nUser-Agent: " ++ kolproxy_version_string ++ "\r\nHost: www.kingdomofloathing.com\r\nAccept: */*\r\n\r\n"
		connPut c request
		connFlush c
		lines <- read_till_empty c
		hClose c
		case lines of
			("HTTP/1.1 200 OK\r\n":_rest) -> putInfoStrLn "Detected fast server connection" >> return False
			_ -> putWarningStrLn "Detected slow server connection, using compatibility mode" >> return True
	case (use_proxy, use_server) of
		(Nothing, Nothing) -> do
			try_ad <- try autodetect
			case try_ad of
				(Right False) -> return False
				(Left err) -> do
					putDebugStrLn $ "check_for_http10 exception: " ++ show (err :: SomeException)
					return True
				_ -> return True
		_ -> return True

doHTTPreq (absuri, rq) = do
--	putDebugStrLn $ "doHTTPreq: " ++ show absuri
	use_proxy <- getEnvironmentSetting "KOLPROXY_USE_PROXY_SERVER"
	r <- case (use_proxy, uriScheme absuri) of
		(Nothing, "https:") -> simple_https_direct rq
		_ -> simple_http_withproxy rq
	case r of
		Right resp -> return (absuri, rspBody resp, rewrite_headers $ rspHeaders resp, mkCode resp)
		Left ce -> do
			putWarningStrLn $ "doHTTPreq: " ++ (show ce)
			throwIO $ InternalError $ "doHTTPreq[" ++ (show ce) ++ "]"

doHTTPSreq (absuri, rq) = do
--	putDebugStrLn $ "doHTTPSreq: " ++ show absuri
	r <- simple_https_direct rq
	case r of
		Right resp -> return (absuri, rspBody resp, rewrite_headers $ rspHeaders resp, mkCode resp)
		Left ce -> do
			putWarningStrLn $ "doHTTPSreq: " ++ (show ce)
			throwIO $ InternalError $ "doHTTPSreq[" ++ (show ce) ++ "]"

kolproxy_withVersion v hs = case v of
	[] -> hs
	(h:_)
		| h == httpVersion -> hs
		| otherwise -> (Header (HdrCustom "X-HTTP-Version") h) : hs

kolproxy_parseRequestHead reqhead = case reqhead of
	[] -> Left Network.Stream.ErrorClosed
	(com:hdrs) -> do
			(version, rqm, uri) <- requestCommand com
			hdrs' <- parseHeaders hdrs
			return (rqm, uri, kolproxy_withVersion version hdrs')
		where
			rqMethodMap = [
			   ("HEAD",    HEAD),
			   ("PUT",     PUT),
			   ("GET",     GET),
			   ("POST",    POST),
			   ("DELETE",  DELETE),
			   ("OPTIONS", OPTIONS),
			   ("TRACE",   TRACE),
			   ("CONNECT", CONNECT)]

			moduri uri = escapeURIString (\x -> x `notElem` "[]") uri

			requestCommand l = case (l, words l) of
				([], _) -> Network.Stream.failWith Network.Stream.ErrorClosed
				(_, (rqm:uri:version)) ->
					case (parseURIReference $ moduri uri, lookup rqm rqMethodMap) of
						(Just u, Just r) -> return (version, r, u)
						(Just u, Nothing) -> return (version, Custom rqm, u)
						_ -> parse_err l
				_ -> parse_err l

			parse_err l = responseParseError "parseRequestHead" ("Request command line parse failure: " ++ l)

kolproxy_receiveHTTP conn = do
	let kolproxy_headerName x = map toLower (f $ f $ x)
		where f = reverse . dropWhile isSpace

	-- TODO: handle favicon.ico better?
	h <- Network.Stream.fmapE (\es -> kolproxy_parseRequestHead (map (Network.BufferType.buf_toStr Network.BufferType.bufferOps) es)) (readTillEmpty1 Network.BufferType.bufferOps (readLine conn))
-- 	putDebugStrLn $ "getRequestHead: " ++ (show h)
	case h of
		Left x -> return $ Left x
		Right (rm, uri, hdrs) -> do
			Network.Stream.fmapE (\(ftrs,bdy) -> Right (Request uri rm (hdrs ++ ftrs) bdy)) $
				case lookupHeader HdrTransferEncoding hdrs of
					Nothing -> case lookupHeader HdrContentLength hdrs of
						Nothing -> return (Right ([], Network.BufferType.buf_empty Network.BufferType.bufferOps))
						Just x -> case reads x of
							((v,_):_) -> linearTransfer (readBlock conn) v
							_ -> return $ responseParseError "unrecognized Content-Length value" x
					Just hte -> if kolproxy_headerName hte == "chunked"
						then chunkedTransfer Network.BufferType.bufferOps (readLine conn) (readBlock conn)
						else uglyDeathTransfer "receiveHTTP"

mkconnectsocket = debug_do "mkconnectsocket" $ do
	proto <- Network.BSD.getProtocolNumber "tcp"
	bracketOnError (Network.Socket.socket Network.Socket.AF_INET Network.Socket.Stream proto) (Network.Socket.sClose) $ \s -> do
		Network.Socket.setSocketOption s Network.Socket.KeepAlive 1
		return s

mklistensocket listenpublic portnum = debug_do "mklistensocket" $ do
	proto <- Network.BSD.getProtocolNumber "tcp"
	let flags = if listenpublic
		then [AI_ADDRCONFIG, AI_PASSIVE]
		else [AI_ADDRCONFIG]
	let hints = Network.Socket.defaultHints {
		addrFlags = flags,
		addrFamily = Network.Socket.AF_INET,
		addrSocketType = Network.Socket.Stream,
		addrProtocol = proto
	}
	addr <- head <$> getAddrInfo (Just hints) Nothing (Just $ show $ portnum)
	bracketOnError (debug_do "socket create" $ Network.Socket.socket (addrFamily addr) (addrSocketType addr) (addrProtocol addr)) (Network.Socket.sClose) $ \s -> do
		Network.Socket.setSocketOption s Network.Socket.KeepAlive 1
		Network.Socket.setSocketOption s Network.Socket.ReuseAddr 1
		debug_do "socket bind" $ Network.Socket.bindSocket s (addrAddress addr)
		debug_do "socket listen" $ Network.Socket.listen s Network.Socket.maxListenQueue
		return s

kolproxy_openTCPConnection server = do
		bracketOnError (mkconnectsocket) (\s -> Network.Socket.sClose s) $ \s -> do
			-- TODO: use getAddrInfo and stuff? for ipv6??
			hostA <- getHostAddr hostname
-- 			putDebugStrLn $ "opentcp connecting to " ++ show auth ++ " | " ++ show hostname ++ " -> " ++ show hostA
			let a = Network.Socket.SockAddrInet (toEnum portnum) hostA
			Network.Socket.connect s a
			h <- Network.Socket.socketToHandle s ReadWriteMode
			return h
	where
		Just parsed = parseURI server
		Just auth = parseURIAuthority $ uriToAuthorityString parsed
		hostname = host auth
		portnum = fromMaybe 80 (port auth)
		getHostAddr h = do
			catchIO (Network.Socket.inet_addr hostname) -- handles ascii IP numbers
				(\ _ -> do
					hostN <- getHostByName_safe hostname
					case Network.BSD.hostAddresses hostN of
						[]     -> throwIO $ NetworkError $ ("openTCPConnection: no addresses in host entry for " ++ show h)
						(ha:_) -> return ha)
		getHostByName_safe h =
			catchIO (Network.BSD.getHostByName h)
				(\ _ -> throwIO $ NetworkError $ ("openTCPConnection: host lookup failure for " ++ show h))

fast_mkconnthing server = do
	-- TODO: merge stale-check and max-requests-check?
	connmv <- newEmptyMVar
	let open_conn = do
		tnow <- getCurrentTime
		let ensure_connection = do
			conn <- try $ kolproxy_openTCPConnection server
			case conn of
				Right c -> return c
				Left err -> do
					putWarningStrLn $ "Connection exception: " ++ show (err :: SomeException)
					threadDelay 500000
					putInfoStrLn $ "Trying again..."
					ensure_connection
		c <- ensure_connection
		rchan <- newChan
		req_counter <- newIORef 0
		let run = do
			stuff <- readChan rchan
			case stuff of
				Just (isok, (absuri, rq, mvdest, ref)) -> do
					(what, was_last_request) <- case isok of
						Right (_requesting_it, req_nr) -> log_time_interval_http ref ("HTTP reading: " ++ (show $ rqURI rq)) $ do
							what <- try $ ((do
								rsp <- log_time_interval_http ref "HTTP head" $ getResponseHead c -- fails to read from mafia because mafia terminates with LF instead of CRLF. Is this still true?
								Right resp <- log_time_interval_http ref "HTTP body" $ switchResponse c True False rsp rq
								return (absuri, rspBody resp, rewrite_headers $ rspHeaders resp, mkCode resp, resp)) `catch` (\e -> do
									doHTTPLOWLEVEL_DEBUGexception $ "http read exception: " ++ (show (e :: SomeException))
									throwIO e))
							return (what, req_nr == 80)
						Left err -> return (Left err, False) -- TODO: Change to True?
					putMVar mvdest what `catch` (\e -> do
						doHTTPLOWLEVEL_DEBUGexception $ "http write mvdest exception for " ++ (uriPath absuri) ++ ": " ++ (show (e :: SomeException))
						throwIO e)
					going <- (modifyMVar connmv $ \zzz -> do
						let Right (cf_stored, _, pending, thiskillfunc) = zzz
						let kill_it = do
							(cf, connt, _, cnewkill) <- open_conn
							let transfer n = when (n > 0) $ do
								Just (_, x) <- readChan rchan
								cf x
								transfer (n - 1)
							transfer (pending - 1)
							return (Right (cf, connt, pending - 1, cnewkill), False)
						case (was_last_request, what) of
							(True, _) -> kill_it
							(_, Right (_, _, hdrs, _, _)) -> case lookup "Connection" hdrs of
								Just "close" -> do
									putWarningStrLn $ "server closed connection"
									kill_it
								_ -> do
									trefreshed <- getCurrentTime
									return (Right (cf_stored, trefreshed, pending - 1, thiskillfunc), True)
							_ -> do
								putWarningStrLn $ "no headers from server, closing connection"
								kill_it) `catch` (\e -> do
									doHTTPLOWLEVEL_DEBUG $ "http put exception for " ++ (uriPath absuri) ++ ": " ++ (show (e :: SomeException))
									throwIO e)
					when going run
				_ -> return ()
		forkIO_ "HTTPlow:run" $ (run `catch` (\e -> do
			doHTTPLOWLEVEL_DEBUGexception $ "http forked-run exception: " ++ (show (e :: SomeException))
			throwIO e))
		let cfunc (absuri, rq, mvdest, ref) = do
			isok <- log_time_interval_http ref ("HTTP asking: " ++ (show $ rqURI $ rq)) $ try $ do
				req_nr <- atomicModifyIORef req_counter (\x -> (x + 1, x + 1))
				let requesting_it = (req_nr <= 80) -- Do a maximum of 80 requests per connection
				if requesting_it
					then do
--						putDebugStrLn $ "Request: " ++ show absuri
						connPut c (show rq)
						connPut c (Data.ByteString.Char8.unpack $ rqBody rq)
						connFlush c -- Maybe TODO???: only flush when done requesting???
					else return ()
				return (requesting_it, req_nr)
			writeChan rchan $ Just (isok, (absuri, rq, mvdest, ref))
		let ckill = writeChan rchan Nothing
		return (cfunc, tnow, 0, ckill)
	putMVar connmv =<< (try $ throwIO $ InternalError $ "Not connected to server")

-- connchan collects requests
-- we have 0-1 open valid connections to server going for this connchan
-- if overfull: wait for closing
-- if 0 or 1 invalid: make new connection
-- send request to connection

	connchan <- newChan
	forkIO_ "HTTPlow:connchan" $ forever $ handle (\e -> doHTTPLOWLEVEL_DEBUGexception $ "connchan error: " ++ (show (e :: SomeException))) $ do
		x <- readChan connchan

		modifyMVar_ connmv $ \z -> do
			what <- case z of
				Right (_cf_stored, t_stored, _pending, oldkill) -> do
					tnow <- getCurrentTime
					if diffUTCTime tnow t_stored <= 60.0 -- Reuse connection if it is less than a minute old
						then return z
						else try $ do
							oldkill
							open_conn
				Left _ -> try $ open_conn
			case what of
				Right (cf, t, p, k) -> do
					cf x
					return $ Right (cf, t, p + 1, k)
				Left err -> do
					let (_absuri, _rq, mvdest, _ref) = x
					putMVar mvdest $ Left (err :: SomeException)
					return $ Left err

	return connchan :: IO ConnChanType

slow_mkconnthing _server = do
	slowconnchan <- newChan
	forkIO_ "HTTPlow:slowconnchan" $ forever $ ((do
		(absuri, rq, mvdest, _ref) <- (readChan slowconnchan) `catch` (\e -> do
			doHTTPLOWLEVEL_DEBUGexception $ "slowconnchan read exception: " ++ (show (e :: SomeException))
			throwIO e)
		use_proxy <- getEnvironmentSetting "KOLPROXY_USE_PROXY_SERVER"
		auth <- case use_proxy of
			Nothing -> getAuth rq
			Just p -> getAuth $ Request { rqURI = fromJust $ parseURI $ ("proxy://" ++ p ++ "/"), rqMethod = GET, rqHeaders = [], rqBody = "" }
		s <- openStream (host auth) $ fromMaybe 80 (port auth)
		let nrq = normalizeRequest (defaultNormalizeRequestOptions { normDoClose = True, normForProxy = True }) rq
		r <- Network.HTTP.HandleStream.sendHTTP s nrq
		answer <- (try $ case r of
			Right resp -> return (absuri, rspBody resp, rewrite_headers $ rspHeaders resp, mkCode resp, resp)
			Left ce -> throwIO $ NetworkError $ "slowHTTP error: [" ++ (show ce) ++ "]") :: IO ConnChanActionType
		putMVar mvdest answer) `catch` (\e -> doHTTPLOWLEVEL_DEBUGexception $ "slowconnchan error: " ++ (show (e :: SomeException))))

	return slowconnchan :: IO ConnChanType

send_http_response h resp = do
	-- TODO: check for errors?
	void $ writeBlock h (Network.BufferType.buf_fromStr Network.BufferType.bufferOps $ show resp)
	void $ writeBlock h (Data.ByteString.Char8.unpack $ rspBody resp)

end_http h = Network.HTTP.close h
