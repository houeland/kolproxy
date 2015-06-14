--v2.5a
-- Displays information about a monster in combat
-- Includes:
--    Current and Original HP, Atk, Def, Meat, Element, HP meter
--    Phylum Treasure when you have a phylum caring familiar out (and phylum on picture tooltip)
--    Item Drop %s

register_setting {
	name = "show monster stats",
	description = "Show monster stat estimates (HP, attack, defense, item drops. <b>Not always accurate</b>)",
	group = "fight",
	default_level = "detailed",
}

register_setting {
	name = "show monster hp meter",
	description = "Show monster HP bar (<b>Not always accurate</b>)",
	group = "fight",
	default_level = "standard",
}

local function should_show_phylum()
	return familiar("Pair of Stomping Boots") or familiar("Happy Medium") or have_item("DNA extraction syringe")
end

local function make_monster_hp_meter(monster, width)
	local data = monster.Stats
	if not data then return "" end
	if not tonumber(data.HP) or not tonumber(data.ModHP) then return "" end

	if not width then width = 100 end
	local hpFrac = math.max(0, data.ModHP) / data.HP

	local hpColor = string.format("#%02X%02X00", 210 * (1 - math.max(0, hpFrac - 0.5) * 2), 210 * math.min(1, hpFrac * 2))

	tooltip = math.max(0, data.ModHP) .. [[&nbsp;/&nbsp;]] .. data.HP

	return [[<div class="monsterHP meter" style="width: ]]..width..[[px;" title="]]..tooltip..[[" ><div style="width: ]]..math.floor(hpFrac * width)..[[px; background-color: ]]..hpColor..[[;" class="meter monsterHPColor"><div class="meter shading"></div></div></div>]]
end

local function formatMonsterItems(monster, bonuses)
	local data = monster.Items
	if not data then return "" end

	local plusitem = bonuses["Item Drops from Monsters"]

	local itemdatalist = {}
	for _, value in ipairs(data) do
		local chance = (value.dropratepercent or 0) * (1 + plusitem / 100)
		chance = math.max(math.min(chance, 100), 0)
		chance = tonumber(round_down(chance, 2))

		local dropinfo = ""
		if chance > 0 then
			dropinfo = chance .. "%"
		else
			dropinfo = "??"
		end

		local extra = {}
		for _, x in ipairs { "no pickpocket", "conditional", "pickpocket only" } do
			if value[x] then
				table.insert(extra, x)
			end
		end
		if extra[1] then
			dropinfo = dropinfo .. " (" .. table.concat(extra, ", ") .. ")"
		end

		table.insert(itemdatalist, "<div><span style='margin-right:5px;'>" .. value.Name .. ":</span><span>" .. dropinfo .. "</span></div>")
	end
	return "<div style='float:left;'><div style='font-size:12px;'>Drops</div>" .. table.concat(itemdatalist) .. "</div>"
end

local function formatMonsterStats(monster, bonuses)
	local data = monster.Stats
	if not data then return "" end

	local statData = "<div style='margin-right:10px;float:left;'>"
	if monster.manuel_stats then
		statData = statData .. "<div style='font-size:12px;'>Stats</div>"
	else
		statData = statData .. "<div style='font-size:12px;'>Estimate</div>"
	end

	local function formatStat(name, value, color, tooltip)
		if not value or value == "" then return end

		local toolTipHTML = ""
		if tooltip then
			toolTipHTML = "<span class='tooltip'>" .. tooltip .. "</span>"
		end

		statData = statData .. "<div class='stat' style='color: " .. (color or "black") .. ";'><span style='margin-right:5px;'>" .. name .. ":</span><span>" .. display_value(value) .. "</span>"..toolTipHTML.."</div>"
	end

	local function formatStatPercent(name, value, color, tooltip)
		if not value or value == 0 then return end
		if not color and value >= 90 then
			color = "red"
		end
		return formatStat(name, value .. "%", color, tooltip)
	end

	formatStat("HP", data.ModHP, nil, "Starting HP: " .. display_value(data.HP or "?"))
	formatStat("Atk", data.ModAtk, nil, "Starting Atk: " .. display_value(data.Atk or "?"))
	formatStat("Def", data.ModDef, nil, "Starting Def: " .. display_value(data.Def or "?"))
	local meattooltip = nil
	if tonumber(data.Meat) then
		local meat_bonus_percent = bonuses["Meat from Monsters"]
		local lo, hi = get_possible_fight_meat_minmax(tonumber(data.Meat), meat_bonus_percent)
		meattooltip = string.format("Drop range: %d to %d", lo, hi)
	end
	formatStat("Meat", data.Meat, nil, meattooltip)
	formatStat("Element", data.Element, element_color(data.Element), "Weak against: " .. table.concat({ get_elemental_weaknesses(data.Element) }, ", ") )
	local inittooltip = nil
	if tonumber(data.Init) and tonumber(data.Atk) then
		local init = (100 - tonumber(data.Init)) + bonuses["Combat Initiative"]
		init = init + math.max(0, buffedmainstat() - tonumber(data.Atk)) - compute_monster_initiative_bonus(bonuses["Monster Level"])
		inittooltip = string.format("%d%% chance to get the jump on monster", init)
	end
	formatStat("Init", data.Init, nil, inittooltip)

	if should_show_phylum() and data.Phylum then
		statData = statData .. [[<div onclick='togglePhylum();' style='cursor:hand;' class='stat'><span style='margin-right:5px;'><span id='phylumToggle'>[+]</span> Phylum:</span><span>]] .. data.Phylum .. [[</span></div>]]
	end

	formatStat("Watch out for", data.WatchOut)
	if (data.physicalresistpercent or 0) ~= 0 or (data.elementalresistpercent or 0) ~= 0 then
		if data.physicalresistpercent == data.elementalresistpercent then
			formatStatPercent("Resist", data.physicalresistpercent, nil, "Reduces physical and elemental damage")
		else
			formatStatPercent("Physical resist", data.physicalresistpercent)
			formatStatPercent("Elemental resist", data.elementalresistpercent)
		end
	end

	if data.staggerimmune then
		formatStatPercent("Stagger resist", 100, nil, "Monster is immune to stun and stagger effects and will attack every round")
	elseif data.stunresistpercent then
		formatStatPercent("Stun resist", data.stunresistpercent, nil, "Chance each round to break out of stuns early")
	end

	if data.reflectspells then
		formatStat("Spells", "Reflected", "red", "Spells cast will damage the player instead of the monster")
	end

	if data.preventcombatskill then
		formatStat("Skills", "Blocked", "red", "Any skills used will be blocked by the monster and do nothing")
	end

	if data.blockcombatitems then
		formatStat("Combat items", "Blocked", "red", "Any combat items used will be blocked by the monster and do nothing")
	end

	statData = statData .. "</div>"
	return statData
end

local function formatMonsterPhylumTreasure(monster)
	local data = monster.Stats

	if not should_show_phylum() or not data.Phylum then return "" end

	local treasure = get_phylum_treasure(data.Phylum)

	local function effectTurnsString(name, duration)
		if name ~= "none" then
			return "Effect: " .. name .. " (" .. duration .. " turns)"
		else
			return ""
		end
	end

	local html = [[<div style='display: none; font-size: 12px; color: #666; margin: 0px auto; text-align: left;' id='phylumData'>]]
	if familiar("Pair of Stomping Boots") then
		local t = treasure.paste
		html = html .. [[<div style='width:200px;margin:0px auto;'>]]..
			"Release the Boots will generate:<br/><br/>" ..
			"<span style='font-weight:bold;'>"..t.name .. "</span><br />" ..
			"Level required: " .. t.quality["level requirement"].."<br />" ..
			"Adventures: " .. t.quality["min adventures"] .. "-" .. t.quality["max adventures"] .."<br />" ..
			effectTurnsString(t.effect["name"], t.quality["effect duration"]) .. "<br />"
		if t.effect.summary ~= "none" then
			html = html .. "Summary: " .. t.effect.summary
		end
		html = html .. [[</div>]]
	elseif familiar("Happy Medium") then
		local function generateSiphonBooze(boozeData)
			return [[<div style="float:left;margin-right:10px;width:200px;">]]..
				"<span style='font-weight:bold;'>"..boozeData.name.."</span><br />" ..
				"Type: " .. boozeData.quality["quality"].."<br />" ..
				"Level required: " .. boozeData.quality["level requirement"].."<br />" ..
				"Adventures: " .. boozeData.quality["min adventures"] .. "-" .. boozeData.quality["max adventures"] .."<br />" ..
				effectTurnsString(boozeData.effect["name"], boozeData.quality["effect duration"]) .. "<br />" ..
				"Summary: " .. boozeData.effect["summary"]..[[</div>]]
		end
		local t = treasure.siphon
		html = html .. "Siphon Spirits will generate:<br/><br/>" .. generateSiphonBooze(t.blue) .. generateSiphonBooze(t.orange) .. generateSiphonBooze(t.red)
	end
	html = html .. [[<p style="clear:both;"></p></div>]]
	return html
end

local function adjustStat(originalStat, modifier, maxval, adjust)
	local returnVal = originalStat
	if modifier == nil then return returnVal end
	if not returnVal then returnVal = "?" end

	if type(originalStat) == "number" then
		returnVal = math.floor(originalStat * (adjust or 1.0)) - (modifier or 0)
		returnVal = math.max(maxval or returnVal, returnVal)
	elseif modifier ~= 0 then
		returnVal = tostring(returnVal) .. " (" .. -modifier ..")"
	end

	return returnVal
end

function getCurrentFightMonster()
	-- something is screwed up if this returns nil
	local current_fight = fight["currently fighting"]
	if not current_fight then return nil end

	local monster = current_fight.data

	if monster then
		monster.Stats.ModHP = adjustStat(monster.Stats.HP, tonumber(fight["damage inflicted"]), nil, nil)
		monster.Stats.ModAtk = adjustStat(monster.Stats.Atk, tonumber(fight["attack decrease"]), 1, nil)
		monster.Stats.ModDef = adjustStat(monster.Stats.Def, tonumber(fight["defense decrease"]), 1, nil)
	end

	local function tonum(x)
		if type(x) == "string" then
			x = x:gsub(",", "")
			return tonumber(x)
		else
			return x
		end
	end

	local first_serverdata = fight["currently fighting first serverdata"]
	if first_serverdata then
		monster = monster or {}
		monster.Stats = monster.Stats or {}
		monster.Stats.HP = tonum(first_serverdata.hp)
		monster.Stats.Atk = tonum(first_serverdata.off)
		monster.Stats.Def = tonum(first_serverdata.def)
	end

	local current_serverdata = fight["currently fighting current serverdata"]
	if current_serverdata then
		monster = monster or {}
		monster.manuel_stats = true
		monster.Stats = monster.Stats or {}
		monster.Stats.ModHP = tonum(current_serverdata.hp)
		monster.Stats.ModAtk = tonum(current_serverdata.off)
		monster.Stats.ModDef = tonum(current_serverdata.def)
	end

	local extra_serverdata = fight["currently fighting extra serverdata"]
	if extra_serverdata then
		monster = monster or {}
		monster.Stats = monster.Stats or {}
		monster.Stats.Phylum = extra_serverdata.phylum or monster.Stats.Phylum
		monster.Stats.Element = extra_serverdata.element or monster.Stats.Element
	end

	return monster
end

add_printer("/fight.php", function()
	if setting_enabled("show monster stats") then
		if text:contains("Enemy's Attack Power") then
			text = text:gsub([[<td><table><tr><td width=30><img src=http://images.kingdomofloathing.com/itemimages/nicesword.gif [^>]*"Enemy's Attack Power"[^>]*>.-</table></td>]], "")
		end

		text = text:gsub([[</head>]], [[
<style>
	.stat {
		position: relative;
	}

	.stat .tooltip {
		border: 1px solid #666;
		color: #666;
		background-color: #f5f5f5;
		padding: 3px;
		display: none;
		border-radius: 2px;
	}

	.stat:hover .tooltip {
		display: block;
		position: absolute;
		left: 10px;
		top: 17px;
		z-index: 99;
		width: 100px;
		box-shadow: 3px 3px 4px #777;
	}
</style>
<script type="text/javascript">
	function togglePhylum() {
		$('#phylumData').slideToggle();
		if ($('#phylumToggle').html() == '[+]') $('#phylumToggle').html('[-]')
		else $('#phylumToggle').html('[+]')
	}
</script>%0]])
		local monster = getCurrentFightMonster()

		if monster then
			text = text:gsub([[(id=['"]monname['"].-)(</td>)]], function(prefix, suffix)
				local bonuses = estimate_current_bonuses() + estimate_fight_page_bonuses(text)
				return prefix .. [[<div style='font-size: 11px; color: #555; margin-top: 5px;'>]] .. formatMonsterStats(monster, bonuses) .. formatMonsterItems(monster, bonuses) .. [[</div>]] .. suffix
			end)

			if monster.Stats.Phylum then
				text = text:gsub([[img id='monpic']], [[%0 title='Phylum: ]]..monster.Stats.Phylum..[[']])
				text = text:gsub([[id=['"]monname['"].-</table>]], [[%0]] .. formatMonsterPhylumTreasure(monster))
			end

			if ascensionpath("Bees Hate You") then
				local boldedName = get_monstername():gsub("[bB]", [[<span style="font-weight: bold; color: orange;">%0</span>]])
				text = text:gsub(get_monstername(), boldedName)
			end
		end
	end

	if setting_enabled("show monster hp meter") then
		text = text:gsub([[</head>]], [[
<style>
	.meter {
		height:7px;
	}

	.monsterHP {
		border:1px solid #888;
		margin:0px auto;
		margin-top:5px;
		border-radius: 2px;
		-moz-border-radius: 2px;
		position:relative;
		font-size:10px;
		background:#f9f9f9;
	}

	.monsterHPColor {
		float:left;
	}

	.shading {
		-o-background-size: 100%% 100%%;
		-moz-background-size: 100%% 100%%;
		-webkit-background-size: 100%% 100%%;
		background-size: 100%% 100%%;
		/* Recent browsers */
		background: -webkit-gradient(
			linear,
			left top, left bottom,
			from(rgba(255,255,255,0.75)),
			to(rgba(255,255,255,0) 70%%)
		);
		background: -webkit-linear-gradient(
			top,
			rgba(255,255,255,0.75),
			rgba(255,255,255,0) 70%%
		);
		background: -moz-linear-gradient(
			top,
			rgba(255,255,255,0.75),
			rgba(255,255,255,0) 70%%
		);
		background: -o-linear-gradient(
			top,
			rgba(255,255,255,0.75),
			rgba(255,255,255,0) 70%%
		);
		background: linear-gradient(
			top,
			rgba(255,255,255,0.75),
			rgba(255,255,255,0) 70%%
		);
	}
</style>%0]])
		local monster = getCurrentFightMonster()
		if monster then
			local monpic = text:match([[<img id='monpic'.->]]) or text:match([[sorcblob.gif".->]])
			if monpic then
				local width = tonumber(monpic:match([[width=(%d+)]]))
				local hpmeter = make_monster_hp_meter(monster, width)
				text = text:gsub(monpic, [[%0]]..hpmeter)
			end
		end
	end
end)
