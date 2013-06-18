-- intercept.lua

-- TODO? check for valid pwd!

local interceptors = {}

function wrapped_function()
text = nil

if not can_read_state() then
	return
end

reset_pageload_cache()

path = requestpath -- temporary workaround for backwards compatibility
query = requestquery -- temporary workaround for backwards compatibility

-- Download and cache available skills. Do this differently(?)
get_player_skills()

function submit_original_request()
	return raw_submit_page(request_type, requestpath, parse_params_raw(input_params))
end

if requestpath == "/manor3.php" then
	determine_cellar_wines()
end

if requestpath == "/automate-tiles" then
	text, url = automate_tiles()
end

-- 			let inrunoption = case choice of
-- 				21 -> 2 -- not trapped in the wrong body
-- 				46 -> 3 -- fight vampire, maybe doubtful?
-- 				105 -> 1 -- gaze into mirror in bathroom
-- 				108 -> 4 -- walk away from craps
-- 				109 -> 1 -- fight hobo
-- 				110 -> 4 -- introduce them to avantgarde
-- 				113 -> 2 -- fight knob goblin chef
-- 				118 -> 2 -- don't do wounded guard quest
-- 				120 -> 4 -- ennui outta here
-- 				123 -> 2 -- raise your hands in hidden temple
-- 				177 -> 5 -- blackberry cobbler, leave
-- 				402 -> 2 -- don't hold a grudge in bathroom, gain myst
-- 				otherwise -> -1
-- 			let aftercoreoption = case choice of
-- 				9 -> 3 -- leave the wheel alone in the castle
-- 				10 -> 3 -- leave the wheel alone in the castle
-- 				11 -> 3 -- leave the wheel alone in the castle
-- 				12 -> 3 -- leave the wheel alone in the castle
-- 				21 -> -1 -- trapped in the wrong body?
-- 				26 -> 2 -- take the scorched path
-- 				28 -> 2 -- investigate the moist crater for spices
-- 				89 -> 2 -- fight TT knight in the gallery
-- 				90 -> 2 -- watch the dancers in ballroom
-- 				112 -> 2 -- no time for harold's bell
-- 				178 -> 2 -- blow popsicle stand in airship
-- 				182 -> 1 -- fight in the airship
-- 				207 -> 2 -- leave hot door alone in burnbarrel
-- 				213 -> 2 -- leave piping hot in burnbarrel
-- 				214 -> 1 -- kick stuff into the hole in the heap
-- 				216 -> 2 -- begone from the compostal service
-- 				otherwise -> inrunoption

for _, x in ipairs(interceptors[requestpath] or {}) do
	local t, u = x.f()
	if t then
		return t, u
	end
end

if requestpath == "/inv_use.php" then
	local n = maybe_get_itemname(tonumber(params.whichitem))
	if n then
		for _, x in ipairs(interceptors["use item"] or {}) do
			local t, u = x.f()
			if t then
				return t, u
			end
		end
		for _, x in ipairs(interceptors["use item: " .. n] or {}) do
			local t, u = x.f()
			if t then
				return t, u
			end
		end
	end
end

if text then
-- 	print "intercept:returning"
	return text, url
else
-- 	print "intercept:rawsubmitting"
	return submit_original_request()
end

end




local envstoreinfo = loadfile("scripts/setup-environment.lua")()

function dofile(f)
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
