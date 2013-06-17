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

add_choice_text("Wheel in the Clouds in the Sky, Keep On Turning", function()
	if choice_adventure_number == 9 then
		return {
			["Turn the wheel clockwise"] = "Turn to mysticality",
			["Turn the wheel counterclockwise"] = "Turn to moxie",
			["Leave the wheel alone"] = "Leave at muscle (does not cost an adventure)",
		}
	elseif choice_adventure_number == 10 then
		return {
			["Turn the wheel clockwise"] = "Turn to back door (quest)",
			["Turn the wheel counterclockwise"] = "Turn to muscle",
			["Leave the wheel alone"] = "Leave at mysticality (does not cost an adventure)",
		}
	elseif choice_adventure_number == 11 then
		return {
			["Turn the wheel clockwise"] = "Turn to moxie",
			["Turn the wheel counterclockwise"] = "Turn to mysticality",
			["Leave the wheel alone"] = "Leave at back door (does not cost an adventure)",
		}
	elseif choice_adventure_number == 12 then
		return {
			["Turn the wheel clockwise"] = "Turn to muscle",
			["Turn the wheel counterclockwise"] = "Turn to back door (quest)",
			["Leave the wheel alone"] = "Leave at moxie (does not cost an adventure)",
		}
	end
end)

add_itemdrop_counter("star chart", function(c)
	return "{ " .. make_plural(c, "star chart", "star charts") .. " in inventory. }"
end)

add_printer("/beanstalk.php", function()
	local castle = text:match([[title="The Castle in the Clouds in the Sky %(1%)"]])
	local hits = text:match([[title="The Hole in the Sky %(1%)"]])
	if not castle then
		local want = { "Tissue Paper Immateria", "Tin Foil Immateria", "Gauze Immateria", "Plastic Wrap Immateria" }
		local got = 0
		for item in table.values(want) do
			if have(item) then
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
	elseif castle and not hits then
		local want = { "awful poetry journal", "giant needle", "furry fur" }
		local status = "<b>Required items</b><br>"
		for _, item in ipairs(want) do
			local itemtext = "?"
			if have(item) then
				itemtext = [[<span style="color: green;">]] .. item .. [[</span>]]
			else
				itemtext = [[<span style="color: darkorange;">]] .. item .. [[</span>]]
			end
			status = status .. itemtext .. "<br>"
		end
		text = text:gsub([[(</table></centeR>)(</body>)]], [[%1<center>]] .. status .. [[</center>%2]])
	elseif hits then
	end
end)

add_automator("item drop: quantum egg", function()
	if not setting_enabled("automate simple tasks") then return end
	meatpaste_items("S.O.C.K.", "quantum egg")
end)
