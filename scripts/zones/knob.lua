-- outskirts

add_choice_text("Knob Goblin BBQ", { -- choice adventure number: 113
	["Kiss the chef"] = "Light birthday cake",
	["Kick the chef"] = { text = "Fight a Knob Goblin Barbecue Team", good_choice = true },
	["Abscond with some goodies"] = "Get a (mostly useless) barbecue item",
})

add_choice_text("Malice in Chains", {
	["Serve your sentence"] = "Gain 4-5 muscle",
	["Rise and revolt"] = "Gain 6-8 muscle or lose 1 hp",
	["Plot a cunning escape"] = { text = "Fight a sleeping Knob Goblin Guard</b>", good_choice = true },
})

add_choice_text("When Rocks Attack", { -- choice adventure number: 118
	["&quot;Sure, I'll help.&quot;"] = { text = "Start wounded guard quest", getmeat = 30 },
	["&quot;Sorry, gotta run.&quot;"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Ennui is Wasted on the Young", { -- choice adventure number: 120
	["&quot;Wrestling's fun.  Wanna wrestle?&quot;"] = { text = "Gain 4-10 muscle, possibly get Pumped Up buff" },
	["&quot;You could go get me a beer.&quot;"] = { getitem = "ice-cold Sir Schlitz" },
	["&quot;Have you considered vandalism, loitering, and petty theft?&quot;"] = { text = "Gain 2-3 moxie", getitem = "lemon" },
	["&quot;Since you're bored, you're boring.  I'm outta here.&quot;"] = { leave_noturn = true, good_choice = true },
})

add_extra_ascension_adventure_warning(function(zoneid)
	if zoneid == 114 and have_item("Knob Goblin encryption key") then
		return "You already have the Knob Goblin encryption key.", "already have encryption key"
	end
end)

-- king

add_extra_ascension_warning("/cobbsknob.php", function()
	if params.action == "throneroom" then
		return "Remember to set the MCD if you want a specific boss drop.", "set mcd for goblin king"
	end
end)
