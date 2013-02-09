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

local porko_mpastr = ""
local dungeonfist_mpastr = ""

if estimate_mallsell_profit("lunar isotope") and estimate_mallbuy_cost("transporter transponder") then
	local porko_mpa = estimate_mallsell_profit("lunar isotope") * 4.385 - estimate_mallbuy_cost("transporter transponder") / 30
	porko_mpastr = string.format(", %.1fk Meat/Adventure", porko_mpa / 1000)
end

if estimate_mallsell_profit("Game Grid ticket") and estimate_mallbuy_cost("Game Grid token") then
	local dungeonfist_mpa = (estimate_mallsell_profit("Game Grid ticket") * 30 - estimate_mallbuy_cost("Game Grid token")) / 5
	dungeonfist_mpastr = string.format(", %.1fk Meat/Adventure", dungeonfist_mpa / 1000)
end

local porko_mpa = (estimate_mallsell_profit("lunar isotope") or 150) * 4.385 - (estimate_mallbuy_cost("transporter transponder") or 8000) / 30
local dungeonfist_mpa = ((estimate_mallsell_profit("Game Grid ticket") or 200) * 30 - (estimate_mallbuy_cost("Game Grid token") or 8000)) / 5

automation_script_details_list["automate-dungeonfist"] = { simple_link = "arcade.php", description = string.format("Automate playing Dungeon Fist (link to the game grid%s)", dungeonfist_mpastr) }
automation_script_details_list["automate-porko"] = { simple_link = "spaaace.php", description = string.format("Automate playing Porko (link to spaaace%s)", porko_mpastr) }
automation_script_details_list["get-faxbot-monster"] = { simple_link = "clan_viplounge.php?action=faxmachine", description = "Request monster from FaxBot (link to fax machine)" }
automation_script_details_list["custom-ascension-checklist"] = { simple = true, description = "Ascension checklist" }
automation_script_details_list["automate-nemesis"] = { when = function() return true end, description = "Automate Nemesis quest" }
automation_script_details_list["automate-suburbandis"] = { when = function() return true end, description = "Automate Suburban Dis quest" }
automation_script_details_list["castle-farming"] = { simple_link = "beanstalk.php", description = "Automate Castle meat farming (link to beanstalk)" }
automation_script_details_list["lua-console"] = { simple = true, description = "Go to Lua console" }
automation_script_details_list["add-log-notes"] = { simple = true, description = "Add note to ascension log" }
automation_script_details_list["automate-aftercore-pulls"] = { when = function() return true end, description = "Pull a selection of useful aftercore items from Hagnks storage" }

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
			if tbl.simple_link then
				table.insert(goodlinks, [[<a href="]]..tbl.simple_link..[[">]]..tbl.description..[[</a>]])
			elseif tbl.simple then
				table.insert(goodlinks, [[<a href="kolproxy-automation-script?automation-script=]]..(tbl.name or x)..[[&pwd=]]..session.pwd..[[">]]..tbl.description..[[</a>]])
			elseif ascensionstatus("Aftercore") and tbl.when and tbl.when() then
				table.insert(goodlinks, [[<a href="kolproxy-automation-script?automation-script=]]..(tbl.name or x)..[[&pwd=]]..session.pwd..[[">]]..tbl.description..[[</a>]])
			else
				table.insert(goodlinks, [[<span style="color: gray">]]..tbl.description..[[</a>]])
			end
		else
--			table.insert(links, [[<a href="kolproxy-automation-script?automation-script=]]..x..[[&pwd=]]..session.pwd..[[">]]..x..[[</a>]])
		end
	end
	return "Note: Work in progress, currently missing an interface<br><br>" .. table.concat(goodlinks, "<br>") .. "<br><br>" .. table.concat(links, "<br>"), requestpath
end)

function maybe_pull_item(name, input_amount)
	local amount = input_amount or 1
	if count_item(name) < amount then
		async_post_page("/storage.php", { action = "pull", whichitem1 = get_itemid(name), howmany1 = amount - count(name), pwd = session.pwd, ajax = 1 })
		if input_amount and count_item(name) < input_amount then
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
	check_supported_table_values(tbl, { "preparation", "macro" }, { "name", "adventuring" })
	automation_script_details_list[tbl.name] = tbl
	return add_automation_script(tbl.name, function()
		-- TODO: limit global variables to script environments
		script = get_automation_scripts()
		if tbl.preparation then
			tbl.preparation()
		end

		if tbl.macro and autoattack_is_set() then
			stop "Unset your autoattack for scripting this quest."
		elseif not tbl.macro and not autoattack_is_set() then
			stop "Set a macro on autoattack to use for scripting this quest."
		end
		automation_macro = tbl.macro

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
