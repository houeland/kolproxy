function add_itemdrop_counter(name, f)
	add_printer("item drop: " .. name, function()
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

	local function get_zoneid(name)
		local zoneid = (datafile("zones")[name] or {}).zoneid
		if not zoneid then
			error("Unknown zone: " .. tostring(name))
		end
		return zoneid
	end

	function add_warning(tbl)
		check_supported_table_values(tbl, {}, { "message", "check", "severity", "zone" })
		local zoneid = get_zoneid(tbl.zone)
		local function f()
			if tonumber(params.snarfblat) == zoneid and tbl.check() then
				return tbl.message, tbl.zone .. "/" .. tbl.message
			end
		end
		if tbl.severity == "extra" then
			localtable.insert(__raw_extra_adventure_warnings, f)
			__raw_add_extra_warning("/adventure.php", f)
		elseif tbl.severity == "warning" then
			localtable.insert(__raw_adventure_warnings, f)
			__raw_add_warning("/adventure.php", f)
		end
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
	check_supported_table_values(tbl, { "ignorewarnings", "noncombatchoices", "specialnoncombatfunction" }, { "zoneid", "macro" })
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

function get_resistance_levels()
	local charpage = get_page("/charsheet.php")
	local elements = {
		cold = "Cold",
		hot = "Hot",
		sleaze = "Sleaze",
		spooky = "Spooky",
		stench = "Stench",
	}
	local resists = {}
	for x, y in pairs(elements) do
		resists[x] = tonumber(charpage:match([[<td align=right>]]..y..[[ Protection:</td><td><b>[^>()]+%(([0-9]+)%)</b></td>]]))
	end
	return resists
end

function elemental_resist_level_multiplier(level)
	local myst_resist = 0
	if get_mainstat() == "Mysticality" then
		myst_resist = 5
	end
	if level <= 3 then
		return 1 - (level * 10 + myst_resist) / 100
	else
		return 1 - (90 - (50 * ((5 / 6) ^ (level - 4))) + myst_resist) / 100
	end
end

function check_supported_table_values(tbl, optional, mandatory)
	if true then return true end
	optional = optional or {}
	mandatory = mandatory or {}
	local ok_keys = {}
	for _, x in ipairs(optional) do
		ok_keys[x] = true
	end
	for _, x in ipairs(mandatory) do
		ok_keys[x] = true
		if not tbl[x] then
--			if playername() == "Eleron" then print("DEBUG: missing mandatory param", x) end
--			error("Missing mandatory table parameter value: " .. tostring(x))
		end
	end
	for x, _ in pairs(tbl) do
		if not ok_keys[x] then
--			if playername() == "Eleron" then print("DEBUG: unsupported param", x, tbl[x]) end
--			error("Unsupported table parameter value: " .. tostring(x))
		end
	end
end

local resistphials = {
	cold = { resistform = "Coldform", doubledmgform1 = "Sleazeform", doubledmgform2 = "Stenchform" },
	hot = { resistform = "Hotform", doubledmgform1 = "Spookyform", doubledmgform2 = "Coldform" },
	sleaze = { resistform = "Sleazeform", doubledmgform1 = "Stenchform", doubledmgform2 = "Hotform" },
	spooky = { resistform = "Spookyform", doubledmgform1 = "Coldform", doubledmgform2 = "Sleazeform" },
	stench = { resistform = "Stenchform", doubledmgform1 = "Hotform", doubledmgform2 = "Spookyform" },
}

function estimate_damage(tbl)
	check_supported_table_values(tbl, { "cold", "hot", "sleaze", "spooky", "stench", "__resistance_levels" })
	local resists = tbl.__resistance_levels or get_resistance_levels()
	local dmg = {}
	for _, dmgtype in ipairs { "cold", "hot", "sleaze", "spooky", "stench" } do
		if tbl[dmgtype] then
			local formmult = 1
			if have_buff(resistphials[dmgtype].resistform) then
				formmult = 0
			elseif have_buff(resistphials[dmgtype].doubledmgform1) or have_buff(resistphials[dmgtype].doubledmgform2) then
				formmult = 2
			end
			dmg[dmgtype] = math.max(1, tbl[dmgtype] * formmult * elemental_resist_level_multiplier(resists[dmgtype] or 0))
		end
	end
	return dmg
end

function table_apply_function(tbl, f)
	local ret = {}
	for x, y in pairs(tbl) do
		ret[x] = f(y)
	end
	return ret
end

local resistcolors = {
	cold = "blue",
	hot = "red",
	sleaze = "blueviolet",
	spooky = "gray",
	stench = "green",
}

function markup_damagetext(tbl)
	check_supported_table_values(tbl, { "cold", "hot", "sleaze", "spooky", "stench" })
	local dmgtext = {}
	for x, y in pairs(tbl) do
		dmgtext[x] = [[<b style="color: ]]..resistcolors[x]..[[">]]..y..[[</b>]]
	end
	return dmgtext
end

function estimate_max_fullness()
	if ascensionpathname() == "Boozetafarian" or ascensionpathname() == "Oxygenarian" then
		return 0
	end
	local mf = 15
	if ascensionpathid() == 8 then
		mf = 20
	elseif ascensionpath("Avatar of Jarlsberg") then
		mf = 10
	end
	if have_skill("Stomach of Steel") then
		mf = mf + 5
	end
	if have_skill("Legendary Appetite") then
		mf = mf + 5
	end
	if have_skill("Insatiable Hunger") then
		mf = mf + 5
	end
	if have_skill("Ravenous Pounce") then
		mf = mf + 5
	end
	if have_skill("Lunch Like a King") then
		mf = mf + 5
	end
	if have_skill("Gluttony") then
		mf = mf + 2
	end
	if have_skill("Pride") then
		mf = mf - 1
	end
	if session["active feast of boris bonus fullness today"] == "yes" then
		mf = mf + 15
	end
	return mf
end

function estimate_max_safe_drunkenness()
	if ascensionpathname() == "Teetotaler" or ascensionpathname() == "Oxygenarian" then
		return 0
	end
	local dlimit = 15
	if ascensionpathid() == 8 or ascensionpathid() == 10 then
		dlimit = 5
	elseif ascensionpath("Avatar of Jarlsberg") then
		dlimit = 10
	end

	if have_skill("Liver of Steel") then
		dlimit = dlimit + 5
	end
	if have_skill("Nightcap") then
		dlimit = dlimit + 5
	end

	return dlimit - 1
end

function estimate_max_spleen()
	local ms = 15
	if have_skill("Spleen of Steel") then
		ms = ms + 5
	end
	return ms
end

function spleen_display_string()
	print("WARNING: spleen_display_string is no longer needed and deprecated, use spleen()!")
	return spleen()
end

function remaining_spleen_display_string()
	print("WARNING: remaining_spleen_display_string is no longer needed and deprecated, use spleen() and estimate_max_spleen()!")
	return estimate_max_spleen() - spleen()
end

function estimate_mallbuy_cost(item)
	return datafile("mallprices")[maybe_get_itemname(item)]
end

function estimate_mallsell_profit(item)
	local buyprice = estimate_mallbuy_cost(item)
	if buyprice then
		return buyprice * 0.85
	end
end

function can_equip_item(item)
	-- TODO: boris/fist
	local name = maybe_get_itemname(item)
	if not name then return true end
	local eqreqs = datafile("items")[name].equip_requirement or {}
	for a, b in pairs(eqreqs) do
		if a == "muscle" and basemuscle() < b then
			return false
		elseif a == "mysticality" and basemysticality() < b then
			return false
		elseif a == "moxie" and basemoxie() < b then
			return false
		end
	end
	return true
end

function estimate_basement_level()
	-- TODO: Implement, processor that sets session[...]
end
