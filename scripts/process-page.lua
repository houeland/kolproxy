-- process-page.lua

-- io = nil
os = nil
-- debug = nil
require = nil
module = nil
package = nil

local processors = {}

function wrapped_function()

if not can_read_state() then
	return text
end

error_on_writing_text_or_url = false

reset_pageload_cache()

newly_started_fight = false
if path == "/fight.php" then
	-- TODO: Also resets on logout/login? Is that true, and for all types of fight state?
	if tonumber(params.ireallymeanit) then
		newly_started_fight = true
		reset_fight_state()
	end
end

if requestpath == "/adventure.php" then
	local z = tonumber(params.snarfblat)
	if z then -- TODO: can be slow because it forces API load. Does it still do that?
		fight.zone = z
		session["adventure.lastzone"] = z
	end
end

setup_variables()

-- if requestpath == "/adventure.php" and zone then
-- 	local encounter = nil
-- 	if monster_name then
-- 		encounter = monster_name
-- 	elseif adventure_result then
-- 		encounter = adventure_result
-- 	else
-- 		encounter = adventure_title
-- 	end
-- 	print("adventure in zone", zone, "got me", encounter, "   $$$$  %%% ", monster_name, adventure_title, adventure_result)
-- 	local tbl = get_ascension_state("zone-"..zone.."-encounters")
-- 	if (tbl == "") then tbl = {} else tbl = str_to_table(tbl) end
-- 	table.insert(tbl, encounter)
-- 	set_ascension_state("zone-"..zone.."-encounters", table_to_str(tbl))
-- end

do
	local function matches(x)
		if monster_name and newly_started_fight and encounter_source == "adventure" then
			return monster_name:contains(x)
		elseif adventure_title == x or adventure_result == x then
			return true
		elseif text:contains(">There once was a bleary-eyed cyclops<") and x == "The Bleary-Eyed Cyclops" then -- HACK! The page for the cyclops eyedrops is weird
			return true
		else
			return false
		end
	end
	for _, x in ipairs(datafile("semirares")) do
		if matches(x) then
			print("INFO: SEMIRARE!!!", x)
			ascension["last semirare encounter"] = x
			ascension["last semirare turn"] = turnsthisrun()
			ascension["last semirare"] = { encounter = x, turn = turnsthisrun() }
		end
	end
end

-- Clear cache whenever we gain (or lose) a skill
if text:contains("You acquire a skill") or text:contains("You leargn a new skill") or text:contains("You learn a new skill") then
	print("INFO: Clearing skill cache!")
	clear_cached_skills()
end

run_functions(path, text, function(target, pt)
	for _, x in ipairs(processors[target] or {}) do
		getfenv(x.f).text = pt
-- 		kolproxy_log_time_interval("run:" .. tostring(x.scriptname), x.f)
		error_on_writing_text_or_url = true
		x.f()
		error_on_writing_text_or_url = false
	end
	return pt
end)

return text

end



local envstoreinfo = loadfile("scripts/setup-environment.lua")()

function dofile(f)
	load_script("../" .. f)
end

load_script("base/util.lua")

envstoreinfo.g_env.setup_functions()
tostring = envstoreinfo.g_env.tostring

local function add_processor_raw(file, func, scriptname)
	if not processors[file] then processors[file] = {} end
	table.insert(processors[file], { f = func, scriptname = scriptname })
end

envstoreinfo.g_env.load_script_files {
	add_processor_raw = add_processor_raw,
	add_printer = function() end,
	add_choice_text_conditional = function() end,
	add_choice_text = function() end,
	add_choice_itemtext = function() end,
	add_choice_function = function() end,
	add_interceptor = function() end,
	add_automator = function() end,
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
