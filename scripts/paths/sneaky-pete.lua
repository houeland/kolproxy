function retrieve_pete_friend()
	if session["pete friend"] == nil then
		--print("DEBUG: check pete friend")
		local skillpt = get_page("/desc_skill.php", { whichskill = 15009 })
		local friend = skillpt:match([[You recently made friends with [^ ]- ([^<]+)]])
		session["pete friend"] = friend or ""
	end
	--print("DEBUG: pete friend [" .. session["pete friend"] .. "]")
	return session["pete friend"]
end

function retrieve_motorcycle_status()
	local pt = get_page("/main.php", { action = "motorcycle" })
	local can_upgrade = not pt:contains("Carry on then.")
	local upgrades = {}
	for x, y in pt:gmatch([[<b>([^<]-):</b> ([^<]-) %(]]) do
		upgrades[x] = y
	end
	--print("DEBUG: retrieve_motorcycle_status", can_upgrade, upgrades, level())
	return can_upgrade, upgrades
end

local in_sneaky_pete_choice = nil
add_processor("/choice.php", function()
	if not ascensionpath("Avatar of Sneaky Pete") then return end
	if text:contains(">Upping Your Grade") then
		in_sneaky_pete_choice = true
	end
	if in_sneaky_pete_choice and text:contains(">Results:") then
		in_sneaky_pete_choice = false
		session["sneaky pete motorcycle check"] = nil
	end
	if text:contains("Carry on then.") and session["sneaky pete motorcycle can_upgrade"] then
		session["sneaky pete motorcycle check"] = nil
	end
end)

add_processor("/fight.php", function()
	if not ascensionpath("Avatar of Sneaky Pete") then return end
	if text:contains("impressed by your charm and panache that you become fast friends") then
		--print("DEBUG: unset pete friend")
		session["pete friend"] = nil
	end
end)

function sneaky_pete_maybe_update_motorcycle_status()
	if not ascensionpath("Avatar of Sneaky Pete") then return end
	if not locked() and level() ~= session["sneaky pete motorcycle check"] then
		local can_upgrade, upgrades = retrieve_motorcycle_status()
		session["sneaky pete motorcycle can_upgrade"] = can_upgrade
		if not can_upgrade then
			session["sneaky pete motorcycle upgrades"] = upgrades
		end
		session["sneaky pete motorcycle check"] = level()
	end
end

add_automator("all pages", sneaky_pete_maybe_update_motorcycle_status)

function can_upgrade_sneaky_pete_motorcycle()
	return session["sneaky pete motorcycle can_upgrade"]
end

function estimate_current_sneaky_pete_motorcycle_bonuses()
	local bonuses = make_bonuses_table {}
	local upgrades = sneaky_pete_motorcycle_upgrades()
	if upgrades["Gas Tank"] == "Nitro-Burnin' Funny Tank" then
		bonuses.add { ["Combat Initiative"] = 50 }
	end
	if upgrades["Cowling"] == "Sweepy Red Light" then
		bonuses.add { ["Stats Per Fight"] = 5 }
	end
	if upgrades["Seat"] == "Sissy Bar" then
		bonuses.add { ["Monster Level"] = -30 }
	end
	return bonuses
end

function get_remaining_peel_outs()
	local pt = get_page("/desc_skill.php", { whichskill = get_skillid("Peel Out"), self = "true" })
	local peelouts = tonumber(pt:match("You can peel out ([0-9]+) more time"))
	return peelouts
end

add_warning {
	message = "Shake It Off will remove the Thrice-Cursed, Twice-Cursed, and Once-Cursed buffs.",
	path = "/runskillz.php",
	type = "extra",
	check = function()
		if tonumber(params.whichskill) ~= get_skillid("Shake It Off") then return end
		return have_apartment_building_cursed_buff()
	end,
}

add_warning {
	message = "Unequipping Sneaky Pete's leather jacket will drop your hate/love down to 30.",
	path = "/inv_equip.php",
	type = "extra",
	check = function()
		if params.type ~= "shirt" then return end
		return (have_equipped_item("Sneaky Pete's leather jacket (collar popped)") or have_equipped_item("Sneaky Pete's leather jacket")) and (petehate() > 30 or petelove() > 30)
	end,
}

function cast_check_mirror_for_intrinsic(intrinsic)
	local options = {
		["Slicked-Back Do"] = "Slick it back",
		["Pompadour"] = "Comb it up",
		["Cowlick"] = "Leave it curly",
		["Fauxhawk"] = "Be a douchebag",
	}
	cast_skill("Check Mirror")
	local pt, pturl = get_page("/choice.php", { forceoption = 0 })
	return handle_adventure_result(pt, pturl, "?", nil, { ["Hair Today"] = options[intrinsic] })
end
