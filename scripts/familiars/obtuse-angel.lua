-- TODO: This should make sure to set the counter based on the correct base value
-- TODO: want a way to refer to the API before the pageload?

local function set_obtuse_angel()
	if day["obtuse angel romantic arrow target"] and not day["obtuse angel romantic arrow next monster start"] then
		day["obtuse angel romantic arrow next monster start"] = turnsthisrun() + 15
	end
end

add_processor("/adventure.php", function()
	-- TODO: only for successful adventure.php loads?
	set_obtuse_angel()
end)

add_processor("/choice.php", function()
	if requestpath == "/adventure.php" then
		set_obtuse_angel()
	end
end)

add_processor("/fight.php", function()
	if requestpath == "/adventure.php" then
		set_obtuse_angel()
	end
end)

add_processor("familiar message: obtuseangel", function()
	if text:contains("fires a badly romantic arrow") then
-- 		print("fired romantic at", monster_name)
		day["obtuse angel romantic arrow target"] = monster_name
		day["obtuse angel romantic arrow next monster start"] = nil
		if have_equipped_item("quake of arrows") then
			day["obtuse angel romantic arrow monsters remaining"] = 3
		else
			day["obtuse angel romantic arrow monsters remaining"] = 2
		end
	end
end)

add_processor("/fight.php", function()
	if text:contains("shot with a love arrow earlier") then
		day["obtuse angel romantic arrow monsters remaining"] = tonumber(day["obtuse angel romantic arrow monsters remaining"]) - 1
		day["obtuse angel romantic arrow next monster start"] = turnsthisrun() + 15
	end
end)

add_printer("/charpane.php", function()
	local remaining = tonumber(day["obtuse angel romantic arrow monsters remaining"])
	if remaining and remaining > 0 then
		local compact = nil
		local normal = nil
		local tooltip = nil
		local start = tonumber(day["obtuse angel romantic arrow next monster start"])
		if not start then
			compact = "Not set"
			normal = "Not started"
			tooltip = string.format("The counter starts when you visit adventure.php. %s of %s remaining.", make_plural(remaining, "copy", "copies"), day["obtuse angel romantic arrow target"])
		else
			local t = start - turnsthisrun()
			local first = t - 1
			local last = t + 11
			if first < 0 then
				first = 0
			end
			if first >= last then
				compact = string.format("%d", first)
				normal = make_plural(first, "turn", "turns")
			else
				compact = string.format("%d-%d", first, last)
				normal = string.format("%d-%d turns", first, last)
			end
			tooltip = string.format("%s of %s remaining.", make_plural(remaining, "copy", "copies"), day["obtuse angel romantic arrow target"])
		end
		print_charpane_value { normalname = "Arrowed", compactname = "Arrowed", compactvalue = compact, normalvalue = normal, tooltip = tooltip }
	end
end)
