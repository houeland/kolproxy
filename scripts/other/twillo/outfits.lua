function get_outfit_bonuses()
	local bonuses = {combat = 0, item = 0, initiative = 0, ml = 0, meat = 0}
	for _, x in pairs(datafile("outfits")) do
		local wearing = true
		for _, y in ipairs(x.items) do
			if not have_equipped(y) then
				wearing = false
			end
		end
		if wearing then
			for a, b in pairs(x.bonuses) do
				bonuses[a] = (bonuses[a] or 0) + b
			end
		end
	end
	return bonuses
end
