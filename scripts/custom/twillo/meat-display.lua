-- ToDo - Stinky Cheese, Tuesday Ruby, Hodgman gear

local function lep_bonus(weight)
	return 2 * fairy_bonus(weight)
end

local function get_fam_meat()
	-- TODO: Use familiar IDs/names instead
	local tw_meat = 0
	if familiarpicture() == "hobomonkey" then
		tw_meat = tw_meat + lep_bonus(buffedfamiliarweight() * 1.25)
	end
	local vanilla_lep = {
		"familiar2",
		"familiar22",
		"familiar23",
		"familiar25",
		"familiar41",
		"familiar42",
		"jitterbug",
		"tick",
		"cassagnome",
		"hunchback",
		"uniclops",
		"dancebear",
		"heboulder",
		"urchin",
		"dancfrog",
		"chauvpig",
		"hippofam",
		"organgoblin",
		"pianocat",
		"dramahog",
		"groose",
		"kloop",
	}
	for _, fam in pairs(vanilla_lep) do
		if familiarpicture() == fam then
			tw_meat = tw_meat + lep_bonus(buffedfamiliarweight())
		end
	end
	return tw_meat
end

local function get_equipment_meat()
	local tw_meat = 0
	if have_equipped("scratch 'n' sniff sword") or have_equipped("scratch 'n' sniff crossbow") then
		for i = 1, 3 do
			if applied_scratchnsniff_stickers()[i] == get_itemid("scratch 'n' sniff UPC sticker") then
				tw_meat = tw_meat + 25
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
		tw_meat = tw_meat + math.pow(2, count_bs)
	end
	local count_ms = count_distinct_equipped {
		"bewitching boots",
		"bitter bowtie",
		"brazen bracelet",
	}
	tw_meat = tw_meat + (count_ms + 1) * count_ms * 5
	local equipmentarray = {
		["lucky Tam O'Shatner"] = 50,
		["lucky Tam O'Shanter"] = 50,
		["incredibly dense meat gem"] = 40,
		["Grimacite gauntlets"] = 30,
		["astral longbow"] = 30,
		["origami pasties"] = 30,
		["Coily&trade;"] = 25,
		["poodle skirt"] = 25,
		["Grimacite galoshes"] = 25,
		["Uncle Hobo's belt"] = 25,		
		["Seeger's Unstoppable Banjo"] = 23,
		["Loathing Legion electric knife"] = 20,
		["duct tape shirt"] = 20,
		["natty blue ascot"] = 20,
		["astral trousers"] = 20,
		["stainless steel slacks"] = 20,
		["Bag o' Tricks"] = 15,
		["Spooky Putty leotard"] = 15,
		["bottle-rocket crossbow"] = 15,
		["meatspout staff"] = 15,
		["cane-mail shirt"] = 15,
		["Baron von Ratsworth's money clip"] = 15,
		["evil flaming eyeball pendant"] = 15,
		["ice skates"] = 15,
		["pulled porquoise pendant"] = 15,
		["Radio KoL Bottle Opener"] = 15,
		["bobble-hip hula elf doll"] = 15,
		["cup of infinite pencils"] = 15,
		["Order of the Silver Wossname"] = 11,
		["Ye Olde Navy Fleece"] = 10,
		["booty chest charrrm bracelet"] = 10,
		["ancient turtle shell helmet"] = 10,
		["mayfly bait necklace"] = 10,
		["ratskin belt"] = 10,
		["teddybear backpack"] = 10,
		["toy crazy train"] = 10,
		["toy maglev monorail"] = 10,
		["toy train"] = 10,
		["Ellsbury's skull"] = 10,
		["fish bazooka"] = 10,
		["Shagadelic Disco Banjo"] = 10,
		["cyber-mattock"] = 10,	
		["acoustic guitarrr"] = 8,	
		["Mayflower bouquet"] = 7,
		["lucky rabbit's foot"] = 7,
		["BGE 'cuddly critter' shirt"] = 7,
		["tiny plastic hermit"] = 6,
		["muculent machete"] = 5,
		["flamingo mallet"] = 5,
		["flimsy clipboard"] = 5,
		["Li'l Businessman Kit"] = 5,
		["world's smallest violin"] = 5,
		["mysterious silver lapel pin"] = 5,
		["7-ball"] = 5,
		["fancy opera glasses"] = 5,
		["tip jar"] = 5,
		-- ["Tuesday's ruby"] = 5,
		["navel ring of navel gazing"] = 4,
		["tiny plastic Crimbo Casino"] = 4,
		["tiny plastic 11 Dealer"] = 4,
		["tiny plastic hobo elf"] = 4,
		["tiny plastic fat stack of cash"] = 3,
		["meat shield"] = 3,
		["box-in-the-box-in-the-box"] = 3,
		["penguin whip"] = 3,
		["tiny plastic Baron von Ratsworth"] = 3,
		["tiny plastic The Man"] = 3,
		["white collar"] = 3,
		["box-in-the-box"] = 3,
		["box"] = 3,
		["stinky cheese eye"] = session["cached stinky cheese eye bonus"] or 1,
	}
	for meatequip, bonus in pairs(equipmentarray) do
		tw_meat = tw_meat + count_equipped(meatequip) * bonus
	end
	return tw_meat
	-- To Do - Hobo Gear
end

local function get_skill_meat()
	local tw_meat = 0
	local skillarray = {
		["Greed"] = 50,
		["Undying Greed"] = 25,
		["Nimble Fingers"] = 20,
		["Expert Panhandling"] = 10,
		["Gnefarious Pickpocketing"] = 10,
		["Thrift and Grift"] = 10,
		["Envy"] = -15,
	}
	for skill, meat in pairs(skillarray) do
		if have_skill(skill) then
			tw_meat = tw_meat + meat
		end
	end
	return tw_meat
end

function estimate_meat_modifiers()
	local meatmods = {}
	if moonsign() == "Wombat" then
		meatmods.background = (meatmods.background or 0) + 20
	end
	meatmods.skill = get_skill_meat()
	meatmods.familiar = get_fam_meat()
	meatmods.equipment = get_equipment_meat()
	meatmods.outfit = get_outfit_bonuses().meat
	meatmods.buff = get_buff_bonuses().meat
	return meatmods
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local meatmods = estimate_meat_modifiers()
	local meat = 0
	for _, m in pairs(meatmods) do
		meat = meat + m
	end

	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "Meat drops", compactname = "Meat", value = string.format("%+.1f%%", floor_to_places(meat, 1)) .. uncertaintystr }
end)
