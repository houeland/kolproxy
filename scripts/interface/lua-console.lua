add_automation_script("lua-console", function()
	local prefilltext = params.command or ""
	output = ""
	if params.command then
		local f, e = loadstring(params.command)
		if f then
			setfenv(f, getfenv())
			f()
		else
			output = "Error: " .. tostring(e)
		end
	end
	output = (tostring(output) or ""):gsub([[if %(parent.frames.length == 0%) location.href="game.php";]], "")
	return [[
<html>
<body>
]] .. output .. [[

<form action="/kolproxy-automation-script">
<input type="hidden" name="automation-script" value="lua-console">
<input type="hidden" name="pwd" value="]] .. params.pwd .. [[">
<textarea name="command" rows="5" cols="80">]] .. prefilltext .. [[</textarea><br>
<input type="submit">
<p>Type Lua commands to evaluate in the form. Assign to the variable "output" to see it on the page.</p>
<p>Examples:
<ul>
<li>output = "hello"</li>
<li>output = get_page("/plains.php")</li>
<li>print "hello"</li>
</ul></p>
</form>
</body>
</html>
]], requestpath
end)
