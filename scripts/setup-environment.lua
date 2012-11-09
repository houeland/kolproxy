local g_env = {}
g_env._G = g_env

function load_script(scriptname)
	local function add_do_nothing_function(name)
		if not g_env[name] then
			g_env[name] = function() end
		end
	end
	add_do_nothing_function("add_processor")
	add_do_nothing_function("add_printer")
	add_do_nothing_function("add_choice_text")
	add_do_nothing_function("add_automator")
	add_do_nothing_function("add_interceptor")
	add_do_nothing_function("add_chat_printer")
	add_do_nothing_function("add_json_chat_printer")
	add_do_nothing_function("add_chat_trigger")

-- 	print("loadfile", scriptname)
	local f, e = loadfile("scripts/" .. scriptname)
	if not f then error(e, 2) end
	setfenv(f, g_env)
	f()
end

local envstoreinfo = {
	g_env = g_env,
	f_store = {},
	g_store = {},
	store_target = nil,
	store_target_name = "g_store",
}
envstoreinfo.store_target = envstoreinfo.g_store

local logged = {}
local log_internal_tostring = tostring
local log_internal_print = print
local function logprint(k, msg)
	local x = log_internal_tostring(k)..":"..log_internal_tostring(msg)
	if not logged[x] then
		local cached_tostring = tostring
		tostring = log_internal_tostring
		log_internal_print(log_internal_tostring(k), log_internal_tostring(msg))
		tostring = cached_tostring
		logged[x] = true
	end
end

setmetatable(g_env, { __index = function(t, k)
	local g_v = rawget(envstoreinfo.g_store, k)
	if g_v ~= nil then
-- 		logprint(k, "from g_v")
		return g_v
	end

	local f_v = rawget(envstoreinfo.f_store, k)
	if f_v ~= nil then
-- 		logprint(k, "from f_v")
		return f_v
	end

-- 	logprint(k, "from _G")
	return _G[k]
end, __newindex = function(t, k, v)
-- 	if envstoreinfo.store_target_name ~= "g_store" then
-- 		print("process", envstoreinfo.store_target_name, "set", k, "=", "...")
-- 	end
	envstoreinfo.store_target[k] = v
end	})
setfenv(wrapped_function, g_env)

-- setmetatable(_G, { __index = function(t, k)
-- 	log_internal_print("_G <- ", k)
-- 	return rawget(t, k)
-- end, __newindex = function(t, k, v)
-- 	log_internal_print("_G -> ", k)
-- 	rawset(t, k, v)
-- end	})

return envstoreinfo
