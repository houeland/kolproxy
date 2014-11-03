local g_env = {}
g_env._G = g_env
g_env._G_envname = "setup-environment g_env"

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

setmetatable(g_env, {
__index = function(t, k)
	local g_v = rawget(envstoreinfo.g_store, k)
	if g_v ~= nil then return g_v end
	local f_v = rawget(envstoreinfo.f_store, k)
	if f_v ~= nil then return f_v end
	return _G[k]
end,
__newindex = function(t, k, v)
	envstoreinfo.store_target[k] = v
end
})
setfenv(wrapped_function, g_env)

return envstoreinfo
