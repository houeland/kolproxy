local places = {
		["346"] = "northwest",
		["347"] = "southwest",
		["348"] = "northast",
		["349"] = "southeast",
		["350"] = "ziggurat",
	}

add_warning {
	message = "You can equip an antique machete to cut away dense lianas without taking a turn (found in The Hidden Park).",
	type = "warning",
	when = "ascension",
	zone = { "An Overgrown Shrine (Northwest)", "An Overgrown Shrine (Southwest)", "An Overgrown Shrine (Northeast)", "An Overgrown Shrine (Southeast)", "A Massive Ziggurat" },
	check = function(zoneid)
		if not can_wear_weapons() then return end
		if have_equipped_item("antique machete") or have_equipped_item("machetito") or have_equipped_item("muculent machete") or have_equipped_item("papier-m&acirc;ch&eacute;te") then return end
		if get_ascension_counter("zone.hiddencity." .. places[tostring(zoneid)] .. ".liana.kills") < 3 then
			return true
		end
	end
}

local have_hidden_tavern_access = nil

function check_hidden_tavern_access()
	if have_item("book of matches") then return true end
	if not have_hidden_tavern_access then
		have_hidden_tavern_access = get_page("/shop.php", { whichshop = "hiddentavern" }):contains("overpriced tiki drinks")
	end
	return have_hidden_tavern_access
end

function have_apartment_building_cursed_buff()
	return have_buff("Thrice-Cursed") or have_buff("Twice-Cursed") or have_buff("Once-Cursed")
end

add_warning {
	message = "You might want to get Thrice-Cursed first for fighting the boss (by drinking Cursed Punch from The Hidden Tavern).",
	type = "extra",
	when = "ascension",
	zone = "The Hidden Apartment Building",
	check = function()
		if have_buff("Thrice-Cursed") then return end
		return check_hidden_tavern_access()
	end
}

add_warning {
	message = "You might want to buy a Bowl of Scorpions first to avoid fighting drunk pygmys (from The Hidden Tavern).",
	type = "extra",
	when = "ascension",
	zone = "The Hidden Bowling Alley",
	check = function()
		if have_item("Bowl of Scorpions") then return end
		return check_hidden_tavern_access()
	end
}

function have_mcclusky_file_items()
	return have_item("boring binder clip") and have_item("McClusky file (page 1)") and have_item("McClusky file (page 2)") and have_item("McClusky file (page 3)") and have_item("McClusky file (page 4)") and have_item("McClusky file (page 5)")
end

add_ascension_assistance(function() return have_mcclusky_file_items() and not ascensionpath("Bees Hate You") end, function()
	use_item("boring binder clip")
end)

add_warning {
	message = "You might want to use the boring binder clip first.",
	type = "warning",
	when = "ascension",
	zone = "The Hidden Office Building",
	check = function()
		return have_mcclusky_file_items()
	end
}

add_processor("/fight.php", function()
	if text:contains("dense liana") and text:contains("<!--WINWINWIN-->") then
		zone = text:gmatch("snarfblat=(%d%d%d)")()
		increase_ascension_counter("zone.hiddencity." .. places[zone] .. ".liana.kills")
	end
end)
