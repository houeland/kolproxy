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
	["Buy the photograph (500 meat)"] = { getitem = "photograph of God", good_choice = true },
	["Politely decline"] = { leave_noturn = true },
})

add_choice_text("Rod Nevada, Vendor", { -- choice adventure number: 130
	["Accept (500 Meat)"] = { getitem = "photograph of a red nugget", good_choice = true },
	["Decline"] =  { leave_noturn = true },
})

add_choice_text("A Pre-War Dresser Drawer, Pa!", function()
	if have_skill("Torso Awaregness") then
		return {
			["Look in the drawer"] = { getitem = "Ye Olde Navy Fleece" },
			["Ignawer the drawer"] = { leave_noturn = true },
		}
	else
		return {
			["Look in the drawer"] = { getmeatmin = 200, getmeatmax = 300 },
			["Ignawer the drawer"] = { leave_noturn = true },
		}
	end
end)

add_printer("/choice.php", function()
	if not text:contains("Drawn Onward") or not text:contains("a column of four empty photo frames") then return end

	local checks = {
		photo1 = "photograph of God",
		photo2 = "photograph of a red nugget",
		photo3 = "photograph of a dog",
		photo4 = "photograph of an ostrich egg",
	}

	text = text:gsub("<select.-</select", function(selecttag)
		for name, item in pairs(checks) do
			if selecttag:contains([[name="]]..name..[["]]) then
				return selecttag:gsub([[(<option value="[0-9]*")(>]]..item..[[</option>)]], [[%1 selected="selected"%2]])
			end
		end
	end)
end)

add_automator("/choice.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("Drawn Onward") and text:contains("a column of four empty photo frames") then
		if have_item("photograph of God") and have_item("photograph of a dog") and have_item("photograph of a red nugget") and have_item("photograph of an ostrich egg") then
			text, url = post_page("/choice.php", { pwd = session.pwd, whichchoice = 872, option = 1, photo1 = get_itemid("photograph of God"), photo2 = get_itemid("photograph of a red nugget"), photo3 = get_itemid("photograph of a dog"), photo4 = get_itemid("photograph of an ostrich egg") })
		end
	end
end)

add_ascension_adventure_warning(function(zoneid)
	if zoneid == "palindome" and requestpath == "/place.php" and params.action == "pal_droffice" then return end
	if have_equipped_item("Mega Gem") then
		return "You might want to unequip the Mega Gem when you're not fighting Dr. Awkward.", "wearing mega gem in adventure"
	end
end)

local function check_dr_awkwards_office_access()
	if have_item("&quot;I Love Me, Vol. I&quot;") then return true end
	local pt = get_place("palindome")
	if not pt:contains("The Palindome") then return nil end
	return pt:contains("Dr. Awkward's Office")
end

local office_access = nil
function have_dr_awkwards_office_access()
	if not office_access then
		office_access = check_dr_awkwards_office_access()
	end
	return office_access
end

add_ascension_zone_check(386, function()
	if meat() < 500 and not (have_item("photograph of God") and have_item("photograph of a red nugget")) and have_dr_awkwards_office_access() ~= true then
		return "Palindome items cost 500 meat."
	end
end)

add_ascension_adventure_warning(function(zoneid)
	-- TODO: also incorrectly warns if you adventure in some random place without talisman, and you haven't unlocked office yet
	if zoneid == "palindome" and requestpath == "/place.php" and params.action == "pal_droffice" then return end
	if have_item("photograph of God") and have_item("photograph of a dog") and have_item("photograph of a red nugget") and have_item("photograph of an ostrich egg") and have_dr_awkwards_office_access() ~= false then
		return "You might want to place the photographs in Dr. Awkwards office.", "place palindome photographs"
	end
end)
