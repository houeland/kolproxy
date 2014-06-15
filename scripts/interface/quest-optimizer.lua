function estimate_orchard_turns(plus_item)
	local gland_droprate = math.min(1, 0.1 * (100 + plus_item) / 100)

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
	local average_bandit_meat = 1000 * (100 + plus_meat) / 100
	-- TODO?: compute precisely
	return 100000 / average_bandit_meat + 0.5
end

function estimate_beach_turns(plus_combat, barrels)
	local p_lfm = 0.1 + plus_combat / 100
	return (5 - barrels) / p_lfm
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

local function lvl12_quest_optimizer()
	local options = {}
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
	sidequest_data["+Item%"] = 0
	sidequest_data["+Meat%"] = 0
	sidequest_data["+Combat%"] = 0
	sidequest_data["Banished AMC (0/1)"] = 0
	sidequest_data["barrels of gunpowder"] = count_item("barrel of gunpowder")
	sidequest_data["Copy nun trick (0/1)"] = 0
	sidequest_data["chaos butterfly (0/1)"] = have_item("chaos butterfly") and 1 or 0
	sidequest_data["Frat boys defeated"] = 0
	update_data_from_params()
	sidequest_data["Arena turns"] = 0
	sidequest_data["Junkyard turns"] = estimate_junkyard_turns(sidequest_data["Banished AMC (0/1)"] ~= 0)
	sidequest_data["Beach turns"] = estimate_beach_turns(sidequest_data["+Combat%"], sidequest_data["barrels of gunpowder"])
	sidequest_data["Orchard turns"] = estimate_orchard_turns(sidequest_data["+Item%"])
	sidequest_data["Nuns turns"] = estimate_nuns_turns(sidequest_data["+Meat%"])
	sidequest_data["Dooks turns"] = estimate_dooks_turns(sidequest_data["chaos butterfly (0/1)"] ~= 0)
	update_data_from_params()
	local nuntrick = sidequest_data["Copy nun trick (0/1)"] ~= 0

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
	editable_field("Frat boys defeated", true)
	editable_field("Arena turns")
	editable_field("Junkyard turns")
	editable_field("Beach turns")
	editable_field("Orchard turns")
	editable_field("Nuns turns")
	editable_field("Dooks turns", true)
	table.insert(option_lines, string.format([[<tr class="tr_divider"><td>%s:</td><td>%s</td><td></td></tr>]], "Frat boys left", 1000 - sidequest_data["Frat boys defeated"]))
	for _, arena in ipairs { true, false } do
		for _, junkyard in ipairs { true, false } do
			for _, beach in ipairs { true, false } do
				for _, orchard in ipairs { true, false } do
					for _, nuns in ipairs { true, false } do
						for _, dooks in ipairs { true, false } do
							local name = ""
							local turns = 0
							local defeated = sidequest_data["Frat boys defeated"]
							local kills_per_fight = 1
							if nuns and nuntrick then
								name = name .. "Nun trick, N"
								turns = turns + sidequest_data["Nuns turns"]
								kills_per_fight = kills_per_fight * 2
							end
							if arena then
								name = name .. "A"
								turns = turns + sidequest_data["Arena turns"]
								kills_per_fight = kills_per_fight * 2
							end
							if junkyard then
								name = name .. "J"
								turns = turns + sidequest_data["Junkyard turns"]
								kills_per_fight = kills_per_fight * 2
							end
							if beach then
								name = name .. "B"
								turns = turns + sidequest_data["Beach turns"]
								kills_per_fight = kills_per_fight * 2
							end

							while defeated < 64 do
								turns = turns + 1
								defeated = defeated + kills_per_fight
							end
							if orchard then
								name = name .. "O"
								turns = turns + sidequest_data["Orchard turns"]
								kills_per_fight = kills_per_fight * 2
							end

							while defeated < 191 do
								turns = turns + 1
								defeated = defeated + kills_per_fight
							end
							if nuns and not nuntrick then
								name = name .. "N"
								turns = turns + sidequest_data["Nuns turns"]
								kills_per_fight = kills_per_fight * 2
							end

							while defeated < 458 do
								turns = turns + 1
								defeated = defeated + kills_per_fight
							end
							if dooks then
								name = name .. "D"
								turns = turns + sidequest_data["Dooks turns"]
								kills_per_fight = kills_per_fight * 2
							end

							while defeated < 1000 do
								turns = turns + 1
								defeated = defeated + kills_per_fight
							end

							table.insert(options, { name = name, turns = turns })
						end
					end
				end
			end
		end
	end
	table.sort(options, function(a, b) return a.turns < b.turns end)
	for _, x in ipairs(options) do
		table.insert(option_lines, string.format([[<tr><td>%s</td><td>%s</td><td></td></tr>]], x.name, display_value(x.turns)))
	end

	sidequest_params_data.pwd = session.pwd
	return [[
<script language="javascript">
function update_lvl12_quest_optimizer_settings(title) {
	var N = prompt('How many?')
	if (N >= 0 && N <= 1000) {
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
