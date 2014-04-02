local function html_encode(str)
	local repls = {
		[ [[%"]] ] = "&quot;",
		["%("] ="&#40;",
		["%)"] = "&#41;",
		["%["] = "&#91;",
		["%]"] = "&#93;",
		[ [[%\]] ] = "&#92;",
		["\n"] = " ",
		["\r"] = " ",
	}
	for from, to in pairs(repls) do
		str = str:gsub(from, to)
	end
	return str
end

add_chat_command("/addlognote", "Adding log line.", function(line)
	if line == "" then return make_kol_html_frame("You didn't specify any text to log.") end
	local notes = ascension["__log notes"] or {}
	table.insert(notes, { turn = turnsthisrun(), note = html_encode(line) })
	ascension["__log notes"] = notes
	return make_kol_html_frame("Added note: [" .. turnsthisrun() .. "] " .. html_encode(line) .. ".")
end)

add_chat_alias("/lognote", "/addlognote")
add_chat_alias("/log", "/addlognote")

add_automation_script("add-log-notes", function()
	local notes = ascension["__log notes"] or {}
	if params.note then
		table.insert(notes, { turn = turnsthisrun(), note = html_encode(params.note) })
		ascension["__log notes"] = notes
	end
	local notehtmltbl = {}
	for x in table.values(notes) do
		table.insert(notehtmltbl, "<li>[" .. x.turn .. "] " .. (x.note or "(Error, note missing!)") .. "</li>")
	end
	return [[
<html>
<body>
<ul>
]] .. table.concat(notehtmltbl, "\n") .. [[
</ul>
<form action="/kolproxy-automation-script">
<input type="hidden" name="automation-script" value="add-log-notes">
<input type="hidden" name="pwd" value="]] .. params.pwd .. [[">
<input type="text" name="note" size="80"></input><input type="submit">
</form>
</body>
</html>
]], requestpath
end)
