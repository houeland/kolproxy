function get_buff_bonuses()
	local bonuses = {combat = 0, item = 0, initiative = 0, ml = 0, meat = 0}
	local buffarray = {
		["Sole Soul"] = { item = math.min(buffturns("Sole Soul"), 300) },
		["The HeyDezebound Heart"] = { item = math.min(buffturns("The HeyDezebound Heart"), 300) },
		["Bubble Vision"] = { item = math.max(101 - buffturns("Bubble Vision"), 0) },
		["Polka Face"] = { item = math.min(55, 5 * level()), meat = math.min(55, 5 * level()) },
		["Withered Heart"] = { item = math.min(buffturns("Withered Heart"), 20) },
		["Fortunate Resolve"] = { item = 5, meat = 5, initiative = 5 },
		-- ["Limber as Mortimer"] = ...,
		["Voracious Gorging"] = { item = math.min(40, math.ceil(fullness() / 5) * 10) },

		["Cunctatitis"] = { initiative = -1000 },

		["Buy!  Sell!  Buy!  Sell!"] = { meat = math.max(202 - 2 * buffturns("Buy!  Sell!  Buy!  Sell!"), 0) },
		["Sweet Heart"] = { meat = math.min(2 * buffturns("Sweet Heart"), 40) },

		["Ur-Kel's Aria of Annoyance"] = { ml = math.min(2 * level(), 60) },
		["Mysteriously Handsome"] = { ml = 6 }, -- Not for men
		["A Little Bit Evil"] = { ml = 2 },
	}
	local buff_datafile = datafile("buffs")
	for buff, _ in pairs(buffslist()) do
		local buffb = buffarray[buff]
		if not buffb then
			buffb = (buff_datafile[buff] or {}).bonuses
		end
		if buffb then
			for a, b in pairs(buffb) do
				bonuses[a] = (bonuses[a] or 0) + b
			end
		end
	end
	if equipment().weapon == nil and equipment().offhand == nil then -- unarmed
		if have_intrinsic("Expert Timing") then
			bonuses.item = (bonuses.item or 0) + 20
		end
		if have_intrinsic("Fast as Lightning") then
			bonuses.initiative = (bonuses.initiative or 0) + 50
		end
	end

	if have_buff("Amorous Avarice") then
		bonuses.meat = (bonuses.meat or 0) + 25 * math.min(math.floor(drunkenness() / 5), 4)
	end

	if have_intrinsic("Overconfident") then
		bonuses.ml = (bonuses.ml or 0) + 30
	end

	return bonuses
end
