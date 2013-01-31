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
	["buff: Overconfident"] = true,
	["Iron Palms"] = true,
	["Missing Kidney"] = true,

	["A Little Bit Evil (Seal Clubber)"] = true,
	["A Little Bit Evil (Turtle Tamer)"] = true,
	["A Little Bit Evil (Pastamancer)"] = true,
	["A Little Bit Evil (Sauceror)"] = true,
	["A Little Bit Evil (Disco Bandit)"] = true,
	["A Little Bit Evil (Accordion Thief)"] = true,
	["Buy! Sell! Buy! Sell!"] = true,

	[""] = true,
	["especially homoerotic frat-paddle"] = true,

	["bonuses: jalape&ntilde;o slices"] = true,
	["bonuses: frosty halo"] = true,

	["recast buff warning: Overconfident"] = true,
}

local processed_datafiles = {}

local softwarn = function() end
local function hardwarn(...)
	print("WARNING: downloaded data files inconsistent,", ...)
end

function string.contains(a, b) return a:find(b, 1, true) end

local function split_line_on(what, l)
	local tbl = {}
	local idx = 0
	while idx do
		local nextidx = l:find(what, idx + 1)
		if nextidx then
			table.insert(tbl, l:sub(idx + 1, nextidx - 1))
		else
			table.insert(tbl, l:sub(idx + 1))
		end
		idx = nextidx
	end
	return tbl
end

local function split_tabbed_line(l)
	return split_line_on("	", l:gsub("\r$", ""))
end

local function split_commaseparated(l)
	return split_line_on(",", l)
end

local function parse_mafia_bonuslist(bonuslist)
	local checks = {
		["Initiative"] = "Combat Initiative",
		["Item Drop"] = "Item Drops from Monsters",
		["Meat Drop"] = "Meat from Monsters",
		["Monster Level"] = "Monster Level",
		["Combat Rate"] = "Monsters will be more attracted to you",

		["Muscle"] = "Muscle",
		["Mysticality"] = "Mysticality",
		["Moxie"] = "Moxie",
		["Hobo Power"] = "Hobo Power",
		["PvP Fights"] = "PvP fights per day", -- PvP fight(s) per day when equipped
		["Adventures"] = "Adventures per day", -- Adventure(s) per day when equipped.
		["Muscle Percent"] = "Muscle %", -- Muscle +15%
		["Mysticality Percent"] = "Mysticality %",
		["Moxie Percent"] = "Moxie %",

		["Damage Absorption"] = "Damage Absorption",
		["Damage Reduction"] = "Damage Reduction",

		["Cold Resistance"] = "Cold Resistance",
		["Hot Resistance"] = "Hot Resistance",
		["Sleaze Resistance"] = "Sleaze Resistance",
		["Spooky Resistance"] = "Spooky Resistance",
		["Stench Resistance"] = "Stench Resistance",
		["Slime Resistance"] = "Slime Resistance",

		["Cold Spell Damage"] = "Damage to Cold Spells",
		["Hot Spell Damage"] = "Damage to Hot Spells",
		["Sleaze Spell Damage"] = "Damage to Sleaze Spells",
		["Spooky Spell Damage"] = "Damage to Spooky Spells",
		["Stench Spell Damage"] = "Damage to Stench Spells",

		["Cold Damage"] = "Cold Damage",
		["Hot Damage"] = "Hot Damage",
		["Sleaze Damage"] = "Sleaze Damage",
		["Spooky Damage"] = "Spooky Damage",
		["Stench Damage"] = "Stench Damage",

		["Spell Damage"] = "Spell Damage",
		["Weapon Damage"] = "Weapon Damage",

		["Maximum HP"] = "Maximum HP",
		["Maximum MP"] = "Maximum MP",

		["HP Regen Min"] = "Regenerate minimum HP per adventure", -- Regenerate 10-15 HP and MP per adventure
		["HP Regen Max"] = "Regenerate maximum HP per adventure",
		["MP Regen Min"] = "Regenerate minimum MP per adventure",
		["MP Regen Max"] = "Regenerate maximum MP per adventure",

		-- TODO: add more modifiers
	}

	local bonuses = {}
	for x, y in (", "..bonuslist):gmatch(", ([^,:]+): ([^,]+)") do
		if checks[x] then
			bonuses[checks[x]] = tonumber(y)
		end
	end

	return bonuses
end

function parse_buffs()
	local buffs = {}
	buffs["A Little Bit Evil"] = {}
	buffs["Buy!  Sell!  Buy!  Sell!"] = {}
	buffs["Everything Looks Yellow"] = {}
	buffs["Everything Looks Red"] = {}
	buffs["Everything Looks Blue"] = {}

	local section = nil
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		local name2 = l:match([[^# ([^	:]+)]])
		if section == "Status Effects" and name and bonuslist and not blacklist[name] and not blacklist["buff: " .. name] and not name2 then
			buffs[name] = { bonuses = parse_mafia_bonuslist(bonuslist) }
		elseif section == "Status Effects" and name2 and not blacklist[name2] and not buffs[name2] then
			buffs[name2] = {}
		end
	end
	return buffs
end

function verify_buffs(data)
	if data["Peppermint Twisted"].bonuses["Combat Initiative"] == 40 and data["Peppermint Twisted"].bonuses["Monster Level"] == 10 and data["Peeled Eyeballs"].bonuses["Meat from Monsters"] == -20 then
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
				hardwarn("outfit:item does not exist", y)
				data[xi] = nil
			end
		end
	end

	if data["Antique Arms and Armor"].bonuses["Combat Initiative"] == -10 and data["Pork Elf Prizes"].bonuses["Item Drops from Monsters"] == 10 and data["Pork Elf Prizes"].items[2] == "pig-iron helm" then
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
		if not processed_datafiles["buffs"][x] and not blacklist["recast buff warning: "..x] then
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
	local allitemuses = {}
	local itemslots = { hat = "hat", shirt = "shirt", container = "container", weapon = "weapon", offhand = "offhand", pants = "pants", accessory = "accessory", familiar = "familiarequip" }
	for l in io.lines("cache/files/items.txt") do
		local tbl = split_tabbed_line(l)
		local itemid, name, picture, itemusestr, plural = tonumber(tbl[1]), tbl[2], tbl[4], tbl[5], tbl[8]
		if picture then
			picture = picture:gsub("%.gif$", "")
		end
		if itemid and name and not blacklist[name] then
			items[name] = { id = itemid }
			lowercasemap[name:lower()] = name
			for _, u in ipairs(split_commaseparated(itemusestr or "")) do
				items[name].equipment_slot = itemslots[u]
			end
		end
	end

	function do_organ_line(l, field)
		local tbl = split_tabbed_line(l)
		local fakename, size, levelreq, advgainstr = tbl[1], tonumber(tbl[2]), tonumber(tbl[3]), tbl[5]
		if fakename and size and not blacklist[fakename] then
			local name = lowercasemap[fakename:lower()]
			if name then
				items[name][field] = size
				items[name].levelreq = levelreq
				if advgainstr then
					local advmin, advmax = advgainstr:match("^([0-9]+)%-([0-9]+)$")
					if advmin and advmax then
						items[name].advmin = tonumber(advmin)
						items[name].advmax = tonumber(advmax)
					else
						items[name].advmin = tonumber(advgainstr)
						items[name].advmax = tonumber(advgainstr)
					end
				end
			else
				softwarn("organ:item does not exist", fakename)
			end
		end
	end
	for l in io.lines("cache/files/fullness.txt") do
		do_organ_line(l, "fullness")
	end
	for l in io.lines("cache/files/inebriety.txt") do
		do_organ_line(l, "drunkenness")
	end
	for l in io.lines("cache/files/spleenhit.txt") do
		do_organ_line(l, "spleen")
	end

	for l in io.lines("cache/files/equipment.txt") do
		local tbl = split_tabbed_line(l)
		local name, power, req = tbl[1], tbl[2], tbl[3]
		if name and req and not blacklist[name] then
			if items[name] then
				local reqtbl = {}
				reqtbl.muscle = tonumber(req:match("Mus: ([0-9]+)"))
				reqtbl.mysticality = tonumber(req:match("Mys: ([0-9]+)"))
				reqtbl.moxie = tonumber(req:match("Mox: ([0-9]+)"))
				if req ~= "none" and not next(reqtbl) then
					hardwarn("unknown equip requirement", req, "for", name)
				end
				-- Mafia data files frequently show no equipment requirements as e.g. "Mus: 0" instead of "none"
				for a, b in pairs(reqtbl) do
					if b == 0 then
						reqtbl[a] = nil
					end
				end
				items[name].equip_requirement = reqtbl
				items[name].power = power
			else
				hardwarn("equipment:item does not exist", name)
			end
		end
	end

	local section = nil
	local equip_sections = { Hats = true, Containers = true, Shirts = true, Weapons = true, ["Off-hand"] = true, Pants = true, Accessories = true, ["Familiar Items"] = true }
	for l in io.lines("cache/files/modifiers.txt") do
		section = l:match([[^# (.*) section of modifiers.txt]]) or section
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		local name2 = l:match([[^# ([^	:]+)]])
		if section and equip_sections[section] and name and bonuslist and not blacklist[name] and not name2 and not blacklist["bonuses: " .. name] then
			if items[name] then
				items[name].equip_bonuses = parse_mafia_bonuslist(bonuslist)
			else
				hardwarn("modifiers:item does not exist", name)
			end
		end
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

function parse_hatrack()
	local hatrack = {}

	for l in io.lines("cache/files/modifiers.txt") do
		local name, bonuslist = l:match([[^([^	]+)	(.+)$]])
		if name and bonuslist and not blacklist[name] and processed_datafiles["items"][name] then
			hatrack[name] = bonuslist:match([[Familiar Effect: "(.-)"]])
		end
	end

	return hatrack
end

function verify_hatrack(data)
	if data["Cloaca-Cola fatigues"]:lower():contains("potato") and data["Cloaca-Cola fatigues"]:contains("7") then
		if data["asbestos helmet turtle"]:lower():contains("fairy") and data["asbestos helmet turtle"]:contains("20") then
			return data
		end
	end
end

function parse_familiars()
	local familiars = {}
	for l in io.lines("cache/files/familiars.txt") do
		local tbl = split_tabbed_line(l)
		local famid, name, pic = tonumber(tbl[1]), tbl[2], tbl[3]
		if pic then
			pic = pic:gsub("%.gif$", "")
		end
		if famid and name then
			familiars[name] = { famid = famid, familiarpic = pic }
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

	if data["Leprechaun"]["Meat from Monsters"] == 20 and data["Feral Kobold"]["Item Drops from Monsters"] == 15 then
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

function parse_semirares()
	local semirares = {}
	for l in io.lines("cache/files/KoLmafia.java") do
		local sr = l:match([[{ *"([^"]+)", *EncounterTypes.SEMIRARE *}]])
		if sr then
			table.insert(semirares, sr)
		end
	end
	return semirares
end

function verify_semirares(data)
	local ok1, ok2 = false, false
	for _, x in ipairs(data) do
		if x == "All The Rave" then
			ok1 = true
		end
		if x == "It's a Gas Gas Gas" then
			ok2 = true
		end
	end
	if ok1 and ok2 then
		return data
	end
end

function parse_mallprices()
	local fobj = io.open("cache/files/mallprices.json")
	local mallprices_datafile = fobj:read("*a")
	fobj:close()
	return json_to_table(mallprices_datafile)
end

function verify_mallprices(data)
	if data["Mr. Accessory"] >= 1000000 and data["Mr. Accessory"] <= 100000000 and data["Mick's IcyVapoHotness Inhaler"] >= 200 and data["Mick's IcyVapoHotness Inhaler"] <= 200000 then
		return data
	end
end

-- TODO: Merge with items datafile, or at least don't have fullness/drunkenness/spleen in both?
function parse_consumables()
	local fobj = io.open("cache/files/consumable-advgain.json")
	local consumables_datafile = fobj:read("*a")
	fobj:close()
	return json_to_table(consumables_datafile)
end

function verify_consumables(data)
	if data["Hell ramen"].type == "food" and data["Hell ramen"].size[1] == 6 and data["Hell ramen"].advmin == 22 and data["Hell ramen"].advmax == 28 then
		if data["beastly paste"].type == "spleen" and data["beastly paste"].size[3] == 4 and data["beastly paste"].advmin == 5 and data["beastly paste"].advmax == 10 then
				return data
		end
	end
end

function parse_choice_spoilers()
	local jsonlines = {}
	local found_adv_options = false
	for l in io.lines("cache/files/68727.user.js") do
		if l:match("var advOptions") then
			found_adv_options = true
			table.insert(jsonlines, "{")
		elseif found_adv_options then
			if l:match("};") then
				table.insert(jsonlines, "}")
				break
			else
				l_json = l:gsub("\r", ""):gsub("//.+", ""):gsub("([0-9]+)(:%[)", [["%1"%2]]) -- Strip CRs, comments, and quote keys
				l_json = l_json:gsub("\\m", "\\n") -- Correct known typo
				l_json = l_json:gsub("%+$", ",") -- HACK: Remove code using string concatenation
				table.insert(jsonlines, l_json)
			end
		end
	end
	local rawspoilers = json_to_table(table.concat(jsonlines, "\n"))
	local choice_spoilers = {}
	for a, b in pairs(rawspoilers) do
		table.remove(b, 1)
		choice_spoilers["choiceid:"..tonumber(a)] = b
	end
	return choice_spoilers
end

function verify_choice_spoilers(data)
	if data["choiceid:17"][2]:contains("snowboarder pants") and data["choiceid:603"][4]:contains("Skeletal Rogue") and data["choiceid:497"][1]:contains("unearthed monstrosity") then
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

process("choice spoilers")

process("familiars")
process("enthroned familiars")

process("items")
process("outfits")
process("hatrack")

process("buffs")
process("skills")
process("buff recast skills")

process("faxbot monsters")

process("semirares")

process("mallprices")
process("consumables")
