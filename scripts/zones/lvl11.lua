-- beach

add_choice_text("Let's Make a Deal!", {
	["Buy the carburetor (5,000 Meat)"] = "Buy a broken carburetor for 5k meat",
	["Haggle for a better price"] = { text = "Unlock oasis", good_choice = true },
})

-- hidden temple

add_choice_text("At Least It's Not Full Of Trash", {
	["Try to jam the walls with a weapon"] = { disabled = true },
	["Raise your hands up toward the heavens"] = "Pass first test",
	["Kneel penitently on the ground"] = { disabled = true },
})

add_printer("/tiles.php", function()
	if not setting_enabled("run automation scripts") then return end
	text = text:gsub([[(<td class='cell'><a class=nounder href='tiles.php%?action=jump&whichtile=8'><img src="http://images.kingdomofloathing.com/itemimages/tilep.gif" width=30 height=30 border=0 alt='Tile labeled "P"'></a></td><td></td></tr><tr><td><img src='http://images.kingdomofloathing.com/itemimages/rightarrow.gif' alt='You are currently standing on this row'></td><td colspan=9 align=center>)%(start%)]], [[%1<a href="automate-tiles" style="color:green">{ solve }</a>]])
end)

add_choice_text("No Visible Means of Support", {
	["Run around in a mad panic"] = { disabled = true },
	["Attempt to douse the flames"] = { disabled = true },
	["Do nothing"] = "Unlock the hidden city",
})

-- hidden city

add_automator("/fight.php", function()
	if text:contains([[<a href="hiddencity.php">Go back to The Hidden City</a>]]) then
		local hctext = get_page("/hiddencity.php")
		local which = hctext:match([[<a href='hiddencity.php%?which=([0-9]-)'><img src="http://images.kingdomofloathing.com/otherimages/hiddencity/map_unruins]])
		if which then
--~ 			print("next which tile is", which)
			text = text:gsub([[<p><a href="hiddencity.php">Go back to The Hidden City</a></center>]], [[<p><a href="hiddencity.php?which=]]..which..[[" style="color: green">{ Continue exploring (The Hidden City) }</a>%0]])
		end
	end
end)

add_automator("/adventure.php", function()
	if text:contains([[<a href="hiddencity.php">Go back to The Hidden City</a>]]) then
		local hctext = get_page("/hiddencity.php")
		local which = hctext:match([[<a href='hiddencity.php%?which=([0-9]-)'><img src="http://images.kingdomofloathing.com/otherimages/hiddencity/map_unruins]])
		if which then
--~ 			print("next which tile is", which)
			text = text:gsub([[<p><a href="hiddencity.php">Go back to The Hidden City</a></center>]], [[<p><a href="hiddencity.php?which=]]..which..[[" style="color: green">{ Continue exploring (The Hidden City) }</a>%0]])
		end
	end
end)

add_processor("/fight.php", function()
	if text:match([[<table><tr><td[^>]-><img src="http://images.kingdomofloathing.com/itemimages/[a-z]-.gif" width=30 height=30 alt="[a-z]- stone sphere" title="[a-z]- stone sphere"></td><td[^>]->.-You hold the [a-z]- stone sphere up in the air.<p>]]) then -- TODO: redo using item-use capture instead?
		local tbl = ascension["zone.hiddencity.sphere"] or {}
		for sphere, color in text:gmatch([[<table><tr><td[^>]-><img src="http://images.kingdomofloathing.com/itemimages/[a-z]-.gif" width=30 height=30 alt="[a-z]- stone sphere" title="[a-z]- stone sphere"></td><td[^>]->.-You hold the ([a-z]-) stone sphere up in the air.<p>It radiates a bright ([a-z]-) light,]]) do
			print("sphere["..sphere.."] = color["..color.."]")
			tbl[color] = sphere
		end
		ascension["zone.hiddencity.sphere"] = tbl
	end
end)

add_printer("/fight.php", function()
	if text:match([[<table><tr><td[^>]-><img src="http://images.kingdomofloathing.com/itemimages/[a-z]-.gif" width=30 height=30 alt="[a-z]- stone sphere" title="[a-z]- stone sphere"></td><td[^>]->.-You hold the [a-z]- stone sphere up in the air.<p>]]) then -- TODO: redo using item-use capture instead?
		text = text:gsub([[(<table><tr><td[^>]-><img src="http://images.kingdomofloathing.com/itemimages/[a-z]-.gif" width=30 height=30 alt="[a-z]- stone sphere" title="[a-z]- stone sphere"></td><td[^>]->.-)(You hold the [a-z]- stone sphere up in the air.)(<p>)(It radiates a bright [a-z]- light.-)(</td></tr></table>)]], [[%1<span style="color: darkorange">%2</span>%3<span style="color: darkorange">%4</span>%5]]) -- TODO: redo using item-use capture instead?
	end
end)

function get_stone_sphere_status()
	tbl = ascension["zone.hiddencity.sphere"] or {}
	colors = {
		["water"] = "blue",
		["nature"] = "green",
		["fire"] = "red",
		["lightning"] = "yellow",
	}
	unknown_spheres = {
		["cracked"] = true,
		["mossy"] = true,
		["rough"] = true,
		["smooth"] = true
	}
	altars = {}
	found = 0
	for a, b in pairs(colors) do
		sphere = tbl[b]
		if sphere then
			altars[a] = sphere
			unknown_spheres[sphere] = nil
			found = found + 1
		end
	end
	if (found == 3) then
		for a, b in pairs(colors) do
			if not tbl[b] then
				which = nil
				for x, y in pairs(unknown_spheres) do
					which = x
				end
				altars[a] = which
				unknown_spheres[which] = nil
			end
		end
	end
	return {
		["altars"] = altars,
		["unknown spheres"] = unknown_spheres
	}
end

add_printer("/hiddencity.php", function()
	for a, b in pairs(get_stone_sphere_status().altars) do
--~ 		print("altar["..a.."] -> " .. b)
		if text:match("<table><tr><td><table><tr><td valign=center><img src='http://images.kingdomofloathing.com/otherimages/hiddencity/altar[0-9].gif' alt='An altar with a carving of a god of "..a.."' title='An altar with a carving of a god of "..a.."'></td><td><b>Altared Perceptions</b><p>You discover a stone altar, elaborately carved with a depiction of what appears to be some kind of ancient god.</td></tr></table>The top of the altar features a bowl%-like depression %-%- it looks as though you're meant to put something into it. Probably something round.<p>") then
			text = text:gsub("(<option value='[0-9]+')(>"..b.." stone sphere %([0-9]+%)</option>)", [["%1 selected="selected"%2]])
		end
	end
end)

add_ascension_zone_check(50, function()
	if ascensionstatus() == "Softcore" and not have("wet stunt nut stew") then
		return "You might want to use pulls to make wet stunt nut stew before visiting Mr. Alarm"
	end
end)
