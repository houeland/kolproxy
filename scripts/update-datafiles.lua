local faxbot_most_popular = {
	["Blooper"] = true,
	["dirty thieving brigand"] = true,
	["ghost"] = true,
	["Knob Goblin Elite Guard Captain"] = true,
	["lobsterfrogman"] = true,
	["sleepy mariachi"] = true,
	["smut orc pervert"] = true,
}

local faxbot_category_order = {
	"Most Popular",
	"Sorceress's Quest",
	"Misc Ascension",
	"Misc Aftercore",
	"Bounty Targets",
	"Featured Butts",
}

local blacklist = {
	["Kung Fu Fighting"] = true,
	["Fast as Lightning"] = true,
	["Expert Timing"] = true,
	["Gaze of the Trickster God"] = true,
	["Overconfident"] = true,
	["Iron Palms"] = true,
	["Missing Kidney"] = true,

	["A Little Bit Evil (Seal Clubber)"] = true,
	["A Little Bit Evil (Turtle Tamer)"] = true,
	["A Little Bit Evil (Pastamancer)"] = true,
	["A Little Bit Evil (Sauceror)"] = true,
	["A Little Bit Evil (Disco Bandit)"] = true,
	["A Little Bit Evil (Accordion Thief)"] = true,
	["Fortunate Resolve"] = true,
}

local processed_datafiles = {}

local softwarn = function() end
local function hardwarn(...)
	print("WARNING: downloaded data files inconsistent,", ...)
end

local function split_tabbed_line(l)
	local tbl = {}
	for x in l:gmatch("[^	]+") do
		table.insert(tbl, x)
	end
	return tbl
end

local function parse_mafia_bonuslist(bonuslist)
	local bonuses = {}
	local checks = {
		["Initiative"] = "initiative",
		["Item Drop"] = "item",
		["Meat Drop"] = "meat",
		["Monster Level"] = "ml",
		["Combat Rate"] = "combat",
	}
	for x, y in (", "..bonuslist):gmatch(", ([^,:]+): ([^,]+)") do
		if checks[x] then
			bonuses[checks[x]] = tonumber(y)
		end
	end
	return bonuses
end

function parse_buffs()
	local buffs = {}
	local section = nil
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		local name2 = l:match([[^# ([^	:]+)]])
		if section == "Status Effects" and name and bonuslist and not blacklist[name] then
			buffs[name] = parse_mafia_bonuslist(bonuslist)
		elseif section == "Status Effects" and name2 and not blacklist[name2] and not buffs[name2] then
			buffs[name2] = {}
		end
	end
	return buffs
end

function verify_buffs(data)
	if data["Peppermint Twisted"].initiative == 40 and data["Peppermint Twisted"].ml == 10 and data["Peeled Eyeballs"].meat == -20 then
		return data
	end
end

function parse_outfits()
	local outfits = {}
	for l in io.lines("cache/files/outfits.txt") do
		local name, itemlist = l:match([[^[0-9]*	([^	]+)	(.+)$]])
		if name and itemlist then
			local items = {}
			for x in (", "..itemlist):gmatch(", ([^,]+)") do
				table.insert(items, x)  
			end
			table.sort(items)
			outfits[name] = { items = items, bonuses = {} }
		end
	end
	for l in io.lines("cache/files/modifiers.txt") do
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		if name and bonuslist and outfits[name] then
			outfits[name].bonuses = parse_mafia_bonuslist(bonuslist)
		end
	end
	return outfits
end

function verify_outfits(data)
	for xi, x in pairs(data) do
		for _, y in ipairs(x.items) do
			if not processed_datafiles["items"][y] then
				hardwarn("unknown outfit item", y)
				data[xi] = nil
			end
		end
	end

	if data["Antique Arms and Armor"].bonuses.initiative == -10 and data["Pork Elf Prizes"].bonuses.item == 10 and data["Pork Elf Prizes"].items[2] == "pig-iron helm" then
		return data
	end
end

function parse_skills()
	local skills = {}
	for l in io.lines("cache/files/classskills.txt") do
		local tbl = split_tabbed_line(l)
		local skillid, name, mpcost = tonumber(tbl[1]), tbl[2], tonumber(tbl[4])
		if skillid and name and mpcost then
			skills[name] = { skillid = skillid, mpcost = mpcost }
		end
	end
	return skills
end

function verify_skills(data)
	if data["Summon Sugar Sheets"].skillid == 8002 and data["Summon Sugar Sheets"].mpcost == 2 then
		if data["Leash of Linguini"].skillid == 3010 and data["Leash of Linguini"].mpcost == 12 then
			return data
		end
	end
end

function parse_buff_recast_skills(skills)
	local buff_recast_skills = {}
	for l in io.lines("cache/files/statuseffects.txt") do
		local tbl = split_tabbed_line(l)
		local buffname, usecmd = tbl[2], tbl[5]
		local castname = (usecmd or ""):match("^cast 1 ([^|]+)")
		if buffname and castname and not blacklist[buffname] then
			buff_recast_skills[buffname] = castname
		end
	end
	return buff_recast_skills
end

function verify_buff_recast_skills(data)
	for x, y in pairs(data) do
		if not processed_datafiles["buffs"][x] then
			hardwarn("unknown recast buff", x)
			data[x] = nil
		end
		if not processed_datafiles["skills"][y] then
			hardwarn("unknown recast skill", y)
			data[x] = nil
		end
	end

	if data["Zomg WTF"] == "Ag-grave-ation" and data["Ode to Booze"] == "The Ode to Booze" and data["Leash of Linguini"] == "Leash of Linguini" then
		return data
	end
end

function parse_items()
	local items = {}
	local lowercasemap = {}
	for l in io.lines("cache/files/items.txt") do
		local tbl = split_tabbed_line(l)
		local itemid, name = tonumber(tbl[1]), tbl[2]
		if itemid and name then
			items[name] = { id = itemid }
			lowercasemap[name:lower()] = name
		end
	end
	function do_line(l, field)
		local tbl = split_tabbed_line(l)
		local fakename, size = tbl[1], tonumber(tbl[2])
		if fakename and size then
			local name = lowercasemap[fakename:lower()]
			if name then
				items[name][field] = size
			else
				softwarn("item does not exist", fakename)
			end
		end
	end
	for l in io.lines("cache/files/fullness.txt") do
		do_line(l, "fullness")
	end
	for l in io.lines("cache/files/inebriety.txt") do
		do_line(l, "drunkenness")
	end
	for l in io.lines("cache/files/spleenhit.txt") do
		do_line(l, "spleen")
	end
	return items
end

function verify_items(data)
	if data["Orcish Frat House blueprints"] and data["Boris's Helm"] then
		if data["Hell ramen"].fullness == 6 and data["water purification pills"].drunkenness == 3 and data["beastly paste"].spleen == 4 then
			return data
		end
	end
end

function parse_familiars()
	local familiars = {}
	for l in io.lines("cache/files/familiars.txt") do
		local tbl = split_tabbed_line(l)
		local famid, name = tonumber(tbl[1]), tbl[2]
		if famid and name then
			familiars[name] = { famid = famid }
		end
	end
	return familiars
end

function verify_familiars(data)
	if data["Frumious Bandersnatch"].famid == 105 and data["Oily Woim"].famid == 168 then
		return data
	end
end

function parse_enthroned_familiars()
	local enthroned_familiars = {}
	local section = nil
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^Throne:([^	]+)	(.+)$]])
		if section == "Enthroned familiars" and name and bonuslist then
			enthroned_familiars[name] = parse_mafia_bonuslist(bonuslist)
		end
	end
	return enthroned_familiars
end

function verify_enthroned_familiars(data)
	for x, _ in pairs(processed_datafiles["familiars"]) do
		if not data[x] then
			softwarn("missing enthroned familiar", x)
		end
	end
	for x, _ in pairs(data) do
		if not processed_datafiles["familiars"][x] then
			hardwarn("unknown enthroned familiar", x)
			data[x] = nil
		end
	end

	if data["Leprechaun"].meat == 20 and data["Feral Kobold"].item == 15 then
		return data
	end
end

function xml_findelements(elem, name)
	local tbl = {}
	local function iter(e)
		if e.name == name then
			table.insert(tbl, e)
		else
			for _, c in ipairs(e.children) do
				iter(c)
			end
		end
	end
	iter(elem)
	return tbl
end

function parse_faxbot_monsters()
	local fobj = io.open("cache/files/faxbot.xml")
	local faxbot_datafile = fobj:read("*a")
	fobj:close()
	local faxbot_xml = simplexmldata_to_table(faxbot_datafile)

	local categories = {}
	local catsortorder = {}
	for x, y in ipairs(faxbot_category_order) do
		table.insert(catsortorder, { name = y, sortpriority = x })
		categories[y] = {}
	end

	for _, e in ipairs(xml_findelements(faxbot_xml, "monsterdata")) do
		local m = {}
		m.name = xml_findelements(e, "actual_name")[1].text
		m.description = xml_findelements(e, "name")[1].text

		local cmd = xml_findelements(e, "command")[1].text
		local cat = xml_findelements(e, "category")[1].text

		if not categories[cat] then
			categories[cat] = {}
			table.insert(catsortorder, { name = cat, sortpriority = 1000000 })
		end
		categories[cat][cmd] = m
		if faxbot_most_popular[m.name] then
			categories["Most Popular"][cmd] = m
		end
	end

	table.sort(catsortorder, function(a, b)
		if a.sortpriority ~= b.sortpriority then
			return a.sortpriority < b.sortpriority
		else
			return a.name < b.name
		end
	end)

	local order = {}
	for _, x in ipairs(catsortorder) do
		table.insert(order, x.name)
	end

	local faxbot_monsters = {
		categories = categories,
		order = order,
	}

	return faxbot_monsters
end

function verify_faxbot_monsters(data)
	if data.categories["Most Popular"]["blooper"].name == "Blooper" and data.categories["Sorceress's Quest"]["handsomeness"].name == "handsome mariachi" and data.order[1] == "Most Popular" then
		return data
	end
end

function process(datafile)
	local filename = datafile:gsub(" ", "-")
	local loadf = _G["parse_"..datafile:gsub(" ", "_")]
	local verifyf = _G["verify_"..datafile:gsub(" ", "_")]
	local dataok, data = pcall(loadf)
	if dataok then
		local verifyok, verified = pcall(verifyf, data)
		if verifyok and verified then
			local json = table_to_json(verified)
			local fobj = io.open("cache/data/" .. filename .. ".json", "w")
			fobj:write(json)
			fobj:close()
			processed_datafiles[datafile] = verified
		else
			print("WARNING: verifying " .. tostring(filename) .. " data file failed (" .. tostring(verified) .. ").")
		end
	else
		print("ERROR: parsing " .. tostring(filename) .. " data file failed (" .. tostring(data) .. ").")
	end
end

process("familiars")
process("enthroned familiars")

process("items")
process("outfits")

process("buffs")
process("skills")
process("buff recast skills")

process("faxbot monsters")
