function use_hottub()
	return async_get_page("/clan_viplounge.php", { action = "hottub" })
end

function meatpaste_items(a, b)
	-- TODO: can this be done without requiring up-to-date status?
	if moonsign_area("Degrassi Knoll") and not ascensionpath("Zombie Slayer") then
		return async_post_page("/knoll.php", { action = "combine", pwd = session.pwd, item1 = get_itemid(a), item2 = get_itemid(b), quantity = 1, ajax = 1 })
	else
		if not have_item("meat paste") then
			async_post_page("/craft.php", { pwd = session.pwd, action = "makepaste", qty = 1, ajax = 1, whichitem = get_itemid("meat paste") })
		end
		return async_post_page("/craft.php", { mode = "combine", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
	end
end

function cook_items(a, b)
	return async_post_page("/craft.php", { mode = "cook", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
end

function mix_items(a, b)
	return async_post_page("/craft.php", { mode = "cocktail", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
end

function smith_items(a, b)
	return async_post_page("/knoll.php", { action = "smith", pwd = session.pwd, item1 = get_itemid(a), item2 = get_itemid(b), quantity = 1, ajax = 1 })
end

function buy_item(name, whichstore, amount)
	print_debug("  buying", name, amount or "")
	return async_get_page("/store.php", { phash = session.pwd, buying = 1, whichitem = get_itemid(name), howmany = amount or 1, whichstore = whichstore, ajax = 1, action = "buyitem" })
end

function equip_item(name, slot)
	local itemid = get_itemid(name)
	print_debug("  equipping", slot, maybe_get_itemname(itemid) or itemid)
	local tbl = { pwd = session.pwd, action = "equip", whichitem = itemid, ajax = 1 }
	if slot == "dualwield" then
		tbl.action = "dualwield"
	elseif slot == "offhand" then
		tbl.action = "dualwield"
		local f, furl = get_page("/inv_equip.php", tbl)
		if equipment().offhand ~= itemid then
			tbl.action = "equip"
			tbl.slot = tostring(slot)
			return async_get_page("/inv_equip.php", tbl)
		else
			return f, furl
		end
	elseif slot == "acc1" then
		tbl.slot = "1"
	elseif slot == "acc2" then
		tbl.slot = "2"
	elseif slot == "acc3" then
		tbl.slot = "3"
	elseif slot == "familiarequip" then
		tbl.action = "hatrack"
		local f, furl = get_page("/inv_equip.php", tbl)
		if equipment().familiarequip ~= itemid then
			tbl.action = "equip"
			tbl.slot = tostring(slot)
			return async_get_page("/inv_equip.php", tbl)
		else
			return f, furl
		end
	elseif slot then
		tbl.slot = tostring(slot)
	end
	return async_get_page("/inv_equip.php", tbl)
end

function unequip_slot(name)
	print_debug("  unequipping", name)
	return async_get_page("/inv_equip.php", { pwd = session.pwd, action = "unequip", type = name, ajax = "1" })
end

function set_mcd(amount)
	if have_item("detuned radio") then
		return async_get_page("/inv_use.php", { pwd = session.pwd, whichitem = get_itemid("detuned radio"), ajax = 1, tuneradio = amount })
	elseif moonsign_area("Little Canadia") then
		return async_get_page("/canadia.php", { pwd = session.pwd, action = "changedial", whichlevel = amount })
	elseif moonsign_area("Gnomish Gnomad Camp") then
		return async_get_page("/gnomes.php", { pwd = session.pwd, action = "changedial", whichlevel = amount })
	end
end

function set_equipment(tbl)
--	print("setting equipment to", tbl)
	local eq = equipment()
	for a, b in pairs(eq) do
--		print("checking", b, "vs[", a, "]", tbl[a])
		if b ~= tbl[a] then
			unequip_slot(a)
--			print("unequipping slot", a)
		end
	end
	local eq = equipment()
	if eq.weapon ~= tbl.weapon then
		equip_item(tbl.weapon, "weapon")
		eq = equipment()
	end
	for a, b in pairs(tbl) do
		if eq[a] ~= b then
--			print("equipping", b, a)
			equip_item(b, a)
		end
	end
	local eq = equipment()
	local function getnamedesc(id)
		if tonumber(id) then
			local n = maybe_get_itemname(id)
			if n then
				return (n .. " (itemid:" .. tonumber(id) .. ")")
			else
				return ("itemid:" .. tonumber(id))
			end
		elseif id then
			return id
		else
			return "nil"
		end
	end
	for a, b in pairs(eq) do
		if b ~= tbl[a] then
			error("Wearing " .. tostring(a) .. ":" .. tostring(b) .. " after trying to wear " .. getnamedesc(tbl[a]))
		end
	end
	for a, b in pairs(tbl) do
		if eq[a] ~= b then
			error("Wearing " .. tostring(a) .. ":" .. tostring(eq[a]) .. " after trying to wear " .. getnamedesc(b))
		end
	end
end

function use_item(name, amount, noajax)
	print_debug("  using", name, amount or "")
	local ajax = (not noajax) and 1 or nil
	if amount then
		return async_get_page("/multiuse.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax, quantity = amount, action = "useitem" })
	else
		return async_get_page("/inv_use.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax })
	end
end

function use_item_noajax(name, amount)
	return use_item(name, amount, true)
end

function eat_item(name)
	print_debug("  eating", name)
	return async_get_page("/inv_eat.php", { pwd = session.pwd, which = 1, whichitem = get_itemid(name), ajax = 1 })
end

function drink_item(name)
	print_debug("  drinking", name)
	return async_get_page("/inv_booze.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = 1 })
end

function pull_storage_items(xs)
	local pf
	for _, name in ipairs(xs) do
		pf = async_post_page("/storage.php", { pwd = session.pwd, action = "pull", ajax = 1, howmany1 = 1, whichitem1 = get_itemid(name) })
	end
	return pf
end

function freepull_item(name)
	return async_post_page("/storage.php", { action = "pull", pwd = session.pwd, howmany1 = 1, whichitem1 = get_itemid(name) })
end

function closet_item(name)
	return async_get_page("/inventory.php", { action = "closetpush", pwd = session.pwd, qty = 1, whichitem = get_itemid(name), ajax = 1 })
end

function uncloset_item(name)
	return async_get_page("/inventory.php", { action = "closetpull", pwd = session.pwd, qty = 1, whichitem = get_itemid(name), ajax = 1 })
end
		
function autosell_item(name, amount)
	print_debug("  selling", name)
	return async_get_page("/sellstuff.php", { action = "sell", ajax = 1, type = "quant", ["whichitem[]"] = get_itemid(name), howmany = amount or 1, pwd = session.pwd })
end
sell_item = autosell_item

function add_store_item(name, amount, price, limit)
	return async_get_page("/managestore.php", { action = "additem", ajax = 1, item1 = get_itemid(name), limit1 = limit, price1 = price, qty1 = amount or 1, pwd = session.pwd }) 
end
stock_item = add_store_item

function cast_skill(skill, quantity, targetid)
	local skillid = get_skillid(skill)
	targetid = targetid or playerid()
	assert(targetid and targetid ~= "")
	local tbl = { whichskill = skillid, ajax = 1, action = "Skillz", pwd = session.pwd, targetplayer = targetid, quantity = quantity }
	return async_get_page("/skills.php", tbl)
end
cast_skillid = cast_skill

function switch_familiarid(id)
	if (id == 0) then
		return async_get_page("/familiar.php", { action = "putback", ajax = 1 })
	else
		return async_get_page("/familiar.php", { action = "newfam", ajax = 1, newfam = id })
	end
end

function handle_adventure_result(pt, url, zoneid, macro, noncombatchoices, specialnoncombatfunction)
	if url:contains("/fight.php") then
		local advagain = nil
		if pt:contains([[>You win the fight!<!--WINWINWIN--><]]) then
			advagain = true
		elseif pt:contains([[state['fightover'] = true;]]) or true then -- HACK: doesn't get set with combat bar disabled
			if pt:contains("You lose.") then
				advagain = false
			elseif zoneid and pt:contains([[<a href="adventure.php?snarfblat=]]..zoneid..[[">Adventure Again]]) then
				advagain = true
			end
		end
		if advagain == nil then
			if macro then
				local macrotext = macro
				if type(macrotext) ~= "string" then
					macrotext = macro()
				end
				local pt, url = post_page("/fight.php", { action = "macro", macrotext = macrotext })
-- 				print("recurse with macro")
				return handle_adventure_result(pt, url, zoneid, nil, noncombatchoices, specialnoncombatfunction)
			else
				print("fight.php unhandled url", url)
			end
		end
-- 		print("return1 p u a", pt:len(), url, advagain)
		return pt, url, advagain
	elseif url:contains("/choice.php") then
		local advagain = nil
		local adventure_title
		local found_results = false
		for x in pt:gmatch([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>([^<]*)</b></td></tr>]]) do
			if x == "Results:" then
				found_results = true
			else
				adventure_title = x
			end
		end
		adventure_title = (adventure_title or ""):gsub(" %(#[0-9]*%)$", "")
		if found_results and zoneid and pt:contains([[<a href="adventure.php?snarfblat=]]..zoneid..[[">Adventure Again]]) then
			advagain = true
			return pt, url, advagain
		end
		local choice_adventure_number = tonumber(pt:match([[<input type=hidden name=whichchoice value=([0-9]+)>]]))
--~ 		print("choice", adventure_title, choice_adventure_number)
		local pickchoice = nil
		local optname = nil
		if specialnoncombatfunction then
			optname, pickchoice = specialnoncombatfunction(adventure_title, choice_adventure_number, pt)
		else
			optname = noncombatchoices[adventure_title]
		end
		if optname and not pickchoice then
			for nr, title in pt:gmatch([[<input type=hidden name=option value=([0-9])><input class=button type=submit value="([^>]+)">]]) do
--~ 				print("opt", nr, title)
				if title == optname then
					pickchoice = tonumber(nr)
				end
			end
		end
		if optname and not pickchoice then
			print("ERROR: option " .. tostring(optname) .. " not found for " .. tostring(adventure_title) .. ".")
		end
		if pickchoice then
			local pt, url = post_page("/choice.php", { pwd = session.pwd, whichchoice = choice_adventure_number, option = pickchoice })
-- 			print("choice ->", url)
			return handle_adventure_result(pt, url, zoneid, macro, noncombatchoices, specialnoncombatfunction)
		else
			print("choice", adventure_title, choice_adventure_number)
			for nr, title in pt:gmatch([[<input type=hidden name=option value=([0-9])><input class=button type=submit value="([^>]+)">]]) do
				print("opt", nr, title)
			end
-- 			print("return3 p u a", pt:len(), url, advagain)
			return pt, url, false
		end
	else
		local advagain = false
		if zoneid and pt:contains([[<a href="adventure.php?snarfblat=]]..zoneid..[[">Adventure Again]]) then
			advagain = true
-- 		else
-- 			print("non-fight non-choice unhandled url", url)
		end
-- 		print("return4 p u a", pt:len(), url, advagain)
		return pt, url, advagain
	end
end
