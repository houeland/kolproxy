function estimate_outfit_bonuses()
	local bonuses = {}
	for _, x in pairs(datafile("outfits")) do
		local wearing = true
		for _, y in ipairs(x.items) do
			if not have_equipped(y) then
				wearing = false
			end
		end
		if wearing then
			add_modifier_bonuses(bonuses, x.bonuses)
		end
	end
	return bonuses
end
