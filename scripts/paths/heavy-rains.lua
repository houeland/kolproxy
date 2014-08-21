function thunder() return tonumber(status().thunder) or 0 end
function rain() return tonumber(status().rain) or 0 end
function lightning() return tonumber(status().lightning) or 0 end

local rain_monsters = {
	"giant tardigrade", 
	"aquaconda",
	"storm cow",
	"piranhadon",
	"alley catfish",
	"freshwater bonefish",
	"gourmet gourami",
	"giant isopod"
}
add_wandering_monster_tracker("Rain monster", rain_monsters, 35, 45)

add_processor("/fight.php", function()
	if text:contains(">You win the fight!<!--WINWINWIN--><") then
		if status().thunder ~= nil then
			increase_daily_counter("thunder fights won")
		end
		if status().rain ~= nil then
			increase_daily_counter("rain fights won")
		end

		if text:contains("You turn your smiling face up to the rains") then
			reset_daily_counter("rain fights won")
		end
		if text:contains("A peal of thunder sounds nearby") then
			reset_daily_counter("thunder fights won")
		end
	end
end)


add_warning {
	message = "You are in danger of being gored by a storm cow.  Balance MP and HP accordingly!",
	path = "/adventure.php",
	type = "extra", 
	-- Really should check for zone and depth as well!
	check = function()
		if get_wanderer_turn("Rain monster") and turnsthisrun() >= get_wanderer_turn("Rain monster") and ( (mp()-50) > 0.75 * hp() or mp() > 100 ) then
			return true
		else
			return false
		end
	end,
}