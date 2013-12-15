add_warning {
	message = "You might want to equip an antique machete to cut away dense lianas without taking a turn (from The Hidden Park).",
	type = "warning",
	when = "ascension",
	zone = { "An Overgrown Shrine (Northwest)", "An Overgrown Shrine (Southwest)", "An Overgrown Shrine (Northeast)", "An Overgrown Shrine (Southeast)", "A Massive Ziggurat" },
	check = function() return can_wear_weapons() and not have_equipped("antique machete") end
}

local have_hidden_tavern_access = nil

function check_hidden_tavern_access()
	if have_item("book of matches") then return true end
	if not have_hidden_tavern_access then
		have_hidden_tavern_access = get_page("/shop.php", { whichshop = "hiddentavern" }):contains("overpriced tiki drinks")
	end
	return have_hidden_tavern_access
end

add_warning {
	message = "You might want to get Thrice-Cursed first for fighting the boss (by drinking Cursed Punch from The Hidden Tavern).",
	type = "extra",
	when = "ascension",
	zone = "The Hidden Apartment Building",
	check = function()
		if buff("Thrice-Cursed") then return end
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

local places = {
	{ zone = "A Massive Ziggurat", choice = "Legend of the Temple in the Hidden City", option = "Leave" },
	{ zone = "An Overgrown Shrine (Southwest)", unlockzone = "The Hidden Hospital", choice = "Water You Dune", option = "Place your head in the impression", fallback = "Back away", sphere = "dripping" },
	{ zone = "An Overgrown Shrine (Northwest)", unlockzone = "The Hidden Apartment Building", choice = "Earthbound and Down", option = "Place your head in the impression", fallback = "Step away from the altar", sphere = "moss-covered" },
	{ zone = "An Overgrown Shrine (Southeast)", unlockzone = "The Hidden Bowling Alley", choice = "Fire When Ready", option = "Place your head in the impression", fallback = "Back off", sphere = "scorched" },
	{ zone = "An Overgrown Shrine (Northeast)", unlockzone = "The Hidden Office Building", choice = "Air Apparent", option = "Place your head in the impression", fallback = "Leave the altar", sphere = "crackling" },
}

function remaining_hidden_city_liana_zones()
	local citypt = get_page("/place.php", { whichplace = "hiddencity" })
	local remaining = {}
	for _, x in ipairs(places) do
		if not x.unlockzone or not citypt:contains(x.unlockzone) then
			remaining[x.zone] = true
		end
	end
	return remaining
end
