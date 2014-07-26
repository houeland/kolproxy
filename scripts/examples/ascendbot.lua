local pwd = nil

local lsf_env

function wrapped_function(f_env)
	print("starting bot script")

	pwd = json_to_table(get_page("/api.php", { what = "status", ["for"] = "kolproxy-botscript by Eleron", format = "json" })).pwd

	print("starting ascension loop")

	lsf_env.ascension_automation_script_do_loop(1000)

	print("done!")
end

local envstoreinfo = loadfile("scripts/kolproxy-internal/setup-environment.lua")()

function dofile(f)
	load_script("../" .. f)
end

load_script("base/datafile.lua")

load_script("base/util.lua")

envstoreinfo.g_env.setup_functions()

tostring = envstoreinfo.g_env.tostring

lsf_env = envstoreinfo.g_env.load_script_files {}

function run_wrapped_function(f_env)
	envstoreinfo.f_store = f_env
	envstoreinfo.f_store.input_params = envstoreinfo.f_store.raw_input_params
	envstoreinfo.f_store.params = envstoreinfo.g_env.parse_params(envstoreinfo.f_store.raw_input_params)

	envstoreinfo.store_target = envstoreinfo.f_store
	envstoreinfo.store_target_name = "f_store"
	return wrapped_function()
end

return run_wrapped_function
