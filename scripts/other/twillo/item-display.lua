add_processor("/fight.php", function()
	if newly_started_fight then
		session["cached stinky cheese eye bonus"] = nil
	end
end)

add_processor("/inv_equip.php", function()
	session["cached stinky cheese eye bonus"] = nil
end)

add_automator("all pages", function()
	if have_equipped("stinky cheese eye") and not session["cached stinky cheese eye bonus"] then
		local pt = get_page("/desc_item.php", { whichitem = 548672093 })
		local bonus = pt:match([[>%+([0-9]+)%% Item Drops from Monsters<]])
		session["cached stinky cheese eye bonus"] = bonus
	end
end)

add_automator("all pages", function()
	if have_equipped("Jekyllin hide belt") and not session["cached Jekyllin hide belt bonus"] then
		local pt = get_page("/desc_item.php", { whichitem = 253195678 })
		local bonus = pt:match([[>%+([0-9]+)%% Item Drops from Monsters<]])
		session["cached Jekyllin hide belt bonus"] = bonus
	end
end)

local vanilla_fairy = {
	slimeling = true,
	stompboots = true,
	obtuseangel = true,
	familiar15 = true,
	familiar22 = true,
	familiar26 = true,
	familiar34 = true,
	familiar35 = true,
	familiar36 = true,
	familiar39 = true,
	familiar41 = true,
	sgfairy = true,
	slgfairy = true,
	jitterbug = true,
	dandylion = true,
	cassagnome = true,
	dancebear = true,
	sugarfairy = true,
	pictsie = true,
	turtle = true,
	grouper2 = true,
	dancfrog = true,
	hippofam = true,
	pianocat = true,
	kloop = true,
	pep_rhino = true,
	frankengnome = true,
	jungman = true,
}

local function estimate_fam_item()
	if ascensionpathid() == 8 then
		if clancy_instrumentid() == 3 then
			return fairy_bonus(clancy_level() * 5)
		else
			return 0
		end
	end
	-- TODO: Use familiar names instead of pictures
	if vanilla_fairy[familiarpicture()] then
		return fairy_bonus(buffedfamiliarweight())
	elseif familiarpicture() == "jackinthebox" then
		return 2 * fairy_bonus(buffedfamiliarweight())
	elseif familiarpicture() == "hounddog" then
		return fairy_bonus(buffedfamiliarweight() * 1.25)
	elseif familiarpicture() == "spanglehat" and familiarid() == 82 then
		return fairy_bonus(buffedfamiliarweight() * 2)
	elseif familiarpicture() == "spanglepants" and familiarid() == 152 then
		return fairy_bonus(buffedfamiliarweight() * 2)
	else
		return 0
	end
end

local function estimate_skill_item()
	local tw_item = 0
	local skillarray = {
		["Mad Looting Skillz"] = 20,
		["Powers of Observatiogn"] = 10,
		["Natural Born Scrabbler"] = 5,
		["Envy"] = 30,
		["Greed"] = -15,
	}
	for skill, item in pairs(skillarray) do
		if have_skill(skill) then
			tw_item = tw_item + item
		end
	end
	return tw_item
end

function estimate_other_item()
	local item = estimate_fam_item() + estimate_skill_item()
	if ascension["zone.manor.quartet song"] == "Le Mie Cose Favorite" then
		item = item + 5
	end
	if moonsign("Packrat") then
		item = item + 10
	end
	return item
end
