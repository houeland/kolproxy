-- 2.5a
-- Tracks damage and deleveling done to monsters during combat
--
--

local function getFightBody(htmlPageText)
	--get fight body
	local pos, _ = htmlPageText:find([==[<span id=['"]monname['"]]==])
	if not pos then return htmlPageText end
	part1 = htmlPageText:sub(pos)

	local _, pos1 = part1:find("</span>")
	if not pos1 then return htmlPageText end
	part1 = part1:sub(pos1 + 1)

	local pos2, _ = part1:find([[<a name="end">]])
	if not pos2 then return htmlPageText end
	part2 = part1:sub(0, pos2 - 1)
	--remove monster intro text
	part2 = part2:gsub([[<blockquote>(.-)</blockquote>]], "")
	return part2
end

local blackList ={
	[[%b<>]], --any html tags
	[[You lose %d+]], --damage FROM monsters
	[[reduced by %d+]], --develers
	[[You gain %d+]], --hp or mp gain during combat
	[[macroaction: skill %d+]], --macro ids
	[[%d+ scroll]], -- scroll combat items
	[[duration: %d+]], -- acquiring an effect during combat
	[[stabs you for %d+ damage]], --stab bat
	[[sown %d+ damage]], --ice sickle, we'll get the damage on the reap message
	[[you strain your neck, doing %d+ damage]], --birdform fumble
}

local function stripOutBlackList(fightBodyText)
	for item in table.values(blackList) do
		fightBodyText = fightBodyText:gsub(item, "")
	end

	return fightBodyText
end

local mainPattern =" [0-9()+%s]+ " --this is the main damage pattern 
                                   --it WILL need a suffix otherwise it will capture too many things

local whiteList = {
	mainPattern..[[damage]], --main pattern, this will cover most of the things
	[[transferring %d+ points of]], --ggg
	[[%d+ months worth of concentrated palm sweat]], --stinkpalm
	[[%d+ HP worth]], --scary death orb
	mainPattern..[[tiny holes into him]], --birdform
	mainPattern..[[whacks to the face]], --Ax of L'rose
	[[dealing]]..mainPattern..[[to your opponent,]], -- asparagus knife
	mainPattern..[[bullets]], -- astral pistol
	mainPattern..[[hollow]], -- astral pistol
	[[spear factor by]]..mainPattern..[[points]], -- prehistoric spear
	mainPattern..[[points of really neat, groovy, and hip PAIN]], -- cool whip
	mainPattern..[[points[%']? worth]], -- clubs, flails, disco ball, origami riding crop, vampire-duck-on-a-string, plastic pumpkin bucket, can of fake snow, zim-merman's guitar, Vermincelli, Vampieroghi, gift-a-pulting chocolate-covered diamond-studded roses, fancy-pants-scarecrow in Orcish cargo shorts, throw trusty, 6 messages of 'feed' from the vampire fangs
	mainPattern..[[points of damage]], -- 'feed', throw trusty, whipping a G IMP, knob goblin firecracker, grease gun, dense meat crossbow, black sword, 
	mainPattern..[[points of automatic, systematic, hydromatic damage]], -- grease gun
	mainPattern..[[points of frozen, sharp damage]], -- ice sickle
	mainPattern..[[to the foul demon]], -- sing against AT nemesis
	[[missing]]..mainPattern..[[hit points]], -- headbutt
}

local function getCombatDamage(fightBodyText)
	filteredText = stripOutBlackList(fightBodyText)

	local total = 0

	for item in table.values(whiteList) do
		for number in filteredText:gmatch(item) do
			for num in number:gmatch([[%d+]]) do
				total = total + tonumber(num)
			end
		end
		filteredText = filteredText:gsub(item, "", 1)
	end

	--adding machine
	if fightBodyText:match([[a wisp of smoke rises from the top of it as it spits a different scroll back out of the slot]]) then
		total = total + 30
	end

	return total
end

add_processor("/fight.php", function()
	if not fight["currently fighting"] or fight["currently fighting"].name ~= get_monstername() then
		fight["currently fighting first serverdata"] = nil
		fight["currently fighting current serverdata"] = nil
		--if the monster changed mid-combat, regen the 'currently fighting' table
		fight["currently fighting"] = {
			["name"] = get_monstername(),
			["data"] = buildCurrentFightMonsterDataCache(get_monstername(), text), -- BUG: should not be caching item droprates!
		}
		fight["currently fighting first serverdata"] = nil
		for server_monsterstats_text in text:gmatch("var monsterstats = ({[^}]*})") do
			fight["currently fighting first serverdata"] = json_to_table(server_monsterstats_text)
			break
		end
	end

	for server_monsterstats_text in text:gmatch("var monsterstats = ({[^}]*})") do
		fight["currently fighting current serverdata"] = json_to_table(server_monsterstats_text)
	end

	if text:contains("var monsterstats") then
		local extra_serverdata = {}
		local phylumstr = text:match([[title="This monster is ([A-Za-z -]+)"]])
		local phylumsuffix = phylumstr and phylumstr:match(".+ (.+)")
		extra_serverdata.phylum = phylumsuffix or phylumstr
		extra_serverdata.element = text:match([[title="This monster is [A-Za-z]+%.  ([A-Za-z]+) is weak against]])
		fight["currently fighting extra serverdata"] = extra_serverdata
	end

	fightBody = getFightBody(text)

	fight["damage inflicted"] = (tonumber(fight["damage inflicted"]) or 0) + getCombatDamage(fightBody)

	--atk delevel
	local atkDelevel = 0
	for number in fightBody:gmatch([[Monster attack power reduced by <b>%d+]]) do
		atkDelevel = atkDelevel + tonumber(number:match([[%d+]]))
	end
	fight["attack decrease"] = (tonumber(fight["attack decrease"]) or 0) + atkDelevel

	--def delevel
	local defDelevel = 0
	for number in fightBody:gmatch([[Monster defense reduced by <b>%d+]]) do
		defDelevel = defDelevel + tonumber(number:match([[%d+]]))
	end
	fight["defense decrease"] = (tonumber(fight["defense decrease"]) or 0) + defDelevel
end)
