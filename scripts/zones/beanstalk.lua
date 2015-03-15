-- airship

add_choice_text("Random Lack of an Encounter", { -- choice adventure number: 182
	["Investigate the crew quarters"] = "Fight airship monster (MagiMechTech MechaMech if you have +20 ML or more)",
	["Check the cargo hold"] = { getitem = "Penultimate Fantasy chest" },
	["Head down to the galley"] = "Lose 40-50 HP, gain 18-40ish stats",
	["Gallivant down to the head"] = { getitem = "model airship" },
})

add_choice_text("Hammering the Armory", { -- choice adventure number: 178
	["Dig through the stuff"] = { getitem = "bronze breastplate" },
	["Blow this popsicle stand"] = { leave_noturn = true, good_choice = true },
})

-- castle in the clouds in the sky

local completed_castle_quest = nil
function check_castle_quest_completed()
	if not completed_castle_quest and level() >= 10 then
		completed_castle_quest = not get_page("/questlog.php", { which = 1 }):contains("The Rain on the Plains is Mainly Garbage")
	end
	return completed_castle_quest
end

add_warning {
	message = "You might want to wear your Mohawk wig to finish the castle quest faster.",
	type = "warning",
	when = "ascension",
	zone = "The Castle in the Clouds in the Sky (Top Floor)",
	check = function()
		if have_equipped_item("Mohawk wig") then return end
		if not have_item("Mohawk wig") then return end
		return not check_castle_quest_completed()
	end
}

-- TODO: only a good choice if you don't have one
add_choice_text("Home on the Free Range", { -- choice adventure number: 1026
	["Look under the bed"] = { text = "Get 3-4 mostly useless candy items" },
	["Investigate the noisy drawer"] = { getitem = "electric boning knife", good_choice = true },
	["Leave through a vent"] = { leave_noturn = true },
})

-- hole in the sky

add_itemdrop_counter("star chart", function(c)
	return "{ " .. make_plural(count_item("star"), "star", "stars") .. ", " .. make_plural(count_item("line"), "line", "lines") .. ", and " .. make_plural(count_item("star chart"), "star chart", "star charts") .. " in inventory. }"
end)

add_itemdrop_counter("star", function(c)
	return "{ " .. make_plural(count_item("star"), "star", "stars") .. ", " .. make_plural(count_item("line"), "line", "lines") .. ", and " .. make_plural(count_item("star chart"), "star chart", "star charts") .. " in inventory. }"
end)

add_itemdrop_counter("line", function(c)
	return "{ " .. make_plural(count_item("star"), "star", "stars") .. ", " .. make_plural(count_item("line"), "line", "lines") .. ", and " .. make_plural(count_item("star chart"), "star chart", "star charts") .. " in inventory. }"
end)

add_printer("/beanstalk.php", function()
	if not have_item("S.O.C.K.") then
		local want = { "Tissue Paper Immateria", "Tin Foil Immateria", "Gauze Immateria", "Plastic Wrap Immateria" }
		local got = 0
		for _, item in ipairs(want) do
			if have_item(item) then
				got = got + 1
			end
		end
		local status = "<b>Quest progress</b><br>"
		if got < 4 then
			status = status .. got .. [[ / 4 immateria<br>]]
		else
			status = status .. [[<span style="color: green;">]] .. got .. [[ / 4 immateria</span><br>]]
		end
		status = status .. "Need S.O.C.K.<br>"
		text = text:gsub([[(</table></centeR>)(</body>)]], [[%1<center>]] .. status .. [[</center>%2]])
	end
end)
