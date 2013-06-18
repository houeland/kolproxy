-- hippy camp

add_choice_text("An Inconvenient Truth", {
	["Check out the clothing"] = { getitem = "filthy knitted dread sack" },
	["Avert your eyes"] = { getitem = "filthy corduroys" },
	["Flee in terror before your brain cracks"] = { getmeatmin = 200, getmeatmax = 300 },
})

add_choice_text("Peace Wants Love", {
	["Agree to take his clothes"] = { getitem = "filthy corduroys" },
	["Say &quot;No thanks.&quot;"] = { getitem = "filthy knitted dread sack" },
	["Ask if he had anything in his pockets"] = { getmeatmin = 200, getmeatmax = 300 },
})

add_choice_text("Purple Hazers", { -- choice adventure number: 138
	["Search the pledge"] = { getitem = "Orcish cargo shorts" },
	["Examine the hazers"] = { getitem = "Orcish baseball cap" },
	["Leave the whole disturbing scene"] = { getitem = "homoerotic frat-paddle" },
})

-- pirate cove

add_choice_text("The Arrrbitrator", {
	["Vote for Jack Robinson"] = { getitem = "eyepatch" },
	["Vote for Sergeant Hook"] = { getitem = "swashbuckling pants" },
	["Vote for the Dread Pirate Bob"] = { getmeat = 100 },
})

add_choice_text("Barrie Me at Sea", {
	["Help Sammy Skillet"] = { getitem = "stuffed shoulder parrot", getmeat = -5 },
	["Help Captain Ladle"] = { getitem = "swashbuckling pants" },
	["Help the crocodile"] = { getmeat = 100 },
})

add_choice_text("Amatearrr Night", {
	["What's orange and sounds like a parrot?"] = { getitem = "stuffed shoulder parrot" },
	["So a pirate walks into a bar..."] = { getmeat = 100 },
	["What's gold and sounds like a pirate?"] = { getitem = "eyepatch" },
})

add_warning {
	message = "You already have the pirate outfit.",
	severity = "warning",
	zone = "The Obligatory Pirate's Cove",
	check = function()
		return not ascensionstatus("Aftercore") and
			((have_item("eyepatch") and have_item("swashbuckling pants") and have_item("stuffed shoulder parrot")) or have_item("pirate fledges"))
	end,
}
