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
	meatmods.equipment = get_equipment_bonuses().meat
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
