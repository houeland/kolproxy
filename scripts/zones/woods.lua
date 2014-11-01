-- spooky forest

add_interceptor("/adventure.php", function()
	if requested_zone_id() == get_zoneid("The Spooky Forest") then
		if session["unlocked hidden temple"] then return end
		local pt = get_page("/woods.php")
		session["unlocked hidden temple"] = pt:contains("The Hidden Temple")
	end
end)

add_warning {
	message = "You already have the required items to locate The Hidden Temple. You might want to use your Spooky Temple map instead.",
	type = "warning",
	zone = "The Spooky Forest",
	check = function()
		return have_item("Spooky Temple map") and have_item("spooky sapling") and have_item("Spooky-Gro fertilizer")
	end,
}

add_processor("/choice.php", function()
	if text:contains("Arboreal Respite") then
		session["want mosquito larva"] = text:contains("look for that mosquito larva")
	end
end)

local function want_spooky_item()
	if session["want mosquito larva"] then
		return "mosquito larva"
	elseif session["unlocked hidden temple"] ~= false then
		return "?"
	elseif not have_item("tree-holed coin") and not have_item("Spooky Temple map") then
		return "tree-holed coin"
	elseif not have_item("Spooky Temple map") then
		return "Spooky Temple map"
	elseif not have_item("Spooky-Gro fertilizer") then
		return "Spooky-Gro fertilizer"
	elseif not have_item("spooky sapling") then
		return "spooky sapling"
	end
	return "?"
end

add_choice_text("Arboreal Respite", function() -- choice adventure number: 502
	local want_item = want_spooky_item()
	return {
		["Follow the old road"] = { text = "Go to The Road Less Traveled (buy spooky sapling)", good_choice = (want_item == "spooky sapling") },
		["Explore the stream"] = { text = "Go to Consciousness of a Stream (get larva or tree-holed coin)", good_choice = (want_item == "mosquito larva" or want_item == "tree-holed coin") },
		["Brave the dark thicket"] = { text = "Go to Through Thicket and Thinnet (get spooky temple map, fertilizer or starting items)", good_choice = (want_item == "Spooky Temple map" or want_item == "Spooky-Gro fertilizer") },
	}
end)

add_choice_text("Consciousness of a Stream", function() -- choice adventure number: 505
	local want_item = want_spooky_item()
	return {
		["March to the marsh"] = session["want mosquito larva"] and { text = "Get mosquito larva", good_choice = true } or "Get 3 spooky mushrooms",
		["Squeeze into the cave"] = { text = "Get tree-holed coin and gain 300 meat (first time only)", good_choice = (want_item == "tree-holed coin") },
		["Go further upstream"] = "Go to An Interesting Choice (meet a vampire)",
	}
end)

add_choice_text("The Road Less Traveled", { -- choice adventure number: 503
	["Follow the ruts"] = "Gain some meat",
	["Knock on the cottage door"] = "Get wooden stakes or trade vampire hearts",
	["Talk to the hunter"] = { text = "Buy spooky saplings and sell bar skins", good_choice = true },
})

add_choice_text("Through Thicket and Thinnet", function() -- choice adventure number: 506
	local want_item = want_spooky_item()
	return {
		["Follow the even darker path"] = "Get starting items",
		["Investigate the dense foliage"] = { getitem = "Spooky-Gro fertilizer", good_choice = (want_item == "Spooky-Gro fertilizer") },
		["Follow the coin"] = { getitem = "Spooky Temple map", good_choice = true },
	}
end)

add_choice_text("O Lith, Mon", { -- choice adventure number: 507
	["Insert coin to continue"] = { getitem = "Spooky Temple map", good_choice = true },
	["Ignore the monolith"] = { disabled = true, leave_noturn = true },
	["Hit a monkey with a bone"] = { disabled = true, leave_noturn = true },
})


-- old spooky forest
add_choice_text("An Interesting Choice", { -- choice adventure number: 46
	["Interview the vampire"] = "Gain 5-10 moxie",
	["Interrogate the vampire"] = "Gain 5-10 muscle",
	["Inter the vampire"] = "<b>Fight a spooky vampire</b>",
})

add_choice_text("A Three-Tined Fork", { -- choice adventure number: 26
	["Take the normal path"] = "Get muscle class items, e.g. turtle totem",
	["Take the scorched path"] = "Get mysticality class items, e.g. saucepan + spices",
	["Take the dark path"] = "Get moxie class items, e.g. stolen accordion",
})

add_choice_text("Footprints", { -- choice adventure number: 27
	["Follow the single set to the copse"] = { getitem = { "seal-clubbing club", "seal-skull helmet" } },
	["Follow the double set to the other copse"] = { getitem = { "helmet turtle", "turtle totem" }, good_choice = true },
})

add_choice_text("A Pair of Craters", { -- choice adventure number: 28
	["Investigate the smoking crater"] = { getitem = { "pasta spoon", "ravioli hat" } },
	["Investigate the moist crater"] = { getitem = { "saucepan", "spices" }, good_choice = true },
})

add_choice_text("The Road Less Visible", { -- choice adventure number: 29
	["Continue down the path"] = { getitem = { "disco mask", "disco ball" } },
	["Investigate the bushes"] = { getitem = { "stolen accordion", "mariachi pants" }, good_choice = true },
})

-- hidden temple

add_choice_text("Fitting In", { -- choice adventure number: 582
	["Explore the higher levels"] = { text = "Go to top floor (unlock control room [quest step 1])" },
	["Poke around the ground floor"] = { text = "Go to center floor (use control room [quest step 2-4])" },
	["Head downwards"] = { text = "Go to bottom floor" },
})

add_choice_text("Such Great Heights", { -- choice adventure number: 579
	["Sidle along the ledge"] = { text = "Gain mysticality" },
	["Climb down some vines"] = { text = "Unlock control room [quest step 1]" },
	["Head towards the top of the temple"] = { text = "Get +3 adventures and extend buffs by 3 turns (once per ascension)" },
})

local temple_door_spoilers = {
	["a carved stone hemisphere"] = { text = "Gain muscle" },
	["a carved sun"] = { getitem = "ancient calendar fragment" },
	["a tongue-wagging stone gargoyle"] = { text = "Gain MP" },
	["that little lightning-tailed guy from your father's diary"] = { text = "Unlock hidden city [quest step 4]", good_choice = true },
}

add_choice_text("The Hidden Heart of the Hidden Temple", function()
	return { -- choice adventure number: 580
		["Go through the door"] = temple_door_spoilers[text:match("The door is decorated with (.-)%.")],
		["Go through the door (3 Adventures)"] = temple_door_spoilers[text:match("The door is decorated with (.-)%.")],
		["Go down the stairs"] = { text = "Use the control room [quest step 2]" },
		["Go back the way you came"] = { text = "Gain moxie" },
	}
end)

add_choice_text("Such Great Depths", { -- choice adventure number: 581
	["The glowing"] = { getitem = "glowing fungus" },
	["The glowering"] = { text = "Get +15 muscle/mysticality/moxie buff" },
	["The growling"] = { text = "Fight clan of cave bars", good_choice = true },
})

add_choice_text("Unconfusing Buttons", { -- choice adventure number: 584
	["The one with the ball on it"] = { text = "Enable gaining muscle" },
	["The one with the sun on it"] = { text = "Enable getting ancient calendar fragments" },
	["The one with the gargoyle on it"] = { text = "Enable gaining MP" },
	["The one with the cute little lightning-tailed guy on it"] = { text = "Enable hidden city unlock [quest step 3]", good_choice = true },
})

-- TODO: track hidden city being unlocked?

add_processor("/choice.php", function()
	if text:contains("the Nostril of the Serpent begins to vibrate and glow") or text:contains("split by the Nostril of the Serpent") or (text:contains("You have trusted your last vine") and not have_item("the Nostril of the Serpent")) then
		print("placed Nostril of the Serpent")
		ascension["zone.hidden temple.placed Nostril of the Serpent"] = "yes"
	end
end)

add_warning {
	message = "There's a semirare soon, be careful not to lose it by unlocking the hidden city.",
	zone = "The Hidden Temple",
	type = "extra",
	when = "ascension",
	check = function()
		return semirare_in_next_N_turns(3) and not semirare_in_next_N_turns(1)
	end,
}

add_extra_ascension_warning("use item: stone wool", function()
	-- TODO: this is not a big problem since it gives 5 turns, remove warning?
	if semirare_in_next_N_turns(3) then
		return "There's a semirare soon, be careful not to lose it by unlocking the hidden city.", "stone wool usage"
	end
end)

-- friars

add_itemdrop_counter("hellion cube", function(c)
	return "{ " .. make_plural(c, "hellion cube", "hellion cubes") .. " in inventory. }"
end)

add_itemdrop_counter("imp air", function(c)
	return "{ " .. c .. " of 5 found. }"
end)

add_itemdrop_counter("bus pass", function(c)
	return "{ " .. c .. " of 5 found. }"
end)

local svengolly_href = add_automation_script("automate-sven-golly", function()
	if (count_item("sponge cake") + count_item("comfy pillow") + count_item("booze-soaked cherry")) >= 2 and (count_item("gin-soaked blotter paper") + count_item("giant marshmallow") + count_item("beer-scented teddy bear")) >= 2 then
		local bognort = have_item("giant marshmallow") and "giant marshmallow" or "gin-soaked blotter paper"
		local stinkface = have_item("beer-scented teddy bear") and "beer-scented teddy bear" or "gin-soaked blotter paper"
		local flargwurm = have_item("booze-soaked cherry") and "booze-soaked cherry" or "sponge cake"
		local jim = have_item("comfy pillow") and "comfy pillow" or "sponge cake"
		async_post_page("/pandamonium.php", { action = "sven", preaction = "help" })
		async_post_page("/pandamonium.php", { action = "sven", bandmember = "Bognort", togive = get_itemid(bognort), preaction = "try" })
		async_post_page("/pandamonium.php", { action = "sven", bandmember = "Stinkface", togive = get_itemid(stinkface), preaction = "try" })
		async_post_page("/pandamonium.php", { action = "sven", bandmember = "Flargwurm", togive = get_itemid(flargwurm), preaction = "try" })
		return post_page("/pandamonium.php", { action = "sven", bandmember = "Jim", togive = get_itemid(jim), preaction = "try" })
	else
		critical "Not enough items to automatically complete Sven Golly quest."
	end
end)

add_printer("/pandamonium.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.action == "sven" then
		text = text:gsub([[(<input class="button" type="submit" value="Give It" />)]], function(button)
			if (count_item("sponge cake") + count_item("comfy pillow") + count_item("booze-soaked cherry")) >= 2 and (count_item("gin-soaked blotter paper") + count_item("giant marshmallow") + count_item("beer-scented teddy bear")) >= 2 then
				return button .. [[<br><br><a href="]]..svengolly_href { pwd = session.pwd }..[[" style="color: green">{ Complete quest. }</a>]]
			else
				return button .. [[<br><br><span style="color: gray">{ More items required to automate quest. }</span>]]
			end
		end)
	end
end)

-- Whitey's Grove

add_choice_text("Don't Fence Me In", {
	["Whitewash the fence"] = "Gain 20-30 muscle",
	["Steal the fence"] = "Get a white picket fence",
	["Jump the fence"] = "Get a piece of wedding cake + white rice [max 3 per day, or 5 with a rice bowl]",
})

add_choice_text("Rapido!", {
	["Steer for the cave"] = "Gain 20-30 mysticality",
	["Steer for the trees"] = "Get 3 jars of white lightning",
	["Steer for the laundromat"] = "Get a white collar",
})

add_choice_text("The Only Thing About Him is the Way That He Walks", {
	["Show him some moves"] = "Gain 20-30 moxie",
	["Show him a good time"] = "Get 3 boxes of wine",
	["Show him how easy it is to steal all of his stuff"] = "Get mullet wig",
})

add_printer("item drop", function()
	if item_name:contains(" pixel") then
		local white = count_item("white pixel")
		local red = count_item("red pixel")
		local green = count_item("green pixel")
		local blue = count_item("blue pixel")
		local c = white + math.min(red, green, blue)
		text = text .. [[<center><span style="color: green">{ ]] .. c .. [[ of 30 white pixels found. }</span></center><br>]]
	end
end)

-- TODO: no longer mystic.php
add_automator("/mystic.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("Would you like to hear a tale") then
		text = pick_up_continuum_transfunctioner()()
	end
end)

add_extra_always_adventure_warning(function(zoneid)
	if zoneid == 280 and have_item("stone wool") and not have_buff("Stone-Faced") then
		return "You might want to use your stone wool first.", "use stone wool for hidden temple"
	end
end)

add_always_adventure_warning(function(zoneid)
	if zoneid ~= 280 and have_buff("Stone-Faced") then
		return "You have the Stone-Faced buff and might want to adventure in the hidden temple.", "adventure in the hidden temple with stone-faced buff"
	end
end)

-- black forest
add_choice_text("All Over the Map", { -- choice adventure number: 923
	["Head toward the blackberry patch"] = { text = "Fight blackberry bush or craft blackberry galoshes" },
	["Visit the blacksmith's cottage"] = { text = "Craft black armor" },
	["Go to the black gold mine"] = { text = "Get black gold, Texas tea, or Black Lung" },
	["Check out the black church"] = { text = "Get black kettle drum or +item% buff" },
})

add_choice_text("You Found Your Thrill", { -- choice adventure number: 924
	["Attack the bushes"] = { text = "Fight blackberry bush" },
	["Visit the cobbler's house"] = { text = "Craft blackberry galoshes to speed up quest or other blackberry items" },
})

add_choice_text("Be Mine", { -- choice adventure number: 926
	["Go left"] = { getitem = "black gold" },
	["Go right"] = { getitem = "Texas tea" },
	["Go down"] = { text = "Get Black Lung effect" },
	["Never mine.  I mean mind."] = { text = "Go back" },
})

add_choice_text("Sunday Black Sunday", { -- choice adventure number: 927
	["Attend the mass"] = { text = "Get beaten up, or +item% buff with enough black equipment" },
	["Dive into the orchestra pit"] = { getitem = "black kettle drum" },
	["Sneak out the black back, black Jack"] = { text = "Go back" },
})
