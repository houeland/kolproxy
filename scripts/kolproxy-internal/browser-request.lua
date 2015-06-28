function log_time_interval(msg, f) return f() end

local shared_env = {}
--shared_env._G = shared_env
shared_env._G_envname = "browser-request shared_env"
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
	wrapped_env._G_envname = "browser-request wrapped_env " .. wrapperpath
	setmetatable(wrapped_env, { __index = shared_env })

	local f, e = loadfile(wrapperpath)
	if not f then error(e, 2) end
	setfenv(f, wrapped_env)
	local wrapped = f()
	return wrapped
end

local intercept_wrapped = load_wrapped_function("scripts/kolproxy-internal/intercept.lua")
local automate_wrapped = load_wrapped_function("scripts/kolproxy-internal/automate.lua")
local printer_wrapped = load_wrapped_function("scripts/kolproxy-internal/printer.lua")

local function descit(what, pt, url)
--	print("DEBUG descit:", what, "url", url, "pt", type(pt), type(pt) == "string" and pt:len(), kolproxy_can_read_state())
end

local function add_raw_message_to_page(pagetext, msg)
	local pre_, dv_, mid_, end_, post_ = pagetext:match("^(.+)(<div style='overflow: auto'><center><table)(.+)(</body></html>)(.*)$")
	if pre_ and dv_ and mid_ and end_ and post_ then
		local wrappedmsg = [[<center><table width=95%><tr><td>]] .. msg .. [[</td></tr></table></center>]]
		return pre_ .. wrappedmsg .. "<br>" .. dv_ .. mid_ .. end_ .. post_
	elseif pagetext:match("<body>") then
		return pagetext:gsub("<body>", function(a) return a .. msg end)
	else
		return msg .. pagetext
	end
end

local function show_error(basepage, errortbl)
	return add_raw_message_to_page(basepage, [[<pre style="color: red">]] .. errortbl.trace .. [[</pre>]])
end

local function run_wrapped_function_internal(f_env)
	local function submit_original_request()
		local tbl = parse_request_param_string(f_env.raw_input_params)
		if not tbl[1] then tbl = nil end
		local a, b, c = kolproxycore_async_submit_page(f_env.request_type, f_env.request_path, tbl)()
		if a then
			return a, b
		else
			error("Error downloading page " .. tostring(f_env.request_path) .. ":<br><br>" .. tostring(b))
		end
	end

	descit("start")

	if not kolproxy_can_read_state() then
		local pt, url = submit_original_request()

		f_env.requestpath = f_env.request_path
		f_env.requestquery = f_env.request_query
		f_env.text = pt
		f_env.path, f_env.query = kolproxycore_splituri(url)

		local printer_pt = printer_wrapped(f_env)
		return printer_pt, url
	end

	f_env.requestpath = f_env.request_path
	f_env.requestquery = f_env.request_query
	f_env.text = ""

	descit("pre-intercept")

	local intercept_pt, intercept_url = intercept_wrapped(f_env)

	descit("intercept", intercept_pt, intercept_url)
	if not intercept_pt then
		return intercept_url, "/error"
	end

	local intercept_path, intercept_query = kolproxycore_splituri(intercept_url)

	f_env.text = intercept_pt
	f_env.intercept_url = intercept_url
	f_env.path = intercept_path
	f_env.query = intercept_query
	f_env.effuri_params = kolproxycore_decode_uri_query(intercept_url) or {}

	local automate_pt, automate_url = automate_wrapped(f_env)

	descit("automate", automate_pt, automate_url)

	local automate_path, automate_query = kolproxycore_splituri(automate_url)

	f_env.text = automate_pt
	f_env.automate_url = automate_url
	f_env.path = automate_path
	f_env.query = automate_query

	local printer_pt = printer_wrapped(f_env)

	descit("printer", printer_pt, automate_url)

	return printer_pt, intercept_url
end

local function run_wrapped_function(f_env)
	local ok, pt, url = xpcall(function() return run_wrapped_function_internal(f_env) end, function(e) return { msg = e, trace = debug.traceback(e, 2) } end)
	if ok then
		return pt, url, "text/html; charset=UTF-8"
	else
		return show_error(f_env.text or "{ No page text. }", pt), "/kolproxy-error", "text/html; charset=UTF-8"
	end
end

return run_wrapped_function
