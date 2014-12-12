local vanilla_fairies = {}
local vanilla_leprechauns = {}
local vanilla_volleyballs = {}

for name, d in pairs(datafile("familiars")) do
	if d.fairytype then
		vanilla_fairies[d.famid] = true
	end
	if d.leprechauntype then
		vanilla_leprechauns[d.famid] = true
	end
	if d.volleyballtype then
		vanilla_volleyballs[d.famid] = true
	end
end

function leprechaun_bonus(weight)
	return 2 * fairy_bonus(weight)
end

function volleyball_bonus(weight)
	return math.sqrt(weight)
end

function estimate_current_familiar_bonuses()
	if ascensionpath("Avatar of Boris") then
		-- TODO: Move, not a familiar
		if clancy_instrumentid() == 3 then
			return make_bonuses_table { ["Item Drops from Monsters"] = fairy_bonus(clancy_level() * 5) }
		else
			return make_bonuses_table {}
		end
	end

	if not familiarid() then
		return make_bonuses_table {}
	elseif familiar("Steam-Powered Cheerleader") then
		return make_bonuses_table { ["Item Drops from Monsters"] = fairy_bonus(math.floor(buffedfamiliarweight() * get_steampowered_cheerleader_bonus_multiplier())) }
	elseif familiar("Fancypants Scarecrow") or familiar("Mad Hatrack") then
		local famequip = equipment().familiarequip
		local name = famequip and maybe_get_itemname(famequip)
		local d = name and datafile("hatrack")[name]
		local bonuses = make_bonuses_table {}
		if d then
			-- SPADE: Is this floored?
			local fairy = d.familiar_types["Baby Gravy Fairy"]
			if fairy then bonuses.add { ["Item Drops from Monsters"] = fairy_bonus(math.floor(buffedfamiliarweight() * fairy)) } end
			local leprechaun = d.familiar_types["Leprechaun"]
			if leprechaun then bonuses.add { ["Meat from Monsters"] = leprechaun_bonus(math.floor(buffedfamiliarweight() * leprechaun)) } end
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
		return make_bonuses_table { ["Meat from Monsters"] = leprechaun_bonus(buffedfamiliarweight() * 1.25) }
	elseif familiar("Reanimated Reanimator") then
		return estimate_reanimated_reanimator_bonuses()
	elseif familiar("Baby Bugged Bugbear") then
		if have_equipped_item("bugged balaclava") then
			return make_bonuses_table { ["Stats Per Fight"] = volleyball_bonus(buffedfamiliarweight()) }
		else
			-- TODO
			return make_bonuses_table { ["Stats Per Fight"] = "?" }
		end
	elseif familiar("Llama Lama") then
		-- SPADE: Is this floored?
		return make_bonuses_table { ["Stats Per Fight"] = volleyball_bonus(math.floor(buffedfamiliarweight() / 2)) }
	elseif familiar("Wizard Action Figure") then
		-- TODO
		return make_bonuses_table { ["Item Drops from Monsters"] = "?", ["Stats Per Fight"] = "?" }
	elseif familiar("Jack-in-the-Box") then
		-- TODO
		return make_bonuses_table { ["Item Drops from Monsters"] = "?", ["Stats Per Fight"] = "?" }
	elseif familiar("Mutant Cactus Bud") then
		local multiplier = 1.30 - (0.15 * estimate_grimace_darkness())
		return make_bonuses_table { ["Meat from Monsters"] = leprechaun_bonus(buffedfamiliarweight()) * multiplier }
	elseif familiar("Mutant Fire Ant") then
		local multiplier = 1.30 - (0.15 * estimate_grimace_darkness())
		return make_bonuses_table { ["Item Drops from Monsters"] = fairy_bonus(buffedfamiliarweight()) * multiplier }
	else
		local bonuses = make_bonuses_table {}
		if vanilla_fairies[familiarid()] then bonuses.add { ["Item Drops from Monsters"] = fairy_bonus(buffedfamiliarweight()) } end
		if vanilla_leprechauns[familiarid()] then bonuses.add { ["Meat from Monsters"] = leprechaun_bonus(buffedfamiliarweight()) } end
		if vanilla_volleyballs[familiarid()] then bonuses.add { ["Stats Per Fight"] = volleyball_bonus(buffedfamiliarweight()) } end
		return bonuses
	end
end

function estimate_grimace_darkness()
	local gown_ML = estimate_item_equip_bonuses("Grimacite gown")["Monster Level"]
	return gown_ML / 10
end
