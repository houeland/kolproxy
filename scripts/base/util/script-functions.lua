function add_itemdrop_counter(name, f)
	add_printer("item drop: " .. name, function ()
		local c = count_item(item_name)
		local msg = f(c)
		if msg then
			text = text .. [[<center style="color: green">]] .. msg .. [[</center>]]
		end
	end)
end

function fairy_bonus(lb)
	return math.sqrt(55.0 * lb) + lb - 3
end

do
	local localtable = table
	local localsession = session
	local localmake_href = make_href

	-- TODO: Find a way to remove the function environment setting hack and make these functions local
	-- TODO: check all the normal ones before any extra ones
	function __raw_add_warning(filename, f)
		add_interceptor(filename, function()
			if not setting_enabled("enable adventure warnings") then return end
			local message, warningid, custommsg, customdisablecolor, customwarningprefix = f()
			if message then
				return intercept_warning { message = message, id = warningid, customdisablemsg = custommsg, customdisablecolor = customdisablecolor, customwarningprefix = customwarningprefix }
			end
		end)
	end

	function __raw_add_extra_warning(filename, f)
		add_interceptor(filename, function()
			if not setting_enabled("enable adventure warnings") then return end
			if not setting_enabled("show extra warnings") then return end
			local message, warningid, custommsg, customdisablecolor, customwarningprefix = f()
			if message then
				return intercept_warning { message = message, id = warningid, customdisablemsg = custommsg, customdisablecolor = customdisablecolor or "green", customwarningprefix = customwarningprefix or "Consider: " }
			end
		end)
	end

	function add_ascension_warning(filename, f)
		if filename == "/adventure.php" then error("Use add_ascension_adventure_warning instead of warning on /adventure.php") end
		__raw_add_warning(filename, function()
			if ascensionstatus() == "Aftercore" then return end
			return f()
		end)
	end

	function add_extra_ascension_warning(filename, f)
		if filename == "/adventure.php" then error("Use add_extra_ascension_adventure_warning instead of warning on /adventure.php") end
		__raw_add_extra_warning(filename, function()
			if ascensionstatus() == "Aftercore" then return end
			return f()
		end)
	end

	function add_aftercore_warning(filename, f)
		if filename == "/adventure.php" then error("Use add_aftercore_adventure_warning instead of warning on /adventure.php") end
		__raw_add_warning(filename, function()
			if ascensionstatus() ~= "Aftercore" then return end
			return f()
		end)
	end

	function add_always_warning(filename, f)
		if filename == "/adventure.php" then error("Use add_always_adventure_warning instead of warning on /adventure.php") end
		__raw_add_warning(filename, function()
			return f()
		end)
	end

	function add_extra_always_warning(filename, f)
		if filename == "/adventure.php" then error("Use add_extra_always_adventure_warning instead of warning on /adventure.php") end
		__raw_add_extra_warning(filename, function()
			if not setting_enabled("show extra warnings") then return end
			return f()
		end)
	end

	local __raw_adventure_warnings = {}
	local __raw_extra_adventure_warnings = {}
	function get_raw_adventure_warnings()
		return __raw_adventure_warnings, __raw_extra_adventure_warnings
	end
	local function add_raw_adventure_warning(f)
		localtable.insert(__raw_adventure_warnings, f)
		__raw_add_warning("/adventure.php", function()
			return f(tonumber(params.snarfblat))
		end)
		__raw_add_warning("/hiddencity.php", function()
			if params.which then
				return f()
			end
		end)
	end

	local function add_raw_extra_adventure_warning(f)
		localtable.insert(__raw_extra_adventure_warnings, f)
		__raw_add_extra_warning("/adventure.php", function()
			return f(tonumber(params.snarfblat))
		end)
		__raw_add_extra_warning("/hiddencity.php", function()
			if params.which == nil then return end
			return f()
		end)
	end

	function add_ascension_adventure_warning(f)
		add_raw_adventure_warning(function(...)
			if ascensionstatus() == "Aftercore" then return end
			return f(...)
		end)
	end

	function add_extra_ascension_adventure_warning(f)
		add_raw_extra_adventure_warning(function(...)
			if ascensionstatus() == "Aftercore" then return end
			return f(...)
		end)
	end

	function add_aftercore_adventure_warning(f)
		add_raw_adventure_warning(function(...)
			if ascensionstatus() ~= "Aftercore" then return end
			return f(...)
		end)
	end

	function add_always_adventure_warning(f)
		add_raw_adventure_warning(f)
	end

	function add_extra_always_adventure_warning(f)
		add_raw_extra_adventure_warning(f)
	end

	local __zone_checks = {}
	local function raw_add_zone_check(zoneid_to_check, checkfunc)
		if not __zone_checks[zoneid_to_check] then __zone_checks[zoneid_to_check] = {} end
		localtable.insert(__zone_checks[zoneid_to_check], checkfunc)
		add_always_adventure_warning(function(adv_zoneid)
			if zoneid_to_check ~= adv_zoneid then return end
			local x = checkfunc()
			if x then
				local xidx = table.maxn(__zone_checks[zoneid_to_check])
				return x, "zonecheck-" .. zoneid_to_check .. "-" .. xidx
			end
		end)
	end

	function add_ascension_zone_check(zid, f)
		raw_add_zone_check(zid, function(...)
			if ascensionstatus() == "Aftercore" then return end
			return f(...)
		end)
	end

	function add_aftercore_zone_check(zid, f)
		raw_add_zone_check(zid, function(...)
			if ascensionstatus() ~= "Aftercore" then return end
			return f(...)
		end)
	end

	function add_always_zone_check(zid, f)
		raw_add_zone_check(zid, f)
	end

	local added_automation_handler = false
	local automation_scripts = {}

	function get_automation_script_links()
		return automation_scripts
	end

	function add_automation_script(x, f)
		if not added_automation_handler then
			add_interceptor("/kolproxy-automation-script", function()
				local scriptname = params["automation-script"]
				if not scriptname or params.pwd ~= localsession.pwd then
					error "Error: Invalid settings when running automation script"
				end
				if automation_scripts[scriptname] then
					return run_automation_script(automation_scripts[scriptname], params.pwd, scriptname)
				else
					error "Error: Automation script not found"
				end
			end)
			added_automation_handler = true
		end
		automation_scripts[x] = f
		return function(tbl)
			tbl["automation-script"] = x
			if tbl.make_jquery then
				local extra_params = tbl.make_jquery
				tbl.make_jquery = nil
				local data = {}
				for a, b in pairs(tbl) do
					a = tostring(a)
					local rawname = a:match("__raw__(.+)")
					if rawname then
						table.insert(data, "'" .. rawname .. "': " .. tostring(b))
					else
						table.insert(data, "'" .. a .. "': '" .. tostring(b) .. "'")
					end
				end
				local ret = [[$.ajax({ url: '/kolproxy-automation-script', cache: false, data: { ]]..table.concat(data, ", ")..[[ }, global: false, ]]..extra_params..[[ })]]
				return ret
			else
				return localmake_href("/kolproxy-automation-script", tbl)
			end
		end
	end
end


function set_ascension_turn_counter(name, length)
	local tbl = ascension["turn counters"] or {}
	table.insert(tbl, { name = name, turn = turnsthisrun(), length = length })
	ascension["turn counters"] = tbl
end

function add_chat_redirect(cmd, msg, href, hrefparams)
	add_chat_trigger(cmd, function()
		return [[<span style="color: green">{ ]] .. msg .. [[ }</span><!--js(top.mainpane.location.href=']] .. make_href(href, hrefparams) .. [[')-->]]
	end)
end

function add_raw_chat_script_redirect(cmd, msg, f)
	add_automation_script("custom-chat-command-" .. cmd, function()
		return f(params.line)
	end)
	add_chat_trigger(cmd, function(line)
		return [[<span style="color: green">{ ]] .. msg .. [[ }</span><!--js(top.mainpane.location.href=']] .. make_href("/kolproxy-automation-script", { ["automation-script"] = "custom-chat-command-" .. cmd, pwd = sendchat_pwd, line = line }) .. [[')-->]]
	end)
end

function add_chat_command(cmd, msg, f)
	add_automation_script("custom-chat-command-" .. cmd, function()
		return make_kol_html_frame(f(params.line)), requestpath
	end)
	add_chat_trigger(cmd, function(line)
		return [[<span style="color: green">{ ]] .. msg .. [[ }</span><!--js(dojax(']] .. make_href("/kolproxy-automation-script", { ["automation-script"] = "custom-chat-command-" .. cmd, pwd = sendchat_pwd, line = line }) .. [[');)--><br>]]
	end)
end


function add_chat_alias(newcmd, realcmd)
	add_chat_trigger(newcmd, function(line)
		return sendchat_run_command_raw(realcmd, line)
	end)
end

function autoadventure(tbl)
-- 	if not tbl.ignorewarnings and setting_enabled("enable adventure warnings") then
	if not tbl.ignorewarnings and character["setting: enable adventure warnings"] ~= "no" then
		local foo = { kolproxy_log_time_interval("check adv warnings", function()
			local warn_tbl = get_raw_adventure_warnings()
-- 			print("warn_tbl is", warn_tbl)
			for f in table.values(warn_tbl) do
				local message, warningid, custommsg = f(tbl.zoneid)
				if message then
					print("advwarn?", f, message, warningid)
					local x, y = intercept_warning { message = message, id = warningid, customdisablemsg = custommsg, norepeat = true }
					if x then
-- 								print("  warn!", x, y, "...")
						return x, y, false
					end
				end
			end
		end) }
		if foo[1] then
			return unpack(foo)
		end
	end
	session["adventure.lastzone"] = tbl.zoneid
	local pt, url = post_page("/adventure.php", { snarfblat = tbl.zoneid })
	return handle_adventure_result(pt, url, tbl.zoneid, tbl.macro, tbl.noncombatchoices or {}, tbl.specialnoncombatfunction)
end
