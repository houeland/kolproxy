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

local automation_script_details_list = {}

add_automation_script("custom-aftercore-automation", function()
	local questlogcompleted_page = get_page("/questlog.php", { which = 2 })
	function quest_completed(name)
		return questlogcompleted_page:contains([[<b>]] .. name .. [[</b>]])
	end

	local goodlinks = {}
	local links = {}
	for x in pairs(get_automation_script_links()) do
		local tbl = automation_script_details_list[x]
		if tbl and tbl.description then
			if ascensionstatus("Aftercore") and tbl.when() then
				table.insert(goodlinks, [[<a href="kolproxy-automation-script?automation-script=]]..tbl.name..[[&pwd=]]..session.pwd..[[">]]..tbl.description..[[</a>]])
			else
				table.insert(goodlinks, [[<span style="color: gray">]]..tbl.description..[[</a>]])
			end
		else
			table.insert(links, [[<a href="kolproxy-automation-script?automation-script=]]..x..[[&pwd=]]..session.pwd..[[">]]..x..[[</a>]])
		end
	end
	return "Note: Work in progress, currently missing an interface<br><br>" .. table.concat(goodlinks, "<br>") .. "<br><br>" .. table.concat(links, "<br>"), requestpath
end)

function maybe_pull_item(name, amount)
	amount = amount or 1
	if count(name) < amount then
		async_post_page("/storage.php", { action = "pull", whichitem1 = get_itemid(name), howmany1 = amount - count(name), pwd = session.pwd, ajax = 1 })
		if amount > 1 and count(name) < amount then
			critical("Couldn't pull " .. tostring(amount) .. "x " .. tostring(name))
		end
	end
end

function cast_autoattack_macro()
	local attid = status().flag_config.autoattack
	local macroid = attid:match("^99([0-9]+)$")
	if tonumber(macroid) then
		local pt, pturl = post_page("/fight.php", { action = "macro", macrotext = "", whichmacro = macroid })
		return handle_adventure_result(pt, pturl)
	else
		return result, resulturl, advagain
	end
end

result, resulturl = "?", "?"

function setup_turnplaying_script(tbl)
	automation_script_details_list[tbl.name] = tbl
	return add_automation_script(tbl.name, function()
		-- TODO: limit global variables to script environments
		script = get_automation_scripts()
		if tbl.preparation then
			tbl.preparation()
		end

		if not tbl.macro and not autoattack_is_set() then
			stop "Set a macro on autoattack to use for scripting this quest."
		end

		-- TODO: cache quest per pageload
		local questlog_page = nil
		local questlog_page_async = async_get_page("/questlog.php", { which = 1 })
		function refresh_quest()
			questlog_page = get_page("/questlog.php", { which = 1 })
		end

		function quest(name)
			return questlog_page:contains([[<b>]] .. name .. [[</b>]])
		end
		function quest_text(name)
			return questlog_page:contains(name)
		end
		questlog_page = questlog_page_async()

		function inform(msg)
			local mpstr = string.format("%s / %s MP", mp(), maxmp())
			if challenge == "zombie" then
				mpstr = string.format("%s horde", horde_size())
			end
			local formatted = string.format("[%s] %s (level %s.%02d, %s turns remaining, %s full, %s drunk, %s spleen, %s meat, %s)", turnsthisrun(), tostring(msg), level(), level_progress() * 100, advs(), fullness(), drunkenness(), spleen(), meat(), mpstr)
			print(formatted)
		end

		function __set_turnplaying_result(result_, resulturl_, advagain_)
			result, resulturl, advagain = result_, resulturl_, advagain_
		end

		advagain = true
		while advagain do
			advagain = false
			result, resulturl = nil, nil
			result, resulturl = "Automation failed", requestpath
			if advs() == 0 then
				stop "Out of adventures."
			end
			refresh_quest()
			inform(tbl.name)
			tbl.adventuring()
		end
		return result, resulturl
	end)
end
