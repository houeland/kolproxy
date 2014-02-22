function retrieve_motorcycle_status()
	local pt = get_page("/main.php", { action = "motorcycle" })
	local can_upgrade = not pt:contains("Carry on then.")
	local upgrades = {}
	for x, y in pt:gmatch([[<b>([^<]-):</b> ([^<]-) %(]]) do
		upgrades[x] = y
	end
	--print("DEBUG retrieve_motorcycle_status", can_upgrade, upgrades, level())
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
		bonuses = bonuses + make_bonuses_table { ["Combat Initiative"] = 50 }
	end
	if upgrades["Cowling"] == "Sweepy Red Light" then
		bonuses = bonuses + make_bonuses_table { ["Stats Per Fight"] = 5 }
	end
	if upgrades["Seat"] == "Sissy Bar" then
		bonuses = bonuses + make_bonuses_table { ["Monster Level"] = -30 }
	end
	return bonuses
end
