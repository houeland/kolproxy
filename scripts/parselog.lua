loadfile("scripts/base/base-lua-functions.lua")()
loadfile("scripts/base/kolproxy-core-functions.lua")()

local xmeta = { __index = function(t, k)
	if k == "time" or k == "requestedurl" or k == "retrievedurl" or k == "pagetext" then
		t[k] = get_line_text(t.idx, k)
	elseif k == "statusbefore" or k == "inventorybefore" then
		local v = json_to_table(get_line_text(t.idx, "statusbefore"))
		t.statusbefore = v.status
		t.inventorybefore = v.inventory
	elseif k == "statusafter" or k == "inventoryafter" then
		local v = json_to_table(get_line_text(t.idx, "statusafter"))
		t.statusafter = v.status
		t.inventoryafter = v.inventory
	elseif k == "onthetrail" then
		t[k] = t.statusbefore.effects["91635be2834f8a07c8ff9e3b47d2e43a"] ~= nil
	elseif k == "allparams" then
		t[k] = get_line_allparams(t.idx)
	elseif k == "__warprogress" then
		local rettbl = {}
		local v = get_line_text(t.idx, "statebefore")
		for sset in v:gmatch("(%b())") do
			for val in sset:sub(2, -2):gmatch("(%b())") do
				if val:match("battlefield.kills") then
					table.insert(rettbl, val)
				end
			end
		end
		t[k] = table.concat(rettbl, " #+# ")
	end
	return rawget(t, k)
end }

local tbl = {}

for _, idx in ipairs(get_log_lines()) do
	table.insert(tbl, idx)
end

print("log pageloads:", #tbl)

local function desc_item(id)
	return maybe_get_itemname(id) or ("{???_item_" .. id .. "_???}")
end

local function parse_page(x, xtbl)
	local pt = x.pagetext
	local pagetitle
	local backuppagetitle
	local backuptypetitle
	for z in pt:gmatch([[<tr><td style="color: white;" align=center bgcolor=blue><b>([^<]+)</b></td></tr>]]) do
		if z ~= "Results:" and z ~= "Adventure Results:" and z ~= "Adventure Again:" then
			pagetitle = z
			break
		end
		if not backuppagetitle then
			backuppagetitle = z
		end
	end
	local monstername = pt:match([[>You're fighting <span id='monname'>([^<]*)</span><]])
	local advrestitle = pt:match([[<td style="color: white;" align=center bgcolor=blue><b>[a-zA-Z]* Results:</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center><b>([^<]*)</b>]])
	local title = monstername or advrestitle or pagetitle

	for _, u in ipairs { "/inv_eat.php", "/inv_booze.php", "/inv_use.php", "/multiuse.php" } do
		-- TODO: support non-ajax pageloads that result in inventory.php
		if x.retrievedurl:contains(u) then
			local whichitem = tonumber(x.allparams.whichitem)
			if whichitem then
				xtbl.item = { description = desc_item(whichitem), quantity = x.allparams.quantity }
			end
		end
	end

	if x.retrievedurl:contains("/storage.php") then
		local pulls = {}
		for itemname, amount in pt:gmatch([[<b>([^<]-) %(([0-9]+)%)</b> moved from storage to inventory.<br />]]) do
			table.insert(pulls, { itemname = itemname, amount = tonumber(amount) })
		end
		xtbl.pulls = pulls
		backuptypetitle = "(Storage)"
	end

	if x.retrievedurl:contains("/craft.php") then
		-- craft.target = 50
		local whichitem = tonumber(x.allparams.target)
		if whichitem then
			xtbl.item = { description = desc_item(whichitem), quantity = x.allparams.qty }
		end

		-- craft.a = 476 + craft.b = 346
		local whicha = tonumber(x.allparams.a)
		local whichb = tonumber(x.allparams.b)
		if whicha and whichb then
			xtbl.item_a = { description = desc_item(whicha) }
			xtbl.item_b = { description = desc_item(whichb) }
		end
		backuptypetitle = "(Crafting)"
	end

	if title then
		xtbl.title = title
	elseif x.pagetext:contains([[top.mainpane.document.location = "fight.php]]) then
		xtbl.title = "(fight redirect)"
		xtbl.page_redirect = "/fight.php"
	elseif x.pagetext:contains([[top.mainpane.document.location = "choice.php]]) then
		xtbl.title = "(choice redirect)"
		xtbl.page_redirect = "/choice.php"
	elseif backuppagetitle then
		xtbl.title = backuppagetitle
	elseif backuptypetitle then
		xtbl.title = backuptypetitle
	else
		print("")
		print("")
		print("strange page!", x.idx, x.retrievedurl, pagetitle)
		print("")
		print("")
		xtbl.title = "???"
	end
end

local function is_interesting(x, laststatus)
	if laststatus.turnsthisrun ~= x.statusafter.turnsthisrun then
		return "+turncount"
	elseif x.retrievedurl:contains("/fight.php") or x.retrievedurl:contains("/choice.php") or x.retrievedurl:contains("/adventure.php") then
		return "funretrurl"
	elseif x.retrievedurl:contains("/storage.php") then
		return "is-storage"
	elseif laststatus.adventures ~= x.statusafter.adventures or laststatus.rawmuscle ~= x.statusafter.rawmuscle or laststatus.rawmysticality ~= x.statusafter.rawmysticality or laststatus.rawmoxie ~= x.statusafter.rawmoxie then
		return "statchange"
	elseif laststatus.locked ~= x.statusafter.locked then
		return "lockchange"
	elseif laststatus.freedralph ~= x.statusafter.freedralph then
		return "freedralph"
	elseif x.retrievedurl:contains("/inv_use.php") or x.retrievedurl:contains("/multiuse.php") then
		if x.pagetext:contains([[top.mainpane.document.location = "]]) then
			return "item-usage"
		end
	end
	return false
end

local laststatus = nil
local laststatestatus = {}

local ret_log_tbl = {}

local set_key = false

for _, xidx in ipairs(tbl) do
	local x = { idx = xidx }
	setmetatable(x, xmeta)

	local xtbl = {}

--	xtbl.debug_line = x.idx .. ": " .. x.__warprogress -- DEBUG

	for _, n in pairs{ "name", "class", "path", "sign", "hardcore", "casual", "freedralph" } do
		if laststatestatus[n] ~= x.statusafter[n] then
			xtbl.new_runstate = {
				name = x.statusafter.name,
				classid = tonumber(x.statusafter.class),
				pathname = x.statusafter.pathname,
				sign = x.statusafter.sign,
				hardcore = tonumber(x.statusafter.hardcore),
				casual = tonumber(x.statusafter.casual),
				freedralph = tonumber(x.statusafter.freedralph),
			}
			break
		end
	end

	if (not laststatus) or (laststatus.daysthisrun ~= x.statusafter.daysthisrun) or (laststatus.turnsthisrun < x.statusbefore.turnsthisrun) then
		laststatus = x.statusbefore
	end
	if tonumber(x.statusbefore.freedralph) == 1 then
-- 		print("=== === === DONE === === ===")
		break
	end
	if not set_key and x.statusbefore.eleronkey then
		set_log_info(tonumber(x.statusbefore.playerid), x.statusbefore.name, x.statusbefore.ascensions + 1, "kolproxylogparse:" .. x.statusbefore.eleronkey .. ":kolproxylogparse")
		set_key = true
	end

	if is_interesting(x, laststatus) then
		do
			local gained_effects = {}
			for effid, effname in pairs(x.statusafter.effects) do
				if not laststatus.effects[effid] then
					table.insert(gained_effects, effname[1])
				end
			end
			table.sort(gained_effects)
			if next(gained_effects) then
				xtbl.gained_effects = gained_effects
			end
		end

		do
			local lost_effects = {}
			for effid, effname in pairs(laststatus.effects) do
				if not x.statusafter.effects[effid] then
					table.insert(lost_effects, effname[1])
				end
			end
			table.sort(lost_effects)
			if next(lost_effects) then
				xtbl.lost_effects = lost_effects
			end
		end

		do
			local gained_intrinsics = {}
			for effid, effname in pairs(x.statusafter.intrinsics) do
				if not laststatus.intrinsics[effid] then
					table.insert(gained_intrinsics, effname[1])
				end
			end
			table.sort(gained_intrinsics)
			if next(gained_intrinsics) then
				xtbl.gained_intrinsics = gained_intrinsics
			end
		end

		do
			local lost_intrinsics = {}
			for effid, effname in pairs(laststatus.intrinsics) do
				if not x.statusafter.intrinsics[effid] then
					table.insert(lost_intrinsics, effname[1])
				end
			end
			table.sort(lost_intrinsics)
			if next(lost_intrinsics) then
				xtbl.lost_intrinsics = lost_intrinsics
			end
		end

		xtbl.statusbefore = {
			turnsthisrun = tonumber(laststatus.turnsthisrun),
			rawmuscle = tonumber(laststatus.rawmuscle),
			rawmysticality = tonumber(laststatus.rawmysticality),
			rawmoxie = tonumber(laststatus.rawmoxie),
			adventures = tonumber(laststatus.adventures),
			locked = laststatus.locked,
			hp = tonumber(laststatus.hp),
			maxhp = tonumber(laststatus.maxhp),
			mp = tonumber(laststatus.mp),
			maxmp = tonumber(laststatus.maxmp),
			familiar = { id = tonumber(laststatus.familiar), pic = laststatus.familiarpic, famlevel = tonumber(laststatus.famlevel) },
			meat = tonumber(laststatus.meat),
		}

		xtbl.statusafter = {
			turnsthisrun = tonumber(x.statusafter.turnsthisrun),
			rawmuscle = tonumber(x.statusafter.rawmuscle),
			rawmysticality = tonumber(x.statusafter.rawmysticality),
			rawmoxie = tonumber(x.statusafter.rawmoxie),
			adventures = tonumber(x.statusafter.adventures),
			locked = x.statusafter.locked,
			hp = tonumber(x.statusafter.hp),
			maxhp = tonumber(x.statusafter.maxhp),
			mp = tonumber(x.statusafter.mp),
			maxmp = tonumber(x.statusafter.maxmp),
			familiar = { id = tonumber(x.statusafter.familiar), pic = x.statusafter.familiarpic, famlevel = tonumber(x.statusafter.famlevel) },
			meat = tonumber(x.statusafter.meat),
		}
--		xtbl.idx = tonumber(x.idx) -- DEBUG
		xtbl.daysthisrun = tonumber(x.statusafter.daysthisrun)
		xtbl.mcd = tonumber(x.statusafter.mcd)
		xtbl.zonename = x.statusafter.lastadv.name
		parse_page(x, xtbl)
		xtbl.fromurlpath = get_url_path(x.requestedurl)
		xtbl.urlpath = get_url_path(x.retrievedurl)
		if x.retrievedurl:contains("fight.php") and x.allparams.ireallymeanit then
			xtbl.new_fight = true
		end
		if x.retrievedurl:contains("fight.php") then
			if x.pagetext:contains("fires a badly romantic arrow") then
				xtbl.fired_romantic_arrow = true
			end
			if x.pagetext:contains("shot with a love arrow earlier") then
				xtbl.encounter_source = "Obtuse Angel"
			end
		end
		if xtbl.title or xtbl.pulls or xtbl.gained_effects or xtbl.lost_effects or xtbl.gained_effects or xtbl.lost_effects or xtbl.new_runstate then
			if xtbl.title then
				print(xtbl.statusafter.turnsthisrun, xtbl.title, xtbl.zonename, x.idx)
			end
			table.insert(ret_log_tbl, xtbl)
		end
-- 		print(table_to_json(xtbl))
-- 		if not parse_page_title(x) then
-- 			print(x.requestedurl, x.retrievedurl)
-- 			print(x.pagetext)
-- 		end
		laststatestatus = x.statusafter
	end

-- 	print(x.idx, tonumber(laststatus.turnsthisrun), tonumber(x.statusbefore.turnsthisrun), tonumber(x.statusafter.turnsthisrun), x.statusafter.lastadv.name, x.requestedurl, x.retrievedurl)
	laststatus = x.statusafter
end

tbl = nil

return ret_log_tbl
