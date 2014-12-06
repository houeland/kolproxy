local thralls = {
	{ name = "Vampieroghi", effect = "+HP" , desc = { "attack/heal", "dispels negative effects", "+60 HP" }, img = "t_vampieroghi" },
	{ name = "Vermincelli", effect = "+MP", desc = { "restores MP", "attack + poison", "+30 MP" }, img = "t_vermincelli" },
	{ name = "Angel Hair Wisp", effect = "+init%", desc = { "+init", "prevents enemy crits", "blocks" }, img = "t_wisp" },
	{ name = "Elbow Macaroni", effect = "mus=mys", desc = { "mus >= myst", "+weapon damage", "+10% crit chance" }, img = "t_elbowmac" },
	{ name = "Penne Dreadful", effect = "mox=mys", desc = { "mox >= myst", "delevel", "DR +10" }, img = "t_dreadful" },
	{ name = "Lasagmbie", effect = "+meat%", desc = { "+meat", "spooky attack", "+10 spooky spell dam" }, img = "t_lasagmbie" },
	{ name = "Spice Ghost", effect = "+item%", desc = { "+item", "spices", "better entangling" }, img = "t_spiceghost" },
	{ name = "Spaghetti Elemental", effect = "+stat", desc = { "+stat", "prevents 1st attack", "+5 spell dam" }, img = "t_spagdemon" },
}

function get_current_pastathrall_info()
	local data = thralls[pastathrallid()] or {}
	local tbl = {}
	tbl.id = pastathrallid()
	tbl.level = pastathralllevel()
	tbl.name = data.name or string.format("{?thrallid:%d?}", tbl.id)
	tbl.effect = data.effect or "?"
	tbl.abilities = {}
	local desc = data.desc or {}
	for idx, lvl in ipairs { 1, 5, 10 } do
		if pastathralllevel() >= lvl and desc[idx] then
			table.insert(tbl.abilities, desc[idx])
		end
	end
	tbl.picture = data.img or "?"
	return tbl
end

local thrall_name_lookup = {}
for id, x in ipairs(thralls) do
	thrall_name_lookup[x.name] = id
end

function pastathrall(name)
	if name == nil then return pastathrallid() ~= 0 end
	local id = thrall_name_lookup[name]
	if id then
		return pastathrallid() == id
	else
		error("Unknown pasta thrall: " .. tostring(name))
	end
end

function estimate_current_pastathrall_bonuses()
	if pastathrall("Angel Hair Wisp") then
		return make_bonuses_table { ["Combat Initiative"] = 5 * pastathralllevel() }
	elseif pastathrall("Spice Ghost") then
		return make_bonuses_table { ["Item Drops from Monsters"] = 10 + pastathralllevel() }
	elseif pastathrall("Lasagmbie") then
		return make_bonuses_table { ["Meat from Monsters"] = 20 + 2 * pastathralllevel() }
	else
		return make_bonuses_table {}
	end
end

add_warning {
	message = "A Vampieroghi can remove the Thrice-Cursed, Twice-Cursed, and Once-Cursed buffs.",
	type = "warning",
	check = function()
		if not pastathrall("Vampieroghi") then return end
		if pastathralllevel() < 5 then return end
		return have_apartment_building_cursed_buff()
	end,
}
