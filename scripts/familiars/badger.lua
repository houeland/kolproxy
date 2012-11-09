add_processor("familiar message: badger", function()
	if text:contains("You pick it up because, hey, free mushroom.") then
		increase_daily_counter("familiar.badger.mushroom")
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "badger" then
		mushrooms = get_daily_counter("familiar.badger.mushroom")

		compact = mushrooms .. " / 5"
		normal = mushrooms .. " / 5 mushrooms"

		print_familiar_counter(compact, normal)
	end
end)
