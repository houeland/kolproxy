-- ToDo - Grimacite, Tuesday Ruby, LBOF range, Bounty Hunting Outfit

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
	gibberer = true,
	grouper2 = true,
	dancfrog = true,
	hippofam = true,
	pianocat = true,
	kloop = true,
	pep_rhino = true,
	frankengnome = true,
	jungman = true,
}

local function get_fam_item()
	if ascensionpathid() == 8 then
		if clancy_instrumentid() == 3 then
			return fairy_bonus(clancy_level() * 5)
		else
			return 0
		end
	end
	-- TODO: Use familiar names instead of pictures
	local tw_item = 0
	if familiarpicture() == "jackinthebox" then
		tw_item = tw_item + 2 * fairy_bonus(buffedfamiliarweight())
	elseif familiarpicture() == "hounddog" then
		tw_item = tw_item + fairy_bonus(buffedfamiliarweight() * 1.25)
	elseif familiarpicture() == "spanglehat" and familiarid() == 82 then
		tw_item = tw_item + fairy_bonus(buffedfamiliarweight() * 2)
	elseif familiarpicture() == "spanglepants" and familiarid() == 152 then
		tw_item = tw_item + fairy_bonus(buffedfamiliarweight() * 2)
	end
	if vanilla_fairy[familiarpicture()] then
		tw_item = tw_item + fairy_bonus(buffedfamiliarweight())
	end
	return tw_item
end

local function get_skill_item()
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
	local item = get_fam_item() + get_skill_item()
	if ascension["zone.manor.quartet song"] == "Le Mie Cose Favorite" then
		item = item + 5
	end
	if moonsign() == "Packrat" then
		item = item + 10
	end
	return item
end

function estimate_item_bonus()
	local item = estimate_other_item()
	item = item + get_equipment_bonuses().item
	item = item + get_outfit_bonuses().item
	item = item + get_buff_bonuses().item
	return item
end
