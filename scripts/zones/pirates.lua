add_choice_text("The Infiltrationist", { -- choice adventure number: 188
	["Attempt a frontal assault"] = "Get dentures if wearing frat outfit",
	["Go in through the side door"] = "Get dentures if wearing a mullet wig, with a briefcase",
	["Catburgle"] = { text = "Get dentures if wearing a frilly skirt, with 3 hot wings", good_choice = true, countitem = "hot wing" },
})

-- barrr

add_choice_text("A Test of Testarrrsterone", {
	["Cheat"] = "Gain stats",
	["Drink up and hope for the best"] = "Get 3 drunk and stats",
	["Wuss out"] = "Gain moxie",
})

add_choice_text("Yes, You're a Rock Starrr", function()
	if drunkenness() == 0 then
		return {
			["Sing the high-pitched, densely harmonic &quot;Knob Goblin Rhapsody.&quot;"] = "Get 2-5 base booze",
			["Sing the ridiculously long ballad &quot;Banana Cream Pie.&quot;"] = "Get 2-3 drinks",
			["Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;"] = "Fight a tetchy pirate",
		}
	else
		return {
			["Sing the high-pitched, densely harmonic &quot;Knob Goblin Rhapsody.&quot;"] = "Get 2-5 base booze",
			["Sing the ridiculously long ballad &quot;Banana Cream Pie.&quot;"] = "Get 2-3 drinks",
			["Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;"] = "Gain stats",
		}
	end
end)

add_choice_text("That Explains All The Eyepatches", function()
	if mainstat_type("Muscle") then
		return {
			["Carefully throw the darrrt at the tarrrget"] = "Fight a tipsy pirate",
			["Pull one over on the pirates"] = "Get shot of rotgut",
			["Throw hard and hope for the best"] = "Gain 3 drunk + stats",
		}
	elseif mainstat_type("Mysticality") then
		return {
			["Carefully throw the darrrt at the tarrrget"] = "Gain 3 drunk + stats",
			["Pull one over on the pirates"] = "Get shot of rotgut",
			["Throw hard and hope for the best"] = "Get shot of rotgut",
		}
	elseif mainstat_type("Moxie") then
		return {
			["Carefully throw the darrrt at the tarrrget"] = "Fight a tipsy pirate",
			["Pull one over on the pirates"] = "Gain 3 drunk + stats",
			["Throw hard and hope for the best"] = "Get shot of rotgut",
		}
	end
end)

local fcle_unlocked = nil
add_warning {
	message = "You don't have an insult book.",
	type = "warning",
	zone = "Barrrney's Barrr",
	check = function()
		if not have_item("The Big Book of Pirate Insults") and not have_item("Massive Manual of Marauder Mockery") and not fcle_unlocked then
			local pt = get_page("/cove.php")
			fcle_unlocked = pt:contains("F'c'le")
			return not fcle_unlocked
		end
	end,
}

add_processor("/fight.php", function()
	if text:contains("The pirate sneers at you and replies") or text:contains("The pirate stammers for a moment") then
		fight["item.The Big Book of Pirate Insults"] = "used"
	end
end)

add_processor("/fight.php", function()
	if text:match("The pirate sneers at you and replies") then
		local tbl = ascension["zone.pirates.insults"] or {}
		insult = text:match("The pirate sneers at you and replies &quot;(.-)&quot;")
		print("INFO pirate insult: "..tostring(insult))
		local should_add = true
		for from, to in pairs(tbl) do
			if to == insult then
				should_add = false
			end
		end
		if should_add then
			table.insert(tbl, insult)
			ascension["zone.pirates.insults"] = tbl
			fight["pirate.new insult"] = "yes"
		end
	end
end)

add_printer("/fight.php", function()
	if text:contains("The pirate sneers at you and replies") then
		local tbl = ascension["zone.pirates.insults"] or {}
		if fight["pirate.new insult"] == "yes" then
			text = text:gsub("(The pirate sneers at you and replies &quot;)(.-)(&quot;)", [[%1<span style="color: darkorange">%2</span>%3 (]]..#tbl.." / 8 insults)")
		else
			text = text:gsub("(The pirate sneers at you and replies &quot;)(.-)(&quot;)", [[%1<span style="color: darkslategray">%2</span>%3 (]]..#tbl.." / 8 insults)")
		end
	end
end)

local beer_pong_responses = {
	["Arrr, the power of me serve'll flay the skin from yer bones!"] = "Obviously neither your tongue nor your wit is sharp enough for the job.",
	["Do ye hear that, ye craven blackguard?  It be the sound of yer doom!"] = "It can't be any worse than the smell of your breath!",
	["Suck on <i>this</i>, ye miserable, pestilent wretch!"] = "That reminds me, tell your wife and sister I had a lovely time last night.",
	["The streets will run red with yer blood when I'm through with ye!"] = "I'd've thought yellow would be more your color.",
	["Yer face is as foul as that of a drowned goat!"] = "I'm not really comfortable being compared to your girlfriend that way.",
	["When I'm through with ye, ye'll be crying like a little girl!"] = "It's an honor to learn from such an expert in the field.",
	["In all my years I've not seen a more loathsome worm than yerself!"] = "Amazing!  How do you manage to shave without using a mirror%?",
	["Not a single man has faced me and lived to tell the tale!"] = "It only seems that way because you haven't learned to count to one.",
}

add_printer("/beerpong.php", function()
	local choice = nil
	for from, to in pairs(beer_pong_responses) do
		if text:contains(from) then
			choice = to
		end
	end
	print("INFO: beer pong choice", choice)
	if choice and text:match(choice) then
		text = text:gsub("(<option value=[0-9]+)(>"..choice.."</option>)", [[%1 selected="selected"%2]])
	else
		text = text:gsub("<select name=response>", [[%0<option selected="selected" value=11>-- Missing insult --</option>]])
	end
end)

add_automator("/beerpong.php", function()
	if not setting_enabled("automate simple tasks") then return end
	local function solve_beerpong(n)
		if n <= 0 then return end
		local choice = nil
		for from, to in pairs(beer_pong_responses) do
			if text:contains(from) then
				choice = to
			end
		end
		if choice and text:match(choice) then
			responsenum = tonumber(text:match("<option value=([0-9]+)>"..choice.."</option>"))
			print("INFO: beer pong choose choice", choice, responsenum)
			if responsenum then
				text, url = post_page("/beerpong.php", { response = responsenum })
				return solve_beerpong(n - 1)
			end
		end
	end
	solve_beerpong(3)
end)

add_printer("/cove.php", function()
	if not text:contains([[title="The F'c'le (1)"]]) then
		local tbl = ascension["zone.pirates.insults"] or {}
		local count = #tbl
		local chance = 0
		if count >= 3 then
			chance = count / 8 * (count - 1) / 7 * (count - 2) / 6
		end
		local status = string.format("<b>%s collected (%.1f%% chance)</b><br>", make_plural(count, "insult", "insults"), chance * 100)
		status = status .. table.concat(tbl, "<br>")
		text = text:gsub([[(</table>)(</body>)]], function(a, b) return a .. "<center>" .. status .. "</center>" .. b end)
	end
end)

add_interceptor("use item: Orcish Frat House blueprints", function() -- TODO: split off warning and automation as separate things!
	if not setting_enabled("automate simple tasks") then return end
	local options = {
		{ choicenum = 1, equipment = { hat = "Orcish baseball cap", weapon = "homoerotic frat-paddle", pants = "Orcish cargo shorts" } },
		{ choicenum = 2, equipment = { hat = "mullet wig" }, inventory = { name = "briefcase", amount = 1 } },
		{ choicenum = 3, equipment = { pants = "frilly skirt" }, inventory = { name = "hot wing", amount = 3 } },
	}
	local buyable = {
		["frilly skirt"] = (moonsign_area() == "Degrassi Knoll"),
	}
	for _, opt in ipairs(options) do
		local possible = true
		for _, want in pairs(opt.equipment) do
			if not have_item(want) and not buyable[want] then
				possible = false
			elseif want == "homoerotic frat-paddle" and not can_wear_weapons() then
				-- Can't use in fist or boris
				possible = false
			end
		end
		if opt.inventory and count_item(opt.inventory.name) < opt.inventory.amount then
			possible = false
		end
-- 		print("option", choicenum, possible)
		if possible then
-- 			print("doing option", opt.choicenum)
			local eq = equipment()
			for where, want in pairs(opt.equipment) do
				if not have_item(want) then
					store_buy_item(want, "4", 1)
				end
				equip_item(want, where)
			end
			local neweq = equipment()
			for where, want in pairs(opt.equipment) do
				if neweq[where] ~= get_itemid(want) then
					error("Failed to equip " .. want)
				end
			end
			async_post_page(requestpath, params)
			async_get_page("/choice.php")
			text = post_page("/choice.php", { pwd = params.pwd, whichchoice = 188, option = opt.choicenum })
			text = text:gsub([[<a href="adventure.php%?snarfblat=27">Adventure Again %(The Orcish Frat House%)</a>]], "")
			set_equipment(eq)
			return text, requestpath
		end
	end
	return intercept_warning { message = "You do not have the equipment/items to retrieve the dentures.", id = "no equipment for retrieving dentures" }
end)

-- f'cl'e

add_choice_text("Chatterboxing", {
	["Fight chatty fire with chatty fire"] = "Gain moxie",
	["Distract them with shiny objects"] = "Banish chatty pirate if you have a valuable trinket, otherwise lose HP",
	["Ride it out"] = "Gain muscle",
	["Jump overboard"] = "Gain mysticality",
})

add_extra_ascension_adventure_warning(function(zoneid)
	if zoneid == 158 then
		local touse = {}
		for _, x in ipairs { "ball polish", "mizzenmast mop", "rigging shampoo" } do
			if have_item(x) then
				table.insert(touse, x)
			end
		end
		if next(touse) then
			return "You might want to use your F'c'le quest items first (" .. table.concat(touse, ", ") .. ").", "use fcle quest items"
		end
	end
end)

add_processor("use item", function()
	if text:contains("find the big pile of cannonballs on the F'c'le and polish each ball until it shines") then
		ascension["zone.fcle.used ball polish"] = true
	end
end)

add_processor("use item", function()
	if text:contains("take the mop to the mizzenmast and scrub like you've never scrubbed before") then
		ascension["zone.fcle.used mizzenmast mop"] = true
	end
end)

add_processor("use item", function()
	if text:contains("climb up into the rigging, lather it up, and rinse it off") then
		ascension["zone.fcle.used rigging shampoo"] = true
	end
end)

-- poop deck

add_choice_text("O Cap'm, My Cap'm", {
	["Front the meat and take the wheel"] = { text = "Pay 977 Meat for stats or other options", good_choice = true },
	["Step away from the helm"] = { leave_noturn = true },
	["Show the tropical island volcano lair map to the navigator"] = "Unlock and go to volcanic island",
})

add_printer("/ocean.php", function()
	text = text:gsub("(name=)([a-z]+)(>)", "%1%2 id=%2%3") -- set IDs for inputs
	text = text:gsub([[<input type=submit class=button value="Set Sail!">]], [[%0<br>
	<script type="text/javascript">
	function setlocation(lon, lat) {
		document.getElementById('lon').value = lon;
		document.getElementById('lat').value = lat;
	}
	</script>
	<a href="javascript:setlocation(56, 14)" style="color: green">{ Gain muscle }</a>
	<a href="javascript:setlocation(44, 45)" style="color: green">{ Gain mysticality }</a>
	<a href="javascript:setlocation(22, 62)" style="color: green">{ Gain moxie }</a>]])
end)

add_always_zone_check(159, function()
	if meat() < 977 then
		return "Taking the wheel costs 977 meat."
	end
end)

-- belowdecks

add_ascension_zone_check(160, function()
	if have_buff("On the Trail") and not have_item("Talisman o' Namsilat") and count_item("snakehead charrrm") + count_item("gaudy key") < 2 then
		local trailed = retrieve_trailed_monster()
		if trailed ~= "gaudy pirate" then
			return "You are on the trail of '" .. tostring(trailed) .. "' when you might want to sniff a gaudy pirate."
		end
	end
end)
