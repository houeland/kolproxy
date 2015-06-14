-- add_processor("/fight.php", function()
-- 	pattern = "<center><table class=\"item\" style=\"float: none\" rel=\"[^\"]*\"><tr><td><img src=\"http://images.kingdomofloathing.com/itemimages/[^\"]+.gif\" alt=\"([^\"]*)\" title=\"([^\"]*)\" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire an item: <b>([^<]+)</b></td></tr></table></center>"
-- 	for alt, title, item in text:gmatch(pattern) do
--~ 		print("item drop", alt, title, 1, item)
-- 	end
-- 	pattern = "<center><table class=\"item\" style=\"float: none\" rel=\"[^\"]*\"><tr><td><img src=\"http://images.kingdomofloathing.com/itemimages/[^\"]+.gif\" alt=\"([^\"]*)\" title=\"([^\"]*)\" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire <b>([0-9]+) ([^<]+)</b></td></tr></table></center>"
-- 	for alt, title, amount, item in text:gmatch(pattern) do
--~ 		print("item drop", alt, title, amount, item)
-- 	end
-- 	pattern = "<center><table class=\"item\" style=\"float: none\" rel=\"[^\"]*\"><tr><td><img src=\"http://images.kingdomofloathing.com/itemimages/[^\"]+.gif\" alt=\"([^\"]*)\" title=\"([^\"]*)\" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire <b>(11) ([^<]+)</b><br>%(That's ridiculous.  It's not even funny.%)</td></tr></table></center>"
-- 	for alt, title, amount, item in text:gmatch(pattern) do
--~ 		print("item drop", alt, title, amount, item)
-- 	end
-- end)

add_printer("/fight.php", function()
	text = text:gsub([[(<center><Table><tr><td><img src="http://images.kingdomofloathing.com/itemimages/mp.gif" height=30 width=30></td><td valign=center class=effect>)(You gain )([0-9,]+)( M[a-z]+ Points*.)(</td></tr></table></center>)]], [[%1<span style="color: darkblue">%2%3%4</span>%5]])
	text = text:gsub([[(<center><table><tr><td><img src="http://images.kingdomofloathing.com/itemimages/hp.gif" height=30 width=30></td><td valign=center class=effect>)(You gain )([0-9,]+)( hit points*.)(</td></tr></table></center>)]], [[%1<span style="color: darkred">%2%3%4</span>%5]])
end)


add_printer("/fight.php", function()
	local combat_round = nil
	for x in text:gmatch("var onturn = ([0-9]+);") do
		combat_round = tonumber(x)
	end
	if combat_round then
		text = text:gsub("(<b>)(Combat)(!</b>)", "%1%2 round " .. tostring(combat_round) .. "%3")
	end

	awesome_monsters = {
		["gaudy pirate"] = "gaudy key",
		["zombie waltzers"] = "dance card",
		["blur"] = "drum machine",
		["rampaging adding machine"] = "64735 scroll",
		["cleanly pirate"] = "rigging shampoo",
		["creamy pirate"] = "ball polish",
		["curmudgeonly pirate"] = "mizzenmast mop",
		["dairy goat"] = "goat cheese",
		["Brainsweeper"] = "disembodied brain",
		["Blooper"] = "white pixel",
		["tomb rat"] = "tomb ratchet",
		["lobsterfrogman"] = "barrel of gunpowder",
		["Hellion"] = "hellion cube",
		["dirty old lihc"] = "",
		["rampaging adding machine"] = "",
		["Astronomer"] = "star chart",
	}

	-- yossarian's tools / gremlins, TODO-future: move to lvl12 zone file
	local drop_uncertainty = {}
	if fight["gremlin.has tool"] == "yes" then
		awesome_monsters["batwinged gremlin"] = "molybdenum hammer"
		awesome_monsters["erudite gremlin"] = "molybdenum crescent wrench"
		awesome_monsters["spider gremlin"] = "molybdenum pliers"
		awesome_monsters["vegetable gremlin"] = "molybdenum screwdriver"
	elseif fight["gremlin.has tool"] ~= "no" then
		if adventure_zone("Next to that Barrel with Something Burning in it") then
			awesome_monsters["batwinged gremlin"] = "molybdenum hammer"
			drop_uncertainty["batwinged gremlin"] = true
		elseif adventure_zone("Over Where the Old Tires Are") then
			awesome_monsters["erudite gremlin"] = "molybdenum crescent wrench"
			drop_uncertainty["erudite gremlin"] = true
		elseif adventure_zone("Near an Abandoned Refrigerator") then
			awesome_monsters["spider gremlin"] = "molybdenum pliers"
			drop_uncertainty["spider gremlin"] = true
		elseif adventure_zone("Out by that Rusted-Out Car") then
			awesome_monsters["vegetable gremlin"] = "molybdenum screwdriver"
			drop_uncertainty["vegetable gremlin"] = true
		end
	end

	local color = nil
	local extra = ""
	local awesome_item = nil
	for x, y in pairs(awesome_monsters) do
		if monstername(x) then
			awesome_item = y
		end
	end
	if awesome_item then
		color = "royalblue"
		if awesome_item ~= "" then
			local numitems = count_item(awesome_item)
			if monstername("Blooper") then
				numitems = count_item("white pixel") + math.min(count_item("red pixel"), count_item("green pixel"), count_item("blue pixel"))
			end
			if drop_uncertainty[get_monstername()] then
				extra = extra .. [[<br><center style="font-size: 75%%; color: green">?? []] .. awesome_item .. ":" .. numitems .. "] ??</center>"
			else
				extra = extra .. [[<br><center style="font-size: 75%%; color: green">[]] .. awesome_item .. ":" .. numitems .. "]</center>"
			end
		end
-- 	elseif other_item_dropping_monsters[get_monstername()] then
-- 		local dropdata = {}
-- 		for i table.values(other_item_dropping_monsters[get_monstername()]) do
-- 			table.insert(dropdata, i .. ":" .. count_item(i)
-- 		end
-- 		extra = extra .. [[<br><center style="font-size: 75%%; color: gray">[]] .. table.concat(dropdata, ", ") .. [[]</center>]]
	end

	-- TODO-future: This should be in pirates.lua, and preferably transfer zone to printer after fight state reset, and should actually be removed after that!
	loadzone = session["adventure.lastzone"]
	if loadzone == 157 then
		local tbl = ascension["zone.pirates.insults"] or {}
		extra = extra .. [[<br><center style="font-size: 75%%; color: green">]] .. #tbl .." / 8 insults</center>"
	end

	if tower_monster_items[get_monstername()] then
		local item_name = tower_monster_items[get_monstername()]
		local item_id = get_itemid(item_name)
		if have_item(item_name) then
			-- TODO: use make_href
			extra = extra .. [[<br><center style="font-size: 75%%; color: green">[<a href="fight.php?action=useitem&whichitem=]]..item_id..[[" style="color: green">Use ]] .. item_name .. [[</a>]</center>]] -- should be POST, not GET
		else
			extra = extra .. [[<br><center style="font-size: 75%%; color: grey">[Need ]] .. item_name .. [[]</center>]]
		end
	end

	local colorstr = ""
	if color then
		colorstr = [[ style="color: ]]..color..[["]]
	end
	text = text:gsub([[<span.-</span>]], function(spantext)
		if spantext:contains("monname") then
			return spantext:gsub([[<span [^>]*id=['"]monname['"][^>]*>]], function(spantag)
				return spantag:gsub(">$", colorstr .. ">")
			end) .. extra
		end
	end)
end)
