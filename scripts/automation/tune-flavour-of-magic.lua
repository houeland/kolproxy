register_setting {
	name = "automatically tune flavour of magic",
	description = "Automatically tune flavour of magic before adventuring",
	group = "automation",
	default_level = "enthusiast",
	beta_version = true,
}

local flavour_of_magic_intrinsics = {
	["Sleaze"] = "Spirit of Bacon Grease",
	["Stench"] = "Spirit of Garlic",
	["Cold"] = "Spirit of Peppermint",
	["Hot"] = "Spirit of Cayenne",
	["Spooky"] = "Spirit of Wormwood",
}

function determine_best_flavour_vs_monsterlist(monsterlist, default)
	local scores = {}
	for x, _ in pairs(flavour_of_magic_intrinsics) do
		scores[x] = 0
	end
	for _, mname in ipairs(monsterlist) do
		local m = maybe_get_monsterdata(mname)
		if m and m.Stats and m.Stats.Element then
			local element = m.Stats.Element
			scores[element] = scores[element] - 1000
			local w1, w2 = get_elemental_weaknesses(element)
			scores[w1] = scores[w1] + 10
			scores[w2] = scores[w2] + 10
		end
	end
	--print("DEBUG scores", scores)

	local best = default
	local best_score = scores[default]
	for a, b in pairs(scores) do
		if b > best_score then
			best, best_score = a, b
		end
	end
	return best
end

add_interceptor("/adventure.php", function()
	if not setting_enabled("automatically tune flavour of magic") then return end
	if not have_skill("Flavour of Magic") then return end
	local zoneid = requested_zone_id()
	if not zoneid then return end
	for _, x in pairs(datafile("zones")) do
		if zoneid == x.zoneid then
			local default = "Stench"
			for x, _ in pairs(flavour_of_magic_intrinsics) do
				if have_intrinsic(x) then
					default = x
				end
			end
			local want_element = determine_best_flavour_vs_monsterlist(x.monsters or {}, default)
			local want_flavour = flavour_of_magic_intrinsics[want_element]
			if not have_intrinsic(want_flavour) then
				--print("WANT!", want_flavour, "vs", x.monsters or {})
				cast_skill(want_flavour)
				if not have_intrinsic(want_flavour) then
					print("ERROR: failed to set flavour to", want_flavour)
				end
			end
			break
		end
	end
end)
