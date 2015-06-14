-- update-datafiles.lua --

dofile("scripts/base/base-lua-functions.lua")

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
	["buff: Kung Fu Fighting"] = true,
	["buff: Fast as Lightning"] = true,
	["buff: Expert Timing"] = true,

	["buff: A Little Bit Evil (Seal Clubber)"] = true,
	["buff: A Little Bit Evil (Turtle Tamer)"] = true,
	["buff: A Little Bit Evil (Pastamancer)"] = true,
	["buff: A Little Bit Evil (Sauceror)"] = true,
	["buff: A Little Bit Evil (Disco Bandit)"] = true,
	["buff: A Little Bit Evil (Accordion Thief)"] = true,

	["buff: Jaba&ntilde;ero Saucesphere"] = true,

	[""] = true,
	["especially homoerotic frat-paddle"] = true,

	["bonuses: jalape&ntilde;o slices"] = true,
	["bonuses: frosty halo"] = true,

	["effect: Loaded Forwarbear"] = true,
	["effect: Grape Expectations"] = true, -- TODO: remove when fixed
}

local processed_datafiles = {}

local error_count_critical = 0
local error_count_hard = 0
local error_count_soft = 0

local function format_param(x)
	if type(x) == "string" then
		return string.format("%q", x)
	elseif type(x) == "table" then
		return tojson(x)
	else
		return tostring(x)
	end
end

local function printwarning(msg, ...)
	local printtbl = {}
	table.insert(printtbl, tostring(msg))
	for _, x in ipairs { ... } do
		table.insert(printtbl, format_param(x))
	end
	print(unpack(printtbl))
end

local function hardwarn(msg, ...)
	--printwarning("WARNING: downloaded data files inconsistent, " .. tostring(msg), ...)
	error_count_hard = error_count_hard + 1
end

local function softwarn(...)
	-- Errors that are just too frequent to spam warnings for
	--print("NOTICE: downloaded data files inconsistent,", ...)
	error_count_soft = error_count_soft + 1
end

function verify_data_fits(correct_data, datafile_data)
	local function check_value(expected, found)
		if type(expected) == "table" then
			if type(found) == "table" then
				for a, b in pairs(expected) do
					if not check_value(b, found[a]) then
						return false
					end
				end
				return true
			else
				return false
			end
		else
			return tojson(expected) == tojson(found)
		end
	end
	local ok = true
	for correct_name, correct_value in pairs(correct_data) do
		local data_value = datafile_data[correct_name]
		if not check_value(correct_value, data_value) then
			printwarning("Verification failed for", correct_name)
			printwarning("  expected:", correct_value)
			printwarning("  found:   ", data_value)
			ok = false
		end
	end
	if ok then
		return datafile_data
	end
end

function string.contains(a, b) return not not a:find(b, 1, true) end

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
	return split_line_on(",", l:gsub(", ", ","))
end

local function remove_line_junk(l)
	return l:gsub("\r$", "")
end

local function parse_mafia_bonuslist(bonuslist, debug_source_name)
	local checks = {
		-- TODO: Rename these three to include the "%"
		["Initiative"] = "Combat Initiative", -- "Combat Initiative +25%"
		["Item Drop"] = "Item Drops from Monsters", -- "+25% Item Drops from Monsters"
		["Meat Drop"] = "Meat from Monsters", -- "+30% Meat from Monsters"
		["Monster Level"] = "Monster Level", -- "+15 to Monster Level"
		["Combat Rate"] = "Monsters will be more attracted to you", -- "Monsters will be more attracted to you."

		["Muscle"] = "Muscle", -- "Muscle +10"
		["Mysticality"] = "Mysticality", -- "Mysticality +10"
		["Moxie"] = "Moxie", -- "Moxie +10"
		["Hobo Power"] = "Hobo Power", -- "+25 Hobo Power"
		-- TODO: Rename to "Fights"(?) and "Day"(?)
		["PvP Fights"] = "PvP fights per day", -- "+5 PvP Fight(s) per day", "+6 PvP fight(s) per day when equipped.", "+5 PvP Fights per Day"
		["Adventures"] = "Adventures per day", -- "+3 Adventure(s) per day", "+3 Adventure(s) per day when equipped."
		["Muscle Percent"] = "Muscle %", -- "Muscle +30%"
		["Mysticality Percent"] = "Mysticality %", -- "Mysticality +30%"
		["Moxie Percent"] = "Moxie %", -- "Moxie +30%"

		["Damage Absorption"] = "Damage Absorption", -- "Damage Absorption +50"
		["Damage Reduction"] = "Damage Reduction", -- "Damage Reduction: 10"

		["Cold Resistance"] = "Cold Resistance", -- "Sublime Cold Resistance (+9)"
		["Hot Resistance"] = "Hot Resistance", -- "Sublime Hot Resistance (+9)"
		["Sleaze Resistance"] = "Sleaze Resistance", -- "Sublime Sleaze Resistance (+9)"
		["Spooky Resistance"] = "Spooky Resistance", -- "Sublime Spooky Resistance (+9)"
		["Stench Resistance"] = "Stench Resistance", -- "Sublime Stench Resistance (+9)"
		["Slime Resistance"] = "Slime Resistance", -- "Slight Slime Resistance (+1)"

		["Cold Spell Damage"] = "Damage to Cold Spells", -- "+30 Damage to Cold Spells"
		["Hot Spell Damage"] = "Damage to Hot Spells", -- "+10 Damage to Hot Spells"
		["Sleaze Spell Damage"] = "Damage to Sleaze Spells", -- "+10 Damage to Sleaze Spells"
		["Spooky Spell Damage"] = "Damage to Spooky Spells", -- "+75 Damage to Spooky Spells"
		["Stench Spell Damage"] = "Damage to Stench Spells", -- "+15 Damage to Stench Spells"

		["Cold Damage"] = "Cold Damage", -- "+25 Cold Damage"
		["Hot Damage"] = "Hot Damage", -- "+25 Hot Damage"
		["Sleaze Damage"] = "Sleaze Damage", -- "+25 Sleaze Damage"
		["Spooky Damage"] = "Spooky Damage", -- "+25 Spooky Damage"
		["Stench Damage"] = "Stench Damage", -- "+25 Stench Damage"

		["Spell Damage"] = "Spell Damage", -- "Spell Damage +40"
		["Spell Damage Percent"] = "Spell Damage %", -- "Spell Damage +150%"
		["Weapon Damage"] = "Weapon Damage", -- "Weapon Damage +7"
		["Weapon Damage Percent"] = "Weapon Damage %", -- "Weapon Damage +50%"

		["Critical Hit Percent"] = "% Chance of Critical Hit", -- "+5% Chance of Critical Hit", "+20% chance of Critical Hit"
		["Spell Critical Percent"] = "% Chance of Spell Critical Hit", -- "+20% Chance of Spell Critical Hit"

		["Maximum HP"] = "Maximum HP", -- "Maximum HP +20"
		["Maximum MP"] = "Maximum MP", -- "Maximum MP +20"
		["Maximum HP Percent"] = "Maximum HP %", -- "Maximum HP +100%"
		["Maximum MP Percent"] = "Maximum MP %", -- "Maximum MP +50%"

		-- TODO: Find better names for these. "(minimum)" at the end? Rename to "Adventure"(?)
		["HP Regen Min"] = "Regenerate minimum HP per adventure", -- "Regenerate 30-60 HP per adventure", "Regenerate 10-15 HP and MP per adventure"
		["HP Regen Max"] = "Regenerate maximum HP per adventure",
		["MP Regen Min"] = "Regenerate minimum MP per adventure", -- "Regenerate 10-15 MP per adventure"
		["MP Regen Max"] = "Regenerate maximum MP per adventure",

		-- TODO: Rename these two to include the "%"
		["Food Drop"] = "Food Drops from Monsters", -- "+30% Food Drops from Monsters"
		["Booze Drop"] = "Booze Drops from Monsters", -- "+30% Booze Drops from Monsters"

		["Familiar Weight"] = "Familiar Weight", -- "+5 to Familiar Weight"

		["Smithsness"] = "Smithsness", -- "+5 Smithsness"

		-- TODO: Rename to lowercase "per"?
		["Experience"] = "Stats Per Fight", -- "+2 Stat(s) Per Fight"
		["Experience (Muscle)"] = "Muscle Stats Per Fight", -- "+2 Muscle Stat(s) Per Fight"
		["Experience (Mysticality)"] = "Mysticality Stats Per Fight", -- "+2 Mysticality Stat(s) Per Fight"
		["Experience (Moxie)"] = "Moxie Stats Per Fight", -- "+2 Moxie Stat(s) Per Fight"

		-- TODO: add more modifiers
	}

	local bonuses = {}
	for x, y in (", "..bonuslist):gmatch(", ([^,:]+): ([^,]+)") do
		-- TODO: Do more complicated parsing for expressions
		if checks[x] then
			if not tonumber(y) and y:contains("Accordion Appreciation") then
				y = y:match("%[([0-9]+)%*%(1%+skill%(Accordion Appreciation%)%)]")
			end
			bonuses[checks[x]] = tonumber(y)
		end
	end

	return bonuses
end

local function mafia_datafile(filename, whichsection)
	local section = nil
	local results = {}
	for l in io.lines(filename) do
		l = remove_line_junk(l)
		section = l:match([[^# (.*) section]]) or section
		local tbl = split_tabbed_line(l)
		local name = tbl[2]
		local name2 = l:match([[^# ([^	:]+)]])
		if section == whichsection or not whichsection then
			if name and not name2 then
				results[name] = { section = section, columns = tbl }
			elseif name2 and not results[name2] then
				results[name2] = { section = section }
			end
		end
	end
	return results
end

function parse_buffs()
	local buffs = {}
	buffs["A Little Bit Evil"] = {}

	for name, tbl in pairs(mafia_datafile("cache/files/modifiers.txt", "Status Effects")) do
		local bonuslist = tbl.columns and tbl.columns[3]
		if bonuslist then
			buffs[name] = { bonuses = parse_mafia_bonuslist(bonuslist, name) }
		else
			buffs[name] = {}
		end
	end

	for l in io.lines("cache/files/statuseffects.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local buffname, descid, usecmd = tbl[2], tbl[4], tbl[5]
		local castname = (usecmd or ""):match("^cast 1 ([^|]+)")
		if buffname and not buffs[buffname] and not blacklist["buff: " .. buffname] then
			softwarn("missing buff", buffname)
			buffs[buffname] = {}
		end
		if buffname and descid and not blacklist["buff: " .. buffname] then
			buffs[buffname].descid = descid
		end
		if buffname and castname and not blacklist["buff: " .. buffname] then
			-- Datafile is full of capitalization problems
			if not processed_datafiles["skills"][castname] then
				for x, y in pairs(processed_datafiles["skills"]) do
					if x:lower() == castname:lower() then
						softwarn("statuseffects:", castname, "should be", x)
						castname = x
					end
				end
			end
			buffs[buffname].cast_skill = castname
		end
	end

	return buffs
end

function verify_buffs(data)
	for x, y in pairs(data) do
		if y.cast_skill and not processed_datafiles["skills"][y.cast_skill] then
			hardwarn("unknown recast skill", y.cast_skill)
			data[x] = nil
		end
	end
	local correct_data = {
		["Peppermint Twisted"] = { bonuses = { ["Combat Initiative"] = 40, ["Monster Level"] = 10 } },
		["Peeled Eyeballs"] = { bonuses = { ["Stats Per Fight"] = -1, ["Meat from Monsters"] = -20, ["Item Drops from Monsters"] = 15 } },
		["On the Trail"] = {},
		["Aloysius' Antiphon of Aptitude"] = { bonuses = { ["Muscle Stats Per Fight"] = 1, ["Mysticality Stats Per Fight"] = 1, ["Moxie Stats Per Fight"] = 1 } },
		["Everything Looks Yellow"] = {},
		["Buy!  Sell!  Buy!  Sell!"] = {},
		["Bored With Explosions"] = {},
		["Zomg WTF"] = { cast_skill = "Ag-grave-ation" },
		["Ode to Booze"] = { cast_skill = "The Ode to Booze" },
		["Leash of Linguini"] = { cast_skill = "Leash of Linguini" },
	}
	return verify_data_fits(correct_data, data)
end

function parse_passives()
	local passives = {}
	for name, tbl in pairs(mafia_datafile("cache/files/modifiers.txt", "Passive Skills")) do
		local bonuslist = tbl.columns and tbl.columns[3]
		if bonuslist then
			passives[name] = { bonuses = parse_mafia_bonuslist(bonuslist, name) }
		else
			passives[name] = {}
		end
	end
	return passives
end

function verify_passives(data)
	if data["Mad Looting Skillz"].bonuses["Item Drops from Monsters"] == 20 and data["Nimble Fingers"].bonuses["Meat from Monsters"] == 20 and data["Thief Among the Honorable"].bonuses["Item Drops from Monsters"] == 5 and data["Greed"].bonuses["Item Drops from Monsters"] == -15 then
		return data
	end
end

function parse_outfits()
	local outfits = {}
	for l in io.lines("cache/files/outfits.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local outfitid, name, avatar, itemlist = tonumber(tbl[1]), tbl[2], tbl[3], tbl[4]
		if name and itemlist then
			local items = {}
			for x in (", "..itemlist):gmatch(", ([^,]+)") do
				table.insert(items, x)
			end
			table.sort(items)
			outfits[name] = { items = items, bonuses = {} }
		end
	end
	for name, tbl in pairs(mafia_datafile("cache/files/modifiers.txt")) do
		local bonuslist = tbl.columns and tbl.columns[3]
		if outfits[name] and bonuslist then
			outfits[name].bonuses = parse_mafia_bonuslist(bonuslist, name)
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
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local skillid, name, mafiaskilltypeid, mpcost = tonumber(tbl[1]), tbl[2], tonumber(tbl[4]), tonumber(tbl[5])
		if skillid and name and mpcost then
			local is_TT_shell = (2000 <= skillid and skillid <= 2999 and mafiaskilltypeid == 4)
			local is_S_sphere = (4000 <= skillid and skillid <= 4999 and mafiaskilltypeid == 4)
			local is_AT_song = (6000 <= skillid and skillid <= 6999 and mafiaskilltypeid == 4)
			skills[name] = { skillid = skillid, mpcost = mpcost, turtle_tamer_shell = is_TT_shell, sauceror_sphere = is_S_sphere, accordion_thief_song = is_AT_song }
		end
	end
	return skills
end

function verify_skills(data)
	local correct_data = {
		["Summon Sugar Sheets"] = { skillid = 7215, mpcost = 2 },
		["Leash of Linguini"] = { skillid = 3010, mpcost = 12 },
		["Patience of the Tortoise"] = { turtle_tamer_shell = false },
		["Spiky Shell"] = { turtle_tamer_shell = true },
		["Sauce Contemplation"] = { sauceror_sphere = false },
		["Antibiotic Saucesphere"] = { sauceror_sphere = true },
		["Moxie of the Mariachi"] = { accordion_thief_song = false },
		["The Ode to Booze"] = { accordion_thief_song = true },
	}
	return verify_data_fits(correct_data, data)
end

function parse_items()
	local items = {}
	local lowercasemap = {}
	local allitemuses = {}
	local itemslots = { hat = "hat", shirt = "shirt", container = "container", weapon = "weapon", offhand = "offhand", pants = "pants", accessory = "accessory", familiar = "familiarequip" }
	for l in io.lines("cache/files/items.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local itemid, name, descidstr, picturestr, itemusestr, accessstr, autosellstr, plural = tonumber(tbl[1]), tbl[2], tbl[3], tbl[4], tbl[5], tbl[6], tbl[7], tbl[8]
		local picture = (picturestr or ""):match("^(.-)%.gif$")
		if itemid and name and not blacklist[name] then
			items[itemid] = { id = itemid, name = name, picture = picture, sellvalue = tonumber(autosellstr), descid = tonumber(descidstr) }
			lowercasemap[name:lower()] = itemid
			for _, u in ipairs(split_commaseparated(itemusestr or "")) do
				if itemslots[u] then
					items[itemid].equipment_slot = itemslots[u]
				end
			end
			for _, a in ipairs(split_commaseparated(accessstr or "")) do
				if a == "t" then
					items[itemid].cantransfer = true
				end
			end
		end
	end

	function do_organ_line(l, field)
		local tbl = split_tabbed_line(l)
		local fakename, size, levelreq, advgainstr = tbl[1], tonumber(tbl[2]), tonumber(tbl[3]), tbl[5]
		if fakename and size and not blacklist[fakename] then
			local itemid = lowercasemap[fakename:lower()]
			if itemid then
				--if not items[fakename] then
				--	hardwarn("wrong item capitalization", fakename, "should be", name)
				--end
				items[itemid][field] = size
				items[itemid].levelreq = levelreq
				if advgainstr then
					local advmin, advmax = advgainstr:match("^([0-9]+)%-([0-9]+)$")
					if advmin and advmax then
						items[itemid].advmin = tonumber(advmin)
						items[itemid].advmax = tonumber(advmax)
					else
						items[itemid].advmin = tonumber(advgainstr)
						items[itemid].advmax = tonumber(advgainstr)
					end
				end
			else
				softwarn("organ:item does not exist", fakename)
			end
		end
	end
	for l in io.lines("cache/files/fullness.txt") do
		l = remove_line_junk(l)
		do_organ_line(l, "fullness")
	end
	for l in io.lines("cache/files/inebriety.txt") do
		l = remove_line_junk(l)
		do_organ_line(l, "drunkenness")
	end
	for l in io.lines("cache/files/spleenhit.txt") do
		l = remove_line_junk(l)
		do_organ_line(l, "spleen")
	end

	for l in io.lines("cache/files/equipment.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local name, power, req, weaptype = tbl[1], tonumber(tbl[2]), tbl[3], tbl[4]
		if name and req and not blacklist[name] then
			local itemid = lowercasemap[name:lower()]
			if items[itemid] then
				local reqtbl = {}
				reqtbl.Muscle = tonumber(req:match("Mus: ([0-9]+)"))
				reqtbl.Mysticality = tonumber(req:match("Mys: ([0-9]+)"))
				reqtbl.Moxie = tonumber(req:match("Mox: ([0-9]+)"))
				if req ~= "none" and not next(reqtbl) then
					hardwarn("unknown equip requirement for", name, req)
				end
				if reqtbl.Muscle then
					items[itemid].attack_stat = "Muscle"
				elseif reqtbl.Moxie then
					items[itemid].attack_stat = "Moxie"
				end
				-- Mafia data files frequently show no equipment requirements as e.g. "Mus: 0" instead of "none"
				for a, b in pairs(reqtbl) do
					if b == 0 then
						reqtbl[a] = nil
					end
				end
				items[itemid].equip_requirements = reqtbl
				items[itemid].power = power
				items[itemid].weapon_hands = tonumber((weaptype or ""):match("^([0-9]+)%-handed"))
				items[itemid].weapon_type = weaptype
				if weaptype == "shield" then
					items[itemid].is_shield = true
				end
			else
				hardwarn("equipment:item does not exist", name)
			end
		end
	end

	local equip_sections = { Hats = true, Containers = true, Shirts = true, Weapons = true, ["Off-hand Items"] = true, Offhand = true, Offhands = true, Pants = true, Accessories = true, ["Familiar Items"] = true }
	for name, tbl in pairs(mafia_datafile("cache/files/modifiers.txt")) do
		local itemid = lowercasemap[name:lower()]
		local bonuslist = tbl.columns and tbl.columns[3]
		if equip_sections[tbl.section] and bonuslist and not blacklist[name] and not blacklist["bonuses: " .. name] then
			if items[itemid] then
				items[itemid].equip_bonuses = parse_mafia_bonuslist(bonuslist, name)
				items[itemid].song_duration = tonumber(bonuslist:match("Song Duration: ([0-9]+)"))
				if bonuslist:match("Single Equip") then
					items[itemid].equip_requirements = items[itemid].equip_requirements or {}
					items[itemid].equip_requirements["You may not equip more than one of these at a time"] = true
				end
				if bonuslist:match("Class:") then
					items[itemid].class = bonuslist:match([[Class: "(.-)"]])
				end
			else
				hardwarn("modifiers:item does not exist", name)
			end
		elseif tbl.section == "Everything Else" and name and bonuslist and bonuslist:contains("Effect:") then
			local effect = bonuslist:match([[Effect: "(.-)"]])
			if not effect then
				hardwarn("modifiers:useitem effect does not exist", name, effect)
			elseif blacklist["effect: " .. effect] then
			elseif items[itemid] then
				if items[itemid].fullness == nil and items[itemid].drunkenness == nil and items[itemid].spleen == nil then
					items[itemid].use_effect = effect
				end
			elseif not name:match("^# ") then
				hardwarn("modifiers:useitem does not exist", name, effect)
			end
		end
	end

	for l in io.lines("cache/files/statuseffects.txt") do
		l = remove_line_junk(l)
		local n = l:match("[0-9]*	([^	]+)")
		local i = l:match("[0-9]*	[^	]+	.*use 1 (.+)") or l:match("[0-9]*	[^	]+	.*use 5 (.+)")
		local itemid = i and lowercasemap[i:lower()]
		if n and not processed_datafiles["buffs"][n] then
			softwarn("statuseffects:buff does not exist", n)
		elseif n and itemid and items[itemid] and items[itemid].use_effect ~= n then
			softwarn("modifiers/statuseffects mismatch", i, n)
			items[itemid].use_effect = n
		end
	end

	for x, y in pairs(items) do
		fixed_name = y.name:gsub([["]], [[&quot;]])
		if y.name ~= fixed_name then
			softwarn("statuseffects:item", y.name, "should be", fixed_name)
		end
		items[x].name = fixed_name
	end

	local sa_id = lowercasemap["stolen accordion"]
	if items[sa_id].song_duration ~= 5 then
		softwarn("statuseffects:stolen accordion should have song duration 5")
		items[sa_id].song_duration = 5 -- HACK: datafile is broken
	end

	return items
end

function verify_items(data)
	local correct_data = {
		["Orcish Frat House blueprints"] = {},
		["Boris's Helm"] = { equip_bonuses = { ["Combat Initiative"] = 25 }, power = 100 },
		["Hell ramen"] = { fullness = 6 },
		["water purification pills"] = { drunkenness = 3 },
		["beastly paste"] = { spleen = 4 },
		["leather chaps"] = { equip_requirements = { Moxie = 65 } },
		["dried gelatinous cube"] = { id = 6256 },
		["flaming pink shirt"] = { equipment_slot = "shirt" },
		["mayfly bait necklace"] = { equip_bonuses = { ["Item Drops from Monsters"] = 10, ["Meat from Monsters"] = 10 } },
		["Jarlsberg's pan (Cosmic portal mode)"] = { equip_bonuses = { ["Food Drops from Monsters"] = 50 } },
		["stolen accordion"] = { song_duration = 5 },
		["toy accordion"] = { song_duration = 5 },
		["pygmy concertinette"] = { song_duration = 17 },
		["ring of conflict"] = { equip_bonuses = { ["Monsters will be more attracted to you"] = -5 }, equip_requirements = { ["You may not equip more than one of these at a time"] = true } },
		["Juju Mojo Mask"] = { equip_bonuses = { ["Stats Per Fight"] = 2 } },
		["Shakespeare's Sister's Accordion"] = { equip_bonuses = { ["Smithsness"] = 5 } },
		["Rock and Roll Legend"] = { equip_bonuses = { ["Moxie"] = 7 } },
		["Sneaky Pete's basket"] = { attack_stat = "Moxie" },
		["Staff of Fats"] = { id = 2268 },
		["Spookyraven library key"] = { id = 7302 },
		["Galapagosian Cuisses"] = { class = "Turtle Tamer" },
	}
	local known_classes = {
		["Seal Clubber"] = true,
		["Turtle Tamer"] = true,
		["Pastamancer"] = true,
		["Sauceror"] = true,
		["Disco Bandit"] = true,
		["Accordion Thief"] = true,
	}
	local return_data = {}
	for x, y in pairs(data) do
		if y.class and not known_classes[y.class] then
		elseif y.id == 7964 then -- Ed's Staff of Fats
		elseif not return_data[y.name] or y.id > return_data[y.name].id then
			return_data[y.name] = y
		end
	end
	if verify_data_fits(correct_data, return_data) then
		return return_data
	end
end

local function parse_monster_stats(stats, monster_debug_line)
	if stats == "" then
		return {}
	end
	local statstbl = {}
	local i = 1
	if stats:match("^BOSS ") then
		statstbl.boss = true
		i = i + 5
	end
	stats = stats .. " "
	while i <= #stats do
		local name, value, pos
		if stats:sub(i, i) == [["]] then -- quoted string
			name = "WatchOut"
			value, pos = stats:match('^"([^"]*)" ()', i)
		elseif stats:sub(i, i) == " " then -- space (formatting error, ignore)
			pos = i + 1
		else
			name, value, pos = stats:match("^([^:]+): +([^ ]+) ()", i)
			if name and value then
				if tonumber(value) then
					value = tonumber(value)
				elseif value:match("^%[.*%]$") then
					value = "mafiaexpression:" .. value
				elseif name == "Meat" then
					local lo, hi = value:match("^([0-9]+)%-([0-9]+)$")
					lo, hi = tonumber(lo), tonumber(hi)
					if lo and hi then
						value = math.floor((lo + hi) / 2)
						if value * 2 ~= lo + hi then
							softwarn("bad monster meat value", value, lo, hi)
						end
					end
				end

				if name == "P" then
					name = "Phylum"
					value = value:sub(1, 1):upper() .. value:sub(2)
				elseif name == "E" or name == "ED" then
					name = "Element"
					value = value:sub(1, 1):upper() .. value:sub(2)
				end

				if name == "Init" and value == -10000 then
					value = 0
				end
			end
		end
		if name and value then
			statstbl[name] = value
		elseif stats:sub(i, i) == " " then
			softwarn("monsters.txt:malformed line", monster_debug_line)
		elseif stats:contains("DUMMY") then
			return statstbl
		else
			error_count_hard = error_count_hard + 1
			print("WARNING: failed to parse monster stat", stats:sub(i))
			print("DEBUG: ", monster_debug_line)
			return statstbl
		end
		i = pos
	end
	return statstbl
end

local prefixkeys = {
	p = "pickpocket only",
	n = "no pickpocket",
	b = "bounty",
	c = "conditional",
	f = "fixed",
	a = "accordion",
}

local function parse_monster_items(items)
	if #items == 0 then return nil end
	itemtbl = {}
	for _, item in ipairs(items) do
		local name, prefix, rate, suffix = item:match("^ ?(.*) %(([pnbcfa]?)(%d+)([pnbcfa]?)%)$")
		if suffix and suffix ~= "" then
			prefix = suffix
		end

		if not name then
			-- a few items are missing drop rates
			name = item
		end
		local nameitemid = tonumber(name:match("^%[([0-9]+)%]$"))
		if nameitemid then
			for n, d in pairs(processed_datafiles["items"]) do
				if d.id == nameitemid then
					name = n
				end
			end
		end

		local itementry = {
			Name = name,
		}
		rate = tonumber(rate)
		if rate and rate > 0 then
			itementry.Chance = rate
		end
		if prefix and prefix ~= "" then
			itementry[prefixkeys[prefix]] = true
			if prefix == "b" then
				itementry.Chance = 100
			end
		end
		table.insert(itemtbl, itementry)
	end
	return itemtbl
end

function parse_monsters()
	local monsters = {}
	for l in io.lines("cache/files/monsters.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local name, id, image, stats = tbl[1], tonumber(tbl[2]), tbl[3], tbl[4]
		if id == 0 then id = nil end
		if image == "" then image = nil end
		__parse_monster_debug = tojson(tbl)
		if not l:match("^#") and name and stats then
			--print("DEBUG parsing monster", name)
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			local items = tbl
			monsters[name:lower()] = {
				Stats = parse_monster_stats(stats, l),
				Items = parse_monster_items(items),
				image = image,
			}
		end
	end
	monsters["booty crab"].Stats.boss = true
	monsters["cosmetics wraith"].Stats.boss = true
	monsters["huge ghuol"].Stats.boss = true
	monsters["knob goblin king"].Stats.boss = true
	monsters["ancient protector spirit"].Stats.boss = true
	monsters["giant tardigrade"].Stats.boss = true
	monsters["panicking knott yeti"].Stats.boss = true
	return monsters
end

function verify_monsters(data)
	for xi, x in pairs(data) do
		for _, y in ipairs(x.Items or {}) do
			if not processed_datafiles["items"][y.Name] then
				hardwarn("monsters:item does not exist:", xi, y.Name)
			end
		end
	end

	local cube_ok = false
	for _, x in ipairs(data["hellion"].Items) do
		if x.Name == "hellion cube" then
			cube_ok = true
		end
	end
	if not cube_ok then return end

	local correct_data = {
		["hellion"] = { Stats = { HP = 52, Element = "Hot", Phylum = "Demon" } },
		["hank north, photojournalist"] = { Stats = { HP = 180 } },
		["beefy bodyguard bat"] = { Stats = { Meat = 250 } },
		["booty crab"] = { Stats = { boss = true } },
	}
	return verify_data_fits(correct_data, data)
end

function parse_hatrack()
	local hatrack = {}
	for name, tbl in pairs(mafia_datafile("cache/files/modifiers.txt")) do
		local bonuslist = tbl.columns and tbl.columns[3]
		if bonuslist and processed_datafiles["items"][name] then
			local desc = bonuslist:match([[Familiar Effect: "(.-)"]])
			if desc then
				hatrack[name] = { description = desc, familiar_types = {} }
				hatrack[name].familiar_types["Baby Gravy Fairy"] = tonumber(desc:match("([0-9.]+)xFairy"))
				hatrack[name].familiar_types["Leprechaun"] = tonumber(desc:match("([0-9.]+)xLep"))
				hatrack[name].familiar_types["Levitating Potato"] = tonumber(desc:match("([0-9.]+)xPotato"))
			end
		end
	end
	return hatrack
end

function verify_hatrack(data)
	if data["Cloaca-Cola fatigues"].familiar_types["Levitating Potato"] and data["Cloaca-Cola fatigues"].description:contains("7") then
		if data["asbestos helmet turtle"].familiar_types["Baby Gravy Fairy"] and data["asbestos helmet turtle"].description:contains("20") then
			if data["frilly skirt"].familiar_types["Baby Gravy Fairy"] == 4 then
				if data["spangly sombrero"].familiar_types["Baby Gravy Fairy"] == 2 then
					return data
				end
			end
		end
	end
end

function parse_recipes()
	local recipes = {}
	local function add_recipe(item, tbl)
		if tbl.ingredients then -- WORKAROUND
			if tbl.ingredients[1] == "[2528]" then tbl.ingredients[1] = "filet of tangy gnat (&quot;fotelif&quot;)" end
			if tbl.ingredients[1] == "[0]" then table.remove(tbl.ingredients, 1) end
		end
		local short_itemname = item:match("^(.+) %([0-9]+%)$")
		if short_itemname then item = short_itemname end
		if not recipes[item] then
			recipes[item] = {}
		end
		table.insert(recipes[item], tbl)
	end

	for l in io.lines("cache/files/concoctions.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local itemname, crafttype = tbl[1], tbl[2]
		if l:match("^# ") then
		elseif crafttype == "CLIPART" then
			add_recipe(itemname, { type = "cliparts", clips = { tonumber(tbl[3]), tonumber(tbl[4]), tonumber(tbl[5]) } })
		elseif crafttype == "SMITH" or crafttype == "WSMITH" or crafttype == "ASMITH" then
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			table.sort(tbl)
			add_recipe(itemname, { type = "smith", ingredients = tbl })
		elseif crafttype == "MIX" or crafttype == "ACOCK" or crafttype == "SCOCK" or crafttype == "SACOCK" then
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			table.sort(tbl)
			add_recipe(itemname, { type = "cocktail", ingredients = tbl })
		elseif crafttype == "COOK" or crafttype == "PASTA" or crafttype == "TEMPURA" or crafttype == "SAUCE" or crafttype == "SSAUCE" or crafttype == "DSAUCE" then
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			table.sort(tbl)
			add_recipe(itemname, { type = "cook", ingredients = tbl })
		elseif crafttype == "COMBINE" then
			table.remove(tbl, 1)
			table.remove(tbl, 1)
			table.sort(tbl)
			add_recipe(itemname, { type = "combine", ingredients = tbl })
		elseif crafttype and crafttype:contains("STILL") then
			add_recipe(itemname, { type = "still", base = tbl[3], ingredients = { tbl[3] } })
		end
	end

	return recipes
end

function verify_recipes(data)
	for name, ways in pairs(data) do
		if not processed_datafiles["items"][name] then
			hardwarn("recipe:item does not exist", name)
			data[name] = nil
		end
		for _, recipe in ipairs(ways) do
			for _, x in ipairs(recipe.ingredients or {}) do
				if not processed_datafiles["items"][x] then
					hardwarn("recipe:item ingredient does not exist", x, "for", name)
					data[name] = nil
				end
			end
		end
	end
	local correct_data = {
		["potion of X-ray vision"] = { { type = "cliparts", clips = { 4, 6, 8 } } },
		["margarita"] = { { type = "cocktail", ingredients = { "bottle of tequila", "lemon" } } },
		["tonic water"] = { { type = "still", base = "soda water" } },
		["Hell ramen"] = { { type = "cook", ingredients = { "Hell broth", "dry noodles" } } },
		["Hairpiece On Fire"] = { { type = "smith", ingredients = { "lump of Brituminous coal", "maiden wig" } } },
	}
	return verify_data_fits(correct_data, data)
end

function parse_familiars()
	local function if_nonempty(x)
		if x and x ~= "" then
			return x
		end
	end
	local familiars = {}
	for l in io.lines("cache/files/familiars.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local famid, name, pic, famtype, larvaitem, equip = tonumber(tbl[1]), tbl[2], tbl[3], tbl[4], if_nonempty(tbl[5]), if_nonempty(tbl[6])
		if pic then
			pic = pic:gsub("%.gif$", "")
		end
		if famid and name then
			familiars[name] = {
				famid = famid,
				familiarpic = pic,
				familiarequip = equip,
				larvaitem = larvaitem,
				volleyballtype = famtype:contains("stat0") or nil,
				fairytype = famtype:contains("item0") or nil,
				leprechauntype = famtype:contains("meat0") or nil,
			}
		end
	end
	return familiars
end

function verify_familiars(data)
	for x, y in pairs(data) do
		if y.familiarequip and not processed_datafiles["items"][y.familiarequip] then
			hardwarn("familiar:familiarequip does not exist", y.familiarequip)
			data[x].familiarequip = nil
		end
		if y.larvaitem and not processed_datafiles["items"][y.larvaitem] then
			hardwarn("familiar:larvaitem does not exist", y.larvaitem)
			data[x].larvaitem = nil
		end
	end

	local correct_data = {
		["Frumious Bandersnatch"] = { famid = 105 },
		["Oily Woim"] = { famid = 168, larvaitem = "woim" },
		["Bloovian Groose"] = { volleyballtype = true, leprechauntype = true, larvaitem = "The Groose in the Hoose", familiarequip = "spruce juice" },
		["Slimeling"] = { fairytype = true, familiarequip = "undissolvable contact lenses" },
	}
	return verify_data_fits(correct_data, data)
end

-- TODO: merge with parse_familiars
function parse_enthroned_familiars()
	local enthroned_familiars = {}
	for name, tbl in pairs(mafia_datafile("cache/files/modifiers.txt", "Enthroned familiars")) do
		local bonuslist = tbl.columns and tbl.columns[3]
		if name and bonuslist then
			enthroned_familiars[name] = parse_mafia_bonuslist(bonuslist, name)
		end
	end
	return enthroned_familiars
end

function verify_enthroned_familiars(data)
	local ok_missing = { "Mad Hatrack", "Money-Making Goblin", "Egg Benedict", "Vampire Bat", "Disembodied Hand", "Fancypants Scarecrow", "Floating Eye", "Snowhitman", "Worm Doctor", "Bank Piggy", "Oyster Bunny", "Doppelshifter", "Comma Chameleon", "Plastic Grocery Bag" }
	for x, _ in pairs(processed_datafiles["familiars"]) do
		if not data[x] then
			local ok = false
			for _, y in ipairs(ok_missing) do
				if x == y then
					ok = true
				end
			end
			if not ok then
				-- TODO: get these fixed in mafia and change to hardwarn
				softwarn("missing enthroned familiar", x)
			end
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

local function sort_and_remove_duplicates(tbl)
	local key_tbl = {}
	for _, x in ipairs(tbl) do
		key_tbl[x] = true
	end
	local output_tbl = {}
	for x, _ in pairs(key_tbl) do
		table.insert(output_tbl, x)
	end
	table.sort(output_tbl)
	return output_tbl
end

function parse_semirares()
	local semirares = {}
	for l in io.lines("cache/files/encounters.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local zone, advtype, title = tbl[1], tbl[2], tbl[3]
		if zone and advtype == "SEMIRARE" and title then
			table.insert(semirares, title)
		end
	end
	return sort_and_remove_duplicates(semirares)
end

function verify_semirares(data)
	local check_semis = { "All The Rave", "It's a Gas Gas Gas", "Bad ASCII Art", "Baa'baa'bu'ran" }
	local missing = {}
	for _, x in ipairs(check_semis) do
		missing[x] = true
	end
	for _, x in ipairs(data) do
		missing[x] = nil
	end
	if not next(missing) then
		return data
	end
	hardwarn("verify_semirares failure:", missing)
end

function parse_mallprices()
	local fobj = io.open("cache/files/mallprices.json")
	local mallprices_datafile = fobj:read("*a")
	fobj:close()
	return fromjson(mallprices_datafile)
end

function verify_mallprices(data)
	if data["Mr. Accessory"]["buy 10"] >= 1000000 and data["Mr. Accessory"]["buy 10"] <= 100000000 and data["Mick's IcyVapoHotness Inhaler"]["buy 10"] >= 200 and data["Mick's IcyVapoHotness Inhaler"]["buy 10"] <= 200000 then
		return data
	end
end

-- TODO: Merge with items datafile, or at least don't have fullness/drunkenness/spleen in both?
function parse_consumables()
	local fobj = io.open("cache/files/consumable-advgain.json")
	local consumables_datafile = fobj:read("*a")
	fobj:close()
	return fromjson(consumables_datafile)
end

function verify_consumables(data)
	if data["Hell ramen"].type == "food" and data["Hell ramen"].size[1] == 6 and data["Hell ramen"].advmin == 22 and data["Hell ramen"].advmax == 28 then
		if data["beastly paste"].type == "spleen" and data["beastly paste"].size[3] == 4 and data["beastly paste"].advmin == 5 and data["beastly paste"].advmax == 10 then
				return data
		end
	end
end

function parse_zones()
	local zones = {}
	for l in io.lines("cache/files/adventures.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local zoneurl, attributes, name = tbl[2], tbl[3], tbl[4]
		if zoneurl and name then
			zones[name] = {
				zoneid = tonumber(zoneurl:match("adventure=([0-9]*)")),
				stat = tonumber(attributes:match("Stat:%s(%w+)")),
				terrain = attributes:match("Env:%s(%w+)"),
			}
		end
	end

	local found_valid = false
	for l in io.lines("cache/files/combats.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local name, combat_percent = tbl[1], tonumber(tbl[2])
		if zones[name] then
			if combat_percent and combat_percent ~= -1 then
--				zones[name].combat_percent = combat_percent -- SKIP: terrible data
			end
			local monsters = {}
			local monster_encounter_list = {}
			for xidx, x in ipairs(tbl) do
				if xidx >= 3 then
					local xprefix, xsuffix = x:match("^(.+): ([0-9oe-]+)$")
					table.insert(monsters, xprefix or x)
					for i = 1, tonumber(xsuffix) or 1 do
						table.insert(monster_encounter_list, xprefix or x)
					end
				end
			end
			table.sort(monsters)
			zones[name].monsters = monsters
			zones[name].monster_encounter_list = monster_encounter_list
			found_valid = true
		elseif found_valid and tbl[1] and tbl[1] ~= "" and not l:match("^#") and tbl[2] ~= "0" then
			hardwarn("unknown adventure zone", tbl[1])
		end
	end
	return zones
end

function verify_zones(data)
	for a, b in pairs(data) do
		for _, x in ipairs(b.monsters or {}) do
			if not processed_datafiles["monsters"][x:lower()] then
				softwarn("zones:unknown monster", x, a)
			end
		end
	end
	local correct_data = {
		["The Spooky Forest"] = { zoneid = 15 },
		["The Dungeons of Doom"] = { zoneid = 39 },
		["McMillicancuddy's Farm"] = { zoneid = 155 },
	}
	return verify_data_fits(correct_data, data)
end

function parse_stores()
	local stores = {}
	local function process(whichshop, itemname)
		if whichshop and itemname then
			stores[whichshop] = stores[whichshop] or {}
			stores[whichshop][itemname] = true
		end
	end
	for l in io.lines("cache/files/npcstores.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local _storename, whichshop, itemname = tbl[1], tbl[2], tbl[3]
		-- Store names are currently inconsistent in the datafiles
		process(whichshop, itemname)
	end
	for l in io.lines("cache/files/coinmasters.txt") do
		l = remove_line_junk(l)
		local tbl = split_tabbed_line(l)
		local storename, itemname = tbl[1], tbl[4]
		-- coinmaster.txt doesn't contain whichshop value and is only barely useful
		if storename == "Everything Under the World" then
			process("edunder_shopshop", itemname)
		end
	end
	return stores
end

function verify_stores(data)
	for a, b in pairs(data) do
		for x, _ in pairs(b) do
			if not processed_datafiles["items"][x] then
				hardwarn("stores:unknown item", x, a)
				b[x] = nil
			end
		end
	end
	local correct_data = {
		["generalstore"] = { ["fortune cookie"] = true, ["Ben-Gal&trade; Balm"] = true },
		["gnoll"] = { ["empty meat tank"] = true },
		["edunder_shopshop"] = { ["mummified beef haunch"] = true },
		["bartender"] = { ["overpriced &quot;imported&quot; beer"] = true },
	}
	return verify_data_fits(correct_data, data)
end

function parse_choice_spoilers()
	local jsonlines = {}
	local found_adv_options = false
	local found_adv_start = false
	for l in io.lines("cache/files/68727.user.js") do
		l = remove_line_junk(l)
		if l:match("var advOptions") and found_adv_start then
			found_adv_options = true
			table.insert(jsonlines, "{")
		elseif l:match("function GetSpoilersForAdvNumber") then
			found_adv_start = true
		elseif found_adv_options then
			if l:match("};") then
				table.insert(jsonlines, "}")
				break
			else
				l_json = l:gsub("\r", ""):gsub("//.*", ""):gsub("([0-9]+)(:%[)", [["%1"%2]]) -- Strip CRs, comments, and quote keys
				l_json = l_json:gsub("\\m", "\\n") -- Correct known typo
				l_json = l_json:gsub("%+$", ",") -- WORKAROUND: Remove code using string concatenation
				table.insert(jsonlines, l_json)
			end
		end
	end
	local rawspoilers = fromjson(table.concat(jsonlines, "\n"))
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

function process(filename, loadf, verifyf)
	local dataok, data = pcall(loadf)
	if dataok then
		local verifyok, verified = pcall(verifyf, data)
		if verifyok and verified then
			local json = tojson(verified)
			local fobj = io.open("cache/data/" .. filename .. ".json", "w")
			fobj:write(json)
			fobj:close()
			processed_datafiles[filename] = verified
		else
			error_count_hard = error_count_hard + 1
			print("WARNING: verifying " .. tostring(filename) .. " data file failed (" .. tostring(verified) .. ").")
		end
	else
		error_count_critical = error_count_critical + 1
		print("ERROR: parsing " .. tostring(filename) .. " data file failed (" .. tostring(data) .. ").")
	end
end

local function add_itemstxt_aliases(tbl)
	local itemids = {}
	for x, y in pairs(tbl) do
		itemids[x] = y.name
	end
	for id, name in pairs(itemids) do
		tbl["["..id.."]"] = tbl[id]
		tbl["["..id.."]"..name] = tbl[id]
	end
end

process("skills", parse_skills, verify_skills)
process("buffs", parse_buffs, verify_buffs)
process("items", parse_items, verify_items)
add_itemstxt_aliases(processed_datafiles["items"] or {})
process("choice-spoilers", parse_choice_spoilers, verify_choice_spoilers)
process("passives", parse_passives, verify_passives)
process("outfits", parse_outfits, verify_outfits)
process("hatrack", parse_hatrack, verify_hatrack)
process("recipes", parse_recipes, verify_recipes)
process("familiars", parse_familiars, verify_familiars)
process("enthroned-familiars", parse_enthroned_familiars, verify_enthroned_familiars) -- TODO: merge with familiars
process("monsters", parse_monsters, verify_monsters)
process("faxbot-monsters", parse_faxbot_monsters, verify_faxbot_monsters)
process("semirares", parse_semirares, verify_semirares)
process("mallprices", parse_mallprices, verify_mallprices)
process("consumables", parse_consumables, verify_consumables)
process("zones", parse_zones, verify_zones)
process("stores", parse_stores, verify_stores)


local prefix = "INFO"
if error_count_critical > 0 then
	prefix = "ERROR"
elseif error_count_hard >= 20 or error_count_soft >= 500 then
	prefix = "WARNING"
end
print(string.format("%s: %d errors, %d warnings, %d notices (expected: 0 errors, fewer then 20 warnings, and fewer than 500 notices)", prefix, error_count_critical, error_count_hard, error_count_soft))
