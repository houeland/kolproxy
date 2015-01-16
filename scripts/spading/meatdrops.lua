function possible_monster_meat_minmax(base_meat_value)
	local spread = math.max(1, math.floor(base_meat_value * 0.2))
	return base_meat_value - spread, base_meat_value + spread
end

function compute_final_monster_meat_drop(dropped, meat_bonus_percent)
	return math.floor(dropped * (1 + meat_bonus_percent / 100))
end

function get_possible_fight_meat_drops(base_meat_value, meat_bonus_percent)
	local lo, hi = possible_monster_meat_minmax(base_meat_value)
	local values = {}
	for x = lo, hi do
		table.insert(values, compute_final_monster_meat_drop(x, meat_bonus_percent))
	end
	return values
end

function get_possible_fight_meat_minmax(base_meat_value, meat_bonus_percent)
	local lo, hi = possible_monster_meat_minmax(base_meat_value)
	lo = compute_final_monster_meat_drop(lo, meat_bonus_percent)
	hi = compute_final_monster_meat_drop(hi, meat_bonus_percent)
	return lo, hi
end
