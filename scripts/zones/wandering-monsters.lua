local bees = {
	[" beebee gunners"] = true,
	["a moneybee"] = true,
	["a mumblebee"] = true,
	["a beebee queue"] = true,
	["a bee swarm"] = true,
	["a buzzerker"] = true,
	["a Beebee King"] = true,
	["a bee thoven"] = true,
	["a Queen Bee"] = true,
}

add_processor("/fight.php", function()
	if bees[monster_name] then
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
