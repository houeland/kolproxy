add_printer("/charpane.php", function()
	local ttr = tonumber(text:match("var turnsthisrun = ([0-9]+);"))
	if not ttr then return end
	for _, x in ipairs(ascension["turn counters"] or {}) do
		local turns = x.turn + x.length - ttr
		if turns >= 0 then
			color = nil
			if turnsleft == 0 then
				color = "green"
			end
			print_charpane_value { name = x.name, value = tostring(turns), color = color }
		end
	end
end)

add_printer("/charpane.php", function()
	local ttr = text:match("var turnsthisrun = ([0-9]+);")
	if not ttr then return end
	print_charpane_value { normalname = "Turns played", compactname = "Played", value = ttr }
end)
