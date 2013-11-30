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

-- TODO: handle differently
local function estimate_fam_item()
	if ascensionpath("Avatar of Boris") then
		if clancy_instrumentid() == 3 then
			return fairy_bonus(clancy_level() * 5)
		else
			return 0
		end
	end
	-- TODO: Use familiar names instead of pictures
	-- Preferably datafile
	if familiar("Steam-Powered Cheerleader") then
		return fairy_bonus(math.floor(buffedfamiliarweight() * get_steampowered_cheerleader_bonus_multiplier()))
	elseif vanilla_fairy[familiarpicture()] then
		return fairy_bonus(buffedfamiliarweight())
	elseif familiarpicture() == "hounddog" then
		return fairy_bonus(math.floor(buffedfamiliarweight() * 1.25))
	elseif familiarpicture() == "spanglehat" and familiarid() == 82 then
		return fairy_bonus(buffedfamiliarweight() * 2)
	elseif familiarpicture() == "spanglepants" and familiarid() == 152 then
		return fairy_bonus(buffedfamiliarweight() * 2)
	elseif familiarpicture() == "skirt" and familiarid() == 152 then
		return fairy_bonus(buffedfamiliarweight() * 4)
	else
		return 0
	end
end
__DONOTUSE_estimate_familiar_item_drop_bonus = estimate_fam_item

-- TODO: handle differently
function estimate_other_item()
	local item = estimate_fam_item()
	if ascension["zone.manor.quartet song"] == "Le Mie Cose Favorite" then
		item = item + 5
	end
	if moonsign("Packrat") then
		item = item + 10
	end
	return item
end
