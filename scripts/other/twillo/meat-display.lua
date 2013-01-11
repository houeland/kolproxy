-- ToDo - Stinky Cheese, Tuesday Ruby, Hodgman gear

local function lep_bonus(weight)
	return 2 * fairy_bonus(weight)
end

local vanilla_lep = {
	familiar2 = true,
	familiar22 = true,
	familiar23 = true,
	familiar25 = true,
	familiar41 = true,
	familiar42 = true,
	jitterbug = true,
	tick = true,
	cassagnome = true,
	hunchback = true,
	uniclops = true,
	dancebear = true,
	heboulder = true,
	urchin = true,
	dancfrog = true,
	chauvpig = true,
	hippofam = true,
	organgoblin = true,
	pianocat = true,
	dramahog = true,
	groose = true,
	kloop = true,
	uc = true,
	jungman = true,
}

local function get_fam_meat()
	-- TODO: Use familiar IDs/names instead
	local tw_meat = 0
	if familiarpicture() == "hobomonkey" then
		tw_meat = tw_meat + lep_bonus(buffedfamiliarweight() * 1.25)
	end
	if vanilla_lep[familiarpicture()] then
		tw_meat = tw_meat + lep_bonus(buffedfamiliarweight())
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
