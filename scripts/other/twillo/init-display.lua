local function get_fam_init()
	if familiarid() == 159 then -- happy medium
		return buffedfamiliarweight()
	elseif familiarid() == 168 then -- oily woim
		return buffedfamiliarweight() * 2
	else
		return 0
	end
end

local function get_skill_init()
	local tw_init = 0
	local skillarray = {
		["Legendary Impatience"] = 100,
		["Hunter's Sprint"] = 100,
		["Lust"] = 50,
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

function estimate_initiative_modifiers()
	local initmods = {}
	if moonsign() == "..." then
		initmods.background = (initmods.background or 0) + 0
	end
	initmods.skill = get_skill_init()
	initmods.familiar = get_fam_init()
	initmods.equipment = get_equipment_bonuses().initiative
	initmods.outfit = get_outfit_bonuses().initiative
	initmods.buff = get_buff_bonuses().initiative

	local ml = 0
	for mname, m in pairs(estimate_ML_modifiers()) do
		ml = ml + m
	end

	local ml_init_penalty = 0
	if 20 < ml and ml <= 40 then
		ml_init_penalty = 0 + 1 * (ml - 20)
	elseif 40 < ml and ml <= 60 then
		ml_init_penalty = 20 + 2 * (ml - 40)
	elseif 60 < ml and ml <= 80 then
		ml_init_penalty = 60 + 3 * (ml - 60)
	elseif 80 < ml and ml <= 100 then
		ml_init_penalty = 120 + 4 * (ml - 80)
	elseif 100 < ml then
		ml_init_penalty = 200 + 5 * (ml - 100)
	end

	initmods.mlpenalty = -ml_init_penalty

	return initmods
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local init = 0
	local total_init = 0
	local ml_init_penalty = 0
	for x, y in pairs(estimate_initiative_modifiers()) do
		init = init + y
		if x == "mlpenalty" then
			ml_init_penalty = -y
		else
			total_init = total_init + y
		end
	end

	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "Initiative", compactname = "Init", value = string.format("%+d%%", init) .. uncertaintystr, tooltip = string.format("%+d%% initiative - %d%% ML penalty = %+d%% combined", total_init, ml_init_penalty, init) }
end)
