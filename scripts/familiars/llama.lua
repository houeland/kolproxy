add_processor("familiar message: llama", function()
	if text:contains("This gong will enable you to see things from a different perspective.") then
		increase_daily_counter("familiar.llama.gong")
	end
end)

add_processor("/fight.php", function()
	if text:match("You repeatedly slash .- with your razor%-sharp talons") or text:match("You furiously flap your wings, giving .- a sound buffeting") then
		violence = ascension["familiar.llama.violence"] or 0
		violence = violence + 1
		ascension["familiar.llama.violence"] = violence
	end
end)

add_processor("/choice.php", function()
	if text:contains("You acquire an effect: <b>Form of...Bird!</b>") then
		ascension["familiar.llama.violence"] = 0
	end
end)

add_printer("/charpane.php", function()
	if buff("Form of...Bird!") then
		violence = ascension["familiar.llama.violence"] or 0

		compact = violence .. " / 15v"
		normal = violence .. " / 15 violence"

		print_charpane_infoline(compact, normal)
	end
	if familiarpicture() == "llama" then
		gongs = get_daily_counter("familiar.llama.gong")

		compact = gongs .. " / 5"
		normal = gongs .. " / 5 gongs"

		print_familiar_counter(compact, normal)
	end
end)
