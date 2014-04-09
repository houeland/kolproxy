add_processor("/fight.php", function()
	if not familiar("Happy Medium") then return end
	if text:contains("cocktail") and (text:contains("aura") or text:contains("spirit")) then
		for _, x in pairs(phylumTreasureNames) do
			for _, iname in pairs(x.siphon) do
				if text:contains(">You acquire an item: <b>"..iname.."</b><") then
					increase_daily_counter("familiar.happy medium.siphons")
					reset_ascension_counter("familiar.happy medium.charges")
				end
			end
		end
	end
	if text:contains(">You win the fight!<!--WINWINWIN--><") then
		increase_ascension_counter("familiar.happy medium.charges")
	end
end)

add_printer("/charpane.php", function()
	if familiar("Happy Medium") then
		local normal = make_plural(get_daily_counter("familiar.happy medium.siphons"), "siphon", "siphons")
		local compact = normal
		print_familiar_counter(compact, normal)
	end
end)

-- TODO: needs to be tracked as "Happy Medium", not familiar picture
track_familiar_info("medium_0", function()
	local siphons = get_daily_counter("familiar.happy medium.siphons")
	local charges = get_ascension_counter("familiar.happy medium.charges")
	return {
		count = siphons,
		max = nil,
		type = "counter",
		info = "siphons",
		extra_info = string.format("%d / %d charges", charges, 9 + siphons * 3)
	}
end)
