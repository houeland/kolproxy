add_processor("familiar message: tronguy", function()
	if text:contains("&quot;Please accept this token of my devotion to my user,&quot; and hands you an actual, literal token.") then
		increase_daily_counter("familiar.rogue program.tokens")
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "tronguy" then
		tokens = get_daily_counter("familiar.rogue program.tokens")

		compact = tokens .. " / 5"
		normal = tokens .. " / 5 tokens"

		print_familiar_counter(compact, normal)
	end
end)
