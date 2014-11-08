function log_time_interval(msg, f) return f() end

local shared_env = {}
setmetatable(shared_env, { __index = _G })
do
	local f, e = loadfile("scripts/base/datafile.lua")
	if not f then error(e, 2) end
	setfenv(f, shared_env)
	f()
end

local function load_wrapped_function(wrapperpath)
	local wrapped_env = {}
	function wrapped_env.loadfile(loadfilepath)
		local f, e = loadfile(loadfilepath)
		if not f then error(e, 2) end
		setfenv(f, wrapped_env)
		return f, e
	end
	wrapped_env._G = wrapped_env

	setmetatable(wrapped_env, { __index = shared_env })

	local f, e = loadfile(wrapperpath)
	if not f then error(e, 2) end
	setfenv(f, wrapped_env)
	local wrapped = f()
	return wrapped
end

local chat_wrapped = load_wrapped_function("scripts/kolproxy-internal/chat.lua")
local sendchat_wrapped = load_wrapped_function("scripts/kolproxy-internal/sendchat.lua")
local sentchat_wrapped = load_wrapped_function("scripts/kolproxy-internal/sentchat.lua")

local function show_error(basepage, errortbl)
	print("CHAT ERROR:", errortbl.trace)
	return basepage
end

local function run_wrapped_function_internal(f_env)
	local function submit_original_request()
		local tbl = parse_request_param_string(f_env.raw_input_params)
		if not tbl[1] then tbl = nil end
		local a, b, c = kolproxycore_async_submit_page("GET", f_env.request_path, tbl)()
		if a then
			return a, b
		else
			error("Error downloading page " .. tostring(f_env.request_path) .. ":<br><br>" .. tostring(b))
		end
	end

	local sendchat_result = ""
	if f_env.request_path == "/submitnewchat.php" then
		sendchat_result = sendchat_wrapped(f_env)
	end

	local newgraf = sendchat_result:match([[^//kolproxy:sendgraf:(.+)$]])

	if sendchat_result == "" then
		return submit_original_request()
	elseif newgraf then
		local allparams = parse_params(f_env.raw_input_params)
		allparams.graf = newgraf
		local a, b = get_page("/submitnewchat.php", allparams)
		if a then
			return a, b
		else
			error("Error downloading page " .. tostring(f_env.request_path) .. ":<br><br>" .. tostring(b))
		end
	else
		return sendchat_result
	end
end

local function run_wrapped_function(f_env)
	local ok, pt, url = xpcall(function() return run_wrapped_function_internal(f_env) end, function(e) return { msg = e, trace = debug.traceback(e, 2) } end)
	if ok then
		return pt--, url
	else
		return show_error(f_env.text or "{ No page text. }", pt)--, "/kolproxy-error"
	end
end

return run_wrapped_function
