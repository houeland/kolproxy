function get_outfit_bonuses()
	local bonuses = {}
	for _, x in pairs(outfits_modifier_data) do
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
