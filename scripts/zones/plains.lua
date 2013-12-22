-- bat hole

add_extra_ascension_adventure_warning(function(zoneid)
	if zoneid == 34 then
		if not have_buff("Polka of Plenty") then
			if have_skill("The Polka of Plenty") then
				return "You might want Polka of Plenty for the bodyguards who drop a lot of meat.", "polka of plenty for bat bodyguards"
			end
		end
		if not have_buff("Greedy Resolve") and have_item("resolution: be wealthier") then
			return "You might want to use resolution: be wealthier for the bodyguards who drop a lot of meat.", "greedy resolve for bat bodyguards"
		end
	end
end)

-- The Cola Wars Battlefield

add_choice_text("The Effervescent Fray", {
	["Listen to the red leader"] = "Get Cloaca-Cola fatigues",
	["Listen to the blue leader"] = { text = "Get Dyspepsi-Cola shield", good_choice = true },
	["Don't get involved"] = "Gain 15 mysticality",
})

add_choice_text("What is it Good For?", {
	["Help the Dyspepsi soldier"] = "Get Dyspepsi-Cola helmet",
	["Help the Cloaca soldier"] = { text = "Get Cloaca-Cola shield", good_choice = true },
	["Don't get involved"] = "Gain 15 moxie",
})

add_choice_text("Smells Like Team Spirit", { -- choice adventure number: 41
	["Dyspepsi-Cola"] = "Get Dyspepsi-Cola fatigues",
	["Cloaca-Cola"] = "Get Cloaca-Cola helmet",
	["Don't get involved"] = "Gain 15 muscle",
})

-- tower ruins

add_itemdrop_counter("disembodied brain", function(c)
	return "{ " .. make_plural(c, "brain", "brains") .. " in inventory. }"
end)

-- palindome

add_choice_text("Sun at Noon, Tan Us", {
	["A little while"] = { text = "Gain moxie", good_choice = true },
	["A medium while"] = "Gain moxie or Sunburned effect",
	["A long while"] = { text = "Gain Sunburned effect", disabled = true },
})

add_choice_text("No sir, away!  A papaya war is on!", {
	["Dive into the bunker"] = "Get 3 papayas",
	["Leap into the fray!"] = "Lose 3 papayas, gain up to ~300 in all stats",
	["Give the men a pep talk"] = { text = "Gain 100 in all stats", good_choice = true },
})

add_choice_text("Do Geese See God?", { -- choice adventure number: 129
	["Buy the photograph (500 meat)"] = { text = "Get photograph of God", good_choice = true },
	["Politely decline"] = { leave_noturn = true },
})

add_choice_text("Rod Nevada, Vendor", { -- choice adventure number: 130
	["Accept (500 Meat)"] = { text = "Get hard rock candy", good_choice = true },
	["Decline"] =  { leave_noturn = true },
})

add_printer("/palinshelves.php", function()
	set_shelf = function(text, shelf, choose)
		text = text:gsub("(<select name="..shelf..">.-<option value=[0-9]*)(>"..choose.."</option>)", [[%1 selected="selected"%2]]) -- TODO-future: redo for faster regex?
		return text
	end
	text = set_shelf(text, "whichitem1", "photograph of God")
	text = set_shelf(text, "whichitem2", "hard rock candy")
	text = set_shelf(text, "whichitem3", "ketchup hound")
	text = set_shelf(text, "whichitem4", "hard%-boiled ostrich egg")
end)

add_automator("/palinshelves.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("It looks as though you could put some things on the shelves") then
		-- Currently always true if you find the adventure
		if have_item("photograph of God") and have_item("hard rock candy") and have_item("ketchup hound") and have_item("hard-boiled ostrich egg") then
			text, url = post_page("/palinshelves.php", { action = "placeitems", whichitem1 = get_itemid("photograph of God"), whichitem2 = get_itemid("hard rock candy"), whichitem3 = get_itemid("ketchup hound"), whichitem4 = get_itemid("hard-boiled ostrich egg") })
		end
	end
end)

add_ascension_zone_check(119, function()
	if meat() < 500 and not have_item("&quot;I Love Me, Vol. I&quot;") and not (have_item("photograph of God") and have_item("hard rock candy")) then
		return "Palindome items cost 500 meat."
	end
end)

add_ascension_adventure_warning(function(zoneid)
	if zoneid ~= 119 and have_equipped_item("Mega Gem") then
		return "You might want to unequip the Mega Gem when you're not adventuring in the Palindome.", "wearing mega gem outside palindome"
	end
end)
