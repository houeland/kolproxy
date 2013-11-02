add_warning {
	message = "You might want to equip an antique machete to cut away dense lianas without taking a turn.",
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
