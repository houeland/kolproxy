-- tea party

add_processor("/choice.php", function()
	if text:contains([[&quot;Perhaps you should call Room Service and order some!&quot;<p>The Hatter squints thoughtfully at you.]]) then
		day["received Mad Tea Party buff"] = true
	end
end)

the_mad_tea_party_hat_buffs = {
	[1] = nil,
	[2] = nil,
	[3] = nil,
	[4] = "+20 to Monster Level",
	[5] = nil,
	[6] = "+3 Familiar Experience Per Combat",
	[7] = "Moxie +10",
	[8] = "Muscle +10",
	[9] = "Weapon Damage +15",
	[10] = "Mysticality +10",
	[11] = "Spell Damage +30%",
	[12] = "Maximum HP +50",
	[13] = "Maximum MP +25",
	[14] = "+10 Sleaze Damage",
	[15] = "Spell Damage +15",
	[16] = "+10 Cold Damage",
	[17] = "+10 Spooky Damage",
	[18] = "+10 Stench Damage",
	[19] = "+10 Hot Damage",
	[20] = "Weapon Damage +30%",
	[21] = "Regenerate 5-10 MP per Adventure",
	[22] = "+40% Meat from Monsters",
	[23] = "Mysticality +20%",
	[24] = "+5 to Familiar Weight",
	[25] = "+3 Stats Per Fight",
	[26] = "Moxie +20%",
	[27] = "Muscle +20%",
	[28] = "+20% Item Drops from Monsters",
	[29] = nil,
	[30] = nil,
	[31] = "+40% Combat Initiative",
}

local mad_tea_party_href
mad_tea_party_href = add_automation_script("custom-choose-mad-tea-party-hat", function()
	if params.choosehat then
		local eq = equipment()
		local pt, pturl = equip_item(params.choosehat)()
		if equipment().hat == get_itemid(params.choosehat) then
			if not have_buff("Down the Rabbit Hole") then
				use_item("&quot;DRINK ME&quot; potion")()
			end
			async_get_place("plains")
			async_get_place("rabbithole")
			get_place("rabbithole", "rabbithole_teaparty")
			pt, pturl = post_page("/choice.php", { pwd = session.pwd, whichchoice = 441, option = 1 })
		end
		set_equipment(eq)
		return pt, pturl
	end

	local lenmap = {}
	for x, _ in pairs(inventory()) do
		local name = maybe_get_itemname(x)
		local d = maybe_get_itemdata(x)
		if name and d and d.equipment_slot == "hat" then
			local len = name:gsub(" ", ""):len()
			if not lenmap[len] or not lenmap[len].ok then
				lenmap[len] = { name = name, ok = can_equip_item(name) }
			end
		end
	end

	local lens = {}
	for x, _ in pairs(the_mad_tea_party_hat_buffs) do
		table.insert(lens, x)
	end
	table.sort(lens)

	local hatlines = {}
	for _, len in ipairs(lens) do
		if lenmap[len] and lenmap[len].ok then
			table.insert(hatlines, string.format([[<a href="%s" style="color: green">%s</a><br>]], mad_tea_party_href { pwd = session.pwd, choosehat = lenmap[len].name }, tostring(the_mad_tea_party_hat_buffs[len]) .. ": " .. lenmap[len].name))
		elseif lenmap[len] then
			table.insert(hatlines, [[<span style="color: darkorange">]] .. tostring(the_mad_tea_party_hat_buffs[len]) .. ": " .. lenmap[len].name .. "</span><br>")
		else
			table.insert(hatlines, [[<span style="color: gray">]] .. tostring(the_mad_tea_party_hat_buffs[len]) .. ": (none)</span><br>")
		end
	end

	return make_kol_html_frame(table.concat(hatlines, "\n"), "Choose hat for Mad Tea Party"), requestpath
end)

add_choice_text("The Mad Tea Party", function()
	local hatid = equipment().hat
	if not hatid then
		return {
			["Try to get a seat"] = "Get hat-based buff: None (you get turned away)",
			["Slouch away"] = "Leave",
		}
	else
		local hatname = item_api_data(hatid).name
		local hatchars = hatname:gsub(" ", ""):len()
		return {
			["Try to get a seat"] = "Get hat-based buff: " .. (the_mad_tea_party_hat_buffs[hatchars] or "?") .. " (" .. hatchars .. " characters)",
			["Slouch away"] = "Leave",
		}
	end
end)

add_printer("/place.php", function()
	if params.whichplace == "rabbithole" then
		text = text:gsub([[</body>]], [[<center><a href="]]..mad_tea_party_href { pwd = session.pwd }..[[" style="color: green">{ Choose hat }</a></center>%0]])
	end
end)

add_modifier_maximizer_script_link_function(function()
	if (have_buff("Down the Rabbit Hole") or have_item("&quot;DRINK ME&quot; potion")) and not day["received Mad Tea Party buff"] then
		return "Get Mad Tea Party daily buff", mad_tea_party_href { pwd = session.pwd }
	end
end)
