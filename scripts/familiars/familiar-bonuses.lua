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
	grouper2 = true,
	dancfrog = true,
	hippofam = true,
	pianocat = true,
	kloop = true,
	pep_rhino = true,
	frankengnome = true,
	jungman = true,
}

local function leprechaun_bonus(weight)
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

function estimate_current_familiar_bonuses()
	if ascensionpath("Avatar of Boris") then
		-- TODO: Move, not a familiar
		if clancy_instrumentid() == 3 then
			return make_bonuses_table { ["Item Drops from Monsters"] = fairy_bonus(clancy_level() * 5) }
		else
			return make_bonuses_table {}
		end
	end

	if not familiarid() then return make_bonuses_table {} end

	-- TODO: Use data files for vanilla fams + purse rat, hound dog, medium, woim, hobo monkey
	if familiar("Steam-Powered Cheerleader") then
		return make_bonuses_table { ["Item Drops from Monsters"] = fairy_bonus(math.floor(buffedfamiliarweight() * get_steampowered_cheerleader_bonus_multiplier())) }
	elseif familiar("Fancypants Scarecrow") or familiar("Mad Hatrack") then
		local famequip = equipment().familiarequip
		local name = famequip and maybe_get_itemname(famequip)
		local d = name and datafile("hatrack")[name]
		local bonuses = make_bonuses_table {}
		if d then
			-- SPADE: Is this floored?
			local fairy = d.familiar_types["Baby Gravy Fairy"]
			if fairy then bonuses = bonuses + { ["Item Drops from Monsters"] = fairy_bonus(math.floor(buffedfamiliarweight() * fairy)) } end
			local leprechaun = d.familiar_types["Leprechaun"]
			if leprechaun then bonuses = bonuses + { ["Meat from Monsters"] = leprechaun_bonus(math.floor(buffedfamiliarweight() * leprechaun)) } end
		end
		return bonuses
	elseif familiar("Purse Rat") then
		-- SPADE: Is this floored?
		return make_bonuses_table { ["Monster Level"] = math.floor(buffedfamiliarweight() / 2) }
	elseif familiar("Jumpsuited Hound Dog") then
		-- SPADE: Is this floored?
		return make_bonuses_table {
			["Item Drops from Monsters"] = fairy_bonus(math.floor(buffedfamiliarweight() * 1.25)),
			["Monsters will be more attracted to you"] = math.min(5, math.floor(buffedfamiliarweight() / 6)),
		}
	elseif familiar("Happy Medium") then
		return make_bonuses_table { ["Combat Initiative"] = buffedfamiliarweight() }
	elseif familiar("Oily Woim") then
		return make_bonuses_table { ["Combat Initiative"] = buffedfamiliarweight() * 2 }
	elseif familiar("Hobo Monkey") then
		-- SPADE: Is this floored?
		return make_bonuses_table { ["Meat from Monsters"] = leprechaun_bonus(buffedfamiliarweight() * 1.25), }
	else
		-- TODO: Use familiar IDs/names instead
		local bonuses = make_bonuses_table {}
		if vanilla_fairy[familiarpicture()] then bonuses = bonuses + { ["Item Drops from Monsters"] = fairy_bonus(buffedfamiliarweight()) } end
		if vanilla_lep[familiarpicture()] then bonuses = bonuses + { ["Meat from Monsters"] = leprechaun_bonus(buffedfamiliarweight()) } end
		return bonuses
	end
end
