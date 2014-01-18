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

function p_data_and_room_permutation_escher_given_starteven(D, choiceid, pe)
	return p_data_given_starteven_withextradata(D, { choiceid = choiceid, pe = pe })
end

function p_data_and_room_permutation_escher_given_startodd(D, choiceid, pe)
	return p_data_given_startodd_withextradata(D, { choiceid = choiceid, pe = pe })
end

function incompatible(choiceid, branch, result, permutation, escher, pe)
	if pe then
		return (permutation .. ":" .. escher) ~= pe
	else
		local prediction = room_layout[choiceid][("ABC"):find(permutation:sub(branch, branch))]
		if prediction == "Escher" then prediction = escher end
		return result ~= prediction
	end
end

function p_data_with_remapper(D, remapper, extradata)
	local rngseeds = {}
	for s in table.values { 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104 } do
		rngseeds[s] = {}
		for permutation in table.values(louvre_order_permutations) do
			for escher = 93, 95 do
				rngseeds[s][permutation .. ":" .. escher] = true
			end
		end
	end
	for d in table.values(D) do
		local s = remapper(d.choiceid)
		for permutation in table.values(louvre_order_permutations) do
			for escher = 93, 95 do
				if incompatible(d.choiceid, d.branch, d.result, permutation, escher, d.pe) then
					rngseeds[s][permutation .. ":" .. escher] = false
				end
			end
		end
	end
	if extradata then
		local s = remapper(extradata.choiceid)
		for permutation in table.values(louvre_order_permutations) do
			for escher = 93, 95 do
				if incompatible(extradata.choiceid, extradata.branch, extradata.result, permutation, escher, extradata.pe) then
					rngseeds[s][permutation .. ":" .. escher] = false
				end
			end
		end
	end
	local p_product = 1
	for s in table.values { 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104 } do
		local p_room_sum = 0
		for permutation in table.values(louvre_order_permutations) do
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

function p_data_given_starteven_withextradata(D, extradata)
	return p_data_with_remapper(D, function(choiceid)
-- 		return math.floor(choiceid / 2) * 2
		return choiceid
	end, extradata)
end

function p_data_given_startodd_withextradata(D, extradata)
	return p_data_with_remapper(D, function(choiceid)
-- 		return math.ceil(choiceid / 2) * 2
		return choiceid
	end, extradata)
end

--[[


P(92:ABC:93 | D) = ?

P(92:ABC:93 | D) = P(92:ABC:93 ^ D) / P(D)

P(92:ABC:93 | D) * P(D) = P(92:ABC:93 ^ D) =
  P(92:ABC:93 ^ D ^ starteven) +
  P(92:ABC:93 ^ D ^ ~starteven)

P(92:ABC:93 ^ D ^ starteven) / P(92:ABC:93 ^ starteven) = P(D | 92:ABC:93 ^ starteven)
P(92:ABC:93 ^ D ^ starteven) = P(D | 92:ABC:93 ^ starteven) * P(92:ABC:93 ^ starteven)

P(92:ABC:93 | D) * P(D) =
  P(D | 92:ABC:93 ^ starteven) * P(92:ABC:93 ^ starteven) +
  P(D | 92:ABC:93 ^ ~starteven) * P(92:ABC:93 ^ ~starteven)


P(92:ABC:93 | D) * P(D) =
  P(D | 92:ABC:93 ^ starteven) * P(92:ABC:93 | starteven) * P(starteven) +
  P(D | 92:ABC:93 ^ ~starteven) * P(92:ABC:93 | ~starteven) * P(~starteven)

P(D) = P(D | starteven) * P(starteven) + P(D | ~starteven) * P(~starteven)

P(92:ABC:93 | D) * P(D) = P(92:ABC:93 ^ D) =
  P(92:ABC:93 ^ D ^ starteven) +
  P(92:ABC:93 ^ D ^ ~starteven)


P(92:ABC:93 | D) * P(D) =
  P(92:ABC:93 ^ D | starteven) * P(starteven) +
  P(92:ABC:93 ^ D | ~starteven) * P(~starteven)

P(92:ABC:93 | D) =
  (P(92:ABC:93 ^ D | starteven) * P(starteven) + P(92:ABC:93 ^ D | ~starteven) * P(~starteven)) /
  (P(D | starteven) * P(starteven) + P(D | ~starteven) * P(~starteven))

]]--


-- p_room_permutation_escher_given_data(92, "ABC:93", D)
function p_room_permutation_escher_given_data(choiceid, pe, D)
	local a = p_data_and_room_permutation_escher_given_starteven(D, choiceid, pe)
	local d = p_data_and_room_permutation_escher_given_startodd(D, choiceid, pe)
--	print("  p", choiceid, pe, "D:", (a * 0.5 + d * 0.5) / (p_data_given_starteven(D) * 0.5 + p_data_given_startodd(D) * 0.5))
	return (a * 0.5 + d * 0.5) / (p_data_given_starteven_withextradata(D, nil) * 0.5 + p_data_given_startodd_withextradata(D, nil) * 0.5)
end

function compute_louvre_probabilities(curchoice, D)
	local poss = { {}, {}, {} }
	for permutation in table.values(louvre_order_permutations) do
		for escher = 93, 95 do
			local p = p_room_permutation_escher_given_data(curchoice, permutation .. ":" .. escher, D)
			for i = 1, 3 do
				local result = room_layout[curchoice][("ABC"):find(permutation:sub(i, i))]
				if result == "Escher" then result = escher end
				poss[i][result] = (poss[i][result] or 0) + p
			end
		end
	end

	return poss
end

function predict_louvre(curchoice, D)
	local probabilities = compute_louvre_probabilities(curchoice, D)
--	print(probabilities)
	return probabilities
end
