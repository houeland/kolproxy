register_setting {
	name = "show spleen counter",
	description = "Show spleen counter",
	group = "charpane",
	default_level = "limited",
	update_charpane = true,
}

-- TODO: handle ode/milk checks in a better and more generic way. use add_warning {}

add_printer("/charpane.php", function()
	if setting_enabled("use custom kolproxy charpane") then return end
	if not setting_enabled("show spleen counter") then return end

	if tonumber(api_flag_config().compactchar) == 1 then
		text = text:gsub([[(<hr width=50%%>.-)(</table><hr width=50%%><table align=center cellpadding=1 cellspacing=1>)]], function(a, b)
			local spleentext = ""
			if spleen() > 0 then
				spleentext = [[<tr><td align=right>Spleen:</td><td align=left><b>]] .. spleen() .. [[</b></td></tr>]]
			end
			if a:match(">Drunk:<") then
				return a:gsub([[(.-)(<tr><td align=right>Drunk:</td><td align=left><b>[0-9,]-</b></td></tr>)]], function(x, y)
					return x .. y .. spleentext
				end) .. b
			else
				return a .. spleentext .. b
			end
		end)
	else
		local function addit(a, b)
			local spleentext = ""
			if spleen() > 0 then
				local spleen_description = random_choice { "Spleen", "Melancholy", "Moroseness" }
				spleentext = [[<tr><td align=right>]] .. spleen_description .. [[:</td><td><b>]] .. spleen() .. [[</b></td></tr>]]
			end
			if a:match("<tr><td align=right>[^<]-</td><td><b>[0-9,]-</b></td></tr>") then
				return a:gsub([[(.-)(<tr><td align=right>[^<]-</td><td><b>[0-9,]-</b></td></tr>)]], function(x, y)
					return x .. y .. spleentext
				end) .. b
			else
				return a:gsub("</table>$", function() return spleentext .. "</table>" .. b end)
			end
			return a .. b
		end
		text = text:gsub([[^(.-)(<table cellpadding=3 align=center>)]], addit)
		text = text:gsub([[^(.-)(<table><tr><td><img src=http://images.kingdomofloathing.com/itemimages/slimhp.gif)]], addit)
	end
end)

local cached_potency = {}
function retrieve_item_potency(item)
	if not item then
		print("WARNING: called retrieve_item_potency(" .. tostring(item) .. ")")
		return
	end

	local d = maybe_get_itemdata(item)
	local dn = maybe_get_itemname(item)
	if d and d.drunkenness and dn and dn:contains("dusty bottle of") then
		return d.drunkenness
	else
		local itemid = get_itemid(item)
		if not cached_potency[itemid] then
			local descid = item_api_data(itemid).descid
			local pt = get_page("/desc_item.php", { whichitem = descid })
			cached_potency[itemid] = tonumber(pt:match([[>Potency: <b>([0-9]*)</b><]]))
		end
		return cached_potency[itemid]
	end
end

function retrieve_speakeasy_potency(drinkid)
	if not cached_potency["speakeasy:" .. tostring(drinkid)] then
		local speakeasy_pt = get_page("/clan_viplounge.php", { action = "speakeasy" })
		local drink_descids = {}
		for x in speakeasy_pt:gmatch("<tr.-</tr>") do
			local drinkid = tonumber(x:match([[input type="hidden" name="drink" value="([0-9]+)"]]))
			local descid = tonumber(x:match([[descitem%(([0-9]+)%)]]))
			if drinkid and descid then
				drink_descids[drinkid] = descid
			end
		end
		--print("DEBUG: drink_descids", tostring(drink_descids))
		if drink_descids[drinkid] then
			local pt = get_page("/desc_item.php", { whichitem = drink_descids[drinkid] })
			cached_potency["speakeasy:" .. drinkid] = tonumber(pt:match([[>Potency: <b>([0-9]*)</b><]]))
		end
	end
	return cached_potency["speakeasy:" .. tostring(drinkid)]
end

function drink_booze_warning(potency_f, quantity)
	local potency = nil
	if ascensionstatus("Aftercore") or have_skill("The Ode to Booze") then
		if not have_buff("Ode to Booze") then
			return "You do not have Ode to Booze active.", "drinking without ode"
		end
		potency = potency or potency_f()
		if not potency then
			return "You might not have enough turns of Ode to Booze active (unspecified potency).", "drinking unspecified potency without enough turns of ode to booze"
		end
		local need_turns = quantity * potency
		if buffturns("Ode to Booze") < need_turns then
			return "You do not have enough turns of Ode to Booze active (need " .. need_turns .. " turns).", "drinking without enough turns of ode to booze"
		end
	end

	potency = potency or potency_f()
	if potency and drunkenness() + potency * quantity <= estimate_max_safe_drunkenness() then
	elseif drunkenness() >= estimate_max_safe_drunkenness() then
	else
		return "You have not drunk to full liver before nightcapping.", "not drunk before nightcapping"
	end
end

function drink_booze_extra_warning(potency_f, quantity)
	local potency = potency_f()
	if not potency then
		return "This booze could make you fallen-down drunk (unspecified potency).", "overdrinking unspecified potency"
	elseif drunkenness() + potency * quantity <= estimate_max_safe_drunkenness() then
	elseif drunkenness() > estimate_max_safe_drunkenness() then
	else
		return "This booze will make you fallen-down drunk.", "overdrinking", "OK, I'm done for today, disable the warning and do it."
	end
end

add_always_warning("/inv_booze.php", function()
	for _, x in ipairs { "steel margarita", "shot of flower schnapps", "used beer", "slap and slap again", "beery blood" } do
		if tonumber(params.whichitem) == get_itemid(x) then
			return
		end
	end
	return drink_booze_warning(function() return retrieve_item_potency(tonumber(params.whichitem)) end, tonumber(params.quantity) or 1)
end)

add_extra_always_warning("/inv_booze.php", function()
	if tonumber(params.whichitem) == get_itemid("steel margarita") then
		return
	end
	return drink_booze_extra_warning(function() return retrieve_item_potency(tonumber(params.whichitem)) end, tonumber(params.quantity) or 1)
end)

add_always_warning("/cafe.php", function()
	if params.action ~= "CONSUME!" or tonumber(params.cafeid) ~= 2 then return end
	-- Micromicrobrewery
	if tonumber(params.whichitem) == -1 or tonumber(params.whichitem) == -2 then
		return "Are you sure? You might want to drink Infinitesimal IPA at the very least, and preferably something much better.", "drinking bad microbrewery booze"
	elseif tonumber(params.whichitem) == -3 then
		return "Are you sure? Preferably you'd drink something much better.", "drinking bad microbrewery booze"
	end
end)

add_always_warning("/cafe.php", function()
	if params.action ~= "CONSUME!" or tonumber(params.cafeid) ~= 2 then return end
	-- Micromicrobrewery
	local potency = nil
	if tonumber(params.whichitem) == -1 or tonumber(params.whichitem) == -2 or tonumber(params.whichitem) == -3 then
		potency = 3
	end
	return drink_booze_warning(function() return potency end, tonumber(params.quantity) or 1)
end)

add_extra_always_warning("/cafe.php", function()
	if params.action ~= "CONSUME!" or tonumber(params.cafeid) ~= 2 then return end
	-- Micromicrobrewery
	local potency = nil
	if tonumber(params.whichitem) == -1 or tonumber(params.whichitem) == -2 or tonumber(params.whichitem) == -3 then
		potency = 3
	end
	return drink_booze_extra_warning(function() return potency end, tonumber(params.quantity) or 1)
end)

add_always_warning("/clan_viplounge.php", function()
	if params.preaction ~= "speakeasydrink" then return end
	return drink_booze_warning(function() return retrieve_speakeasy_potency(tonumber(params.drink)) end, 1)
end)

add_extra_always_warning("/clan_viplounge.php", function()
	if params.preaction ~= "speakeasydrink" then return end
	return drink_booze_extra_warning(function() return retrieve_speakeasy_potency(tonumber(params.drink)) end, 1)
end)

local function check_eating_warning(itemid, quantity, whicheffect)
	for _, x in ipairs { "steel lasagna", "flower petal pie", "nailswurst", "fettucini &eacute;pines Inconnu", "gunpowder burrito" } do
		if tonumber(params.whichitem) == get_itemid(x) then
			return
		end
	end
	whicheffect = whicheffect or "Got Milk"
	if not have_buff(whicheffect) then
		return "You do not have " .. whicheffect .. " active.", "eating without " .. whicheffect
	end
	local item = maybe_get_itemdata(tonumber(params.whichitem))
	if not item or not item.fullness then
		return "This food is unknown and could potentially be larger than your remaining turns of " .. whicheffect .. ".", "eating unknown food", "OK, disable the warning."
	else
		local need_turns = quantity * item.fullness
		if buffturns(whicheffect) < need_turns then
			return "You do not have enough turns of " .. whicheffect .. " active (need " .. need_turns .. " turns).", "eating without enough turns of " .. whicheffect
		end
	end
end

add_aftercore_warning("/inv_eat.php", function()
	return check_eating_warning(tonumber(params.whichitem), (tonumber(params.quantity) or 1))
end)

add_aftercore_warning("/inv_eat.php", function()
	if have_buff("Gar-ish") then return end
	for _, x in ipairs { "fishy fish lasagna", "gnat lasagna", "long pork lasagna" } do
		if tonumber(params.whichitem) == get_itemid(x) then
			return "You do not have Gar-ish active while eating lasagna.", "eating lasagna without Gar-ish"
		end
	end
end)

add_extra_ascension_warning("/inv_eat.php", function()
	if have_buff("Got Milk") or have_item("milk of magnesium") or (have_item("glass of goat's milk") and (classid() == 4 or have_skill("Advanced Saucecrafting"))) then
		return check_eating_warning(tonumber(params.whichitem), (tonumber(params.quantity) or 1))
	end
end)

add_always_warning("/inv_eat.php", function()
	if ascensionpath("Avatar of Boris") then
		return check_eating_warning(tonumber(params.whichitem), (tonumber(params.quantity) or 1), "Song of the Glorious Lunch")
	end
end)

add_always_warning("/cafe.php", function()
	if params.action ~= "CONSUME!" or tonumber(params.cafeid) ~= 1 then return end
	-- Chez Snotee
	if tonumber(params.whichitem) == -1 or tonumber(params.whichitem) == -2 or tonumber(params.whichitem) == -3 then
		return "Are you sure? Preferably you'd eat something much better.", "eating bad chez snotee food"
	end
end)

add_always_warning("/cafe.php", function()
	if params.action ~= "CONSUME!" or tonumber(params.cafeid) ~= 1 then return end
	-- Chez Snotee
	if ascensionstatus("Aftercore") or (have_buff("Got Milk") or have_item("milk of magnesium") or (have_item("glass of goat's milk") and (classid() == 4 or have_skill("Advanced Saucecrafting")))) then
		if not have_buff("Got Milk") then
			return "You do not have Got Milk active.", "eating without Got Milk"
		end
		local fullness = nil
		if tonumber(params.whichitem) == -1 then
			fullness = 3
		elseif tonumber(params.whichitem) == -2 then
			fullness = 4
		elseif tonumber(params.whichitem) == -3 then
			fullness = 5
		end
		-- TODO: check fullness for other food
		if not fullness then
			return "You might not have enough turns of Got Milk active (unknown fullness).", "eating unspecified fullness without enough turns of got milk"
		end
		local need_turns = (tonumber(params.quantity) or 1) * fullness
		if buffturns("Got Milk") < need_turns then
			return "You do not have enough turns of Got Milk active (need " .. need_turns .. " turns).", "eating without enough turns of got milk"
		end
	end
end)

add_processor("use item: distention pill", function()
	if text:contains("stomach feels rather stretched out") or text:contains("can't take any more abuse") then
		day["item.distention pill.used today"] = true
	end
end)

