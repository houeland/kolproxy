add_choice_text("Finger-Lickin'... Death.", { -- choice adventure number: 4
	["Bet 500 Meat on Tapajunta Del Maiz"] = "Win or lose 500 meat",
	["Bet 500 Meat on Cuerno De...  the other one"] = "Lose 500 meat, chance to get a poultrygeist",
	["Walk away in disgust"] = { leave_noturn = true, good_choice = true },
})

-- shore

add_warning {
	message = "You might be shoring over a semirare.",
	path = "/choice.php",
	type = "warning",
	check = function()
		if tonumber(params.whichchoice) == 793 then
			local opt = tonumber(params.option)
			if opt and opt >= 1 and opt <= 3 then
				if ascensionpath("Way of the Surprising Fist") then
					return semirare_in_next_N_turns(5)
				else
					return semirare_in_next_N_turns(3)
				end
			end
		end
	end,
}

add_warning {
	message = "You don't have the forged identification documents.",
	path = "/choice.php",
	type = "warning",
	when = "ascension",
	check = function()
		if tonumber(params.whichchoice) == 793 then
			local opt = tonumber(params.option)
			if opt and opt >= 1 and opt <= 3 then
				return level() >= 11 and not have_item("forged identification documents") and not have_item("your father's MacGuffin diary")
			end
		end
	end,
}

add_printer("/shop.php", function()
	if not text:contains(">The Shore, Inc. Gift Shop<") then return end
	local tower_items = get_lair_tower_monster_items()
	local crates = {
		["barbed-wire fence"] = "ski resort souvenir crate",
		["stick of dynamite"] = "dude ranch souvenir crate",
		["tropical orchid"] = "tropical island souvenir crate",
	}
	if tower_items[6] and not have_item(tower_items[6]) then
		local crate = crates[tower_items[6]]
		if crate and not have_item(crate) then
			text = text:gsub("<tr.-</tr>", function(tr)
				if not tr:contains(crate) then return end
				return tr:gsub("<td.-</td>", function(td)
					if not td:contains(crate) then return end
					return td:gsub("<td", [[<td style="background-color: lightgreen"]])
				end)
			end)
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

add_ascension_assistance(function() return have_item("your father's MacGuffin diary") end, function()
	-- TODO: Show something first time to show this actually happened
	async_get_page("/diary.php", { whichpage = 1 })
	async_get_page("/diary.php", { textversion = 1 })
end)

-- desert/oasis

function get_desert_exploration(pt)
	pt = pt or get_place("desertbeach")
	if pt:contains("zonefont/percent.gif") then
		local snippet = pt:match("zonefont/lparen.gif.-zonefont/percent.gif")
		local digits = ""
		for x in snippet:gmatch("zonefont/([0-9]).gif") do
			digits = digits .. x
		end
		return tonumber(digits)
	end
end

add_automator("/fight.php", function()
	if text:contains(">Desert exploration <b>+") then
		local explored = get_desert_exploration()
		text = text:gsub(">Desert exploration <b>%+[0-9]*%%</b>", [[%0 <span style="color: green">{&nbsp;]] .. tostring(explored) .. [[%% explored&nbsp;}</span>]])
	end
end)

-- TODO: Do these by noncombat choice option text, not option ID
add_ascension_assistance(function() return have_item("stone rose") end, function()
	get_place("desertbeach", "db_gnasir")
	async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 805, option = 2 })
	async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 805, option = 1 })
end)

add_ascension_assistance(function() return count_item("worm-riding manual page") >= 15 end, function()
	get_place("desertbeach", "db_gnasir")
	async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 805, option = 2 })
	async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 805, option = 1 })
end)

add_warning {
	message = "You might want to equip an UV-resistant compass to aid in desert exploration (from The Shore, Inc.)",
	type = "warning",
	when = "ascension",
	zone = "The Arid, Extra-Dry Desert",
	check = function() return can_wear_weapons() and not have_equipped_item("UV-resistant compass") and not have_equipped_item("ornate dowsing rod") end
}

add_warning {
	message = "You might want to wear a different offhand when not exploring the desert.",
	type = "extra",
	when = "ascension",
	check = function(zoneid)
		if zoneid == get_zoneid("The Arid, Extra-Dry Desert") then return end
		if zoneid == get_zoneid("The Oasis") and not have_buff("Ultrahydrated") then return end
		return have_equipped_item("UV-resistant compass") or have_equipped_item("ornate dowsing rod")
	end
}

add_warning {
	message = "You might want to get Ultrahydrated first (from The Oasis)",
	type = "extra",
	when = "ascension",
	zone = "The Arid, Extra-Dry Desert",
	check = function()
		if have_buff("Ultrahydrated") then return end
		local pt = get_place("desertbeach")
		if pt:contains("Oasis") then
			return true
		end
	end
}

add_warning {
	message = "You might want to use your worm-riding hooks and drum machine first.",
	type = "warning",
	when = "ascension",
	zone = "The Arid, Extra-Dry Desert",
	check = function() return have_item("worm-riding hooks") and have_item("drum machine") end,
}

add_warning {
	message = "You might want to turn in your worm-riding manual pages first.",
	type = "warning",
	when = "ascension",
	zone = "The Arid, Extra-Dry Desert",
	check = function() return count_item("worm-riding manual page") >= 15 end,
}

add_itemdrop_counter("worm-riding manual page", function(c)
	return "{ " .. c .. " of 15 found. }"
end)

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
get_ancient_buried_pyramid_action = get_pyramid_action

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
