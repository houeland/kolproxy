local function add_flyaway_message(pattern)
	local runaways = get_daily_counter("item.fly away.free runaways")
	if runaways == 1 then
		text = text:gsub(pattern, [[>%1 <span style="color: green">(]]..runaways..[[ free flyaway today.)</span><]])
	else
		text = text:gsub(pattern, [[>%1 <span style="color: green">(]]..runaways..[[ free flyaways today.)</span><]])
	end
end

-- navel ring

add_processor("/fight.php", function()
	if text:contains(">The pyramid of energy surrounding you shimmers as you quickly float away.<") then
		increase_daily_counter("item.fly away.free runaways")
	end
end)

add_printer("/fight.php", function()
	if text:contains(">The pyramid of energy surrounding you shimmers as you quickly float away.<") then
		add_flyaway_message(">(The pyramid of energy surrounding you shimmers as you quickly float away.)<")
	end
end)

-- greatest american pants

add_processor("/fight.php", function()
	if text:contains(">As you turn to run away, your pants suddenly activate, and you rocket off into the sky at breakneck speed.<") then
		increase_daily_counter("item.fly away.free runaways")
	end
end)

add_printer("/fight.php", function()
	if text:contains(">As you turn to run away, your pants suddenly activate, and you rocket off into the sky at breakneck speed.<") then
		add_flyaway_message(">(As you turn to run away, your pants suddenly activate, and you rocket off into the sky at breakneck speed.)<")
	end
end)

-- peppermint parasol

add_processor("/fight.php", function()
	if text:contains(">You hold up the parasol, and a sudden freak gust of wind sends you hurtling through the air to safety.<") then
		increase_daily_counter("item.fly away.free runaways")
		increase_ascension_counter("item.peppermint parasol.uses")
	end
	if text:contains("That last gust was more than your parasol could handle.") then
		reset_ascension_counter("item.peppermint parasol.uses")
	end
end)

add_printer("/fight.php", function()
	if text:contains(">You hold up the parasol, and a sudden freak gust of wind sends you hurtling through the air to safety.<") then
		add_flyaway_message(">(You hold up the parasol, and a sudden freak gust of wind sends you hurtling through the air to safety.)<")
	end
end)

add_charpane_line(function()
	if have_equipped_item("navel ring of navel gazing") or have_equipped_item("Greatest American Pants") or have_item("peppermint parasol") then
		local runaways = get_daily_counter("item.fly away.free runaways")
		local chancestr = "?"
		local remainingstr = ""
		if have_item("peppermint parasol") then
			remainingstr = (" [%d left]"):format(math.max(0, 10 - get_ascension_counter("item.peppermint parasol.uses")))
		end
		if runaways < 3 then
			chancestr = "100%"
		elseif runaways < 6 then
			chancestr = "80%"
		elseif runaways < 9 then
			chancestr = "50%"
		else
			chancestr = "20%"
		end
		local compact = ("%s (%s)%s"):format(runaways, chancestr, remainingstr)
		local normal = ("%s used (%s chance)%s"):format(runaways, chancestr, remainingstr)
		local color = nil
		if (familiar("Frumious Bandersnatch") and have_buff("Ode to Booze")) or familiar("Pair of Stomping Boots") then
			if have_equipped_item("navel ring of navel gazing") or have_equipped_item("Greatest American Pants") then
				color = "gray"
			end
		end

		return { normalname = "Flyaways", compactname = "Flyaways", compactvalue = compact, normalvalue = normal, color = color }
	end
end)

-- TODO: auto-adjust counter from messages?
-- You're starting to get kinda queasy from all of this flying.
-- Eurgh. At this point, you're officially airsick.




-- You smear part of your handful of Blank-Out on the monster until you can't see it anymore. And if you've learned one thing from urban legends about ostriches, it's that what you can't see can't hurt you. You mosey off.
