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
	-- TODO: Use familiar IDs/names instead
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
		"frankengnome",
	}
	for i,fam in ipairs(vanilla_fairy) do
		if familiarpicture() == fam then
			tw_item = tw_item + fairy_bonus(buffedfamiliarweight())
		end
	end
	return tw_item
end

local function get_equipment_item()
	local tw_item = 0
	if have_equipped("frosty halo") and not (equipment().weapon or equipment().offhand) then -- unarmed
		tw_item = tw_item + 25
	end
	if have_equipped("scratch 'n' sniff sword") or have_equipped("scratch 'n' sniff crossbow") then
		for _, x in pairs(applied_scratchnsniff_stickers()) do
			if x == get_itemid("scratch 'n' sniff unicorn sticker") then
				tw_item = tw_item + 25
			end
		end
	end
	local function count_distinct_equipped(items)
		local c = 0
		for item in table.values(items) do
			if have_equipped(item) then
				c = c + 1
			end
		end
		return c
	end

	local count_bs = count_distinct_equipped {
		"Brimstone Bunker",
		"Brimstone Brooch",
		"Brimstone Boxers",
		"Brimstone Beret",
		"Brimstone Bludgeon",
		"Brimstone Bracelet",
	}
	if count_bs > 0 then
		tw_item = tw_item + math.pow(2, count_bs)
	end
	local count_ms = count_distinct_equipped {
		"monstrous monocle",
		"musty moccasins",
		"molten medallion",
	}
	tw_item = tw_item + count_ms * count_ms * 5
	local equipmentarray = {
		["Jekyllin hide belt"] = session["cached Jekyllin hide belt bonus"] or 36,
		["Grimacite go-go boots"] = 30,
		["Grimacite gorget"] = 25,
		["Mr. Accessory Jr."] = 25,
		["miniature gravy-covered maypole"] = 25,
		["hypnodisk"] = 25,
		["chiptune guitar"] = 25,
		["astral mask"] = 20,
		["bounty-hunting helmet"] = 20,
		["plexiglass pants"] = 20,
		["ice pick"] = 15,
		["flaming pink shirt"] = 15,
		["bounty-hunting pants"] = 15,
		["bounty-hunting rifle"] = 15,
		["Radio KoL Maracas"] = 15,
		["Camp Scout backpack"] = 15,
		["plastic pumpkin bucket"] = 13,
		["little box of fireworks"] = 12.5,
		["Red Balloon of Valor"] = 11,
		["Order of the Silver Wossname"] = 11,
		["Uranium Omega of Temperance"] = 11,
		["bindlestocking"] = 10,
		["sleazy bindle"] = 10,
		["spooky bindle"] = 10,
		["Crimbo ukelele"] = 10,
		["flamin' bindle"] = 10,
		["freezin' bindle"] = 10,
		["stinkin' bindle"] = 10,
		["Purple Horseshoe of Honor"] = 10,
		["Lead Zeta of Chastity"] = 10,
		["Coily&trade;"] = 10,
		["bottle-rocket crossbow"] = 10,
		["Crimbo ukelele"] = 10,
		["PVC staff"] = 10,
		["straw hat"] = 10,
		["honeycap"] = 10,
		["Bag o' Tricks"] = 10,
		["bottle-rocket crossbow"] = 10,
		["Ellsbury's skull"] = 10,
		["Loathing Legion many-purpose hook"] = 10,
		["spiky turtle shield"] = 10,
		["Baron von Ratsworth's monocle"] = 10,
		["mayfly bait necklace"] = 10,
		["Blue Diamond of Honesty"] = 9,
		["Aluminum Epsilon of Humility"] = 9,
		["Green Clover of Justice"] = 8,
		["Zinc Delta of Tranquility"] = 8,
		["Yellow Moon of Compassion"] = 7,
		["Nickel Gamma of Frugality"] = 7,
		["BGE 'cuddly critter' shirt"] = 7,
		["lucky rabbit's foot"] = 7,
		["Orange Star of Sacrifice"] = 6,
		["Iron Beta of Industry"] = 6,
		["makeshift cape"] = 5,
		["observational glasses"] = 5,
		["Pink Heart of Spirit"] = 5,
		["Copper Alpha of Sincerity"] = 5,
		["eye of the Tiger-lily"] = 5,
		["fancy opera glasses"] = 5,
		-- ["Tuesday's ruby"] = 5
		["bat hat"] = 5,
		["miner's helmet"] = 5,
		["Grateful Undead T-shirt"] = 5,
		["octopus's spade"] = 5,
		["pixel boomerang"] = 5,
		["bubble bauble bow"] = 5,
		["cyber-mattock"] = 5,
		["duck-on-a-string"] = 5,
		["vampire duck-on-a-string"] = 5,
		["roboduck-on-a-string"] = 5,
		["duct tape sword"] = 5,
		["gnauga hide whip"] = 3,
		["Mr. Container"] = 3,
		["hemp backpack"] = 2,
		["Colonel Mustard's Lonely Spades Club Jacket"] = 2, -- 1-3%
		["Newbiesport&trade; backpack"] = 1,
		["stinky cheese eye"] = session["cached stinky cheese eye bonus"] or 1,

		["aerated diving helmet"] = -50,
		["rusty diving helmet"] = -50,
		["makeshift SCUBA gear"] = -100,
	}
	for itemequip, bonus in pairs(equipmentarray) do
		tw_item = tw_item + count_equipped(itemequip) * bonus
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
	itemmods.equipment = get_equipment_item() + (get_equipment_bonuses().item or 0)
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
