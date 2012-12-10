local hippycamp, fratcamp = 1, 2

local function turn_in(turnins, camp)
	for x in table.values(turnins) do
		if have(x) then
			async_get_page("/bigisland.php", { action = "turnin", pwd = session.pwd, whichcamp = camp, whichitem = get_itemid(x), quantity = count(x) })
		end
	end
	return get_page("/bigisland.php", { place = "camp", whichcamp = camp })
end

local function lturn_in_junk_for_quarters()
	local turnins = {
		"communications windchimes",
		"green clay bead",
		"pink clay bead",
		"purple clay bead",
	}
	return turn_in(turnins, fratcamp)
end

turn_in_junk_for_quarters = lturn_in_junk_for_quarters

local turn_in_junk_for_quarters_href = add_automation_script("turn-in-junk-for-quarters", lturn_in_junk_for_quarters)

local function lturn_in_all_for_quarters()
	local turnins = {
		"bullet-proof corduroys",
		"communications windchimes",
		"didgeridooka",
		"fire poi",
		"flowing hippy skirt",
		"Gaia beads",
		"green clay bead",
		"hippy medical kit",
		"hippy protest button",
		"lead pipe",
		"Lockenstock&trade; sandals",
		"pink clay bead",
		"purple clay bead",
		"reinforced beaded headband",
		"round green sunglasses",
		"round purple sunglasses",
		"wicker shield",
	}
	return turn_in(turnins, fratcamp)
end

turn_in_all_for_quarters = lturn_in_all_for_quarters

local turn_in_all_for_quarters_href = add_automation_script("turn-in-all-for-quarters", lturn_in_all_for_quarters)

local function lturn_in_junk_for_dimes()
	local turnins = {
		"blue class ring",
		"PADL Phone",
		"red class ring",
		"white class ring",
	}
	return turn_in(turnins, hippycamp)
end

turn_in_junk_for_dimes = lturn_in_junk_for_dimes

local turn_in_junk_for_dimes_href = add_automation_script("turn-in-junk-for-dimes", lturn_in_junk_for_dimes)

local function lturn_in_all_for_dimes()
	local turnins = {
		"beer bong",
		"beer helmet",
		"bejeweled pledge pin",
		"blue class ring",
		"bottle opener belt buckle",
		"distressed denim pants",
		"Elmley shades",
		"energy drink IV",
		"giant foam finger",
		"keg shield",
		"kick-ass kicks",
		"PADL Phone",
		"perforated battle paddle",
		"red class ring",
		"war tongs",
		"white class ring",
	}
	return turn_in(turnins, hippycamp)
end

turn_in_all_for_dimes = lturn_in_all_for_dimes

local turn_in_all_for_dimes_href = add_automation_script("turn-in-all-for-dimes", lturn_in_all_for_dimes)

add_printer("/bigisland.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.place == "camp" and text:contains("value=\"turnin\"") then
		local junk_href = ""
		local all_href = ""
		if tonumber(params.whichcamp) == fratcamp then
			junk_href = turn_in_junk_for_quarters_href { pwd = session.pwd }
			all_href = turn_in_all_for_quarters_href { pwd = session.pwd }
		else
			junk_href = turn_in_junk_for_dimes_href { pwd = session.pwd }
			all_href = turn_in_all_for_dimes_href { pwd = session.pwd }
		end
		text = text:gsub("\"Turn it in\"></form>", [[%0<p><a href="]] .. junk_href .. [[" style="color:green">{ Turn in junk }</a><a href="]] .. all_href .. [[" style="color:green">{ Turn in all }</a></p>]])
	end
end)
