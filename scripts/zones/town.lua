-- The Sleazy Back Alley

add_choice_text("Under the Knife", { -- choice adventure number: 21
	["Yes!  I'm trapped in the wrong body! (500 Meat)"] = { text = "Pay 500 meat to switch gender" },
	["Umm, no thanks.  Seriously."] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Aww, Craps", { -- choice adventure number: 108
	["Cheat just a little"] = { text = "Gain 4-5 moxie" },
	["Cheat like crazy"] = { text = "Either gain 6-8 moxie and 30-40 meat, or lose 2 HP" },
	["Bilk 'em, Danno"] = { text = "Either gain 6-8 moxie and 40-50 meat and +5 moxie buff, or lose all HP" },
	["Walk away"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Dumpster Diving", { -- choice adventure number: 109
	["Punch the hobo"] = { text = "Fight drunken half-orc hobo", good_choice = true },
	["Rob the hobo"] = { text = "Get 3-4 meat and 4-5 moxie" },
	["Look under the hobo"] = { getitem = "Mad Train wine" },
})

add_choice_text("The Entertainer", { -- choice adventure number: 110
	["Put on a classical tragedy"] = { text = "Gain 4-5 moxie" },
	["Do a musical, instead"] = { text = "Gain 2-4 moxie and mysticality" },
	["Try for a science-fiction double feature"] = { text = "Get 15 meat and sometimes 6-8 mysticality" },
	["Introduce them to avant-garde"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Please, Hammer", { -- choice adventure number: 112
	["&quot;Sure, I'll help.&quot;"] = { text = "Start hammer miniquest (does not cost an adventure)", good_choice = true },
	["&quot;Sorry, no time.&quot;"] = { leave_noturn = true },
	["&quot;What's the frequency, Kenneth?&quot;"] = { text = "Gain 5-6 muscle" },
})

add_always_warning("/casino.php", function()
	if tonumber(params.whichslot) == 11 and not have("ten-leaf clover") then
		return "You do not have a ten-leaf clover to win the big rock.", "no clover for big rock"
	end
end)
