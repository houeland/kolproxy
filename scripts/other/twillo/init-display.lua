local function estimate_fam_init()
	if familiarid() == 159 then -- happy medium
		return buffedfamiliarweight()
	elseif familiarid() == 168 then -- oily woim
		return buffedfamiliarweight() * 2
	else
		return 0
	end
end

local function estimate_skill_init()
	local tw_init = 0
	local skillarray = {
		["Legendary Impatience"] = 100,
		["Hunter's Sprint"] = 100,
		["Lust"] = 50,
		["Never Late for Dinner"] = 50,
		["Overdeveloped Sense of Self Preservation"] = 20,
		["Slimy Shoulders"] = 20,
		["Sloth"] = -25,
	}
	for skill, init in pairs(skillarray) do
		if have_skill(skill) then
			tw_init = tw_init + init
		end
	end
	return tw_init
end

function estimate_other_init()
	local init = estimate_fam_init() + estimate_skill_init()
	if moonsign("Vole") then
		init = init + 20
	end
	return init
end

function estimate_init_penalty(ml)
	local penalty = 0
	if 20 < ml and ml <= 40 then
		penalty = 0 + 1 * (ml - 20)
	elseif 40 < ml and ml <= 60 then
		penalty = 20 + 2 * (ml - 40)
	elseif 60 < ml and ml <= 80 then
		penalty = 60 + 3 * (ml - 60)
	elseif 80 < ml and ml <= 100 then
		penalty = 120 + 4 * (ml - 80)
	elseif 100 < ml then
		penalty = 200 + 5 * (ml - 100)
	end
	return penalty
end
