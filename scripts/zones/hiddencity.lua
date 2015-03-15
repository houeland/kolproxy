add_warning {
	message = "You can equip an antique machete to cut away dense lianas without taking a turn (found in The Hidden Park).",
	type = "warning",
	when = "ascension",
	zone = { "An Overgrown Shrine (Northwest)", "An Overgrown Shrine (Southwest)", "An Overgrown Shrine (Northeast)", "An Overgrown Shrine (Southeast)", "A Massive Ziggurat" },
	check = function(zoneid)
		if not can_wear_weapons() then return end
		if have_equipped_item("antique machete") or have_equipped_item("machetito") or have_equipped_item("muculent machete") or have_equipped_item("papier-m&acirc;ch&eacute;te") then return end
		for x, _ in pairs(remaining_hidden_city_liana_zones()) do
			if get_zoneid(x) == zoneid then
				return true
			end
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

local places = {
	{ zone = "A Massive Ziggurat", choice = "Legend of the Temple in the Hidden City", option = "Leave" },
	{ zone = "An Overgrown Shrine (Southwest)", unlockzone = "The Hidden Hospital", choice = "Water You Dune", option = "Place your head in the impression", fallback = "Back away", sphere = "dripping" },
	{ zone = "An Overgrown Shrine (Northwest)", unlockzone = "The Hidden Apartment Building", choice = "Earthbound and Down", option = "Place your head in the impression", fallback = "Step away from the altar", sphere = "moss-covered" },
	{ zone = "An Overgrown Shrine (Southeast)", unlockzone = "The Hidden Bowling Alley", choice = "Fire When Ready", option = "Place your head in the impression", fallback = "Back off", sphere = "scorched" },
	{ zone = "An Overgrown Shrine (Northeast)", unlockzone = "The Hidden Office Building", choice = "Air Apparent", option = "Place your head in the impression", fallback = "Leave the altar", sphere = "crackling" },
}

function remaining_hidden_city_liana_zones()
	local citypt = get_place("hiddencity")
	local remaining = {}
	for _, x in ipairs(places) do
		if not x.unlockzone or not citypt:contains(x.unlockzone) then
			remaining[x.zone] = true
		end
	end
	return remaining
end
