add_processor("familiar message: cheerleader", function()
	if text:contains("emits an especially large puff of steam") then
		increase_daily_counter("familiar.cheerleader.large puffs")
	end
end)

function get_steampowered_cheerleader_bonus_multiplier()
	local puffs = get_daily_counter("familiar.cheerleader.large puffs")
	if puffs == 0 then
		return 1.4
	elseif puffs == 1 then
		return 1.3
	elseif puffs == 2 then
		return 1.2
	elseif puffs == 3 then
		return 1.1
	else
		return 1.0
	end
end

add_printer("/charpane.php", function()
	if familiarpicture() == "cheerleader" then
		normal = string.format("%1.1fx weight", get_steampowered_cheerleader_bonus_multiplier())
		compact = normal

		print_familiar_counter(compact, normal)
	end
end)
