-- intercept.lua

function log_time_interval(msg, f) return f() end
--log_time_interval = kolproxy_log_time_interval

local interceptors = {}

function wrapped_function()
text = nil

if not can_read_state() then
	return
end

log_time_interval("intercept:initialize", function()
reset_pageload_cache()

path = requestpath -- temporary workaround for backwards compatibility
query = requestquery -- temporary workaround for backwards compatibility

-- Download and cache available skills. Do this differently(?)
get_player_skills()

function submit_original_request()
	return raw_async_submit_page(request_type, requestpath, get_allparams_keyvaluetbl())()
end
end)

text, url = log_time_interval("run intercepts", function()
for _, x in ipairs(interceptors[requestpath] or {}) do
	local t, u = x.f()
	if t then
		return t, u or requestpath
	end
end

if requestpath == "/inv_use.php" or requestpath == "/inv_spleen.php" then
	local n = maybe_get_itemname(tonumber(params.whichitem))
	if n then
		for _, x in ipairs(interceptors["use item"] or {}) do
			local t, u = x.f()
			if t then
				return t, u or requestpath
			end
		end
		for _, x in ipairs(interceptors["use item: " .. n] or {}) do
			local t, u = x.f()
			if t then
				return t, u or requestpath
			end
		end
	end
end
end)

if text then
-- 	print "intercept:returning"
	return text, url
else
-- 	print "intercept:rawsubmitting"
	return submit_original_request()
end

end




local envstoreinfo = loadfile("scripts/kolproxy-internal/setup-environment.lua")()

function doloadfile(f)
	load_script("../" .. f)
end

load_script("base/util.lua")

envstoreinfo.g_env.setup_functions()

tostring = envstoreinfo.g_env.tostring

local function add_interceptor_raw(file, func)
	if not interceptors[file] then interceptors[file] = {} end
	table.insert(interceptors[file], { f = func })
end

envstoreinfo.g_env.load_script_files {
	add_interceptor = add_interceptor_raw,
}

function run_wrapped_function(f_env)
	envstoreinfo.f_store = f_env
	envstoreinfo.f_store.input_params = envstoreinfo.f_store.raw_input_params
	envstoreinfo.f_store.params = envstoreinfo.g_env.parse_params(envstoreinfo.f_store.raw_input_params)

	envstoreinfo.store_target = envstoreinfo.f_store
	envstoreinfo.store_target_name = "f_store"
	return wrapped_function()
end

return run_wrapped_function
