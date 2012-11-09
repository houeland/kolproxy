add_printer("/charpane.php", function()
	if familiarpicture() == "hounddog" then
-- 		local bonus = string.format("+%s%%", round_down(fairy_bonus(buffedfamiliarweight() * 1.25), 1))
-- 		compact = bonus
-- 		normal = bonus .. " items"
-- 		print_charpane_infoline(compact, normal)
	elseif familiarpicture() == "hobomonkey" then
		local bonus = string.format("+%s%%", round_down(2 * fairy_bonus(buffedfamiliarweight() * 1.25), 1))
		compact = bonus
		normal = bonus .. " meat"
		print_charpane_infoline(compact, normal)
	elseif familiarpicture() == "spanglehat" and familiarid() == 82 then
-- 		local bonus = string.format("+%s%%", round_down(fairy_bonus(buffedfamiliarweight() * 2), 1))
-- 		compact = bonus
-- 		normal = bonus .. " items"
-- 		print_charpane_infoline(compact, normal)
	end
end)
