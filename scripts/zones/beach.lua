add_choice_text("Finger-Lickin'... Death.", { -- choice adventure number: 4
	["Bet 500 Meat on Tapajunta Del Maiz"] = "Win or lose 500 meat",
	["Bet 500 Meat on Cuerno De...  the other one"] = "Lose 500 meat, chance to get a poultrygeist",
	["Walk away in disgust"] = { leave_noturn = true, good_choice = true },
})

-- shore

local shore_tower_items = {
	["stick of dynamite"] = "Distant Lands Dude Ranch Adventure",
	["tropical orchid"] = "Tropical Paradise Island Getaway",
	["barbed-wire fence"] = "Large Donkey Mountain Ski Resort",
}

add_printer("/shore.php", function()
	for from, to in pairs(session["zone.lair.itemsneeded"] or {}) do
		if shore_tower_items[to] then
			text = text:gsub("(<td valign=center>)("..shore_tower_items[to]..")(</td>)", "%1<b>%2</b>%3")
		end
	end
end)

add_processor("/shore.php", function()
	if text:contains([[<b>Vacation Results:</b>]]) then
		local trips_text = text:match("You have taken (.-) trip")
		local found_combat_item = false
		for x, _ in pairs(shore_tower_items) do
			if text:contains(x) then
				found_combat_item = true
			end
		end
		if trips_text == "one" or found_combat_item then
			ascension["shore turn"] = turnsthisrun() + 35
		end
	end
end)

add_ascension_warning("/shore.php", function()
	if params.whichtrip then
		if level() >= 11 and not have("forged identification documents") and not have("your father's MacGuffin diary") then
			return "You don't have the forged identification documents.", "shoring without forged identification documents"
		end
	end
end)

add_printer("/charpane.php", function()
	local shore_next_combat_item_turn = ascension["shore turn"]
	if shore_next_combat_item_turn then
		local turns = shore_next_combat_item_turn - turnsthisrun()
		if turns >= 0 then
			print_charpane_value { name = "Shore", value = turns }
			value = turns
		end
	end
end)

add_automator("/beach.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.action == "woodencity" then
		if text:contains("commence to getting that staff") then
			local pwd = session.pwd -- careful!
			meatpaste_items("ancient amulet", "Eye of Ed", pwd)
			meatpaste_items("ancient amulet", "Staff of Fats", pwd)
			meatpaste_items("Staff of Fats", "headpiece of the Staff of Ed", pwd)
			meatpaste_items("Eye of Ed", "Staff of Ed, almost", pwd)
			text, url = post_page("/beach.php", params)
		end
	end
end)

add_automator("/shore.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains([[MacGuffin diary]]) then
		text, url = get_page("/diary.php", { whichpage = "1" }) -- Should it display the shore page or the diary page?
	end
end)


-- This is really the same warning, could this be restructured?
add_always_zone_check(121, function()
	if not buff("Ultrahydrated") then
		local pt = get_page("/beach.php")
		if pt:contains("Oasis") then
			return "Ultrahydrated is required for the desert."
		end
	end
end)

add_always_zone_check(123, function()
	if not buff("Ultrahydrated") then
		local pt = get_page("/beach.php")
		if pt:contains("Oasis") then
			return "Ultrahydrated is required for the desert."
		end
	end
end)

-- TODO: warn when continuing in the wrong zone

add_always_zone_check(121, function()
	if have("stone rose") and not have("can of black paint") then
		return "You'll need a can of black paint for Gnasir."
	end
end)

add_always_zone_check(123, function()
	if have("stone rose") and not have("can of black paint") then
		return "You'll need a can of black paint for Gnasir."
	end
end)

add_always_zone_check(121, function()
	if have("stone rose") and not have("drum machine") then
		return "You'll need a drum machine for Gnasir."
	end
end)

add_always_zone_check(123, function()
	if have("stone rose") and not have("drum machine") then
		return "You'll need a drum machine for Gnasir."
	end
end)

add_itemdrop_counter("star chart", function(c)
end)

-- pyramid
add_itemdrop_counter("tomb ratchet", function(c)
	return "{ " .. make_plural(c, "ratchet", "ratchets") .. " in inventory. }"
end)

local function get_pyramid_action()
	local pyramidpt = get_page("/pyramid.php")
	local action = nil
	if pyramidpt:match("pyramid4_1.gif") and not have("ancient bomb") and not have("ancient bronze token") then
		action = "initial"
	elseif pyramidpt:match("pyramid4_1b.gif") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_1.gif") and have("ancient bomb") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_3.gif") and not have("ancient bomb") and have("ancient bronze token") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_4.gif") and not have("ancient bomb") and not have("ancient bronze token") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_[12345].gif") then
		action = "wheel"
	else
		error "Unknown pyramid state"
	end
	if pyramidpt:match("pyramid3a.gif") then
		return action, "not placed wheel"
	else
		return action, "placed wheel"
	end
end

-- TODO: make warning enabling/disabling more fine-grained? or coarse-grained?
-- TODO: allow customization for when you want warnings?
add_ascension_zone_check(124, function()
	local pa, placed = get_pyramid_action()
	if placed == "not placed wheel" and have("carved wooden wheel") then
		return "The wheel can be placed in the middle chamber now."
	elseif pa == "lower" then
		return "The lower chambers can be used now."
	elseif placed == "not placed wheel" and have("tomb ratchet") and buff("On the Trail") then
		local trailed = retrieve_trailed_monster()
		if trailed == "tomb rat" then
			return "You can use your tomb ratchet to set the wheel."
		end
	end
end)

add_ascension_zone_check(125, function()
	local pa = get_pyramid_action()
	if pa == "initial" and not have("carved wooden wheel") then
		return "The carved wooden wheel is in the upper chamber."
	elseif pa == "lower" then
		return "The lower chambers can be used now."
	elseif not have("carved wooden wheel") and have("tomb ratchet") then
		return "You can use your tomb ratchet first."
	end
end)

add_ascension_warning("/pyramid.php", function()
	if params.action == "lower" and get_pyramid_action() ~= "lower" then
		return "Adventuring in the lower chambers will not make progress yet.", "pyramid lower chamber usage"
	end
end)

add_ascension_warning("use item: tomb ratchet", function()
	if get_pyramid_action() == "lower" then
		return "The lower chambers can be used now.", "tomb ratchet usage"
	end
end)
