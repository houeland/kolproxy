-- ToDo - Grimacite, Tuesday Ruby, LBOF range, Bounty Hunting Outfit

register_setting {
	name = "show modifier estimates",
	description = "Show modifier estimates (+noncombat%, +item%, +ML. <b>Not always accurate</b>)",
	group = "charpane",
	default_level = "standard",
}

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
	local vanilla_fairy = {
		"slimeling",
		"stompboots",
		"obtuseangel",
		"familiar15",
		"familiar22",
		"familiar26",
		"familiar34",
		"familiar35",
		"familiar36",
		"familiar39",
		"familiar41",
		"sgfairy",
		"slgfairy",
		"jitterbug",
		"dandylion",
		"cassagnome",
		"dancebear",
		"sugarfairy",
		"pictsie",
		"turtle",
		"gibberer",
		"grouper2",
		"dancfrog",
		"hippofam",
		"pianocat",
		"kloop",
		"pep_rhino",
		"frankengnome",
	}
	for i,fam in ipairs(vanilla_fairy) do
		if familiarpicture() == fam then
			tw_item = tw_item + fairy_bonus(buffedfamiliarweight())
		end
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

function estimate_item_modifiers()
	local itemmods = {}
	if ascension["zone.manor.quartet song"] == "Le Mie Cose Favorite" then
		itemmods.background = (itemmods.background or 0) + 5
	end
	if moonsign() == "Packrat" then
		itemmods.background = (itemmods.background or 0) + 10
	end
	itemmods.skill = get_skill_item()
	itemmods.familiar = get_fam_item()
	itemmods.equipment = get_equipment_bonuses().item
	itemmods.outfit = get_outfit_bonuses().item
	itemmods.buff = get_buff_bonuses().item
	return itemmods
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local itemmods = estimate_item_modifiers()
	local item = 0
	for _, m in pairs(itemmods) do
		item = item + m
	end

	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "Item drops", compactname = "Item", value = string.format("%+.1f%%", floor_to_places(item, 1)) .. uncertaintystr }
end)
