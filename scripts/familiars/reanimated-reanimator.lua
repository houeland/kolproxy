add_processor("familiar message: reanimator", function()
	if text:contains("nods and begins calculating how much glow-juice he'll need") then
		start_wandering_copied_monster(3)
	end
end)

add_processor("/fight.php", function()
	if text:contains("You stop for a moment because you feel the hairs on the back of your neck stand up") then
		encountered_wandering_copied_monster()
	end
end)
