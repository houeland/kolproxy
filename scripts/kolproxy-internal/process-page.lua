-- process-page.lua

-- io = nil
os = nil
-- debug = nil
require = nil
module = nil
package = nil

function log_time_interval(msg, f) return f() end

local processors = {}

function wrapped_function()

if not can_read_state() then
	return text
end

log_time_interval("process:initialize", function()
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
	local z = requested_zone_id()
	if z then
		-- TODO: can be slow because it forces API load. Does it still do that?
		fight.zone = z
		session["adventure.lastzone"] = z
	end
end

setup_variables()
end)

log_time_interval("process:check semirare and skills", function()
do
	-- TODO: Move to separate file
	local function matches(x)
		if newly_started_fight and encounter_source == "adventure" and monstername(x) then
			return true
		elseif adventure_title == x or adventure_result == x then
			return true
		elseif x == "The Bleary-Eyed Cyclops" and text:contains(">There once was a bleary-eyed cyclops<") then -- WORKAROUND: The page for the cyclops eyedrops is weird with no title
			return true
		else
			return false
		end
	end
	for _, x in ipairs(datafile("semirares")) do
		if matches(x) then
			print("INFO: SEMIRARE!!!", x)
			ascension["last semirare"] = { encounter = x, turn = turnsthisrun() }
			print("INFO: Forgetting old fortune cookie numbers: ", tojson(ascension["fortune cookie numbers"]))
			ascension["fortune cookie numbers"] = nil
		end
	end
end

-- Clear cache whenever we gain (or lose) a skill
if text:contains("You acquire a skill") or text:contains("You leargn a new skill") or text:contains("You learn a new skill") then
	print("INFO: Clearing skill cache!")
	clear_cached_skills()
end
end)

log_time_interval("process:run functions", function()
run_functions(path, text, function(target, pt)
	for _, x in ipairs(processors[target] or {}) do
		getfenv(x.f).text = pt
		error_on_writing_text_or_url = true
--		log_time_interval("run:" .. tostring(x.scriptname), x.f)
		x.f()
		error_on_writing_text_or_url = false
	end
	return pt
end)
end)

return text

end



local envstoreinfo = loadfile("scripts/kolproxy-internal/setup-environment.lua")()

function doloadfile(path)
	load_script("../" .. path)
end

load_script("base/datafile.lua")

load_script("base/util.lua")

envstoreinfo.g_env.setup_functions()
tostring = envstoreinfo.g_env.tostring

local function add_processor_raw(file, func, scriptname)
	if not processors[file] then processors[file] = {} end
	table.insert(processors[file], { f = func, scriptname = scriptname })
end

envstoreinfo.g_env.load_script_files {
	add_processor_raw = add_processor_raw,
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
