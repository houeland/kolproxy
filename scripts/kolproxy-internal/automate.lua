-- automate.lua

function log_time_interval(msg, f) return f() end

local automators = {}

function wrapped_function()

reset_pageload_cache()

if not can_read_state() then
	return text
end

log_time_interval("automate:initialize", function()
which = path
if (requestpath == "/login.php" and text == "kolproxy login redirect") or (requestpath == "/afterlife.php" and path == "/main.php" and text == "kolproxy afterlife ascension") then
	which = "player login"
end

setup_variables()
end)

log_time_interval("run automators", function()
if which ~= "/loggedout.php" then
	local automate_url = path
	text = run_functions(path, text, function(target, pt)
		for _, x in ipairs(automators[target] or {}) do
			getfenv(x.f).text = pt
			getfenv(x.f).url = automateurl
-- 			log_time_interval("run:" .. tostring(x.scriptname), x.f)
			x.f()
			pt = getfenv(x.f).text
			automateurl = getfenv(x.f).url
		end
		return pt
	end)
end
end)

return text

end




local envstoreinfo = loadfile("scripts/kolproxy-internal/setup-environment.lua")()

function doloadfile(f)
	load_script("../" .. f)
end

load_script("base/util.lua")

envstoreinfo.g_env.setup_functions()
tostring = envstoreinfo.g_env.tostring

local function add_automator_raw(file, func, scriptname)
	if not automators[file] then automators[file] = {} end
	table.insert(automators[file], { f = func, scriptname = scriptname })
end

envstoreinfo.g_env.load_script_files {
	add_processor = function() end,
	add_printer = function() end,
	add_choice_text_conditional = function() end,
	add_choice_text = function() end,
	add_choice_itemtext = function() end,
	add_choice_function = function() end,
	add_automator = add_automator_raw,
	add_interceptor = function() end,
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
