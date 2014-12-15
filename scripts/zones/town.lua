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
	if tonumber(params.whichslot) == 11 and not have_item("ten-leaf clover") then
		return "You do not have a ten-leaf clover to win the big rock.", "no clover for big rock"
	end
end)

-- museum
local ice_house_banished = nil
add_processor("/museum.php", function()
	ice_house_banished = nil
end)

function get_ice_house_banished_monster()
	if not ice_house_banished then
		local pt = get_page("/museum.php", { action = "icehouse" })
		ice_house_banished = pt:match([[perfectly%-preserved (.-), right where you left it]]) or "nothing"
	end
	return ice_house_banished
end

function is_monster_banished(monster)
	if day["nanorhino banished monster"] == monster then
		return true
	elseif get_ice_house_banished_monster() == monster then
		return true
	end
	if have_item("Staff of the Standalone Cheese") then
		local banished = retrieve_standalone_cheese_banished_monsters()
		for _, x in ipairs(banished) do
			if x == monster then
				return true
			end
		end
	end
end
