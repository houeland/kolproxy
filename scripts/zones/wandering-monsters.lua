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

add_charpane_line(function()
	local next_bee_turn = ascension["bee turn"]
	if next_bee_turn then
		local turnmin = next_bee_turn - turnsthisrun()
		local turnmax = next_bee_turn + 5 - turnsthisrun()
		if turnmax >= 0 then
			if turnmin < 0 then turnmin = 0 end
			return { name = "Bee", value = turnmin .. " to " .. turnmax }
		end
	end
end)
