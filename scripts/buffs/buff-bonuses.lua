function parse_buff_bonuses(buffname)
	if not kolproxycore_async_submit_page then return end
	local descid = nil
	for a, b in pairs(status().effects) do
		if b[1] == buffname then
			descid = a
		end
	end
	descid = descid or (datafile("buffs")[buffname] or {}).descid
	local pt = get_page("/desc_effect.php", { whicheffect = descid })
	local bonuses = parse_modifier_bonuses_page(pt)
	return bonuses
end

add_automator("all pages", function()
	for buffname, _ in pairs(buffslist()) do
		if not datafile("buffs")[buffname] and not get_cached_modifier_bonuses("buff", buffname) then
			ensure_cached_modifier_bonuses("buff", buffname, parse_buff_bonuses)
		end
	end
end)

local function get_cached_buff(buffname)
	ensure_cached_modifier_bonuses("buff", buffname, parse_buff_bonuses)
	return get_cached_modifier_bonuses("buff", buffname)
end

function estimate_buff_bonuses(buffname)
	local buffarray = {
		["Sole Soul"] = { ["Item Drops from Monsters"] = math.min(buffturns("Sole Soul"), 300) },
		["The HeyDezebound Heart"] = { ["Item Drops from Monsters"] = math.min(buffturns("The HeyDezebound Heart"), 300) },
		["Bubble Vision"] = { ["Item Drops from Monsters"] = math.max(101 - buffturns("Bubble Vision"), 0) },
		["Polka Face"] = { ["Item Drops from Monsters"] = math.min(55, 5 * level()), ["Meat from Monsters"] = math.min(55, 5 * level()) },
		["Withered Heart"] = { ["Item Drops from Monsters"] = math.min(buffturns("Withered Heart"), 20) },
		["Fortunate Resolve"] = { ["Item Drops from Monsters"] = 5, ["Meat from Monsters"] = 5, ["Combat Initiative"] = 5 },
		-- ["Limber as Mortimer"] = ...,
		["Voracious Gorging"] = { ["Item Drops from Monsters"] = math.min(40, math.ceil(fullness() / 5) * 10) },
		["Cunctatitis"] = { ["Combat Initiative"] = -1000 },
		["Buy!  Sell!  Buy!  Sell!"] = { ["Meat from Monsters"] = math.max(202 - 2 * buffturns("Buy!  Sell!  Buy!  Sell!"), 0) },
		["Sweet Heart"] = { ["Meat from Monsters"] = math.min(2 * buffturns("Sweet Heart"), 40) },
		["Ur-Kel's Aria of Annoyance"] = { ["Monster Level"] = math.min(2 * level(), 60) },
		["A Little Bit Evil"] = { ["Monster Level"] = 2 },
		["Amorous Avarice"] = { ["Meat from Monsters"] = 25 * math.min(math.floor(drunkenness() / 5), 4) },
		["Whitesloshed"] = { ["Item Drops from Monsters (Dreadsylvania only)"] = 500 },
		["You've Got a Stew Going!"] = { ["Item Drops from Monsters (Dreadsylvania only)"] = 500 },

		["Mysteriously Handsome"] = "cached",
		["Experimental Effect G-9"] = "cached",
	}

	local unknown_table = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?", ["Monster Level"] = "?", ["Monsters will be more attracted to you"] = "?" }
	if buffarray[buffname] == "cached" then
		return make_bonuses_table(get_cached_buff(buffname) or unknown_table)
	elseif buffarray[buffname] then
		return make_bonuses_table(buffarray[buffname])
	elseif datafile("buffs")[buffname] then
		return make_bonuses_table(datafile("buffs")[buffname].bonuses or {})
	else
		-- unknown
		return make_bonuses_table(unknown_table) + make_bonuses_table(get_cached_buff(buffname) or {})
	end
end

function estimate_current_buff_bonuses()
	local bonuses = {}
	for buff, _ in pairs(buffslist()) do
		add_modifier_bonuses(bonuses, estimate_buff_bonuses(buff))
	end
	return bonuses
end
