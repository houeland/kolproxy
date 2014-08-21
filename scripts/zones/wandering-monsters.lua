function get_wanderer_turn(label)
	return ascension["wanderer: "..label]
end

function add_wandering_monster_tracker(label, monster_list, min_offset, max_offset)

	-- create a lookup table from a list
	local monster_table = {}
	for _, m in ipairs(monster_list) do
		monster_table[m] = true
	end

	--- Add a fight processor to check if a monster is in the list
	add_processor("/fight.php", function()
		if monster_table[monstername()] then
			ascension["wanderer: "..label]  = turnsthisrun() + min_offset
		end
	end)

	-- display the wandering monster window in the charpane
	local window = max_offset - min_offset
	add_charpane_line(function()
		local next_turn = ascension["wanderer: "..label]
		if next_turn then
			local turnmin = next_turn - turnsthisrun()
			local turnmax = next_turn + window - turnsthisrun()
			if turnmax >= 0 then
				if turnmin < 0 then turnmin = 0 end
				return { name = label, value = turnmin .. " to " .. turnmax }
			end
		end
	end)

end


local bees = {"beebee gunners", "moneybee", "mumblebee", "beebee queue", "bee swarm", "buzzerker", "Beebee King", "bee thoven", "Queen Bee"}
add_wandering_monster_tracker("Bees", bees, 15, 20)

