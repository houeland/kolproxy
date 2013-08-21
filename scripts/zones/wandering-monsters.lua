local bees = {
	["beebee gunners"] = true,
	["moneybee"] = true,
	["mumblebee"] = true,
	["beebee queue"] = true,
	["bee swarm"] = true,
	["buzzerker"] = true,
	["Beebee King"] = true,
	["bee thoven"] = true,
	["Queen Bee"] = true,
}

add_processor("/fight.php", function()
	if bees[monstername()] then
		ascension["bee turn"] = turnsthisrun() + 15
	end
end)

add_printer("/charpane.php", function()
	local ttr = tonumber(text:match("var turnsthisrun = ([0-9]+);"))
	if not ttr then return end
	local next_bee_turn = ascension["bee turn"]
	local value = nil
	if next_bee_turn then
		local turnmin = next_bee_turn - ttr
		local turnmax = next_bee_turn + 5 - ttr
		if turnmax >= 0 then
			if turnmin < 0 then turnmin = 0 end
			value = turnmin .. "-" .. turnmax
		end
	else
-- 		value = "?"
	end
	if value then
		print_charpane_value { name = "Bee", value = value }
	end
end)
