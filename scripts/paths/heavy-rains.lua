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
add_wandering_monster_tracker("Rain monster", rain_monsters, 35, 45)

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
	message = "You are in danger of being gored by a storm cow. Balance MP and HP accordingly!",
	path = "/adventure.php",
	type = "extra",
	-- TODO: Really should check for zone and depth as well!
	check = function()
		if get_wanderer_turn("Rain monster") and turnsthisrun() >= get_wanderer_turn("Rain monster") then
			return (mp() - 50) > 0.75 * hp() or mp() > 100
		end
	end,
}
