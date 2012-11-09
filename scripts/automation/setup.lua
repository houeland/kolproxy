__allow_global_writes = true

function set_result(x)
	result = x
end

function get_result()
	if type(result) == "string" then
		return result
	else
		return result()
	end
end

function run_automation_script(f, pwdsrc, scriptname)
	result = "??? No automation done ???"
	resulturl = "/automation-script"
	function get_pwd() return pwdsrc end
	local stopped_err = false
	local critical_err = false
	local errmsg = nil
	function critical(e)
		errmsg = e
		critical_err = true
		error(e, 2)
	end
	function stop(e)
		errmsg = e
		stopped_err = true
		error(e, 2)
	end

	local ok, text, url = xpcall(f, function(e) return { msg = e, trace = debug.traceback(e) } end)
	if ok then
		return text, url
	else
		local e = text
		if critical_err then
			print("Something unexpected happened: " .. errmsg)
			print(e.trace)
--				write_log_line("Something unexpected happened: " .. errmsg)
			result = get_result()
			if result == "??? No action found ???" or result == "??? No automation done ???" then
				return [[<script>top.charpane.location = "charpane.php"</script><p style="color: darkorange">]] .. "Something unexpected happened: " .. errmsg .. "<br><br><pre>Technical details:\n\n" .. e.trace .. "</pre>", requestpath
			else
				return [[<script>top.charpane.location = "charpane.php"</script>]] .. add_formatted_colored_message_to_page(result, "Something unexpected happened: " .. errmsg .. "<br><br><pre>Technical details:\n\n" .. e.trace .. "</pre>", "darkorange"), requestpath
			end
		elseif stopped_err then
			if errmsg:match("End of day.-then done") then -- TODO: redo this
				print("Finished: " .. errmsg)
				print(e.trace)
--					write_log_line("Finished: " .. errmsg)
				--.. "<br><br><pre>Technical details:\n\n" .. e.trace ..
				return [[<script>top.charpane.location = "charpane.php"</script>]] .. "Finished: " .. errmsg .. "</pre>", requestpath
			else
				print("Manual intervention required: " .. errmsg)
				print(e.trace)
--					write_log_line("Manual intervention required: " .. errmsg)
-- 				return [[<script>top.charpane.location = "charpane.php"</script>]] .. "Manual intervention required: " .. errmsg .. "<br><br>Fix this and click the link again to continue automating.<br><br><pre>Technical details:\n\n" .. e.trace .. "</pre>", requestpath
				local runagain_href = make_href("/kolproxy-automation-script", params)
				return [[<script>top.charpane.location = "charpane.php"</script>Manual intervention required: ]] .. errmsg .. [[<br><br>Fix this and run the script again to continue automating.<br><br><a href="]]..runagain_href..[[" style="color: green">{ I have fixed it, run the script again now! }</a>]], requestpath
			end
		else
--				write_log_line("Error: " .. tostring(e.msg))
			error(e.trace, 0)
		end
	end
end

add_automation_script("custom-aftercore-automation", function()
	local links = {}
	for x in pairs(get_automation_script_links()) do
		table.insert(links, [[<a href="kolproxy-automation-script?automation-script=]]..x..[[&pwd=]]..session.pwd..[[">]]..x..[[</a>]])
	end
	return "Note: Work in progress, currently missing an interface<br><br>" .. table.concat(links, "<br>"), requestpath
end)
