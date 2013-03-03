add_printer("/clan_hobopolis.php", function()
	text = text:gsub([[<a href="adventure.php%?snarfblat=[0-9]+"><img src="http://images.kingdomofloathing.com/otherimages/hobopolis/.-([0-9]+).gif" width=500 height=.-></a>]], [[%0<p><span style="color: green">{ Image %1/10 }</span>]]) -- TODO-future: redo regex a bit?
end)

add_choice_text("Hot Dog!  I Mean... Door!", {
	["Open the door"] = "Add ~10k meat to clan coffers and add hot hobos to zone (only if it's cold enough)",
	["Leave the door be"] = "<b>Leave</b>",
})

add_choice_text("Piping Hot", {
	["Turn the valve"] = "Send hot water to PLD",
	["Leave the valve alone"] = "<b>Leave</b>",
})

add_choice_text("The Frigid Air", {
	["Pry open the freezer"] = "<b>Get a frozen banquet</b>",
	["Pry open the fridge"] = "Add ~10k meat to clan coffers",
	["Pry yourself away from the situation"] = "Leave",
})

add_choice_text("Piping Cold", {
	["Turn the first valve"] = "Send cold water to BB",
	["Turn the second valve"] = "Send cold water to PLD",
	["Go all CLUE on the third pipe"] = "Make more icicles",
})

add_choice_text("I Refuse!", {
	["Explore the junkpile"] = "<b>Get 3 random items</b>",
	["Climb back out"] = "Leave",
})
