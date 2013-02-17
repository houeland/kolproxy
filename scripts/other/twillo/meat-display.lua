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

local function estimate_fam_meat()
	-- TODO: Use familiar IDs/names instead
	if vanilla_lep[familiarpicture()] then
		return lep_bonus(buffedfamiliarweight())
	elseif familiarpicture() == "hobomonkey" then
		return lep_bonus(buffedfamiliarweight() * 1.25)
	else
		return 0
	end
end

local function estimate_skill_meat()
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

function estimate_other_meat()
	local meat = estimate_fam_meat() + estimate_skill_meat()
	if moonsign("Wombat") then
		meat = meat + 20
	end
	return meat
end
