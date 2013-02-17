function estimate_buff_bonuses()
	local bonuses = {}
	local buffarray = {
		["Sole Soul"] = { ["Item Drops from Monsters"] = math.min(buffturns("Sole Soul"), 300) },
		["The HeyDezebound Heart"] = { ["Item Drops from Monsters"] = math.min(buffturns("The HeyDezebound Heart"), 300) },
		["Bubble Vision"] = { ["Item Drops from Monsters"] = math.max(101 - buffturns("Bubble Vision"), 0) },
		["Polka Face"] = { ["Item Drops from Monsters"] = math.min(55, 5 * level()), ["Meat from Monsters"] = math.min(55, 5 * level()) },
		["Withered Heart"] = { ["Item Drops from Monsters"] = math.min(buffturns("Withered Heart"), 20) },
		["Fortunate Resolve"] = { ["Item Drops from Monsters"] = 5, ["Meat from Monsters"] = 5, ["Combat Initiative"] = 5 },
		-- ["Limber as Mortimer"] = ...,
		["Voracious Gorging"] = { ["Item Drops from Monsters"] = math.min(40, math.ceil(fullness() / 5) * 10) },

		["Cunctatitis"] = { ["Combat Initiative"] = -1000 },

		["Buy!  Sell!  Buy!  Sell!"] = { ["Meat from Monsters"] = math.max(202 - 2 * buffturns("Buy!  Sell!  Buy!  Sell!"), 0) },
		["Sweet Heart"] = { ["Meat from Monsters"] = math.min(2 * buffturns("Sweet Heart"), 40) },

		["Ur-Kel's Aria of Annoyance"] = { ["Monster Level"] = math.min(2 * level(), 60) },
		["Mysteriously Handsome"] = { ["Monster Level"] = 6 }, -- Not for men
		["A Little Bit Evil"] = { ["Monster Level"] = 2 },

		["Amorous Avarice"] = { ["Meat from Monsters"] = 25 * math.min(math.floor(drunkenness() / 5), 4) },
	}
	for buff, _ in pairs(buffslist()) do
		if buffarray[buff] then
			add_modifier_bonuses(bonuses, buffarray[buff])
		elseif datafile("buffs")[buff] then
			add_modifier_bonuses(bonuses, datafile("buffs")[buff].bonuses or {})
		end
	end
	if equipment().weapon == nil and equipment().offhand == nil then -- unarmed
		if have_intrinsic("Expert Timing") then
			add_modifier_bonuses(bonuses, { ["Item Drops from Monsters"] = 20 })
		end
		if have_intrinsic("Fast as Lightning") then
			add_modifier_bonuses(bonuses, { ["Combat Initiative"] = 50 })
		end
	end

	if have_intrinsic("Overconfident") then
		add_modifier_bonuses(bonuses, { ["Monster Level"] = 30 })
	end

	return bonuses
end
