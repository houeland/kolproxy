-- spooky forest

local function want_spooky_item()
	if text:contains("look for that mosquito larva") then
		return "mosquito larva"
	-- TODO: How do we know if we've completed the quest, or just haven't done anything? Just print progress instead?
-- 	elseif not have("tree-holed coin") and not have("Spooky Temple map") then
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

add_choice_text("Consciousness of a Stream", { -- choice adventure number: 505
	["March to the marsh"] = "Get mosquito larva or 3 spooky mushrooms",
	["Squeeze into the cave"] = "Get tree-holed coin and gain 300 meat (first time only)",
	["Go further upstream"] = "Go to An Interesting Choice (meet a vampire)",
})

add_choice_text("The Road Less Traveled", { -- choice adventure number: 503
	["Follow the ruts"] = "Gain some meat",
	["Knock on the cottage door"] = "Get wooden stakes or trade vampire hearts",
	["Talk to the hunter"] = { text = "Buy spooky saplings and sell bar skins", good_choice = true },
})

add_choice_text("Through Thicket and Thinnet", { -- choice adventure number: 506
	["Follow the even darker path"] = "Get starting items",
	["Investigate the dense foliage"] = { getitem = "Spooky-Gro fertilizer" },
	["Follow the coin"] = { getitem = "Spooky Temple map" },
})

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
	if text:contains("the Nostril of the Serpent begins to vibrate and glow") or text:contains("split by the Nostril of the Serpent") or (text:contains("You have trusted your last vine") and not have("the Nostril of the Serpent")) then
		print("placed Nostril of the Serpent")
		ascension["zone.hidden temple.placed Nostril of the Serpent"] = "yes"
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
		local bognort = have("giant marshmallow") and "giant marshmallow" or "gin-soaked blotter paper"
		local stinkface = have("beer-scented teddy bear") and "beer-scented teddy bear" or "gin-soaked blotter paper"
		local flargwurm = have("booze-soaked cherry") and "booze-soaked cherry" or "sponge cake"
		local jim = have("comfy pillow") and "comfy pillow" or "sponge cake"
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
