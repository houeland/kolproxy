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
	if have_buff("Form of...Bird!") then
		violence = ascension["familiar.llama.violence"] or 0

		compact = violence .. " / 15v"
		normal = violence .. " / 15 violence"

		print_charpane_infoline(compact, normal)
	end
end)


track_familiar_info("llama", function()
	local violence = get_daily_counter("familiar.llama.violence")
	return {count = get_daily_counter("familiar.llama.violence"),
		max = nil,
		type = "counter",
		info = "violence",
}
end)
