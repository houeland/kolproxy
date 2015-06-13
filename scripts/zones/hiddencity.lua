local liana_places = {
	"An Overgrown Shrine (Northwest)",
	"An Overgrown Shrine (Southwest)",
	"An Overgrown Shrine (Northeast)",
	"An Overgrown Shrine (Southeast)",
	"A Massive Ziggurat",
}

add_warning {
	message = "You can equip an antique machete to cut away dense lianas without taking a turn (found in The Hidden Park).",
	type = "warning",
	when = "ascension",
	zone = liana_places,
	check = function(zoneid)
		if not can_wear_weapons() then return end
		if have_equipped_item("antique machete") or have_equipped_item("machetito") or have_equipped_item("muculent machete") or have_equipped_item("papier-m&acirc;ch&eacute;te") then return end
		return remaining_hidden_city_liana_zones()[maybe_get_zonename(zoneid)]
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

function remaining_hidden_city_liana_zones()
	local remaining = {}
	for _, zone in ipairs(liana_places) do
		if get_ascension_counter("zone.hiddencity." .. get_zoneid(zone) .. ".liana.kills") < 3 then
			remaining[zone] = true
		end
	end
	return remaining
end

add_processor("won fight: dense liana", function()
	increase_ascension_counter("zone.hiddencity." .. tostring(get_adventure_zoneid()) .. ".liana.kills")
end)
