add_processor("familiar message: lilxeno", function()
	if text:contains("Your curiosity overcomes your gag reflex and you pick up the device") then
		increase_daily_counter("familiar.lil xenomorph.transponders")
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "lilxeno" then
		tokens = get_daily_counter("familiar.lil xenomorph.transponders")

		compact = tokens .. " / 5"
		normal = tokens .. " / 5 transponders"

		print_familiar_counter(compact, normal)
	end
end)
