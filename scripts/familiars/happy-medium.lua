add_processor("/fight.php", function()
	if not familiar("Happy Medium") then return end
	if text:contains("cocktail") and (text:contains("aura") or text:contains("spirit")) then
		for _, x in pairs(phylumTreasureNames) do
			for _, iname in pairs(x.siphon) do
				if text:contains(">You acquire an item: <b>"..iname.."</b><") then
					increase_daily_counter("familiar.happy medium.siphons")
				end
			end
		end
	end
end)

add_printer("/charpane.php", function()
	if familiar("Happy Medium") then
		local normal = make_plural(get_daily_counter("familiar.happy medium.siphons"), "siphon", "siphons")
		local compact = normal

		print_familiar_counter(compact, normal)
	end
end)
