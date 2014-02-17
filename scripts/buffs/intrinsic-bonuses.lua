function estimate_intrinsic_bonuses(intrinsic)
-- TODO: These are not actually buffs. The data files are just wrong.
	return estimate_buff_bonuses(intrinsic)
end

function estimate_current_intrinsic_bonuses()
	local bonuses = {}
	for intrinsic, _ in pairs(intrinsicslist()) do
		add_modifier_bonuses(bonuses, estimate_intrinsic_bonuses(intrinsic))
	end

	if equipment().weapon == nil and equipment().offhand == nil then -- unarmed
		if have_intrinsic("Expert Timing") then
			add_modifier_bonuses(bonuses, { ["Item Drops from Monsters"] = 20 })
		end
		if have_intrinsic("Fast as Lightning") then
			add_modifier_bonuses(bonuses, { ["Combat Initiative"] = 50 })
		end
	end

	return bonuses
end
