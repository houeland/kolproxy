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

add_processor("/mining.php", function()
	if not params.mine then return end
	if not text:contains("mining.php") then return end
	mine = params.mine:match("([0-9]+)")
	if mine then
		stateid = "mining.results." .. mine
		tbl = ascension[stateid] or {}
		tabletext = text:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
		if not tabletext then return end
		local id = -1
		for celltext in tabletext:gmatch([[<td[^>]*>(.-)</td>]]) do
			id = id + 1
			image, title, height, width = celltext:match([[<img src='(http://images.kingdomofloathing.com/otherimages/mine/[a-z0-9]+.gif)' alt='[^']+' title='([^']+)' border=0 height=(50) width=(50)>]])
			if image then
				if image:match("wall1111.gif") or image:match("wallsparkle") then
					tbl[id] = nil
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
			tbl = ascension[stateid] or {}
			tbl[tonumber(which)] = img
			ascension[stateid] = tbl
		end
	end
end)

add_processor("/place.php", function()
	if params.action == "trappercabin" then
		local wantore = text:match([[some dagburned ([a-z]-) ore]]) or text:match([[bring me that cheese and ([a-z]-) ore]])
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

local function idx_to_which(idx)
	init_remap()
	return remap_id_inverse[idx]
end

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
				if foundtbl[which] then -- and alt == "Open Cavern" 
					curtbl[which] = orechars[foundtbl[which]] or "0"
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

local function compute_mine_spoiler(minetext, foundtbl, wantore)
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
		get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
		session["trapper.visited"] = "yes"
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
		tbl = ascension[stateid] or {}
	else
		tbl = {}
	end
	local distant_sparkles_visible = are_distant_sparkles_visible(text)
	local orechars = { aore = "2", core = "3", lore = "1", baconstone = "8" }
	local pcond = nil
	local values = nil
	local best_value = 0
	local wantore = nil
	if tonumber(mine) == 1 and setting_enabled("enable experimental implementations") then
		local trapper_wants = { asbestos = "2", chrome = "3", linoleum = "1" }
		wantore = trapper_wants[session["trapper.ore"]]
		if wantore then
			pcond, values = compute_mine_spoiler(text, tbl, wantore)
			local x = text:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
			for celltext in x:gmatch([[<td[^>]*>(.-)</td>]]) do
				which = tonumber(celltext:match([[<a href='mining.php%?mine=[0-9]+&which=([0-9]+)&pwd=[0-9a-f]+'>]]))
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
					if tbl[which] then -- and alt == "Open Cavern" 
						celldata = [[<center><img src="http://images.kingdomofloathing.com/itemimages/]] .. tbl[which] .. [[.gif"></center>]]
						if wantore and orechars[tbl[which]] == wantore then
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

-- add_choice_text("Between a Rock and Some Other Rocks", { -- choice adventure number: 162
-- 	["Help the miners clear the rocks away"] = "Unlock the goatlet",
-- 	["Screw these rocks, I'm gonna roll out"] = { leave_noturn = true },
-- })

add_ascension_zone_check(271, function()
	if buff("On the Trail") then
		local trailed = retrieve_trailed_monster()
		if trailed ~= "dairy goat" then
			return "You are trailing '" .. tostring(trailed) .. "' when you might want to sniff a dairy goat."
		end
	end
end)

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

add_choice_text("Lost in the Great Overlook Lodge", { -- choice adventure number: 606
	["Investigate Room 237"] = "Requires level 4 stench resistance",
	["Search the pantry"] = "Requires +50% items from monsters (not counting familiar)",
	["Follow the faint sound of music"] = "Requires jar of oil (from using 12 bubblin' crude)",
	["Wait -- who's that?"] = "Requires +40% initiative",
	["Leave the hotel"] = { leave_noturn = true },
})

add_choice_text("Cabin Fever", { -- choice adventure number: 618
	["A path is formed by laying one stone at a time."] = { text = "Keep trying to solve the mystery" },
	["Burn this mother-goddamning hotel to the ground."] = { text = "Skip the mystery and light the signal fire", good_choice = true },
})

local function predict_aboo_peak_banish()
	local resists = get_resistance_levels()
	local accumuldmg = { cold = 0, spooky = 0 }
	local accumulbanish = 0
	local nextbanish = 2
	local beatenup = false
	for _, dmg in ipairs { 13, 25, 50, 125, 250 } do
		local dmg = table_apply_function(estimate_damage { cold = dmg, spooky = dmg, __resistance_levels = resists }, math.ceil)
		accumuldmg.cold = accumuldmg.cold + dmg.cold
		accumuldmg.spooky = accumuldmg.spooky + dmg.spooky
		if beatenup then
		elseif accumuldmg.cold + accumuldmg.spooky < hp() then
			accumulbanish = accumulbanish + nextbanish
			nextbanish = nextbanish + 2
		else
			accumulbanish = accumulbanish + 2
			beatenup = true
		end
--		print("DEBUG: accumuldmg", accumuldmg, "accumulbanish", accumulbanish)
	end
	return accumulbanish, accumuldmg
end

add_extra_ascension_adventure_warning(function(zoneid)
	if zoneid == 296 and have_item("A-Boo clue") and not have_item("ten-leaf clover") then
		local accumulbanish, accumuldmg = predict_aboo_peak_banish()
		if accumulbanish < 30 then
			local dmgtext = markup_damagetext(accumuldmg)
			return string.format([[<p>You only have enough HP to lower haunting level by %s%% (max is 30%%).</p><p>Maximum reduction would require at least %s HP (taking %s + %s damage) or higher resistance.</p>]], accumulbanish, accumuldmg.cold + accumuldmg.spooky + 1, dmgtext.spooky, dmgtext.cold), "a-boo peak incomplete banish"
		end
	end
end)

local aboo_peak_banish_href = add_automation_script("aboo-peak-banish", function()
	local accumulbanish, accumuldmg = predict_aboo_peak_banish()
	local dmgtext = markup_damagetext(accumuldmg)
	return string.format([[<p>You have enough HP to lower haunting level by %s%% (max is 30%%).</p><p>Maximum reduction requires at least %s HP (taking %s + %s damage) or higher resistance.</p>]], accumulbanish, accumuldmg.cold + accumuldmg.spooky + 1, dmgtext.spooky, dmgtext.cold), requestpath
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
	local questlog_page = get_page("/questlog.php", { which = 1 })
	local hauntedness = questlog_page:match([[It is currently [0-9%%]+ haunted.]])
	if not hauntedness and questlog_page:contains("You should keep clearing the ghosts out of A-Boo Peak so you can reach the signal fire.") then
		hauntedness = "No longer haunted."
	end
	if not hauntedness then
		async_get_page("/place.php", { whichplace = "highlands", action = "highlands_dude" })
		questlog_page = get_page("/questlog.php", { which = 1 })
		hauntedness = questlog_page:match([[It is currently [0-9%%]+ haunted.]])
	end
	if not hauntedness and questlog_page:contains("You should keep clearing the ghosts out of A-Boo Peak so you can reach the signal fire.") then
		hauntedness = "No longer haunted."
	end
	return hauntedness
end

add_automator("/fight.php", function()
	if aboo_peak_monster[monster_name:gsub("^a ", "")] and text:contains("<!--WINWINWIN-->") and not freedralph() then
		local hauntedness = get_hauntedness()
		text = text:gsub("<!%-%-WINWINWIN%-%->", function(x) return x .. [[<p style="color: green">{ ]] .. (hauntedness or "Unknown hauntedness.") .. [[ }</p>]] end)
	end
end)

add_automator("/choice.php", function()
	if text:contains([[Adventure Again (A-Boo Peak)]]) and not freedralph() then
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
	local pressure = questlog_page:match([[The pressure is currently [0-9.]+ microbowies per Mercury.]]) or questlog_page:match([[The pressure is very low at this point.]]) or questlog_page:match([[You've lit the fire on Oil Peak.]])
	if not pressure then
		async_get_page("/place.php", { whichplace = "highlands", action = "highlands_dude" })
		questlog_page = get_page("/questlog.php", { which = 1 })
		pressure = questlog_page:match([[The pressure is currently [0-9.]+ microbowies per Mercury.]]) or questlog_page:match([[The pressure is very low at this point.]]) or questlog_page:match([[You've lit the fire on Oil Peak.]])
	end
	if pressure then
		local microbowies = tonumber(pressure:match([[currently ([0-9.]+) microbowies]]))
		if microbowies then
			pressure = pressure:gsub("Mercury", function(x) return x .. string.format(" (%.0f%%)", microbowies / 3.17) end)
		end
	end
	return pressure
end

add_automator("/fight.php", function()
	if oil_peak_monster[monster_name:gsub("^an ", "")] and text:contains("<!--WINWINWIN-->") and not freedralph() then
		local pressure = get_pressure()
		text = text:gsub("<!%-%-WINWINWIN%-%->", function(x) return x .. [[<p style="color: green">{ ]] .. (pressure or "Unknown pressure.") .. [[ }</p>]] end)
	end
end)
