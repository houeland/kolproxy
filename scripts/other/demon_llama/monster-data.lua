function deepcopy(t)
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
	if type(v) == 'table' then
			v = deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end

local function parseMonsterNameIntoMafiaFormat(monsterName)
	--mafia's table doesn't precede the names of the monsters
	--with "a " or "an " or spaces, this function attempts to
	--strip out those things
	--mafia's table was also inconsistent with cases, 
	--so I lowercased everything and will have to do so here as well
	
	local mafiaMonsterName = monsterName:lower()

	mafiaMonsterName = mafiaMonsterName:gsub("^a ", "")
	mafiaMonsterName = mafiaMonsterName:gsub("^an ", "")
	mafiaMonsterName = mafiaMonsterName:gsub("^ ", "")

	return mafiaMonsterName
end

local function beesIncreaser(monster_name, base_data)
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

	local _, numberBees = monster_name:gsub("[bB]", "%0")
	if numberBees > 0 and not bees[monster_name] then
		local modifier = 1 + (numberBees * .2)
		base_data.Stats.HP = base_data.Stats.HP * modifier
		base_data.Stats.Atk = base_data.Stats.Atk * modifier
		base_data.Stats.Def = base_data.Stats.Def * modifier
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

function getMonsterData(monster_name, fight_text)
	local monster_data_name = parseMonsterNameIntoMafiaFormat(monster_name)
	local monster = datafile("monsters")[monster_data_name]

	if not monster then
		local monster_image = fight_text:match([[<img id='monpic' src="http://images.kingdomofloathing.com/adventureimages/([^"]+)"]])
		monster = get_monster_by_image(monster_image)
		if not monster then
			for prefix, name in pairs(monster_image_prefixes) do
				if monster_image:match("^" .. prefix) then
					monster = datafile("monsters")[name]
					break
				end
			end
		end
	end

	if not monster then return nil end
	monster = deepcopy(monster)

	local ml_increases = {
		HP = true,
		Atk = true,
		Def = true,
	}

	local modifiers = estimate_modifier_bonuses()
	local ml = modifiers["Monster Level"] or 0
	if monster_data_name == "tomb rat king" then ml = 0 end -- ML doesn't get reapplied when using rat tangles

	for a, b in pairs(monster.Stats or {}) do
		if b == 0 then
			monster.Stats[a] = "?"
		elseif ml_increases[a] then
			monster.Stats[a] = math.max(b + ml, 1)
		end
	end

	--In a bees hate you, monster's with b in their names get increased by 20% per b
	--This is AFTER ML is applied
	if ascensionpathid() == 4 then
		monster.Stats = beesIncreaser(monster_name, monster.Stats)
	end

	local item = modifiers["Item Drops from Monsters"] or 0
	for idata in table.values(monster.Items or {}) do
		if not idata["pickpocket only"] then
			local chance = idata.Chance or 0
			local p_mod = chance * (1 + item/100)
			p_mod = math.max(math.min(p_mod, 100), 0)
			idata.Chance = tonumber(round_down(p_mod, 2))
		end
	end
	return monster
end
