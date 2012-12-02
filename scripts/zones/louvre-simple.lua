local room_layout = {
	[92] = { 96, 97, 98 },
	[93] = { 96, 97, 98 },
	[94] = { 96, 97, 98 },
	[95] = { 96, 97, 98 },

	[96] = { "Escher", 99, 100 },
	[97] = { "Escher", 101, 102 },
	[98] = { "Escher", 103, 104 },

	[99] = { "Escher", "Moxie", "bottle of Pinot Renoir" },
	[100] = { "Escher", "Moxie", "Manetwich" },
	[101] = { "Escher", "Manetwich", "Muscle" },
	[102] = { "Escher", "Muscle", "bottle of Vangoghbitussin" },
	[103] = { "Escher", "bottle of Vangoghbitussin", "Mysticality" },
	[104] = { "Escher", "Mysticality", "bottle of Pinot Renoir" },
}

local louvre_order_permutations = { "ABC", "ACB", "BAC", "BCA", "CAB", "CBA" }

local louvre_permutation_escher_probabilities_times_81 = {
	["ABC:93"] = 6,
	["ABC:94"] = 6,
	["ABC:95"] = 9,
	["ACB:93"] = 0,
	["ACB:94"] = 0,
	["ACB:95"] = 12,
	["BAC:93"] = 1,
	["BAC:94"] = 1,
	["BAC:95"] = 0,
	["BCA:93"] = 2,
	["BCA:94"] = 2,
	["BCA:95"] = 0,
	["CAB:93"] = 0,
	["CAB:94"] = 0,
	["CAB:95"] = 6,
	["CBA:93"] = 18,
	["CBA:94"] = 18,
	["CBA:95"] = 0,
}

-- P(D ^ extradata)
local function p_data(D, extradata)
	local rngseeds = {}
	for s = 92, 104 do
		rngseeds[s] = {}
		for _, permutation in ipairs(louvre_order_permutations) do
			for escher = 93, 95 do
				rngseeds[s][permutation .. ":" .. escher] = true
			end
		end
	end
	for _, d in ipairs(D) do
		for _, permutation in ipairs(louvre_order_permutations) do
			local idx = ("ABC"):find(permutation:sub(d.branch, d.branch))
			local roomresult = room_layout[d.choiceid][idx]
			for escher = 93, 95 do
				local prediction = roomresult
				if prediction == "Escher" then prediction = escher end
				if prediction ~= d.result then
					rngseeds[d.choiceid][permutation .. ":" .. escher] = false
				end
			end
		end
	end
	if extradata then
		for _, permutation in ipairs(louvre_order_permutations) do
			for escher = 93, 95 do
				if (permutation .. ":" .. escher) ~= extradata.pe then
					rngseeds[extradata.choiceid][permutation .. ":" .. escher] = false
				end
			end
		end
	end

	local p_product = 1
	for s = 92, 104 do
		local p_room_sum = 0
		for _, permutation in ipairs(louvre_order_permutations) do
			for escher = 93, 95 do
				if rngseeds[s][permutation .. ":" .. escher] then
					p_room_sum = p_room_sum + louvre_permutation_escher_probabilities_times_81[permutation .. ":" .. escher] / 81
				end
			end
		end
		p_product = p_product * p_room_sum
	end
	return p_product
end

--[[

P(92:ABC:93) = probability that room 92 has permutation ABC and that any escher endnode leads to room 93

P(92:ABC:93 | D) = ?

P(92:ABC:93 | D) = P(92:ABC:93 ^ D) / P(D)

]]--


-- p_room_permutation_escher_given_data(92, "ABC:93", D)
-- P(92:ABC:93 | D) = P(92:ABC:93 ^ D) / P(D)
local function p_room_permutation_escher_given_data(choiceid, pe, D)
	return p_data(D, { choiceid = choiceid, pe = pe }) / p_data(D, nil)
end

-- P(curchoice:option1 = result | D) =
-- sum(permutation perm) sum(escher e) P(curchoice:option1 = result | curchoice:perm:e) * P(curchoice:perm:e | D)
local function compute_louvre_probabilities(curchoice, D)
	local poss = { {}, {}, {} }
	for _, permutation in ipairs(louvre_order_permutations) do
		for escher = 93, 95 do
			local p = p_room_permutation_escher_given_data(curchoice, permutation .. ":" .. escher, D)
			for i = 1, 3 do
				local idx = ("ABC"):find(permutation:sub(i, i))
				local result = room_layout[curchoice][idx]
				if result == "Escher" then result = escher end
				poss[i][result] = (poss[i][result] or 0) + p
			end
		end
	end

	return poss
end

function predict_louvre_simple(curchoice, D)
	local probabilities = compute_louvre_probabilities(curchoice, D)
--	print(probabilities)
	return probabilities
end


-- testing, solving

local function generate_random_pe()
	local which = math.random(1, 81)
	for a, b in pairs(louvre_permutation_escher_probabilities_times_81) do
		which = which - b
		if which <= 0 then
			return a
		end
	end
end

function generate_random_louvre()
	local louvremap = {}
	for s = 92, 104 do
		local pe = generate_random_pe()
		louvremap[s] = {}
		local permutation, escher = pe:match("([ABC]*):([0-9]*)")
		for i = 1, 3 do
			local idx = ("ABC"):find(permutation:sub(i, i))
			local result = room_layout[s][idx]
			if result == "Escher" then result = tonumber(escher) end
			louvremap[s][i] = result
		end
	end
	return louvremap
end

local function getvalue_escherval(id, D, escherval)
	local choiceid = tonumber(id)
	if choiceid then
		if choiceid >= 92 and choiceid <= 95 then
			return escherval
		else
			local p = predict_louvre_simple(choiceid, D)
			local bestval = -1
			for i = 1, 3 do
				local optval = 0
				for a, b in pairs(p[i]) do
					table.insert(D, { choiceid = choiceid, branch = i, result = a })
					optval = optval + b * getvalue_escherval(a, D, escherval)
					table.remove(D)
				end
				bestval = math.max(bestval, optval)
			end
			return bestval
		end
	elseif id == "Muscle" then
		return 1
	else
		return 0
	end
end

louvre_choicecache = {}
local choicecache = louvre_choicecache

function desc_cD(choiceid, D)
	local tbl = {}
	for _, x in ipairs(D) do
		table.insert(tbl, x.choiceid .. ":" .. x.branch .. ":" .. x.result)
	end
	return choiceid .. "#" .. table.concat(tbl, "/")
end

function louvre_policy_escherval(escher_value_estimate)
	if not choicecache[escher_value_estimate] then
		choicecache[escher_value_estimate] = {}
	end
	return function(choiceid, D)
		local descstr = desc_cD(choiceid, D)
		if choicecache[escher_value_estimate][descstr] then
			return choicecache[escher_value_estimate][descstr]
		end
		local p = predict_louvre_simple(choiceid, D)
		local chooseopt = -1
		local chooseoptval = -1
		for i = 1, 3 do
			local optval = 0
			for a, b in pairs(p[i]) do
				table.insert(D, { choiceid = choiceid, branch = i, result = a })
				optval = optval + b * getvalue_escherval(a, D, escher_value_estimate)
				table.remove(D)
			end
			if optval > chooseoptval then
				chooseoptval = optval
				chooseopt = i
			end
		end
		print("  DEBUG (" .. escher_value_estimate .. "):", choiceid, "->", chooseopt)
		print("    " .. descstr)
		choicecache[escher_value_estimate][descstr] = chooseopt
		return chooseopt
	end
end

function louvre_policy_random()
	return function(choiceid, D)
		return math.random(1, 3)
	end
end

function louvre_policy_fixed(commands)
	local choicenum = 0
	return function(choiceid, D)
		choicenum = choicenum + 1
		local cmdnow = commands:sub(choicenum, choicenum)
		if cmdnow == "U" then
			return 1
		elseif cmdnow == "D" then
			return 2
		elseif cmdnow == "S" then
			return 3
		end
	end
end

function louvre_policy_DDU()
	return louvre_policy_fixed("DDU")
end

function run_louvre_policy_test_sample(policygen)
	local policy = policygen()
	local louvremap = generate_random_louvre()
	local D = {}
	local curchoiceid = 92
	for i = 1, 1000 do
		local policyopt = policy(curchoiceid, D)
		if not policyopt then
			return "stopped"
		end
		local result = louvremap[curchoiceid][policyopt]

		local hasit = false
		for _, x in ipairs(D) do
			if x.choiceid == curchoiceid and x.branch == policyopt and x.result == result then
				hasit = true
			end
		end
		if not hasit then
			table.insert(D, { choiceid = curchoiceid, branch = policyopt, result = result })
		end

		local nextchoiceid = tonumber(result)
		if nextchoiceid then
			curchoiceid = nextchoiceid
		else
			return result
		end
	end
	return "looping"
end

function test_louvre_policy(policygen, times)
	times = times or 10000
	local results = {}
	for i = 1, times do
		local r = run_louvre_policy_test_sample(policygen)
		results[r] = (results[r] or 0) + 1
		print("DEBUG ran", i, "samples")
	end
	for a, _ in pairs(results) do
		results[a] = results[a] / times
	end
	return results
end
