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

-- TODO: handle differently
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

-- TODO: handle differently
function estimate_other_meat()
	local meat = estimate_fam_meat()
	if moonsign("Wombat") then
		meat = meat + 20
	end
	return meat
end
