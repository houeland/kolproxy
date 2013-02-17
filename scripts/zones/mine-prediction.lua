function compute_mine_aggregate_pcond(inputminestr)
	local raw_mine_aggregate_data = datafile("mine aggregate prediction")

	local mine_aggregate_data = {}
	for a, b in pairs(raw_mine_aggregate_data) do
		for i = 1, 24 do
			local ic = inputminestr:sub(i, i)
			local ac = a:sub(i, i)
			if ic == "1" or ic == "2" or ic == "3" or ic == "8" then
				if a:match(ic) and ic ~= ac then
					b = 0
				elseif not a:match(ic) and ac ~= "?" then
					b = 0
				end
			elseif ic == "0" and ac ~= "?" then
				b = 0
			elseif ic == "?" then
			elseif ic == "!" then
				-- TODO?: Adjust probabilities based on non-empty tiles
			elseif ic == "*" then
				-- TODO?: Adjust probabilities based on loadstone
			end
		end
		mine_aggregate_data[a] = tonumber(b)
	end

	local prob = { ["1"] = {}, ["2"] = {}, ["3"] = {}, ["8"] = {} }
	local proboresum = { ["1"] = 0, ["2"] = 0, ["3"] = 0, ["8"] = 0 }
	for _, ore in ipairs { "1", "2", "3", "8" } do
		for idx = 1, 24 do
			for a, b in pairs(mine_aggregate_data) do
				if a:sub(idx, idx) == ore then
					prob[ore][idx] = (prob[ore][idx] or 0) + b
					proboresum[ore] = (proboresum[ore] or 0) + b
				end
			end
		end
	end

	for _, ore in ipairs { "1", "2", "3", "8" } do
		for idx = 1, 24 do
			prob[ore][idx] = (prob[ore][idx] or 0) / proboresum[ore] * 4
		end
	end

--	for _, xyzzyore in ipairs { "1", "2", "3", "8" } do
--	print("xyzzyore", xyzzyore)
--	local totalone = 0
--	for y = 0, 3 do
--		local row = {}
--		for x = 1, 6 do
--			table.insert(row, string.format("%.5f", prob[xyzzyore][y * 6 + x] or 0))
--			totalone = totalone + (prob[xyzzyore][y * 6 + x] or 0)
--		end
--		print(table.concat(row, " "))
--	end
--	print("sum", totalone)
--	print("")
--	end

	local pcond = {}
	for idx = 1, 24 do
		pcond[idx] = {}
		local fudge_factor = 0.4
		pcond[idx]["0"] = fudge_factor * (1 - prob["1"][idx]) * (1 - prob["2"][idx]) * (1 - prob["3"][idx]) * (1 - prob["8"][idx])
		if inputminestr:sub(idx, idx) == "*" then
			pcond[idx]["0"] = 0
		end
		pcond[idx]["1"] = prob["1"][idx] * (1 - prob["2"][idx]) * (1 - prob["3"][idx]) * (1 - prob["8"][idx])
		pcond[idx]["2"] = (1 - prob["1"][idx]) * prob["2"][idx] * (1 - prob["3"][idx]) * (1 - prob["8"][idx])
		pcond[idx]["3"] = (1 - prob["1"][idx]) * (1 - prob["2"][idx]) * prob["3"][idx] * (1 - prob["8"][idx])
		pcond[idx]["8"] = (1 - prob["1"][idx]) * (1 - prob["2"][idx]) * (1 - prob["3"][idx]) * prob["8"][idx]
		local sum = pcond[idx]["0"] + pcond[idx]["1"] + pcond[idx]["2"] + pcond[idx]["3"] + pcond[idx]["8"]
		pcond[idx]["0"] = pcond[idx]["0"] / sum
		pcond[idx]["1"] = pcond[idx]["1"] / sum
		pcond[idx]["2"] = pcond[idx]["2"] / sum
		pcond[idx]["3"] = pcond[idx]["3"] / sum
		pcond[idx]["8"] = pcond[idx]["8"] / sum
	end

--	for _, xyzzyore in ipairs { "0", "1", "2", "3", "8" } do
--	print("xyzzyore", xyzzyore)
--	local totaltwo = 0
--	for y = 0, 3 do
--		local row = {}
--		for x = 1, 6 do
--			table.insert(row, string.format("%.5f", pcond[y * 6 + x][xyzzyore] or 0))
--			totaltwo = totaltwo + (pcond[y * 6 + x][xyzzyore] or 0)
--		end
--		print(table.concat(row, " "))
--	end
--	print("sum", totaltwo)
--	end

	return pcond
end

function compute_mine_aggregate_values(wantore, inputminestr, pcond)
	local values = {}
	for fy = 0, 3 do
		for fx = 1, 6 do
			local fi = fy * 6 + fx
			local fval = pcond[fi][wantore]
			if inputminestr:sub(fi, fi) ~= "?" and inputminestr:sub(fi, fi) ~= "!" then
				fval = 0
			end
			for ty = 0, 5 do
				for tx = 1, 6 do
					local ti = ty * 6 + tx
					local dx = math.abs(tx - fx)
					local dy = math.abs(ty - fy)
					values[ti] = (values[ti] or 0) + fval / (dx + dy + 1)
				end
			end
		end
	end
	return values
end
