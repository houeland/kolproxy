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


function automate_tiles()
	local function choose(tile)
		return async_post_page("/tiles.php", { action = "jump", whichtile = tile })
	end
	choose(4)
	choose(6)
	choose(3)
	choose(5)
	choose(7)
	choose(6)
	return choose(3)()
end

local automate_tiles_href = add_automation_script("automate-tiles", function()
	return automate_tiles()
end)

add_printer("/tiles.php", function()
	text = text:gsub([[(<td class='cell'><a class=nounder href='tiles.php%?action=jump&whichtile=8'><img src="http://images.kingdomofloathing.com/itemimages/tilep.gif" width=30 height=30 border=0 alt='Tile labeled "P"'></a></td><td></td></tr><tr><td><img src='http://images.kingdomofloathing.com/itemimages/rightarrow.gif' alt='You are currently standing on this row'></td><td colspan=9 align=center>)%(start%)]], [[%1<a href="]] .. automate_tiles_href { pwd = session.pwd } .. [[" style="color: green">{ solve }</a>]])
end)

add_choice_text("No Visible Means of Support", {
	["Run around in a mad panic"] = { disabled = true },
	["Attempt to douse the flames"] = { disabled = true },
	["Do nothing"] = "Unlock the hidden city",
})

add_ascension_zone_check(50, function()
	if ascensionstatus("Softcore") and not have_item("wet stunt nut stew") then
		return "You might want to use pulls to make wet stunt nut stew before visiting Mr. Alarm"
	end
end)
