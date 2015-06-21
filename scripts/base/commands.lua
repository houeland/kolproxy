function use_hottub()
	return async_get_page("/clan_viplounge.php", { action = "hottub" })
end

function meatpaste_items(a, b, qty)
	if not have_item("meat paste") and not moonsign_area("Degrassi Knoll") then
		async_post_page("/craft.php", { pwd = session.pwd, action = "makepaste", qty = qty or 1, ajax = 1, whichitem = get_itemid("meat paste") })
	end
	return async_post_page("/craft.php", { mode = "combine", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = qty or 1, ajax = 1 })
end

function cook_items(a, b, qty)
	return async_post_page("/craft.php", { mode = "cook", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = qty or 1, ajax = 1 })
end

function mix_items(a, b, qty)
	return async_post_page("/craft.php", { mode = "cocktail", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = qty or 1, ajax = 1 })
end

function smith_items(a, b, qty)
	return async_post_page("/craft.php", { mode = "smith", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = qty or 1, ajax = 1 })
end

function craft_item(item)
	print_debug("  crafting", item)
	local recipe = get_recipe(item) or {}
	if (recipe.type == "cook" or recipe.type == "cocktail" or recipe.type == "smith" or recipe.type == "combine") and recipe.ingredients and #recipe.ingredients == 2 then
		if recipe.type == "combine" and not have_item("meat paste") and not moonsign_area("Degrassi Knoll") then
			async_post_page("/craft.php", { pwd = session.pwd, action = "makepaste", qty = qty or 1, ajax = 1, whichitem = get_itemid("meat paste") })
		end
		return async_post_page("/craft.php", { mode = recipe.type, pwd = session.pwd, action = "craft", a = get_itemid(recipe.ingredients[1]), b = get_itemid(recipe.ingredients[2]), qty = 1, ajax = 1 })
	end
	error "Unknown item for craft_item()"
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
	local function dump_debug()
		local slots = {}
		for x, _ in pairs(eq) do
			slots[x] = true
		end
		for x, _ in pairs(tbl) do
			slots[x] = true
		end
		for slot, _ in pairs(slots) do
			print(slot, getnamedesc(eq[slot]), getnamedesc(tbl[slot]))
		end
	end
	for a, b in pairs(eq) do
		if not tbl[a] or b ~= get_itemid(tbl[a]) then
			dump_debug()
			error("Wearing " .. tostring(a) .. ":" .. tostring(b) .. " after trying to wear " .. getnamedesc(tbl[a]))
		end
	end
	for a, b in pairs(tbl) do
		if eq[a] ~= get_itemid(b) then
			dump_debug()
			error("Wearing " .. tostring(a) .. ":" .. tostring(eq[a]) .. " after trying to wear " .. getnamedesc(b))
		end
	end
end

function use_item(name, amount, noajax)
	print_debug("  using", name, amount or "")
	local ajax = (not noajax) and 1 or nil
	local idata = maybe_get_itemdata(name)
	local is_spleen = idata and (tonumber(idata.spleen) or 0) > 0
	if is_spleen then
		return use_spleen_item(name, amount, noajax)
	elseif amount then
		return async_get_page("/multiuse.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax, quantity = amount, action = "useitem" })
	else
		return async_get_page("/inv_use.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax })
	end
end

function use_spleen_item(name, amount, noajax)
	local ajax = (not noajax) and 1 or nil
	return async_get_page("/inv_spleen.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax, quantity = amount or 1 })
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

function pull_storage_item(name, qty)
	return async_post_page("/storage.php", { pwd = session.pwd, action = "pull", ajax = 1, howmany1 = qty or 1, whichitem1 = get_itemid(name) })
end
freepull_item = pull_storage_item

function closet_item(name, qty)
	return async_get_page("/inventory.php", { action = "closetpush", pwd = session.pwd, qty = qty or 1, whichitem = get_itemid(name), ajax = 1 })
end

function uncloset_item(name, qty)
	return async_get_page("/inventory.php", { action = "closetpull", pwd = session.pwd, qty = qty or 1, whichitem = get_itemid(name), ajax = 1 })
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
	print_debug("  casting", skill)
	return async_get_page("/runskillz.php", tbl)
end
cast_skillid = cast_skill

function switch_familiar(which)
	if which == 0 then
		return async_get_page("/familiar.php", { action = "putback", ajax = 1 })
	else
		return async_get_page("/familiar.php", { action = "newfam", ajax = 1, newfam = get_familiarid(which) })
	end
end
switch_familiarid = switch_familiar
