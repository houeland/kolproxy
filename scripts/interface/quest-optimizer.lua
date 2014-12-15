function estimate_orchard_turns(plus_item)
	local gland_droprate = math.minmax(0, 0.1 * (100 + plus_item) / 100, 1)

	local win_turnsum = 0
	local function register_win(p, turns)
--		print("win", p, turns)
		win_turnsum = win_turnsum + p * turns
	end

	local psum_fail = 0
	local fail_turnsum = 0
	local function register_fail(p, turns)
--		print("fail", p, turns)
		psum_fail = psum_fail + p
		fail_turnsum = fail_turnsum + p * turns
	end

	local p_get_first = gland_droprate
	for x = 1, 10 do
		local p_get_first_and_get_second_at_x = p_get_first * math.pow(1 - gland_droprate, x - 1) * gland_droprate
		for y = 1, 10 do
			local p_get_first_and_get_second_at_x_and_get_third_at_y = p_get_first_and_get_second_at_x * math.pow(1 - gland_droprate, y - 1) * gland_droprate
			register_win(p_get_first_and_get_second_at_x_and_get_third_at_y, 1 + x + y + 1)
		end
		register_fail(p_get_first_and_get_second_at_x * math.pow(1 - gland_droprate, 10), 1 + x + 10)
	end
	register_fail(p_get_first * math.pow(1 - gland_droprate, 10), 1 + 10)

	register_fail(1 - p_get_first, 1)

--	X = win_turnsum + fail_turnsum + psum_fail * X
--	X = (win_turnsum + fail_turnsum) / (1 - psum_fail)

	-- turns to get one: 10
	-- turns to get two: 25.353399327876
	-- turns to get three: 48.92608642
	-- turns to kill queen: 49.92608642

	local orchard_turns = (win_turnsum + fail_turnsum) / (1 - psum_fail)
	return orchard_turns
end

function estimate_nuns_turns(plus_meat)
	local average_bandit_meat = math.max(0, 1000 * (100 + plus_meat) / 100)
	-- TODO?: compute precisely
	return 100000 / average_bandit_meat + 0.5
end

function estimate_beach_turns(plus_combat, barrels)
	local p_count = { 0, 0, 0, 0, 0, 0 }
	p_count[math.minmax(0, barrels, 5)] = 1
	local expected_turns = 0
	local function update(turn, p)
		expected_turns = expected_turns + turn * p_count[4] * p
		p_count[5] = p_count[5] + p_count[4] * p
		p_count[4] = p_count[4] * (1 - p) + p_count[3] * p
		p_count[3] = p_count[3] * (1 - p) + p_count[2] * p
		p_count[2] = p_count[2] * (1 - p) + p_count[1] * p
		p_count[1] = p_count[1] * (1 - p) + p_count[0] * p
		p_count[0] = p_count[0] * (1 - p)
	end
	local p_lfm = math.minmax(0, 0.1 + plus_combat / 100, 1)
	for turn = 1, 100 do
		if turn % 12 == 1 and turn >= 10 then
			update(turn, 1)
		else
			update(turn, p_lfm)
		end
	end
	return expected_turns
end

function estimate_junkyard_turns(banished_AMC)
	if not banished_AMC then
		return 2.8791090487968 * 4
	else
		return 2.2501205981669 * 4
	end
end

function estimate_dooks_turns(chaos_butterfly)
	if chaos_butterfly then
		return 11 + 3 * 5
	else
		return 11 + 3 * 10
	end
end

function estimate_can_copy_monster()
	-- TODO: Include other forms
	return have_item("Spooky Putty sheet") or have_item("Rain-Doh black box") or have_skill("Rain Man")
end

function estimate_available_pluscombatrate()
	-- TODO: Include other sources
	local sources = {
		have_skill("Musk of the Moose"),
		have_skill("Carlweather's Cantata of Confrontation"),
		have_item("portable cassette player"),
		get_automation_scripts().have_familiar("Jumpsuited Hound Dog"),
	}
	return table.sum(table.map(sources, function(x)
		if x then
			return 5
		else
			return 0
		end
	end))
end

function estimate_available_plusitem()
	-- TODO: Use a reasonable estimate
	return 100
end

function estimate_available_plusmeat()
	-- TODO: Use a reasonable estimate
	return 200
end

local function compute_lvl12_war_turns_needed(arena, junkyard, beach, orchard, nuns, dooks, sidequest_data, nuntrick, which_side)
	local name = ""
	local turns = 0
	local defeated = which_side == "hippy" and sidequest_data["Hippies defeated"] or sidequest_data["Frat boys defeated"]
	local kills_per_fight = 1
	local completed = {}
	local function sidequest(quest_letter, quest_turns, condition, required)
		if condition and defeated >= required and not completed[quest_letter] then
			name = name .. quest_letter
			turns = turns + quest_turns
			kills_per_fight = kills_per_fight * 2
			completed[quest_letter] = true
		end
	end
	while true do
		if which_side == "frat" then
			sidequest("Nun trick, N", sidequest_data["Nuns turns"], nuns and nuntrick, 0)
			sidequest("A", sidequest_data["Arena turns"], arena, 0)
			sidequest("J", sidequest_data["Junkyard turns"], junkyard, 0)
			sidequest("B", sidequest_data["Beach turns"], beach, 0)
			sidequest("O", sidequest_data["Orchard turns"], orchard, 64)
			sidequest("N", sidequest_data["Nuns turns"], nuns and not nuntrick, 192) -- CHECK: 191 or 192?
			sidequest("D", sidequest_data["Dooks turns"], dooks, 458)
		else
			sidequest("D", sidequest_data["Dooks turns"], dooks, 0)
			sidequest("N", sidequest_data["Nuns turns"], nuns, 0)
			sidequest("O", sidequest_data["Orchard turns"], orchard, 0)
			sidequest("B", sidequest_data["Beach turns"], beach, 64)
			sidequest("J", sidequest_data["Junkyard turns"], junkyard, 192)
			sidequest("A", sidequest_data["Arena turns"], arena, 458)
		end
		if defeated >= 1000 then
			break
		end
		turns = turns + 1
		defeated = defeated + kills_per_fight
	end
	if name == "" then
		name = "(none)"
	end
	return turns, name
end

local function lvl12_quest_optimizer()
	local sidequest_data = {}
	local sidequest_params_data = {}
	local function update_data_from_params()
		for which, _ in pairs(sidequest_data) do
			local v = tonumber(params[which])
			if v then
				sidequest_params_data[which] = v
				sidequest_data[which] = v
			end
		end
	end
	sidequest_data["+Item%"] = estimate_available_plusitem()
	sidequest_data["+Meat%"] = estimate_available_plusmeat()
	sidequest_data["+Combat%"] = estimate_available_pluscombatrate()
	sidequest_data["Banished AMC (0/1)"] = is_monster_banished("A.M.C. gremlin") and 1 or 0
	sidequest_data["barrels of gunpowder"] = count_item("barrel of gunpowder")
	sidequest_data["Copy nun trick (0/1)"] = estimate_can_copy_monster() and 1 or 0
	sidequest_data["chaos butterfly (0/1)"] = have_item("chaos butterfly") and 1 or 0
	sidequest_data["Frat boys defeated"] = (ascension["battlefield.kills.frat boy"] or {}).min or 0
	sidequest_data["Hippies defeated"] = (ascension["battlefield.kills.hippy"] or {}).min or 0
	update_data_from_params()
	sidequest_data["Arena turns"] = 0
	sidequest_data["Junkyard turns"] = estimate_junkyard_turns(sidequest_data["Banished AMC (0/1)"] ~= 0)
	sidequest_data["Beach turns"] = estimate_beach_turns(sidequest_data["+Combat%"], sidequest_data["barrels of gunpowder"])
	sidequest_data["Orchard turns"] = estimate_orchard_turns(sidequest_data["+Item%"])
	sidequest_data["Nuns turns"] = estimate_nuns_turns(sidequest_data["+Meat%"])
	sidequest_data["Dooks turns"] = estimate_dooks_turns(sidequest_data["chaos butterfly (0/1)"] ~= 0)
	update_data_from_params()

	local option_lines = {}
	local function editable_field(title, divider)
		local extra = ""
		local value = sidequest_params_data[title] or display_value(sidequest_data[title])
		if sidequest_params_data[title] and divider then
			extra = [[ class="tr_edited tr_divider"]]
		elseif sidequest_params_data[title] then
			extra = [[ class="tr_edited"]]
		elseif divider then
			extra = [[ class="tr_divider"]]
		end
		local function fixup(x)
			local u = make_href("/", { [x] = "" })
			return u:match([[^/%?(.+)=$]])
		end
		table.insert(option_lines, string.format([[<tr%s><td class="td_title">%s:</td><td class="td_value">%s</td><td><button onclick="update_lvl12_quest_optimizer_settings('%s')">Edit</button></td></tr>]], extra, title, value, fixup(title)))
	end
	editable_field("+Item%")
	editable_field("+Meat%")
	editable_field("+Combat%", true)
	editable_field("Banished AMC (0/1)")
	editable_field("barrels of gunpowder")
	editable_field("Copy nun trick (0/1)")
	editable_field("chaos butterfly (0/1)")
	editable_field("Frat boys defeated")
	editable_field("Hippies defeated", true)
	editable_field("Arena turns")
	editable_field("Junkyard turns")
	editable_field("Beach turns")
	editable_field("Orchard turns")
	editable_field("Nuns turns")
	editable_field("Dooks turns", true)
	table.insert(option_lines, string.format([[<tr><td>%s:</td><td>%s</td><td></td></tr>]], "Frat boys left", 1000 - sidequest_data["Frat boys defeated"]))
	table.insert(option_lines, string.format([[<tr class="tr_divider"><td>%s:</td><td>%s</td><td></td></tr>]], "Hippies left", 1000 - sidequest_data["Hippies defeated"]))
	local options = {}
	local nuntrick = sidequest_data["Copy nun trick (0/1)"] ~= 0
	for _, arena in ipairs { true, false } do
		for _, junkyard in ipairs { true, false } do
			for _, beach in ipairs { true, false } do
				for _, orchard in ipairs { true, false } do
					for _, nuns in ipairs { true, false } do
						for _, dooks in ipairs { true, false } do
							local turns, name = compute_lvl12_war_turns_needed(arena, junkyard, beach, orchard, nuns, dooks, sidequest_data, nuntrick, "frat")
							table.insert(options, { name = "Frat: " .. name, turns = turns })
							local turns, name = compute_lvl12_war_turns_needed(arena, junkyard, beach, orchard, nuns, dooks, sidequest_data, nuntrick, "hippy")
							table.insert(options, { name = "Hippy: " .. name, turns = turns })
						end
					end
				end
			end
		end
	end
	table.sort(options, function(a, b)
		if a.turns ~= b.turns then
			return a.turns < b.turns
		else
			return a.name < b.name
		end
	end)
	for _, x in ipairs(options) do
		table.insert(option_lines, string.format([[<tr><td>%s</td><td>%s</td><td></td></tr>]], x.name, display_value(x.turns)))
	end

	sidequest_params_data.pwd = session.pwd
	return [[
<script language="javascript">
function update_lvl12_quest_optimizer_settings(title) {
	var N = prompt('How many?')
	if (N >= -1000 && N <= 1000) {
		top.mainpane.location.href = ("]] .. quest_optimizer_href(sidequest_params_data) .. [[&" + title + "=" + N)
	}
}
</script>
<h2>Level 12 war quest</h2>
<table id="lvl12quest">
]] .. table.concat(option_lines, "\n") .. [[
</table>
]]
end

quest_optimizer_href = add_automation_script("custom-quest-optimizer", function()
	local sections = {}

	table.insert(sections, lvl12_quest_optimizer())

	local contents = make_kol_html_frame(table.concat(sections, "<br>"), "Quest optimizer (preview)")

	return [[<html>
<head>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/window.20111231.js"></script>
<style>
#lvl12quest { border-collapse: collapse }
#lvl12quest td { padding: 0px 5px }
.tr_divider td { border-bottom: thin solid black }
.tr_edited .td_value { background-color: mediumaquamarine }
</style>
</head>
<body>]] .. contents .. [[</body>
</html>]], requestpath
end)
