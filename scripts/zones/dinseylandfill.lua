function add_lines_at_end_of_body(text, lines)
	return text:gsub([[</body>]], function() return "<center>" .. table.concat(lines, "<br>") .. "</center></body>" end)
end

add_printer("place:airport_stench", function()
	local lines = {}
	local zones = {
		["keycard &alpha;"] = "Barf Mountain",
		["keycard &beta;"] = "Pirates of the Garbage Barges",
		["keycard &gamma;"] = "The Toxic Teacups",
		["keycard &delta;"] = "Uncle Gator's Country Fun-Time Liquid Waste Sluice",
	}
	for _, item in ipairs { "keycard &alpha;", "keycard &beta;", "keycard &gamma;", "keycard &delta;" } do
		if have_item(item) then
			table.insert(lines, string.format([[<span style="color: gray">%s: already found in %s</span>]], item, zones[item]))
		else
			table.insert(lines, string.format([[%s: can be found in %s]], item, zones[item]))
		end
	end
	text = add_lines_at_end_of_body(text, lines)
end)
