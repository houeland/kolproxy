local moonsign_numbers = {
	Mongoose = 1,
	Wallaby = 2,
	Vole = 3,
	Platypus = 4,
	Opossum = 5,
	Marmot = 6,
	Wombat = 7,
	Blender = 8,
	Packrat = 9,
}

function calculate_the_universe(input)
	local moonsign_number = moonsign_numbers[moonsign()] or 10
	return (input + moonsign_number + ascensions_count()) * (spleen() + level()) + advs()
end

add_processor("/choice.php", function()
	if text:contains("consult your table of Numberology for the final digits") then
		day.calculated_the_universe = true
	end
end)

function can_calculate_the_universe()
	return have_skill("Calculate the Universe") and not day.calculated_the_universe
end

function can_calculate_the_universe_as_any_number()
	local remainder = (spleen() + level()) % 10
	return remainder == 1 or remainder == 3 or remainder == 7 or remainder == 9
end

function get_calculate_the_universe_number_turns_remaining()
	local numbers = {}
	for i = 1, 100 do
		numbers[calculate_the_universe(i) % 100] = 0
	end
	local last = nil
	for i = 199, 0, -1 do
		if numbers[i % 100] == 0 then
			last = i
		elseif last then
			numbers[i % 100] = last - i
		end
	end
	return numbers
end

local rewards = {
	{ target = 69, description = "Gain +3 Adventures" },
	{ target = 37, description = "Gain +3 PvP fights" },
	{ target = 51, description = "Fight a War Frat 151st Infantryman" },
	{ target = 89, description = "Gain around +90 mainstat" },
	{ target = 11, description = "Gain or lose Drunkenness" },
}

local calculate_href = add_automation_script("calculate-the-universe", function()
	local target_reward = tonumber(params.target_reward)
	if target_reward then
		for i = 1, 100 do
			if calculate_the_universe(i) % 100 == target_reward then
				cast_skill("Calculate the Universe")()
				get_page("/choice.php", { forceoption = 0 })
				return get_page("/choice.php", { whichchoice = 1103, option = 1, num = i, pwd = session.pwd })
			end
		end
		return "Not available now!"
	end
	local turns_to_wait = get_calculate_the_universe_number_turns_remaining()
	local lines = {}
	table.insert(lines, "<h3>Pick a reward:</h3>")
	table.insert(lines, "<form>")
	table.insert(lines, "<ul>")
	for _, x in ipairs(rewards) do
		if turns_to_wait[x.target] == 0 then
			table.insert(lines, string.format([[<li style="padding: 5px"><a href="#" style="color: black" onclick="document.getElementById('target').value = %d">%d: %s</a></li>]], x.target, x.target, x.description))
		else
			table.insert(lines, string.format([[<li style="padding: 5px">%d: %s (available in %d turns)</li>]], x.target, x.description, turns_to_wait[x.target]))
		end
	end
	table.insert(lines, "</ul>")
	table.insert(lines, "<h3>Or choose a number manually:</h3>")
	table.insert(lines, string.format([[<input name="pwd" type="hidden" value="%s"></input>]], session.pwd))
	table.insert(lines, string.format([[<input name="automation-script" type="hidden" value="calculate-the-universe"></input>]], session.pwd))
	table.insert(lines, [[<input name="target_reward" id="target"></input>]])
	table.insert(lines, [[<input type="submit"></input>]])
	table.insert(lines, "</form>")
	return make_kol_html_frame(table.concat(lines, "\n"), "Calculate the Universe")
end)

add_interceptor("/skills.php", function()
	if tonumber(params.whichskill) ~= 144 then return end
	local href = calculate_href { pwd = session.pwd }
	return string.format([[<script type="text/javascript">top.mainpane.location.href="%s";</script>{ <a href="%s">Loading page...</a> }]], href, href)
end)

add_interceptor("/runskillz.php", function()
	if tonumber(params.whichskill) ~= 144 then return end
	local href = calculate_href { pwd = session.pwd }
	return string.format([[<script type="text/javascript">top.mainpane.location.href="%s";</script>{ <a href="%s">Loading page...</a> }]], href, href)
end)

add_warning {
	message = "You might want to cast Calculate the Universe now to freely choose the result.",
	type = "notice",
	check = function()
		return can_calculate_the_universe() and can_calculate_the_universe_as_any_number()
	end,
}
