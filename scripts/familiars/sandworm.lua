add_processor("familiar message: babyworm", function()
	if text:contains("A few minutes later, he belches some murky fluid back into the bottle and hands it to you.") then
		increase_daily_counter("familiar.sandworm.agua")
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "babyworm" then
		agua = get_daily_counter("familiar.sandworm.agua")

		compact = agua .. " / 5"
		normal = agua .. " / 5 agua"

		print_familiar_counter(compact, normal)
	end
end)
