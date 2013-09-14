function load_wrapped_function(path)
--	print("loading wrapped", path)
	local wrapped_env = {}
	function wrapped_env.loadfile(path)
		local f, e = loadfile(path)
		if not f then error(e, 2) end
		setfenv(f, wrapped_env)
		return f, e
	end
	wrapped_env._G = wrapped_env

	local have_read = {}

        setmetatable(wrapped_env, { __index = function(t, k)
--		if not have_read[k] then
--			print("DEBUG: wrapped_env reading", k)
--			have_read[k] = true
--		end
		return _G[k]
        end, __newindex = function(t, k, v)
--		print("DEBUG: wrapped_env writing", k, v)
		rawset(t, k, v)
        end})

	local f, e = loadfile(path)
	if not f then error(e, 2) end
	setfenv(f, wrapped_env)
	local wrapped = f()
--	print("loaded", wrapped)
	return wrapped
end

local intercept_wrapped = load_wrapped_function("scripts/intercept.lua")
local automate_wrapped = load_wrapped_function("scripts/automate.lua")
local printer_wrapped = load_wrapped_function("scripts/printer.lua")

function descit(what, pt, url)
--	print(what, "url", url, "pt", type(pt), type(pt) == "string" and pt:len())
end

function run_wrapped_function(f_env)
	function submit_original_request()
		local tbl = parse_request_param_string(f_env.raw_input_params)
		if not tbl[1] then tbl = nil end
	        return raw_submit_page(f_env.request_type, f_env.request_path, tbl)
	end

	descit("start")

--	for _, x in ipairs { "raw_input_params", "request_path", "request_query", "request_type" } do
--		print(x, f_env[x])
--	end

	if not can_read_state() then
		local pt, url = submit_original_request()

		f_env.requestpath = f_env.request_path
		f_env.requestquery = f_env.request_query
		f_env.text = pt
		f_env.path, f_env.query = browserrequest_splituri(url)

		local printer_pt = printer_wrapped(f_env)
		return printer_pt, url
	end

	f_env.requestpath = f_env.request_path
	f_env.requestquery = f_env.request_query
	f_env.text = ""

	descit("pre-intercept")

	local intercept_pt, intercept_url = intercept_wrapped(f_env)

	descit("intercept", intercept_pt, intercept_url)

	local intercept_path, intercept_query = browserrequest_splituri(intercept_url)

	f_env.text = intercept_pt
	f_env.path = intercept_path
	f_env.query = intercept_query

	local automate_pt = automate_wrapped(f_env)

	descit("automate", automate_pt, intercept_url)

	f_env.text = automate_pt

	local printer_pt = printer_wrapped(f_env)

	descit("printer", printer_pt, intercept_url)

	return printer_pt, intercept_url
end

return run_wrapped_function
