local function beesIncreaser(name, base_data)
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

	local _, numberBees = name:gsub("[bB]", "%0")
	if numberBees > 0 and not bees[name] and base_data then
		local modifier = 1 + (numberBees * .2)
		base_data.HP = base_data.HP * modifier
		base_data.Atk = base_data.Atk * modifier
		base_data.Def = base_data.Def * modifier
	end
	
	return base_data
end

local monster_image_prefixes = {
	nhobo = "normal hobo",
	hothobo = "hot hobo",
	coldhobo = "cold hobo",
	stenchhobo = "stench hobo",
	spookyhobo = "spooky hobo",
	slhobo = "sleaze hobo",
	slime1 = "slime1",
	slime2 = "slime2",
	slime3 = "slime3",
	slime4 = "slime4",
	slime5 = "slime5",
}

function buildCurrentFightMonsterDataCache(for_monster_name, fight_text)
	local monster = maybe_get_monsterdata(for_monster_name)

	if not monster then
		local monster_image = fight_text:match([[<img id='monpic' src="http://images.kingdomofloathing.com/adventureimages/([^"]+)"]])
		monster = maybe_get_monsterdata(for_monster_name, monster_image)
		if monster_image and not monster then
			for prefix, name in pairs(monster_image_prefixes) do
				if monster_image:match("^" .. prefix) then
					monster = maybe_get_monsterdata(name)
					break
				end
			end
		end
	end

	if not monster then return nil end
	monster = table.copy(monster)

	local ml_increases = {
		HP = true,
		Atk = true,
		Def = true,
	}

	local modifiers = estimate_modifier_bonuses()
	local ml = modifiers["Monster Level"] or 0

	if ascensionpath("BIG!") then
		ml = ml + 150
	end

	for a, b in pairs(monster.Stats or {}) do
		if ml_increases[a] and tonumber(b) then
			monster.Stats[a] = math.max(tonumber(b) + ml, 1)
		elseif type(b) == "string" and b:match("^mafiaexpression:%[.*%]$") then
			monster.Stats[a] = evaluate_mafiaexpression(b)
		end
	end

	--In a bees hate you, monster's with b in their names get increased by 20% per b
	--This is AFTER ML is applied
	if ascensionpath("Bees Hate You") then
		monster.Stats = beesIncreaser(monstername(), monster.Stats)
	end

	local item = modifiers["Item Drops from Monsters"] or 0
	for _, idata in pairs(monster.Items or {}) do
		idata.dropratepercent = idata.Chance
		if not idata["pickpocket only"] then
			local chance = idata.Chance or 0
			local p_mod = chance * (1 + item/100)
			p_mod = math.max(math.min(p_mod, 100), 0)
			idata.Chance = tonumber(round_down(p_mod, 2))
		end
	end
	return monster
end
