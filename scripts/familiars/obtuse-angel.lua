-- TODO: This should make sure to set the counter based on the correct base value
-- TODO: want a way to refer to the API before the pageload?

-- wandering copied monsters

local function set_wandering_copied_monster()
	if day["wandering copied monster"] and not day["wandering copied monster"]["next monster start"] then
		local tbl = day["wandering copied monster"]
		tbl["next monster start"] = turnsthisrun() + 15
		day["wandering copied monster"] = tbl
	end
end

add_processor("/adventure.php", function()
	-- TODO: only for successful adventure.php loads?
	set_wandering_copied_monster()
end)

add_processor("/choice.php", function()
	if requestpath == "/adventure.php" then
		set_wandering_copied_monster()
	end
end)

add_processor("/fight.php", function()
	if requestpath == "/adventure.php" then
		set_wandering_copied_monster()
	end
end)

function start_wandering_copied_monster(copies)
	day["wandering copied monster"] = {
		["monster name"] = get_monstername(),
		["display name"] = get_raw_monstername(),
		["next monster start"] = nil,
		["monsters remaining"] = copies,
	}
end

function encountered_wandering_copied_monster()
	local tbl = day["wandering copied monster"] or {}
	tbl["monsters remaining"] = (tbl["monsters remaining"] or 0) - 1
	tbl["next monster start"] = turnsthisrun() + 15
	day["wandering copied monster"] = tbl
end

local function get_wandering_data()
	local tbl = day["wandering copied monster"]
	if not tbl then return end
	local remaining = tbl["monsters remaining"]
	if remaining > 0 then
		local compact = nil
		local normal = nil
		local tooltip = nil
		local start = tbl["next monster start"]
		local first = nil
		local last = nil
		if not start then
			compact = "Not started"
			normal = "Not started"
			tooltip = string.format("The counter starts when you visit adventure.php. %s of %s remaining.", make_plural(remaining, "copy", "copies"), tbl["display name"])
		else
			local t = start - turnsthisrun()
			first = t - 1
			last = t + 11
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
			tooltip = string.format("%s of %s remaining.", make_plural(remaining, "copy", "copies"), tbl["display name"])
		end
		return { normalname = "Wandering", compactname = "Wandering", compactvalue = compact, normalvalue = normal, tooltip = tooltip }, { start = start, displayname = tbl["display name"], first = first, last = last }
	end
end

add_counter_effect(function()
	local data, extradata = get_wandering_data()
	if extradata then
		if not extradata.start then
			return { title = extradata.displayname, duration = -1, durationdesc = "", imgname = "reanimator", group = "effect" }
		else
			return { title = extradata.displayname, duration = extradata.first, maxduration = extradata.last, imgname = "reanimator", group = "effect" }
		end
	end
end)

add_charpane_line(function()
	if setting_enabled("display counters as effects") then return end
	return get_wandering_data()
end)

-- obtuse angel

add_processor("familiar message: obtuseangel", function()
	if text:contains("fires a badly romantic arrow") then
		if have_equipped_item("quake of arrows") then
			start_wandering_copied_monster(3)
		else
			start_wandering_copied_monster(2)
		end
	end
end)

add_processor("/fight.php", function()
	if text:contains("shot with a love arrow earlier") then
		encountered_wandering_copied_monster()
	end
end)
