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

function estimate_fight_page_bonuses(fight_text)
	local bonuses = make_bonuses_table {}
	for x in fight_text:gmatch([[/friarplants/[^ ]* alt="(.-)"]]) do
		local plusitem = tonumber(x:match("+([0-9]+)%% Item drops"))
		local plusmeat = tonumber(x:match("+([0-9]+)%% Meat drops"))
		local plusinit = tonumber(x:match("+([0-9]+)%% Combat Initiative"))
		local plusml = tonumber(x:match("+([0-9]+) Monster Level"))
		bonuses.add { ["Item Drops from Monsters"] = plusitem, ["Meat from Monsters"] = plusmeat, ["Combat Initiative"] = plusinit, ["Monster Level"] = plusml }
	end

	if ascensionpath("BIG!") then
		bonuses.add { ["Monster Level"] = 150 }
	end

	local waterlevel = tonumber(fight_text:match([[alt="Water %(depth: ([0-9]+)%)"]]))
	if waterlevel then
		bonuses.add { ["Monster Level"] = waterlevel * 10 }
	end

	return bonuses
end

local monster_stat_data = {
	["oil tycoon"] = { autohit = true, stunresistpercent = 50, elementalresistpercent = 25 },
	["oil baron"] = { autohit = true, stunresistpercent = 75, elementalresistpercent = 50 },
	["oil cartel"] = { autohit = true, stunresistpercent = 100, elementalresistpercent = 75, groupsize = 3 },
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

	local monster_modifiers = {}

	if has_monster_modifiers() then
--		print("OCRS", for_monster_name)
		while not monster and for_monster_name do
			local prefix, remaining = for_monster_name:match("^([^ ]+) (.+)$")
			if prefix and remaining then
--				print("OCRS prefix", [["]] .. prefix .. [["]], "and", remaining)
				table.insert(monster_modifiers, prefix)
				for_monster_name = remaining
				monster = maybe_get_monsterdata(for_monster_name)
			else
				break
			end
		end
	end
	monster_modifiers = table.concat(monster_modifiers, " ")

	monster = table.copy(monster or {})

	monster.Stats = monster.Stats or {}
	monster.Items = monster.Items or {}

	local modifiers = estimate_current_bonuses() + estimate_fight_page_bonuses(fight_text)
	local ml = modifiers["Monster Level"]

	local ml_increases = {
		HP = true,
		Atk = true,
		Def = true,
	}

	for a, b in pairs(monster.Stats) do
		if ml_increases[a] and tonumber(b) then
			monster.Stats[a] = math.max(tonumber(b) + ml, 1)
		elseif type(b) == "string" and b:match("^mafiaexpression:%[.*%]$") then
			monster.Stats[a] = evaluate_mafiaexpression(b)
		end
	end

	-- TODO: base value should be in datafile!
	monster.Stats.stunresistpercent = nil
	monster.Stats.physicalresistpercent = nil
	monster.Stats.elementalresistpercent = nil

	local function update_resist(what, value)
		if monster.Stats[what] then
			monster.Stats[what] = math.max(monster.Stats[what], value)
		else
			monster.Stats[what] = value
		end
	end

	if monster.Stats.Phys then -- TODO: rename in datafile
		update_resist("physicalresistpercent", monster.Stats.Phys)
		monster.Stats.Phys = nil
	end

	if monster_stat_data[for_monster_name] then
		for x, y in pairs(monster_stat_data[for_monster_name]) do
			monster.Stats[x] = y
		end
	end

	-- Note: these go negative iff ML < 0 *AND* the monster didn't have any resistance value set earlier
	local mlresistpercent = math.min(ml * 0.4, 50)
	update_resist("physicalresistpercent", mlresistpercent)
	update_resist("elementalresistpercent", mlresistpercent)

	if monstername("one of Doctor Weirdeaux's creations") then
		--an_head7 = "frog head (block combat items)",
		--an_head10 = "jellyfish head (sometimes blocks actions)",
		--an_seg4 = "bee body (dodge attack)",
		--an_seg5 = "snail body (reflect spells)",
		--an_seg9 = "elephant body (+50% elemental resistance)",
		--an_butt10 = "octopus butt (prevent combat skill)",
		local parts = {}
		for img in text:gmatch([[adventureimages/(an_.-)%.gif]]) do
			parts[img] = (parts[img] or 0) + 1
		end
		if parts.an_head7 then
			monster.Stats.blockcombatitems = true
		end
		if parts.an_seg5 then
			monster.Stats.reflectspells = true
		end
		if parts.an_butt10 then
			monster.Stats.preventcombatskill = true
		end
		update_resist("physicalresistpercent", 10)
		update_resist("elementalresistpercent", math.min(100, 10 + (parts.an_seg9 or 0) * 50))
	end

	if ml >= 51 then
		local mlstunresistpercent = math.min(100, ml - 50)
		update_resist("stunresistpercent", mlstunresistpercent)
	end
	if ml >= 151 then
		monster.Stats.staggerimmune = true
	end

	if monster_modifiers:contains("unstoppable") then
		update_resist("stunresistpercent", 100)
		monster.Stats.staggerimmune = true
	end

	if monster_modifiers:contains("untouchable") then
		update_resist("physicalresistpercent", 100)
		update_resist("elementalresistpercent", 100)
	end

	--In a bees hate you, monster's with b in their names get increased by 20% per b
	--This is AFTER ML is applied
	if ascensionpath("Bees Hate You") then
		monster.Stats = beesIncreaser(get_monstername(), monster.Stats)
	end

	local item = modifiers["Item Drops from Monsters"]
	for _, idata in pairs(monster.Items or {}) do
		idata.dropratepercent = idata.Chance
		if not idata["pickpocket only"] then
			local chance = idata.Chance or 0
			local p_mod = chance * (1 + item/100)
			p_mod = math.max(math.min(p_mod, 100), 0)
			idata.Chance = tonumber(round_down(p_mod, 2)) -- TODO: Don't apply droprate increase here!
		end
	end
	return monster
end
