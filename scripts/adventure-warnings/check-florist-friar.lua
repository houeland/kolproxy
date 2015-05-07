register_setting {
	name = "show extra notices/check florist friar",
	description = "Show florist friar notice if re-adventuring without plants",
	group = "warnings",
	default_level = "detailed",
	parent = "enable adventure warnings",
}

register_setting {
	name = "automate florist friar planting",
	description = "Automate Florist Friar planting",
	group = "automation",
	default_level = "enthusiast",
}

local have_friar = nil
local checked_zones = {}

function zone_awaiting_florist_decision(zone)
	local pt = nil
	if have_friar == false then
		return
	elseif have_friar == nil then
		print_debug("INFO: checking for friar")
		pt = get_place("forestvillage", "fv_friar")
		if pt:contains("The Florist Friar's Cottage") then
			have_friar = true
		elseif pt:contains("Forest Village") then
			have_friar = false
			return
		end
	end

	local lastzone = lastadventurezoneid()
	if lastzone and get_zoneid(zone) == lastzone then
		if checked_zones[lastzone] then return end
		if session["warning-no florist plants, zoneid " .. lastzone] then return end
		local noplants = 0
		if not pt then
			print("INFO: checking friar for plants")
			pt = get_place("forestvillage", "fv_friar")
		end
		for x in pt:gmatch([[title="No Plant"]]) do
			noplants = noplants + 1
		end
		if noplants == 3 then
--			--print("INFO:   no plants!")
			return true
		else
--			--print("INFO:   have some plants", 3 - noplants)
			checked_zones[lastzone] = true
			return false
		end
	end
end

function plant_florist_plants(want_plants)
	local available = check_current_available_florist_friar_plants()
	local planted_territorial = false
	local planted_count = 0
	for _, x in ipairs(want_plants) do
		if available[x] then
			local xmod = x % 10
			local is_territorial = (xmod >= 1 and xmod <= 3)
			if (not is_territorial or not planted_territorial) and planted_count < 3 then
				print("INFO: florist friar planting", x)
				async_post_page("/choice.php", { whichchoice = 720, pwd = session.pwd, option = 1, plant = x })
				planted_count = planted_count + 1
				planted_territorial = planted_territorial or is_territorial
			end
		end
	end
end

-- TODO: redo with add_warning!
add_interceptor("/adventure.php", function()
	local ok = false
	if setting_enabled("enable adventure warnings") and setting_enabled("show extra notices") and setting_enabled("show extra notices/check florist friar") then ok = true end
	if setting_enabled("automate florist friar planting") then ok = true end
	if not ok then return end
	if locked() then return end
	if requested_zone_id() and zone_awaiting_florist_decision(requested_zone_id()) then
		local want_plants = nil
		if setting_enabled("automate florist friar planting") then
			local lastadvzoneid = lastadventurezoneid()
			local stored_state = ascension["automation.florist friar.automatic planting"] or {}
			want_plants = stored_state[tostring(lastadvzoneid)]
		end
		if want_plants then
			plant_florist_plants(want_plants)
		elseif setting_enabled("show extra notices/check florist friar") then
			return intercept_warning { message = "The Florist Friar has not planted anything here yet.", id = "no florist plants, zoneid " .. lastadventurezoneid(), customdisablecolor = "rgb(51, 153, 51)", customwarningprefix = "Notice: ", customaction = string.format([[<a href="%s">%s</a>]], make_href("/place.php", { whichplace = "forestvillage", action = "fv_friar" }), "Visit Florist Friar.") }
		end
	end
end)

function check_current_available_florist_friar_plants(friarpt)
	friarpt = friarpt or get_place("forestvillage", "fv_friar")
--	local plantedtext = friarpt:match("Currently planted.+")
--	local planted = {}
--	for x in plantedtext:gmatch([[<img src="http://images.kingdomofloathing.com/otherimages/friarplants/(.-)%.gif"]]) do
--		table.insert(planted, x)
--	end
--	print("DEBUG planted", tostring(planted))
	local available = {}
	for value, inputtext in friarpt:gmatch([[name="plant" value="([0-9]+)" /><input type="submit"(.-)/>]]) do
		if not inputtext:contains("disabled") then
			available[tonumber(value)] = true
		end
	end
	return available
end

local configure_friar_href = add_automation_script("custom-configure-florist-friar-automation", function()
	local lines = {}
	local lastadv = lastadventuredata()
	local lastadvzoneid = lastadventurezoneid()
	local prefilltext = ""
	if lastadv.name and lastadvzoneid then
		local friarpt = get_place("forestvillage", "fv_friar")
		local available_plant_types = {}
		for x in friarpt:gmatch([[name="plant" value="([0-9]+)"]]) do
			table.insert(available_plant_types, tonumber(x))
		end
		table.insert(lines, { zoneid = lastadvzoneid, plants = available_plant_types })
		prefilltext = tojson { [tostring(lastadvzoneid)] = available_plant_types }
	end

	local html_lines = {}
	for _, x in ipairs(lines) do
		table.insert(html_lines, string.format([[%d: %s]], x.zoneid, tojson(x.plants)))
	end

	local stored_state = ascension["automation.florist friar.automatic planting"] or {}

	if params.friarplants then
		local tbl = fromjson(params.friarplants)
		for a, b in pairs(tbl) do
			stored_state[a] = b
		end
		ascension["automation.florist friar.automatic planting"] = stored_state
	end

	local temp_configure_input = [[
Syntax: { "zoneid1": [ordered list of plantids to plant automatically], "zoneid2": [list2], "zoneid3": [list3], ... }<br>
Current configuration is per-ascension only, remember to make a backup before you ascend!<br>
<form action="/kolproxy-automation-script">
<input type="hidden" name="automation-script" value="custom-configure-florist-friar-automation">
<input type="hidden" name="pwd" value="]] .. session.pwd .. [[">
<textarea name="friarplants" rows="5" cols="80">]] .. prefilltext .. [[</textarea><br>
<input type="submit">
</form>
]]

	return "TODO: Work in progress, no configuration interface yet.<br><br>Existing configuration:" .. tojson(stored_state) .. "<br><br>" .. temp_configure_input
end)

add_printer("/choice.php", function()
	if text:contains(">The Florist Friar's Cottage<") then
		text = text:gsub([[</body>]], [[<center><a href="]]..configure_friar_href { pwd = session.pwd } .. [[" style="color: green;">{ Configure friar automation. (beta version) }</a></center>%0]])
	end
end)
