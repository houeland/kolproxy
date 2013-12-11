function adjust_combat(com)
	if com > 25 then
		return 25 + math.floor((com - 25) / 5)
	elseif com < -25 then
		return -adjust_combat(-com)
	else
		return com
	end
end

function compute_monster_initiative_bonus(ml)
	local penalty = 0
	if 20 < ml and ml <= 40 then
		penalty = 0 + 1 * (ml - 20)
	elseif 40 < ml and ml <= 60 then
		penalty = 20 + 2 * (ml - 40)
	elseif 60 < ml and ml <= 80 then
		penalty = 60 + 3 * (ml - 60)
	elseif 80 < ml and ml <= 100 then
		penalty = 120 + 4 * (ml - 80)
	elseif 100 < ml then
		penalty = 200 + 5 * (ml - 100)
	end
	return penalty
end
