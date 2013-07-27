add_printer("/charsheet.php", function()
	text = text:gsub("(<td align=right>)([A-Za-z]+)( Protection:</td><td><b>.- %()([0-9]+)(%)</b>)(</td>)", function(a, b, c, d, e, f)
		local dmgtaken = elemental_resist_level_multiplier(tonumber(d))
		local color = element_color(b) or "black"
		return a .. b .. c .. d .. e .. string.format([[ <span style="color: green">{ <span style="color: %s">%.1f%% %s damage taken</span> }</span>]], color, dmgtaken * 100, b) .. f
	end)
end)
