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

--TODO: Resolve as many ambiguous names as you can find
-- orcish frat boy
-- slimetube
-- hobopolis 
-- more...
local ambiguousNames = {
	[ [[animated nightstand]] ] = { 
		[ [[darkstand.gif]] ] = [[animated nightstand (mahogany)]],
		[ [[nightstand.gif]] ] =[[animated nightstand (white)]],
	},
	[ [[ed the undying]] ] = { 
		[ [[ed.gif]] ] = [[ed the undying (1)]],
		[ [[ed2.gif]] ] = [[ed the undying (2)]],
		[ [[ed3.gif]] ] = [[ed the undying (3)]],
		[ [[ed4.gif]] ] = [[ed the undying (4)]],
		[ [[ed5.gif]] ] = [[ed the undying (5)]],
		[ [[ed6.gif]] ] = [[ed the undying (6)]],
		[ [[ed7.gif]] ] = [[ed the undying (7)]],
	},
	[ [[ninja snowman]] ] = {
		[ [[snowman.gif]] ] = [[ninja snowman (hilt/mask)]],
		[ [[ninjarice.gif]] ] =[[ninja snowman (chopsticks)]],
	},
	[ [[knight]] ] = {
		[ [[snaknight.gif]] ] = [[knight (snake)]],
		[ [[wolfknight.gif]] ] = [[knight (wolf)]],
	}
}

local function parseMonsterNameIntoMafiaFormat(monsterName, fightText)
	--mafia's table doesn't precede the names of the monsters
	--with "a " or "an " or spaces, this function attempts to
	--strip out those things
	--mafia's table was also inconsistent with cases, 
	--so I lowercased everything and will have to do so here as well
	
	local mafiaMonsterName = monsterName:lower()

	mafiaMonsterName = mafiaMonsterName:gsub("^a ", "")
	mafiaMonsterName = mafiaMonsterName:gsub("^an ", "")
	mafiaMonsterName = mafiaMonsterName:gsub("^ ", "")

	if ambiguousNames[mafiaMonsterName] then
		for lookFor, actualName in pairs(ambiguousNames[mafiaMonsterName]) do
			if fightText:contains(lookFor) then
				return actualName
			end
		end	
	end

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

function getMonsterData(monsterName, fightText)
	local monsterDataName = parseMonsterNameIntoMafiaFormat(monsterName, fightText)
	local monster = datafile("monsters")[monsterDataName]

	if not monster then return nil end
	monster = deepcopy(monster)

	local ml_increases = {
		HP = true,
		Atk = true,
		Def = true,
	}

	local modifiers = estimate_modifier_bonuses()
	local ml = modifiers["Monster Level"] or 0
	if monsterDataName == "tomb rat king" then ml = 0 end -- ML doesn't get reapplied when using rat tangles

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
		monster.Stats = beesIncreaser(monsterName, monster.Stats)
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
