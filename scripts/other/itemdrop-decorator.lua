add_printer("item drop", function()
	text = text:gsub([[(<td valign=center class=effect>)(You acquire .-)(</td>)]], [[%1<span style="color: darkgreen">%2</span>%3]])
end)
