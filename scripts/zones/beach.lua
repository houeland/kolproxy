add_choice_text("Finger-Lickin'... Death.", { -- choice adventure number: 4
	["Bet 500 Meat on Tapajunta Del Maiz"] = "Win or lose 500 meat",
	["Bet 500 Meat on Cuerno De...  the other one"] = "Lose 500 meat, chance to get a poultrygeist",
	["Walk away in disgust"] = { leave_noturn = true, good_choice = true },
})

-- shore

add_ascension_warning("/shore.php", function()
	if params.whichtrip then
		if level() >= 11 and not have_item("forged identification documents") and not have_item("your father's MacGuffin diary") then
			return "You don't have the forged identification documents.", "shoring without forged identification documents"
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

-- desert/oasis

function get_desert_exploration()
	local pt = get_page("/place.php", { whichplace = "desertbeach" })
	if pt:contains("zonefont/percent.gif") then
		local snippet = pt:match("zonefont/lparen.gif.-zonefont/percent.gif")
		local digits = ""
		for x in snippet:gmatch("zonefont/([0-9]).gif") do
			digits = digits .. x
		end
		return tonumber(digits)
	end
end

add_warning {
	message = "You might want to equip an UV-resistant compass to aid in desert exploration (from The Shore, Inc.)",
	type = "warning",
	when = "ascension",
	zone = "The Arid, Extra-Dry Desert",
	check = function() return can_wear_weapons() and not have_equipped("UV-resistant compass") end
}

--[[--
-- This is really the same warning, could this be restructured?
add_always_zone_check(121, function()
	if not have_buff("Ultrahydrated") then
		local pt = get_page("/beach.php")
		if pt:contains("Oasis") then
			return "Ultrahydrated is required for the desert."
		end
	end
end)

add_always_zone_check(123, function()
	if not have_buff("Ultrahydrated") then
		local pt = get_page("/beach.php")
		if pt:contains("Oasis") then
			return "Ultrahydrated is required for the desert."
		end
	end
end)

-- TODO: warn when continuing in the wrong zone

add_always_zone_check(121, function()
	if have_item("stone rose") and not have_item("can of black paint") then
		return "You'll need a can of black paint for Gnasir."
	end
end)

add_always_zone_check(123, function()
	if have_item("stone rose") and not have_item("can of black paint") then
		return "You'll need a can of black paint for Gnasir."
	end
end)

add_always_zone_check(121, function()
	if have_item("stone rose") and not have_item("drum machine") then
		return "You'll need a drum machine for Gnasir."
	end
end)

add_always_zone_check(123, function()
	if have_item("stone rose") and not have_item("drum machine") then
		return "You'll need a drum machine for Gnasir."
	end
end)

add_always_zone_check(122, function()
	if have_buff("Ultrahydrated") and have_item("stone rose") and have_item("drum machine") then
		return "You already have the stone rose and a drum machine for Gnasir."
	end
end)
--]]--

-- pyramid
add_itemdrop_counter("tomb ratchet", function(c)
	return "{ " .. make_plural(c, "ratchet", "ratchets") .. " in inventory. }"
end)

local function get_pyramid_action()
	local pyramidpt = get_page("/pyramid.php")
	local action = nil
	if pyramidpt:match("pyramid4_1.gif") and not have_item("ancient bomb") and not have_item("ancient bronze token") then
		action = "initial"
	elseif pyramidpt:match("pyramid4_1b.gif") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_1.gif") and have_item("ancient bomb") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_3.gif") and not have_item("ancient bomb") and have_item("ancient bronze token") then
		action = "lower"
	elseif pyramidpt:match("pyramid4_4.gif") and not have_item("ancient bomb") and not have_item("ancient bronze token") then
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
	if placed == "not placed wheel" and have_item("carved wooden wheel") then
		return "The wheel can be placed in the middle chamber now."
	elseif pa == "lower" then
		return "The lower chambers can be used now."
	elseif placed == "not placed wheel" and have_item("tomb ratchet") and have_buff("On the Trail") then
		local trailed = retrieve_trailed_monster()
		if trailed == "tomb rat" then
			return "You can use your tomb ratchet to set the wheel."
		end
	end
end)

add_ascension_zone_check(125, function()
	local pa = get_pyramid_action()
	if pa == "lower" then
		return "The lower chambers can be used now."
	elseif pa == "initial" and not have_item("carved wooden wheel") then
		return "The carved wooden wheel is in the upper chamber."
	elseif not have_item("carved wooden wheel") and have_item("tomb ratchet") then
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
