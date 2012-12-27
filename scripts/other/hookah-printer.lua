add_processor("/fight.php", function()
	if text:contains("takes a pull on the hookah") then
		local snippet = text:match("takes a pull.-</b>")
		local effect = snippet:match("You acquire an effect: <b>(.-)</b>")
		print("Gained hookah effect:", effect)
	end
end)
