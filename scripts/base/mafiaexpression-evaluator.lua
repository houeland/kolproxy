function evaluate_mafiaexpression(expression_input, tbl)
	local expr = expression_input:match("^mafiaexpression:%[([^]]*)%]$")
	if not expr then return nil end

	expr = expr:gsub("STAT", buffedmainstat)
	expr = expr:gsub("MUS", buffedmuscle)
	expr = expr:gsub("MYS", buffedmysticality)
	expr = expr:gsub("MOX", buffedmoxie)
	expr = expr:gsub("ML", function() return estimate_bonus("Monster Level") end)
	expr = expr:gsub("HP", maxhp)
	expr = expr:gsub("BL", estimate_basement_level)

	expr = expr:gsub("A", ascensions_count)
	-- TODO: Evaluate letters for modifiers.txt too

	expr = expr:gsub("ceil", "math.ceil")
	expr = expr:gsub("floor", "math.floor")
	expr = expr:gsub("sqrt", "math.sqrt")
	expr = expr:gsub("min", "math.min")
	expr = expr:gsub("max", "math.max")

	local checkexpr = expr:gsub("math%.ceil", ""):gsub("math%.floor", ""):gsub("math%.sqrt", ""):gsub("math%.min", ""):gsub("math%.max", "")

	if checkexpr:match("^[0-9.,()*/+-]*$") then
		local f = loadstring("return math.floor(" .. expr .. ")")
		if f then
			setfenv(f, { math = { ceil = math.ceil, floor = math.floor, sqrt = math.sqrt, min = math.min, max = math.max } })
			local ok, result = pcall(f)
			if ok then
				return result
			else
				print("WARNING: couldn't evaluate mafiaexpression", expr)
			end
		end
	elseif checkexpr:contains("KC") then
		-- Kiss count not supported yet
		return nil
	elseif checkexpr:contains("pref(") then
		-- Unsupported state tracking
		return nil
	else
		print("WARNING: invalid mafiaexpression", expr, checkexpr)
	end
end
