function __convert_table_to_json(tbl)
	local newtbl = {}
	for a, _ in pairs(tbl) do
		newtbl[tostring(a)] = tbl[a]
	end
	return newtbl
end

-- itznotyerzitz mine

add_choice_text("A Flat Miner", { -- choice adventure number: 18
	["Loot the dwarf's belongings"] = { getitem = "miner's pants" },
	["Hijack the Meat vein"] = { getitem = "7-Foot Dwarven mattock" },
	["Help the dwarf"] = { getmeat = 100 },
})

add_choice_text("100% Legal", { -- choice adventure number: 19
	["Demand loot"] = { getitem = "miner's helmet" },
	["Ask for ore"] = { getitem = "miner's pants" },
	["Say you'll keep quiet for free"] = { getmeat = 100 },
})

add_choice_text("See You Next Fall", { -- choice adventure number: 20
	["Give 'im the stick"] = { getitem = "miner's helmet" },
	["DOOOOON'T GIVE 'IM THE STICK!"] = { getitem = "7-Foot Dwarven mattock" },
	["Negotiate for a reward"] = { getmeat = 100 },
})

add_choice_text("More Locker Than Morlock", { -- choice adventure number: 556
	["Open the locka'"] = { text = "Get a piece of mining gear" },
	["Get to the choppa' (which is outside)"] = { leave_noturn = true },
})

add_warning {
	message = "You already have the mining outfit.",
	type = "warning",
	when = "ascension",
	zone = "Itznotyerzitz Mine",
	check = function()
		return not ascensionstatus("Aftercore") and have_item("7-Foot Dwarven mattock") and have_item("miner's helmet") and have_item("miner's pants")
	end,
}

add_processor("/mining.php", function()
	if not params.mine then return end
	if not text:contains("mining.php") then return end
	mine = params.mine:match("([0-9]+)")
	if mine then
		stateid = "mining.results." .. mine
		tbl = __convert_table_to_json(ascension[stateid] or {})
		tabletext = text:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
		if not tabletext then return end
		local id = -1
		for celltext in tabletext:gmatch([[<td[^>]*>(.-)</td>]]) do
			id = id + 1
			image, title, height, width = celltext:match([[<img src='(http://images.kingdomofloathing.com/otherimages/mine/[a-z0-9]+.gif)' alt='[^']+' title='([^']+)' border=0 height=(50) width=(50)>]])
			if image then
				if image:match("wall1111.gif") or image:match("wallsparkle") then
					tbl[tostring(id)] = nil
				end
			end
		end
		ascension[stateid] = tbl
	end
	which = query:match("which=([0-9]+)")
	resulttext = text:match([[<table *width=95%% *cellspacing=0 cellpadding=0><tr><td style="color: white;" align=center bgcolor=blue.-><b>Results:</b>(.-)<table *width=95%% *cellspacing=0 cellpadding=0><tr><td style="color: white;" align=center bgcolor=blue.-><b>]])
	if resulttext then
		img = resulttext:match([[<img src="http://images.kingdomofloathing.com/itemimages/([^"]+).gif"]])
		if mine and img then
			stateid = "mining.results." .. mine
			tbl = __convert_table_to_json(ascension[stateid] or {})
			tbl[tostring(which)] = img
			ascension[stateid] = tbl
		end
	end
end)

add_processor("/place.php", function()
	if params.action == "trappercabin" then
		local wantore = text:match([[some dagburned ([a-z]-) ore]]) or text:match([[bring me that cheese and ([a-z]-) ore]]) or text:match([[I can't fix the lift until you bring me that cheese and ([a-z]-) ore]])
		if wantore then
			session["trapper.ore"] = wantore
		end
	end
end)

local remap_id = nil
local remap_id_inverse = nil
local function init_remap()
	if remap_id then return end
	remap_id = {}
	remap_id_inverse = {}
	for y = 0, 5 do
		for x = 1, 6 do
			remap_id[8 + y * 8 + x] = y * 6 + x
			remap_id_inverse[y * 6 + x] = 8 + y * 8 + x
		end
	end
end

local function which_to_idx(which)
	init_remap()
	return remap_id[which]
end
mining_which_to_idx = which_to_idx

local function idx_to_which(idx)
	init_remap()
	return remap_id_inverse[idx]
end
mining_idx_to_which = idx_to_which

local function are_distant_sparkles_visible(minetext)
	local x = minetext:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
	local distant_sparkles_visible = false
	for celltext in x:gmatch([[<td[^>]*>(.-)</td>]]) do
		image, title, height, width = celltext:match([[<img src='(http://images.kingdomofloathing.com/otherimages/mine/[a-z0-9]+.gif)' alt='[^']+' title='([^']+)' border=0 height=(50) width=(50)>]])
		linkdata = celltext:match([[<a href='mining.php%?mine=[0-9]+&which=[0-9]+&pwd=[0-9a-f]+'>]])
		if image and not linkdata and image:match("wallsparkle") then
			distant_sparkles_visible = true
		end
	end
	return distant_sparkles_visible
end

local function get_minestr(minetext, foundtbl)
	-- TODO: loadstone
	local orechars = { aore = "2", core = "3", lore = "1", baconstone = "8", loadstone = "*" }
	local x = minetext:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
	local curtbl = {}
	local distant_sparkles_visible = are_distant_sparkles_visible(minetext)
	local which = -1
	for celltext in x:gmatch([[<td[^>]*>(.-)</td>]]) do
		which = which + 1
		image, title, height, width = celltext:match([[<img src='(http://images.kingdomofloathing.com/otherimages/mine/[a-z0-9]+.gif)' alt='[^']+' title='([^']+)' border=0 height=(50) width=(50)>]])
		linkdata = celltext:match([[<a href='mining.php%?mine=[0-9]+&which=[0-9]+&pwd=[0-9a-f]+'>]])
		if image then
			if linkdata then
				if title:contains("Promising") or image:contains("spark") then
					curtbl[which] = "!"
				else
					curtbl[which] = "0"
				end
			else
				if foundtbl[tostring(which)] then -- and alt == "Open Cavern"
					curtbl[which] = orechars[foundtbl[tostring(which)]] or "0"
				elseif not image:match("wall1111.gif") and not image:match("wallsparkle") then
					curtbl[which] = "0"
				elseif distant_sparkles_visible and not image:match("wallsparkle") then
					curtbl[which] = "0"
				else
					curtbl[which] = "?"
				end
			end
		end
	end

	local minestrtbl = {}
	for idx = 1, 24 do
		table.insert(minestrtbl, curtbl[idx_to_which(idx)])
	end
	return table.concat(minestrtbl)
end

function compute_mine_spoiler(minetext, foundtbl, wantore)
	local inputminestr = get_minestr(minetext, foundtbl)
	local pcond = compute_mine_aggregate_pcond(inputminestr)
	local values = compute_mine_aggregate_values(wantore, inputminestr, pcond)
	for idx = 25, 36 do
		pcond[idx] = { ["0"] = 1, ["1"] = 0, ["2"] = 0, ["3"] = 0, ["8"] = 0 }
	end
	return pcond, values
end

add_automator("/mining.php", function()
	if not session["trapper.ore"] and not session["trapper.visited"] then
		get_place("mclargehuge", "trappercabin")
		session["trapper.visited"] = true
	end
end)

local mining_ids = {
	 [9] = 0, [10] = 1, [11] = 0, [12] = 1, [13] = 0, [14] = 1,
	[17] = 1, [18] = 0, [19] = 1, [20] = 0, [21] = 1, [22] = 0,
	[25] = 0, [26] = 1, [27] = 0, [28] = 1, [29] = 0, [30] = 1,
	[33] = 1, [34] = 0, [35] = 1, [36] = 0, [37] = 1, [38] = 0,
	[41] = 0, [42] = 1, [43] = 0, [44] = 1, [45] = 0, [46] = 1,
	[49] = 1, [50] = 0, [51] = 1, [52] = 0, [53] = 1, [54] = 0,
}

add_printer("/mining.php", function()
	if not params.mine then return end
	if not text:contains("mining.php") then return end
	mine = params.mine:match("([0-9]+)")
	if mine then
		stateid = "mining.results." .. mine
		tbl = __convert_table_to_json(ascension[stateid] or {})
	else
		tbl = {}
	end
	local distant_sparkles_visible = are_distant_sparkles_visible(text)
	local orechars = { aore = "2", core = "3", lore = "1", baconstone = "8" }
	local pcond = nil
	local values = nil
	local best_value = 0
	local wantore = nil
	if tonumber(mine) == 1 then
		local trapper_wants = { asbestos = "2", chrome = "3", linoleum = "1" }
		wantore = trapper_wants[session["trapper.ore"]]
		if wantore then
			pcond, values = compute_mine_spoiler(text, tbl, wantore)
			local x = text:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
			for celltext in x:gmatch([[<td[^>]*>(.-)</td>]]) do
				local which = tonumber(celltext:match([[<a href='mining.php%?mine=[0-9]+&which=([0-9]+)&pwd=[0-9a-f]+'>]]))
				if which then
					best_value = math.max(best_value, values[which_to_idx(which)])
				end
			end
		end
	end
	text = text:gsub("</head>", [[
<style>
	table { border-collapse: collapse; }
	.validcell { background-color: rgba(0, 0, 0, 0.67); border: solid thin gray; }
	td.linkminecell { background-color: rgba(40, 40, 40, 0.67); }
	td.linkminecell:hover { background-color: rgba(150, 150, 150, 0.67); }
	td.linkminecell.recommended { background-color: rgba(20, 100, 20, 0.67); }
	td.linkminecell.recommended:hover { background-color: rgba(150, 200, 150, 0.67); }
</style>
%0]])
	text = text:gsub([[(<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>)(.-)(</table>)]], function(pre, tabletext, post)
		local which = -1
		tabletext = tabletext:gsub([[<td[^>]*>(.-)</td>]], function(celltext)
			which = which + 1
			mineclass = ""
			if mining_ids[which] then
				mineclass = " validcell"
			end
			chance = nil
			if wantore and pcond and pcond[which_to_idx(which)] and pcond[which_to_idx(which)][wantore] then
				chance = string.format("%2.0f%%", pcond[which_to_idx(which)][wantore] * 100)
			end
			image, title, height, width = celltext:match([[<img src='(http://images.kingdomofloathing.com/otherimages/mine/[a-z0-9]+.gif)' alt='[^']+' title='([^']+)' border=0 height=(50) width=(50)>]])
			linkdata = celltext:match([[<a href='mining.php%?mine=[0-9]+&which=[0-9]+&pwd=[0-9a-f]+'>]])
			if image then
				if linkdata then
					local linkcolor = ""
					local linktext = ""
					local bgstyle = ""
					if title:contains("Promising") or image:contains("spark") then
						linkcolor = "lightblue"
						linktext = chance or "?"
					else
						linkcolor = "darkorange"
						linktext = chance or "x"
					end
					bgstyle = [[background-image: url(']] .. image .. [['); background-repeat: no-repeat;]]
					if wantore and values and values[which_to_idx(which)] and values[which_to_idx(which)] > 0 and values[which_to_idx(which)] >= best_value - 0.0000001 then
						mineclass = mineclass .. " recommended"
						linkcolor = "lightgreen"
					end
					return [[<td class="linkminecell]]..mineclass..[[" style="height: ]] .. height .. [[px; width: ]] .. width .. [[px; ]] .. bgstyle .. [[">]] .. linkdata .. [[<center style="line-height: 50px;"><span style="color: ]] .. linkcolor .. [[;">]] .. linktext .. [[</span></center></a></td>]]
				else
					local background = [[background-image: url(']] .. image .. [['); background-repeat: no-repeat;]]
					if tbl[tostring(which)] then -- and alt == "Open Cavern"
						celldata = [[<center><img src="http://images.kingdomofloathing.com/itemimages/]] .. tbl[tostring(which)] .. [[.gif"></center>]]
						if wantore and orechars[tbl[tostring(which)]] == wantore then
							background = "background-color: green;"
						end
					elseif title:contains("Promising") or image:contains("spark") then
						celldata = [[<center><span style="color: lightblue;">]] .. (chance or "?") .. [[</span></center>]]
					elseif not image:match("wall1111.gif") then
						celldata = ""
					elseif distant_sparkles_visible then
						celldata = [[<center><span style="color: darkorange;">]] .. (chance or "") .. [[</span></center>]]
					else
						celldata = [[<center><span style="color: lightblue;">]] .. (chance or "") .. [[</span></center>]]
					end
					return [[<td class="minecell]]..mineclass..[[" style="height: ]] .. height .. [[px; width: ]] .. width .. [[px; ]] .. background .. [[">]] .. celldata .. [[</td>]]
				end
			else
				return false
			end
		end)
		return pre .. tabletext .. post
	end)
end)

-- goatlet

add_on_the_trail_warning("The Goatlet", "dairy goat")

-- extreme slope

-- TODO: Mark good choices

add_choice_text("Generic Teen Comedy Snowboarding Adventure", { -- choice adventure number: 17
	["Give him a pep-talk"] = { getitem = "eXtreme mittens" },
	["Give him some boarding tips"] = { getitem = "snowboarder pants" },
	["Offer to help him cheat"] = { getmeat = 200 },
})

add_choice_text("Saint Beernard", {
	["Help the heroic dog"] = { getitem = "snowboarder pants" },
	["Flee in terror"] = { getitem = "eXtreme scarf" },
	["Ask for some beer, first"] = { getmeat = 200 },
})

add_choice_text("Yeti Nother Hippy", {
	["Help the hippy"] = { getitem = "eXtreme mittens" },
	["Let irony take its course"] = { getitem = "eXtreme scarf" },
	["Negotiate his release"] = { getmeat = 200 },
})

add_choice_text("Duffel on the Double", {
	["Open the bag"] = "Get a piece of eXtreme Cold-Weather Gear",
	["Scram"] = { leave_noturn = true },
})

-- ninja snowmen

add_warning {
	message = "You need to have +combat% to encounter ninja snowman assassins.",
	type = "warning",
	when = "ascension",
	zone = "Lair of the Ninja Snowmen",
	check = function()
		return estimate_bonus("Monsters will be more attracted to you") <= 0
	end,
}

-- orc chasm

add_automator("/mountains.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if tonumber(params.orcs) == 1 then
		if text:contains("you are unable to get past them") then
			async_post_page("/forestvillage.php", { pwd = params.pwd, action = "untinker", whichitem = get_itemid("abridged dictionary") })
			text, url = get_page("/mountains.php", params)
		end
	end
end)

-- mt. noob

add_automator("/tutorial.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.action == "toot" then
		if text:contains("letter from King Ralph XI") then
			text, url = use_item_noajax("letter from King Ralph XI")()
		end
	end
end)

-- highlands

function estimate_twin_peak_effective_plusitem()
	local cur_item = estimate_bonus("Item Drops from Monsters") - estimate_current_familiar_bonuses()["Item Drops from Monsters"]
	local cur_food = estimate_bonus("Food Drops from Monsters") - estimate_current_familiar_bonuses()["Food Drops from Monsters"]
	return cur_item + cur_food
end

add_choice_text("Lost in the Great Overlook Lodge", function()
	local cur_item = estimate_twin_peak_effective_plusitem()
	local cur_init = estimate_bonus("Combat Initiative")
	local pantry_text = string.format([[<span style="color: %s">%s. Currently: %+d%%</span><br>%s]], cur_item >= 50 and "green" or "darkorange", "Requires +50% items from monsters", cur_item, "(+food% bonuses help here, but familiars giving +item% bonus are not included.)")
	return { -- choice adventure number: 606
		["Investigate Room 237"] = "Requires level 4 stench resistance",
		["Search the pantry"] = pantry_text,
		["Follow the faint sound of music"] = string.format([[<span style="color: %s">%s</span>]], have_item("jar of oil") and "green" or "darkorange", "Requires jar of oil (from using 12 bubblin' crude)"),
		["Wait -- who's that?"] = string.format([[<span style="color: %s">%s. Currently: %+d%%</span>]], cur_init >= 40 and "green" or "darkorange", "Requires +40% initiative", cur_init),
		["Leave the hotel"] = { leave_noturn = true },
	}
end)

add_choice_text("Cabin Fever", { -- choice adventure number: 618
	["A path is formed by laying one stone at a time."] = { text = "Keep trying to solve the mystery" },
	["Burn this mother-goddamning hotel to the ground."] = { text = "Skip the mystery and light the signal fire", good_choice = true },
})

add_processor("use item: A-Boo clue", function()
	if text:contains("A-Boo Peak") then
		ascension["zone.aboo peak.clue active"] = true
	end
end)

add_processor("/choice.php", function()
	if text:contains("The Horror...") then
		ascension["zone.aboo peak.clue active"] = nil
	end
end)

function predict_aboo_peak_banish(testhp, resists)
	local testhp = testhp or hp()
	local resists = resists or get_resistance_levels()
	local accumuldmg = { Cold = 0, Spooky = 0 }
	local accumulbanish = 0
	local nextbanish = 2
	local beatenup = false
	local msglines = {}
	for _, dmg in ipairs { 13, 25, 50, 125, 250 } do
		local dmg = table_apply_function(estimate_damage { Cold = dmg, Spooky = dmg, __resistance_levels = resists }, math.ceil)
		accumuldmg.Cold = accumuldmg.Cold + dmg.Cold
		accumuldmg.Spooky = accumuldmg.Spooky + dmg.Spooky
		if beatenup then
			local dmgtext = markup_damagetext(accumuldmg)
			table.insert(msglines, string.format("Failed: %d (%s + %s)", accumuldmg.Cold + accumuldmg.Spooky, dmgtext.Cold, dmgtext.Spooky))
		elseif accumuldmg.Cold + accumuldmg.Spooky < testhp then
			accumulbanish = accumulbanish + nextbanish
			nextbanish = nextbanish + 2
			local dmgtext = markup_damagetext(accumuldmg)
			table.insert(msglines, string.format("%d%%: %d (%s + %s)", accumulbanish, accumuldmg.Cold + accumuldmg.Spooky, dmgtext.Cold, dmgtext.Spooky))
		else
			accumulbanish = accumulbanish + 2
			beatenup = true
			local dmgtext = markup_damagetext(accumuldmg)
			table.insert(msglines, string.format("%d%% (beaten up): %d (%s + %s)", accumulbanish, accumuldmg.Cold + accumuldmg.Spooky, dmgtext.Cold, dmgtext.Spooky))
		end
		--print("DEBUG: accumuldmg", accumuldmg, "accumulbanish", accumulbanish)
	end
	return accumulbanish, accumuldmg, msglines
end

add_extra_ascension_adventure_warning(function(zoneid)
	if zoneid == 296 then
		if ascension["zone.aboo peak.clue active"] and not have_item("ten-leaf clover") then
			local accumulbanish, accumuldmg = predict_aboo_peak_banish()
			if accumulbanish < 30 then
				local dmgtext = markup_damagetext(accumuldmg)
				return string.format([[<p>You only have enough HP to lower haunting level by %s%% (max is 30%%).</p><p>Maximum reduction would require at least %s HP (taking %s + %s damage) or higher resistance.</p>]], accumulbanish, accumuldmg.Cold + accumuldmg.Spooky + 1, dmgtext.Spooky, dmgtext.Cold), "a-boo peak incomplete banish"
			end
		end
		if not ascensionpath("Bees Hate You") and not ascension["zone.aboo peak.clue active"] then
			local hauntedness = get_aboo_peak_hauntedness()
			if hauntedness > 2 and hauntedness - count_item("A-Boo clue") * 30 <= 0 then
				return "You can finish the peak if you fully complete your A-Boo clues.", "a-boo peak enough clues"
			end
		end
	end
end)

local aboo_peak_banish_href = add_automation_script("aboo-peak-banish", function()
	local accumulbanish, accumuldmg, msglines = predict_aboo_peak_banish()
	local dmgtext = markup_damagetext(accumuldmg)
	return string.format([[<p>You have enough HP to lower haunting level by %s%% (max is 30%%).</p><p>Maximum reduction requires at least %s HP (taking %s + %s damage) or higher resistance.</p><p>%s</p>]], accumulbanish, accumuldmg.Cold + accumuldmg.Spooky + 1, dmgtext.Spooky, dmgtext.Cold, table.concat(msglines, "<br>\n")), requestpath
end)

add_printer("/place.php", function()
	if params.whichplace == "highlands" then
		text = text:gsub([[</body>]], [[<center><a href="]] .. aboo_peak_banish_href { pwd = session.pwd } .. [[" style="color: green;">{ Check resistance level. }</a></center>%0]])
	end
end)

local aboo_peak_monster = {
	["Battlie Knight Ghost"] = true,
	["Claybender Sorcerer Ghost"] = true,
	["Dusken Raider Ghost"] = true,
	["Space Tourist Explorer Ghost"] = true,
	["Whatsian Commando Ghost"] = true,
}

local function get_hauntedness()
	local questlog_page = get_page("/questlog.php", { which = 7 })
	local hauntedness = questlog_page:match([[currently [0-9%%]+ haunted]])
	if not hauntedness then print("DEBUG questlog_page", questlog_page) end
	if not hauntedness and questlog_page:contains("You should keep clearing the ghosts out of A-Boo Peak so you can reach the signal fire.") then
		hauntedness = "No longer haunted."
	end
	if not hauntedness then
		async_get_place("highlands", "highlands_dude")
		questlog_page = get_page("/questlog.php", { which = 7 })
		hauntedness = questlog_page:match([[currently [0-9%%]+ haunted]])
	end
	if not hauntedness and questlog_page:contains("You should keep clearing the ghosts out of A-Boo Peak so you can reach the signal fire.") then
		hauntedness = "No longer haunted."
	end
	return hauntedness
end

function get_aboo_peak_hauntedness()
	local hauntedness = get_hauntedness()
	if hauntedness == "No longer haunted." then
		return 0
	elseif not hauntedness then
		return 100
	else
		return tonumber(hauntedness:match([[currently ([0-9]+)%% haunted]]))
	end
end

add_automator("/fight.php", function()
	if aboo_peak_monster[get_monstername()] and text:contains("<!--WINWINWIN-->") and not finished_mainquest() then
		local hauntedness = get_hauntedness()
		text = text:gsub("<!%-%-WINWINWIN%-%->", function(x) return x .. [[<p style="color: green">{ ]] .. (hauntedness or "Unknown hauntedness.") .. [[ }</p>]] end)
	end
end)

add_automator("/choice.php", function()
	if text:contains([[Adventure Again (A-Boo Peak)]]) and not finished_mainquest() then
		local hauntedness = get_hauntedness()
		text = text:gsub("</td></tr></table></center></td></tr><tr><td height=4>", function(y) return [[<p><center style="color: green">{ ]] .. (hauntedness or "Unknown hauntedness.") .. [[ }</center></p>]] .. y end, 1)
	end
end)

local oil_peak_monster = {
	["oil slick"] = true,
	["oil tycoon"] = true,
	["oil baron"] = true,
	["oil cartel"] = true,
}

local function get_pressure()
	local questlog_page = get_page("/questlog.php", { which = 1 })
	local pressure = questlog_page:match([[current pressure: [0-9.]+ &mu;B/Hg]]) or questlog_page:match([[The pressure is very low at this point.]]) or questlog_page:match([[You've lit the fire on Oil Peak.]])
	if not pressure then
		async_get_place("highlands", "highlands_dude")
		questlog_page = get_page("/questlog.php", { which = 1 })
		pressure = questlog_page:match([[current pressure: [0-9.]+ &mu;B/Hg]]) or questlog_page:match([[The pressure is very low at this point.]]) or questlog_page:match([[You've lit the fire on Oil Peak.]])
	end
	if pressure then
		local microbowies = tonumber(pressure:match([[current pressure: ([0-9.]+) &mu;B/Hg]]))
		if microbowies then
			pressure = pressure .. string.format(" (%.0f%%)", microbowies / 3.17)
		end
	end
	return pressure
end
--get_oil_peak_pressure = get_pressure

add_automator("/fight.php", function()
	if oil_peak_monster[get_monstername()] and text:contains("<!--WINWINWIN-->") and not finished_mainquest() then
		local pressure = get_pressure()
		text = text:gsub("<!%-%-WINWINWIN%-%->", function(x) return x .. [[<p style="color: green">{ ]] .. (pressure or "Unknown pressure.") .. [[ }</p>]] end)
	end
end)

add_automator("use item: A-Boo clue", function()
	if not setting_enabled("automate costly tasks") then return end
	if not have_item("ten-leaf clover") then
		local accumulbanish, accumuldmg = predict_aboo_peak_banish()
		if accumulbanish >= 30 then
			text, url = autoadventure { zoneid = get_zoneid("A-Boo Peak"), specialnoncombatfunction = function(advtitle, choicenum)
				if advtitle == "The Horror..." then
					return "", 1
				end
			end }
		end
	end
end)

-- chateau

add_warning {
	message = "Are you sure? You have no free rests left.",
	whichplace = "chateau",
	type = "extra",
	check = function()
		if not params.action then return end
		if not params.action:contains("_rest") then return end
		local pt = get_place("chateau")
		return not pt:contains("restlabelfree")
	end,
}
