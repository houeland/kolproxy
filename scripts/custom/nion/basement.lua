add_automator("/basement.php", function()
	local hot_resist = 0
	local cold_resist = 0
	local spooky_resist = 0
	local stench_resist = 0
	local sleaze_resist = 0

	local myst_resist = 0
	if get_mainstat() == "Mysticality" then
		myst_resist = 5
	end		

	local basement_floor = text:match([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>Fernswarthy's Basement, Level ([^<]*)</b></td></tr>]])
	local challenge_type = text:match([[<input class=button type=submit value="([^>]+) %(1%)">]])

	local challenge_summary
	local minreq
	local havereq
	local maxreq
	local reqtype = ""
	local minreqinfo = ""
	local maxreqinfo = ""
	local bad_estimate = false

	local charpage
	local function handle_resist_test(elem1, elem2)
		if not charpage then
			charpage = get_page("/charsheet.php")
		end
		local function get_resist_amount(e)
			local fieldtext = charpage:match([[<td align=right>]]..e..[[ Protection:</td><td><b>[^>()]+%(([0-9]+)%)</b></td>]])
			local level = tonumber(fieldtext) or 0
			if level <= 3 then
				return (level*10 + myst_resist)/100
			else
				return (90-(50*((5/6)^(level-4))) + myst_resist)/100
			end
		end
		local function get_base_elem_dmg(e)
			return (8 + 4.5 * (basement_floor ^ 1.4)) * (1 - get_resist_amount(e))
		end
		local resistcolors = {
			Cold = "blue",
			Hot = "red",
			Sleaze = "blueviolet",
			Spooky = "gray",
			Stench = "green",
		}
		local mindmg1 = math.floor(0.95 * get_base_elem_dmg(elem1))
		local mindmg2 = math.floor(0.95 * get_base_elem_dmg(elem2))
		local maxdmg1 = math.ceil(1.05 * get_base_elem_dmg(elem1))
		local maxdmg2 = math.ceil(1.05 * get_base_elem_dmg(elem2))
		minreq = mindmg1 + mindmg2
		havereq = hp()
		maxreq = maxdmg1 + maxdmg2
		minreqinfo = [[ (<b style="color: ]]..resistcolors[elem1]..[[">]] .. mindmg1 .. [[</b> + <b style="color: ]]..resistcolors[elem2]..[[">]] .. mindmg2 .. [[</b>)]]
		maxreqinfo = [[ (<b style="color: ]]..resistcolors[elem1]..[[">]] .. maxdmg1 .. [[</b> + <b style="color: ]]..resistcolors[elem2]..[[">]] .. maxdmg2 .. [[</b>)]]
		reqtype = " damage"
		challenge_description = elem1 .. " + " .. elem2 .. " Resistance test"
	end

	if basement_floor % 5 == 0 then
		challenge_summary = ""
		text = text:gsub([[<br><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Save the Cardboard ([^<]*)"></form>]], [[ <span style="color: green">{ Mysticality reward. }</span><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Save the Cardboard (1)"></form> <span style="color: green">{ Moxie reward. }</span>]], 1)
		text = text:gsub([[<br><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Take the Blue Pill ([^<]*)"></form>]], [[ <span style="color: green">{ Muscle reward. }</span><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Take the Blue Pill (1)"></form> <span style="color: green">{ Mysticality reward. }</span>]], 1)
		text = text:gsub([[<br><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Leather is Betther ([^<]*)"></form>]], [[ <span style="color: green">{ Moxie reward. }</span><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Leather is Betther (1)"></form> <span style="color: green">{ Muscle reward. }</span>]], 1)
	elseif challenge_type == "Grab the Handles" then
		-- TODO: max here is too low! Added + 10 to max as a workaround
		minreq = math.ceil(1.5865 * (basement_floor ^ 1.4))
		havereq = mp()
		maxreq = math.ceil(10 + 1.7535 * (basement_floor ^ 1.4))
		challenge_description = "MP drain"
	elseif challenge_type == "Run the Gauntlet Gauntlet" then
		-- TODO: max here is too low! Added 0.95 and 1.05 modifiers as a workaround
		bad_estimate = true
		minreq = math.ceil(0.95 * basement_floor ^ 1.4)
		havereq = hp()
		maxreq = math.ceil(1.05 * 10 * (basement_floor ^ 1.4))
		reqtype = " damage"
		challenge_description = "HP drain (incomplete, wide range estimate)"
	elseif challenge_type == "Lift 'em!" or challenge_type == "Push it Real Good" or challenge_type == "Ring that Bell!" then
		minreq = math.ceil(0.9 * (basement_floor ^ 1.4) + 2)
		havereq = buffedmuscle()
		maxreq = math.ceil(1.1 * (basement_floor ^ 1.4) + 2)
		challenge_description = "Muscularity test"
	elseif challenge_type == "Gathering:  The Magic" or challenge_type == "Mop the Floor with the Mops" or challenge_type == "Do away with the 'doo" then
		minreq = math.ceil(0.9 * (basement_floor ^ 1.4) + 2)
		havereq = buffedmysticality()
		maxreq = math.ceil(1.1 * (basement_floor ^ 1.4) + 2)
		challenge_description = "Mysticality test"
	elseif challenge_type == "Don't Wake the Baby" or challenge_type == "Grab a cue" or challenge_type == "Put on the Smooth Moves" then
		minreq = math.ceil(0.9 * (basement_floor ^ 1.4) + 2)
		havereq = buffedmoxie()
		maxreq = math.ceil(1.1 * (basement_floor ^ 1.4) + 2)
		challenge_description = "Moxie test"
	elseif challenge_type == "Evade the Vampsicle" then
		handle_resist_test("Cold", "Spooky")
	elseif challenge_type == "What's a Typewriter, Again?" then
		handle_resist_test("Hot", "Spooky")
	elseif challenge_type == "Pwn the Cone" then
		handle_resist_test("Stench", "Hot")
	elseif challenge_type == "Drink the Drunk's Drink" then
		handle_resist_test("Cold", "Sleaze")
	elseif challenge_type == "Hold your nose and watch your back" then
		handle_resist_test("Stench", "Sleaze")
	elseif challenge_type == "Commence to Pokin'" or challenge_type == "Collapse That Waveform" or string.find(challenge_type, " Down") or challenge_type == "Don't Fear the Ear" or challenge_type == "It's Stone Bashin' Time" or challenge_type == "Toast that Ghost" or challenge_type == "Round " .. basement_floor .. "...  Fight!" then
		challenge_summary = "{ Combat. }"
	end
	if not challenge_summary then
		if havereq < minreq then
			text = text:gsub([[<input class=button type=submit]], [[%0 disabled="disabled"]], 1)
		end
		challenge_summary = string.format([[<div style="color: %s">{ %s }<br>Estimated%s:<br><span style="color: %s">Min: %s%s</span><br><span style="color: %s">Max: %s%s</span></div>]], bad_estimate and "darkorange" or "green", challenge_description, reqtype, (minreq <= havereq) and "green" or "darkorange", minreq, minreqinfo, (maxreq <= havereq) and "green" or "darkorange", maxreq, maxreqinfo)
	end
	if bad_estimate then
		text = text:gsub([[<br><p><a href="fernruin.php">]], [[<center><div style="color: darkorange">]] .. challenge_summary .. [[</div></center><p><a href="fernruin.php">]], 1)
	else
		text = text:gsub([[<br><p><a href="fernruin.php">]], [[<center><div style="color: green">]] .. challenge_summary .. [[</div></center><p><a href="fernruin.php">]], 1)
	end
end)
