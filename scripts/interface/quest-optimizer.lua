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
	sidequest_data["Frat boys defeated"] = 0
	sidequest_data["+Meat%"] = 0
	update_data_from_params()
	sidequest_data["Arena turns"] = 0
	sidequest_data["Junkyard turns"] = 12
	sidequest_data["Beach turns"] = 50
	local orchard_turns = 50
	sidequest_data["Orchard turns"] = orchard_turns
	local average_bandit_meat = 1000 * (100 + sidequest_data["+Meat%"]) / 100
	sidequest_data["Nuns turns"] = 100000 / average_bandit_meat + 0.5
	sidequest_data["Dooks turns"] = 9 + 3 * 10
	if have_item("chaos butterfly") then
		sidequest_data["Dooks turns"] = 9 + 3 * 5
	end
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
	editable_field("Frat boys defeated")
	editable_field("+Meat%", true)
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
							for _, nuntrick in ipairs { true, false } do
								local name = ""
								local turns = 0
								local defeated = sidequest_data["Frat boys defeated"]
								local kills_per_fight = 1
								if nuntrick then
									name = name .. "Nun-trick, N"
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

								if nuntrick and not nuns then
								else
									table.insert(options, { name = name, turns = turns })
								end
							end
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
.tr_edited .td_value { background-color: orchid }
</style>
</head>
<body>]] .. contents .. [[</body>
</html>]], requestpath
end)
