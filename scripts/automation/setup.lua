__allow_global_writes = true

function set_result(x, xurl)
	result = x
	if type(x) == "string" and xurl then
		resulturl = xurl
	end
end

function get_result()
	if type(result) == "string" then
		return result, resulturl
	else
		return result()
	end
end

function first_wearable(tbl)
	local keys = {}
	for a, _ in pairs(tbl) do
		table.insert(keys, a)
	end
	table.sort(keys)
	for _, xidx in ipairs(keys) do
		local x = tbl[xidx]
		if x and have_item(x) and can_equip_item(x) then
			return x
		end
	end
end

local automation_skiplink = ""
function set_automation_skiplink(l)
	if l then
		automation_skiplink = "<br>" .. l
	else
		automation_skiplink = ""
	end
end

function run_automation_script(f, pwdsrc, scriptname)
	set_automation_skiplink(nil)
	result = "??? No automation done ???"
	resulturl = "/automation-script"
	function get_pwd() return pwdsrc end
	local stopped_err = false
	local critical_err = false
	local errmsg = nil
	local stop_pagetext = nil
	local stop_automation_skiplink = nil
	function critical(e)
		errmsg = e
		critical_err = true
		error(e, 2)
	end
	function stop(e, pagetext, skiplink)
		if pagetext then
			stop_pagetext = pagetext
			if type(stop_pagetext) ~= "string" then
				stop_pagetext = stop_pagetext()
			end
			stop_automation_skiplink = skiplink
		end
		errmsg = e
		stopped_err = true
		error(e, 2)
	end
	local error_trace_steps = {}
	function reset_error_trace_steps()
		error_trace_steps = {}
	end
	function get_error_trace_steps()
		return error_trace_steps
	end
	function add_error_trace_step(msg)
		table.insert(error_trace_steps, tostring(msg))
	end

	local function add_charpane_refresh(pt)
		if not pt:contains("charpane.php") then
			if pt:contains("</head>") then
				pt = pt:gsub("</head>", [[
<script>top.charpane.location = "charpane.php"</script>
%0
]])
			else
				pt = [[<script>top.charpane.location = "charpane.php"</script>]] .. pt
			end
		end
		return pt
	end

	local ok, text, url = xpcall(f, function(e) return { msg = e, trace = debug.traceback(e) } end)
	if ok then
		if url == "json" then
			return text, resulturl
		end
		if not text:contains("<html") then
			text = [[
<html>
<head>
</head>
<body>
]] .. text .. [[
</body>
</html>
]]
		end
		text = add_charpane_refresh(text)
		return text, (url or resulturl)
	else
		local e = text
		if critical_err then
			print("Something unexpected happened: " .. errmsg)
			print(e.trace)
			result = get_result()
			if result == "??? No action found ???" or result == "??? No automation done ???" then
				result = [[<p style="color: darkorange">]] .. "Something unexpected happened: " .. errmsg .. "<br><br><pre>Technical details:\n\n" .. e.trace .. "</pre>"
			else
				result = add_message_to_page(result, "<pre>Something unexpected happened: " .. errmsg .. "</pre><br><br><pre>Technical details:\n\n" .. e.trace .. "</pre>", nil, "darkorange")
			end
			local steptrace = get_error_trace_steps()
			if next(steptrace) then
				result = add_message_to_page(get_result(), "While trying to do: <tt>" .. table.concat(get_error_trace_steps(), " &rarr; ") .. "</tt>" .. automation_skiplink, "Automation stopped:", "darkorange")
			elseif automation_skiplink ~= "" then
				result = add_message_to_page(get_result(), automation_skiplink, "Automation stopped:", "darkorange")
			end
			result = add_charpane_refresh(result)
			return result, requestpath
		elseif stopped_err then
			if errmsg:match("End of day.-then done") then -- TODO: redo this
				print("Finished: " .. errmsg)
				print(e.trace)
				result = "Finished: " .. errmsg
				result = add_charpane_refresh(result)
				return result, requestpath
			elseif stop_pagetext then
				result = stop_pagetext
				result = add_message_to_page(result, errmsg, "Ascension script:")
				if stop_automation_skiplink then
					result = add_message_to_page(result, stop_automation_skiplink, "Automation stopped:", "darkorange")
				end
				result = add_charpane_refresh(result)
				return result, requestpath
			else
				print("Manual intervention required: " .. errmsg)
				print(e.trace)
				local runagain_href = make_href("/kolproxy-automation-script", params)
				result = [[<script>top.charpane.location = "charpane.php"</script>Manual intervention required: ]] .. errmsg .. [[<br><br>Fix this and run the script again to continue automating.<br><br><a href="]]..runagain_href..[[" style="color: green" onclick="this.style.color = 'gray'">{ I have fixed it, run the script again now! }</a>]]
				local steptrace = get_error_trace_steps()
				if next(steptrace) then
					result = add_message_to_page(get_result(), "While trying to do: <tt>" .. table.concat(get_error_trace_steps(), " &rarr; ") .. "</tt>" .. automation_skiplink, "Automation stopped:", "darkorange")
				elseif automation_skiplink ~= "" then
					result = add_message_to_page(get_result(), automation_skiplink, "Automation stopped:", "darkorange")
				end
				result = add_charpane_refresh(result)
				return result, requestpath
			end
		else
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
automation_script_details_list["automate-suburbandis"] = { when = function() return ascension["suburbandis.defeated thing with no name"] ~= "yes" end, description = "Automate Suburban Dis quest" }
automation_script_details_list["castle-farming"] = { simple_link = "beanstalk.php", description = "Automate Castle meat farming (link to beanstalk)" }
--automation_script_details_list["lua-console"] = { simple = true, description = "Go to Lua console" }
automation_script_details_list["add-log-notes"] = { simple = true, description = "Add note to ascension log" }
automation_script_details_list["automate-aftercore-pulls"] = { simple = true, description = "Pull useful aftercore items from storage" }
automation_script_details_list["setup-ascension-automation"] = { simple = true, description = "Setup ascension automation script" }
automation_script_details_list["setup-aftercore-automation"] = { simple = true, description = "Setup aftercore automation" }
automation_script_details_list["custom-inventory-diff"] = { simple = true, description = "Show items found this session" }

automation_script_details_list["custom-cosmic-kitchen"] = { simple = true, description = "Cosmic kitchen dinner planner" }
automation_script_details_list["custom-choose-mad-tea-party-hat"] = { simple = true, description = "Choose hat for mad tea party" }
automation_script_details_list["custom-modifier-maximizer"] = { simple = true, description = "Modifier maximizer" }
automation_script_details_list["custom-quest-optimizer"] = { simple = true, description = "Quest optimizer (preview)" }
automation_script_details_list["custom-compute-net-worth"] = { simple = true, description = "Compute net worth" }
automation_script_details_list["display-tracked-variables"] = { simple = true, description = "Display tracked game variables (preview)" }
automation_script_details_list["custom-mix-drinks"] = { simple = true, description = "List advanced cocktails you can craft (preview)" }
automation_script_details_list["custom-ascension-checklist"] = { simple = true, description = "Pre-ascension checklist" }

function list_automation_scripts()
	local questlogcompleted_page = get_page("/questlog.php", { which = 2 })
	local accomplishments_page = get_page("/questlog.php", { which = 3 })
	function quest_completed(name)
		return questlogcompleted_page:contains([[<b>]] .. name .. [[</b>]])
	end
	function accomplishment_text(text)
		return accomplishments_page:contains(text)
	end

	local script_list = {}
	for x, f in pairs(get_automation_script_links()) do
		local tbl = automation_script_details_list[x]
		if tbl and tbl.description then
			if tbl.simple_link then
				script_list[x] = { category = "Automation", link = tbl.simple_link, description = tbl.description, details = tbl, f = f }
			elseif tbl.simple then
				script_list[x] = { category = "Information", link = [[kolproxy-automation-script?automation-script=]]..(tbl.name or x)..[[&pwd=]]..session.pwd, description = tbl.description, details = tbl, f = f }
			elseif (ascensionstatus("Aftercore") or tbl.can_automate_inrun) and tbl.when and tbl.when() then
				script_list[x] = { category = "Quests", link = [[kolproxy-automation-script?automation-script=]]..(tbl.name or x)..[[&pwd=]]..session.pwd, description = tbl.description, details = tbl, f = f }
			else
				script_list[x] = { category = "Quests", link = nil, description = tbl.description, details = tbl, f = f }
			end
		end
	end
	return script_list
end

custom_aftercore_automation_href = add_automation_script("custom-aftercore-automation", function()
	local category_priorities = { Quests = 1, Automation = 2, Information = 3 }
	local links = {}
	for x, y in pairs(list_automation_scripts()) do
		y.priority = category_priorities[y.category] or 1000
		table.insert(links, y)
	end
	table.sort(links, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		return a.description < b.description
	end)
	local lines = {}
	local header = nil
	for _, x in ipairs(links) do
		if header ~= x.category then
			table.insert(lines, string.format([[<h4>%s</h4>]], x.category))
			header = x.category
		end
		if x.link then
			table.insert(lines, string.format([[<a href="%s" style="color: green">%s</a><br>]], x.link, x.description))
		else
			table.insert(lines, string.format([[<span style="color: gray">%s</span><br>]], x.description))
		end
	end
	return make_kol_html_frame(table.concat(lines, "\n"), "Setup/run scripts")
end)

function maybe_pull_item(name, input_amount)
	local amount = input_amount or 1
	if count_item(name) < amount then
		local ptf = pull_storage_item(name, amount - count_item(name))
		if input_amount and count_item(name) < input_amount then
			stop("Couldn't pull " .. tostring(amount) .. "x " .. tostring(name), ptf)
		end
	end
end

function cast_autoattack_macro()
	local attid = status().flag_config.autoattack
	local macroid = attid:match("^99([0-9]+)$")
	if tonumber(macroid) then
		local pt, pturl = post_page("/fight.php", { action = "macro", macrotext = "", whichmacro = macroid })
		if not pt then print("DEBUG: cast_autoattack_macro() -> handle_adventure_result(nil)") end
		return handle_adventure_result(pt, pturl)
	else
		return result, resulturl, advagain
	end
end

result, resulturl = "?", "?"

function infoline(...)
	print("  " .. table.concat({ ... }, " "))
end

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
			stop "Unset your autoattack for running this script."
		elseif not tbl.macro and not autoattack_is_set() then
			stop "Set a macro on autoattack to use for running this script."
		end
		automation_macro = tbl.macro

		-- TODO: cache quest per pageload
		local questlog_page = nil
		function refresh_quest()
			questlog_page = get_page("/questlog.php", { which = 7 })
		end
		refresh_quest()

		function quest(name)
			return questlog_page:contains([[<b>]] .. name .. [[</b>]])
		end
		function quest_text(name)
			return questlog_page:contains(name)
		end

		function hidden_inform(msg)
			add_error_trace_step(msg)
		end

		function inform(msg)
			add_error_trace_step(msg)
			local mpstr = string.format("%s / %s MP", mp(), maxmp())
			if challenge == "zombie" then
				mpstr = string.format("%s horde", horde_size())
			end
			local formatted = string.format("[%s] %s (level %s.%02d, %s turns remaining, %s full, %s drunk, %s spleen, %s meat, %s / %s HP, %s)", turnsthisrun(), tostring(msg), level(), level_progress() * 100, advs(), fullness(), drunkenness(), spleen(), meat(), hp(), maxhp(), mpstr)
			print(formatted)
		end

		function infoline(...)
			local msg = table.concat({ ... }, " ")
			add_error_trace_step(msg)
			print("  " .. msg)
		end

		function __set_turnplaying_result(result_, resulturl_, advagain_)
			result, resulturl, advagain = result_, resulturl_, advagain_
		end

		if locked() then
			get_page("/main.php")
			if locked() then
				stop(string.format([[Currently locked in "%s" type adventure, finish that before automating.]], tostring(locked())))
			end
		end

		advagain = true
		while advagain and not locked() do
			advagain = false
			result, resulturl = nil, nil
			result, resulturl = "Automation failed", requestpath
			if advs() == 0 then
				stop "Out of adventures."
			end
			refresh_quest()
			if tbl.autoinform ~= false then
				inform(tbl.name)
			end
			reset_error_trace_steps()
			script.bonus_target {}
			tbl.adventuring()
		end
		return result, resulturl
	end)
end
