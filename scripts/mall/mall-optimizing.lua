local librams = {
	["Summon Candy Heart"] = { "white candy heart", "pink candy heart", "orange candy heart", "lavender candy heart", "yellow candy heart", "green candy heart" },
	["Summon Party Favor"] = { "divine noisemaker", "divine can of silly string", "divine blowout" },
	["Summon Love Song"] = { "love song of vague ambiguity", "love song of smoldering passion", "love song of icy revenge", "love song of sugary cuteness", "love song of disturbing obsession", "love song of naughty innuendo" },
	["Summon BRICKOs"] = { "BRICKO brick" }, --3x
	["Summon Dice"] = { "d4", "d6", "d8", "d10", "d12", "d20" },
	["Summon Resolutions"] = { "resolution: be wealthier", "resolution: be happier", "resolution: be feistier", "resolution: be stronger", "resolution: be smarter", "resolution: be sexier" },
	["Summon Taffy"] = { "pulled red taffy", "pulled orange taffy", "pulled blue taffy", "pulled violet taffy" },
}

function estimate_libram_summon_value()
	for x, y in pairs(librams) do
		local avg_value = table.avg(table.map(y, estimate_mallsell_profit))
		if x == "Summon BRICKOs" then
			avg_value = avg_value * 3
		end
		print(string.format("%s: %.1f meat/summon", x, avg_value))
	end
end
