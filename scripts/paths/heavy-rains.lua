function get_water_depth_modifier()
	local mod = 0
	if have_buff("Personal Thundercloud") then
		mod = mod + 2
	end
	if have_buff("The Rain In Loathing") then
		mod = mod + 2
	end
	if have_equipped_item("heavy duty umbrella") then
		mod = mod - 2
	end
	if have_equipped_item("fishbone corset") then
		mod = mod - 2
	end
	return mod
end


function get_water_level(zone)
	local zone_data = maybe_get_zone_data(zone)
	local level = 1
	if zone_data then
		if zone_data.terrain == "indoor" then
			level = level + 2
		elseif zone_data.terrain == "underground" then
			level = level + 4
		end
		-- TODO: confirm cutoff for water level bonus
		if zone_data.stat and zone_data.stat >= 40 then
			level = level + 1
		end
	end
	level = level + get_water_depth_modifier()
	level = math.min(6, math.max(1, level))
	return level
end

local rain_monsters = {
	"giant tardigrade",
	"aquaconda",
	"storm cow",
	"piranhadon",
	"alley catfish",
	"freshwater bonefish",
	"gourmet gourami",
	"giant isopod",
}
add_wandering_monster_tracker("Rain monster", rain_monsters, 35, 45, function() return ascensionpath("Heavy Rains") end, 8, 11)

add_processor("won fight", function()
	if heavyrains_thunder() ~= nil then
		increase_daily_counter("thunder fights won")
		if text:contains("A peal of thunder sounds nearby") then
			reset_daily_counter("thunder fights won")
		end
	end
	if heavyrains_rain() ~= nil then
		increase_daily_counter("rain fights won")
		if text:contains("You turn your smiling face up to the rains") then
			reset_daily_counter("rain fights won")
		end
	end
end)

add_warning {
	message = "You are in danger of being attacked by a storm cow. Balance MP and HP accordingly!",
	path = "/adventure.php",
	type = "extra",
	check = function(zoneid)
		if not ascensionpath("Heavy Rains") then return end
		if get_wanderer_turn("Rain monster") and turnsthisrun() >= get_wanderer_turn("Rain monster") then
			if mp() - 50 >= 0.75 * hp() or mp() >= 100 then
				local zone_data = maybe_get_zone_data(zoneid)
				return zone_data and zone_data.terrain == "outdoor" and get_water_level(zoneid) == 6
			end
		end
	end,
}

add_warning {
	message = "You are in danger of being instantly killed by a storm cow. Balance MP and HP accordingly!",
	path = "/adventure.php",
	type = "warning",
	check = function(zoneid)
		if not ascensionpath("Heavy Rains") then return end
		if get_wanderer_turn("Rain monster") and turnsthisrun() >= get_wanderer_turn("Rain monster") then
			if mp() - 50 >= hp() then
				local zone_data = maybe_get_zone_data(zoneid)
				return zone_data and zone_data.terrain == "outdoor" and get_water_level(zoneid) == 6
			end
		end
	end,
}
