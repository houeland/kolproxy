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
				return intercept_warning { message = message, id = warningid, customdisablemsg = custommsg, customdisablecolor = customdisablecolor or "green", customwarningprefix = customwarningprefix or "Reminder: " }
			end
		end)
	end

	function __raw_add_notice(filename, f)
		add_interceptor(filename, function()
			if not setting_enabled("enable adventure warnings") then return end
			if not setting_enabled("show extra warnings") then return end
			if not setting_enabled("show extra notices") then return end
			local message, warningid, custommsg, customdisablecolor, customwarningprefix = f()
			if message then
				return intercept_warning { message = message, id = warningid, customdisablemsg = custommsg, customdisablecolor = customdisablecolor or "rgb(91, 203, 121)", customwarningprefix = customwarningprefix or "Notice: " }
			end
		end)
	end

	local __raw_adventure_warnings = {}
	local __raw_extra_adventure_warnings = {}
	local __raw_adventure_notices = {}
	function get_raw_adventure_warnings()
		return __raw_adventure_warnings, __raw_extra_adventure_warnings, __raw_adventure_notices
	end

	local function add_warning_internal(warntype, path, f)
		if type(path) ~= "table" then
			path = { path }
		end
		if warntype == "extra" then
			-- TODO: redo these local tables with warnings, at least give them paths, or preferably reuse normal stuff
			for _, p in ipairs(path) do
				if p == "/adventure.php" then
					localtable.insert(__raw_extra_adventure_warnings, f)
				end
				__raw_add_extra_warning(p, f)
			end
		elseif warntype == "warning" then
			for _, p in ipairs(path) do
				if p == "/adventure.php" then
					localtable.insert(__raw_adventure_warnings, f)
				end
				__raw_add_warning(p, f)
			end
		elseif warntype == "notice" then
			for _, p in ipairs(path) do
				if p == "/adventure.php" then
					localtable.insert(__raw_adventure_notices, f)
				end
				__raw_add_notice(p, f)
			end
		else
			error("Invalid warning severity: " .. tostring(warntype))
		end
	end

	function add_ascension_warning(filename, f)
		add_warning_internal("warning", filename, function()
			if ascensionstatus("Aftercore") then return end
			return f()
		end)
	end

	function add_extra_ascension_warning(filename, f)
		add_warning_internal("extra", filename, function()
			if ascensionstatus("Aftercore") then return end
			return f()
		end)
	end

	function add_aftercore_warning(filename, f)
		add_warning_internal("warning", filename, function()
			if not ascensionstatus("Aftercore") then return end
			return f()
		end)
	end

	function add_always_warning(filename, f)
		add_warning_internal("warning", filename, function()
			return f()
		end)
	end

	function add_extra_always_warning(filename, f)
		add_warning_internal("extra", filename, function()
			return f()
		end)
	end

	local function add_raw_adventure_warning(f)
		localtable.insert(__raw_adventure_warnings, f)
		__raw_add_warning("/adventure.php", function()
			return f(requested_zone_id())
		end)
		__raw_add_warning("/mining.php", function()
			return f("mining")
		end)
		__raw_add_warning("/cellar.php", function()
			return f("cellar")
		end)
		__raw_add_warning("/place.php", function()
			if params.action then
				return f(params.whichplace or "place")
			end
		end)
	end

	local function add_raw_extra_adventure_warning(f)
		localtable.insert(__raw_extra_adventure_warnings, f)
		__raw_add_extra_warning("/adventure.php", function()
			return f(requested_zone_id())
		end)
		__raw_add_extra_warning("/mining.php", function()
			return f("mining")
		end)
		__raw_add_extra_warning("/cellar.php", function()
			return f("cellar")
		end)
		__raw_add_extra_warning("/place.php", function()
			if params.action then
				return f(params.whichplace or "place")
			end
		end)
	end

	function add_ascension_adventure_warning(f)
		add_raw_adventure_warning(function(...)
			if ascensionstatus("Aftercore") then return end
			return f(...)
		end)
	end

	function add_extra_ascension_adventure_warning(f)
		add_raw_extra_adventure_warning(function(...)
			if ascensionstatus("Aftercore") then return end
			return f(...)
		end)
	end

	function add_aftercore_adventure_warning(f)
		add_raw_adventure_warning(function(...)
			if not ascensionstatus("Aftercore") then return end
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
				local xidx = #__zone_checks[zoneid_to_check]
				return x, "zonecheck-" .. zoneid_to_check .. "-" .. xidx
			end
		end)
	end

	function add_ascension_zone_check(zid, f)
		raw_add_zone_check(zid, function(...)
			if ascensionstatus("Aftercore") then return end
			return f(...)
		end)
	end

	function add_aftercore_zone_check(zid, f)
		raw_add_zone_check(zid, function(...)
			if not ascensionstatus("Aftercore") then return end
			return f(...)
		end)
	end

	function add_always_zone_check(zid, f)
		raw_add_zone_check(zid, f)
	end

	function add_warning(tbl)
		-- TODO: deprecate some of these
		check_supported_table_values(tbl, {}, { "message", "check", "severity", "zone", "when", "idgenerator", "path", "whichplace" })
		local warnprefix = "everywhere"
		local want_zoneids = nil
		if tbl.zone then
			if type(tbl.zone) == "string" then
				tbl.zone = { tbl.zone }
			end
			warnprefix = table.concat(tbl.zone, ",")
			want_zoneids = {}
			for _, z in ipairs(tbl.zone) do
				want_zoneids[get_zoneid(z)] = true
			end
		end
		local path = nil
		if tbl.whichplace then
			path = { "/place.php" }
		elseif tbl.path then
			path = tbl.path
		else
			path = { "/adventure.php", "/mining.php", "/cellar.php", "/place.php" }
		end
		local function f()
			if tbl.when == "ascension" and finished_mainquest() then return end
			if not tbl.path and requestpath == "/place.php" and not params.action then return end
			if tbl.whichplace and params.whichplace ~= tbl.whichplace then return end
			local zoneid = requested_zone_id()
			if want_zoneids and not want_zoneids[zoneid] then return end
			local msg = tbl.message
			local warnid = warnprefix .. "/" .. msg
			if msg ~= "custom" and session["warning-" .. warnid] then return end
			local check, checkid = tbl.check(zoneid)
			if check then
				if msg == "custom" and type(check) == "string" then
					msg = check
					warnid = checkid
				end
				if tbl.idgenerator then
					warnid = warnid .. "#" .. tbl.idgenerator()
				end
				return msg, warnid
			end
		end
		add_warning_internal(tbl.type, path, f)
	end

	local added_automation_handler = false
	local automation_scripts = {}

	function get_automation_script_links()
		return automation_scripts
	end

	function add_automation_script(x, f)
		if not added_automation_handler then
			add_interceptor("/kolproxy-automation-script", function()
				-- TODO: Deprecate in favor of kolproxy-script
				local scriptname = params["automation-script"]
				if not scriptname or params.pwd ~= localsession.pwd then
					error("Error: Invalid settings when running automation script")
				end
				if automation_scripts[scriptname] then
					return run_automation_script(automation_scripts[scriptname], params.pwd, scriptname)
				else
					error("Error: Automation script not found")
				end
			end)
			add_interceptor("/kolproxy-script", function()
				local scriptname = params["scriptname"]
				if not scriptname or params.pwd ~= localsession.pwd then
					error("Error: Invalid settings when running script")
				end
				if automation_scripts[scriptname] then
					return run_automation_script(automation_scripts[scriptname], params.pwd, scriptname)
				else
					error("Error: Kolproxy script not found")
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
			elseif tbl.ahref_description then
				local desc = tbl.ahref_description
				tbl.ahref_description = nil
				tbl.pwd = session.pwd
				return string.format([[<a href="%s" style="color: green" onclick="this.style.color = 'gray'">{ %s }</a>]], localmake_href("/kolproxy-automation-script", tbl), desc)
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
	return add_custom_chat_redirect(cmd, msg, function()
		return make_href(href, hrefparams)
	end)
end

function add_custom_chat_redirect(cmd, msg, f)
	add_chat_trigger(cmd, function(line)
		return [[<span style="color: green">{ ]] .. msg .. [[ }</span><!--js(top.mainpane.location.href=']] .. f(line) .. [[')-->]]
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
		return f(params.line)
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

function get_element_names()
	return { "Cold", "Hot", "Sleaze", "Spooky", "Stench" }
end

function get_resistance_levels()
	local charpage = get_page("/charsheet.php")
	local resists = {}
	for _, x in pairs(get_element_names()) do
		resists[x] = tonumber(charpage:match([[<td align=right>]]..x..[[ Protection:</td><td><b>[^>()]+%(([0-9]+)%)</b></td>]])) or 0
	end
	return resists
end

function get_resistance_level(elem)
	return get_resistance_levels()[elem]
end

function get_lowest_resistance_level()
	local resists = get_resistance_levels()
	return math.min(resists.Cold, resists.Hot, resists.Sleaze, resists.Spooky, resists.Stench)
end

function get_elemental_weaknesses(element)
	if element == "Cold" then
		return "Hot", "Spooky"
	elseif element == "Hot" then
		return "Sleaze", "Stench"
	elseif element == "Sleaze" then
		return "Spooky", "Cold"
	elseif element == "Spooky" then
		return "Stench", "Hot"
	elseif element == "Stench" then
		return "Cold", "Sleaze"
	end
end

function elemental_resist_level_multiplier(level)
	local myst_resist = 0
	if mainstat_type("Mysticality") then
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
			print("DEBUG: missing mandatory param", x)
--			error("Missing mandatory table parameter value: " .. tostring(x))
		end
	end
	for x, _ in pairs(tbl) do
		if not ok_keys[x] then
			print("DEBUG: unsupported param", x, tbl[x])
--			error("Unsupported table parameter value: " .. tostring(x))
		end
	end
end

function estimate_damage(tbl)
	check_supported_table_values(tbl, { "Cold", "Hot", "Sleaze", "Spooky", "Stench", "__resistance_levels" })
	local resists = tbl.__resistance_levels or get_resistance_levels()
	local dmg = {}
	for _, dmgtype in pairs(get_element_names()) do
		if tbl[dmgtype] then
			local formmult = 1
			for _, testtype in pairs(get_element_names()) do
				local a, b = get_elemental_weaknesses(testtype)
				if (a == dmgtype or b == dmgtype) and have_buff(testtype .. "form") then
					formmult = 2
				end
			end
			if have_buff(dmgtype .. "form") then
				formmult = 0
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

local element_color_lookup = {
	Hot = "red",
	Cold = "blue",
	Spooky = "gray",
	Stench = "green",
	Sleaze = "blueviolet",
}

function element_color(x)
	return element_color_lookup[x]
end

function markup_damagetext(tbl)
	check_supported_table_values(tbl, get_element_names())
	local dmgtext = {}
	for x, y in pairs(tbl) do
		dmgtext[x] = [[<b style="color: ]]..(element_color(x) or "black")..[[">]]..y..[[</b>]]
	end
	return dmgtext
end

function estimate_max_fullness()
	if ascensionpath("Boozetafarian") or ascensionpath("Oxygenarian") then
		return 0
	end
	local mf = 15
	if ascensionpath("Avatar of Boris") then
		mf = 20
	elseif ascensionpath("Avatar of Jarlsberg") then
		mf = 10
	elseif ascensionpath("Avatar of Sneaky Pete") then
		mf = 5
	elseif ascensionpath("Actually Ed the Undying") then
		mf = 0
	end
	local stomach_skills = {
		["Stomach of Steel"] = 5,
		["Legendary Appetite"] = 5,
		["Insatiable Hunger"] = 5,
		["Ravenous Pounce"] = 5,
		["Lunch Like a King"] = 5,
		["Gluttony"] = 2,
		["Pride"] = -1,
		["Replacement Stomach"] = 5,
	}
	for skill, amount in pairs(stomach_skills) do
		if have_skill(skill) then
			mf = mf + amount
		end
	end
	if session["active feast of boris bonus fullness today"] == "yes" then
		mf = mf + 15
	end
	if day["item.distention pill.used today"] then
		mf = mf + 1
	end
	mf = mf + get_daily_counter("pantsgiving bonus fullness")
	return mf
end

function estimate_max_safe_drunkenness()
	if ascensionpath("Teetotaler") or ascensionpath("Oxygenarian") then
		return 0
	end
	local dlimit = 15
	if ascensionpath("Avatar of Boris") or ascensionpath("Zombie Slayer") then
		dlimit = 5
	elseif ascensionpath("Avatar of Jarlsberg") then
		dlimit = 10
	elseif ascensionpath("Avatar of Sneaky Pete") then
		dlimit = 20
	elseif ascensionpath("Actually Ed the Undying") then
		dlimit = 0
	end

	local liver_skills = {
		["Liver of Steel"] = 5,
		["Nightcap"] = 5,
		["Hard Drinker"] = 10,
		["Hollow Leg"] = 1,
		["Replacement Liver"] = 5,
	}
	for skill, amount in pairs(liver_skills) do
		if have_skill(skill) then
			dlimit = dlimit + amount
		end
	end

	return math.max(0, dlimit - 1)
end

function estimate_max_spleen()
	local ms = 15
	if ascensionpath("Actually Ed the Undying") then
		ms = 5
	end
	local spleen_skills = {
		["Spleen of Steel"] = 5,
		["Extra Spleen"] = 5,
		["Another Extra Spleen"] = 5,
		["Yet Another Extra Spleen"] = 5,
		["Still Another Extra Spleen"] = 5,
		["Just One More Extra Spleen"] = 5,
		["Okay Seriously, This is the Last Spleen"] = 5,
	}
	for skill, amount in pairs(spleen_skills) do
		if have_skill(skill) then
			ms = ms + amount
		end
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

function estimate_mallbuy_cost(item, amount)
	amount = amount or 1
	if amount < 0 then
		return -estimate_mallsell_profit(item, -amount)
	end
	local d = datafile("mallprices")[maybe_get_itemname(item)] or {}
	if type(d) ~= "table" and tonumber(d) then return tonumber(d) * amount end -- TODO: support for old datafile, remove in a future version
	local function try(num)
		--print("try", item, num)
		local c = d["buy "..num]
		if c and num <= amount then
			local c10 = try(num * 10)
			if not c10 then
				return c
			elseif c10 >= c * 10 then
				return c * 10
			else
				return c10
			end
		end
	end
	local c = try(1)
	if c then
		return c * amount
	end
end

function estimate_mallsell_profit(item, amount)
	amount = amount or 1
	local buytenprice = estimate_mallbuy_cost(item, 10)
	if buytenprice then
		return buytenprice / 10 * 0.85 * amount
	end
end

function can_equip_chefstaves()
	if have_skill("Spirit of Rigatoni") then
		return true
	elseif playerclass("Sauceror") and have_equipped_item("special sauce glove") then
		return true
	elseif playerclass("Avatar of Jarlsberg") then
		return true
	else
		return false
	end
end

function can_equip_item(item)
	local itemdata = maybe_get_itemdata(item)
	if not itemdata then return true end
	local name = get_itemname(item)
	for a, b in pairs(itemdata.equip_requirements or {}) do
		if a == "Muscle" and basemuscle() < b then
			return false
		elseif a == "Mysticality" and basemysticality() < b then
			return false
		elseif a == "Moxie" and basemoxie() < b then
			return false
		end
	end
	if not playerclass("Accordion Thief") and itemdata.song_duration then
		if name ~= "toy accordion" and name ~= "antique accordion" then
			return false
		end
	end
	if name == "Trusty" then
	elseif (itemdata.equipment_slot == "weapon" or itemdata.equipment_slot == "offhand") and not can_wear_weapons() then
		return false
	end
	if itemdata.equipment_slot == "shirt" and not have_skill("Torso Awaregness") then
		return false
	end
	if itemdata.equipment_slot == "weapon" and (itemdata.weapon_type or ""):contains("chefstaff") and not can_equip_chefstaves() then
		return false
	end
	if itemdata.class and not playerclass(itemdata.class) then
		return false
	end
	return true
end

function estimate_basement_level()
	-- TODO: Implement, processor that sets session[...]
end

function take_stash_item(item)
	return async_post_page("/clan_stash.php", { pwd = session.pwd, action = "takegoodies", quantity = 1, whichitem = get_itemid(item) })
end

function add_stash_item(item)
	return async_post_page("/clan_stash.php", { pwd = session.pwd, action = "addgoodies", qty1 = 1, item1 = get_itemid(item) })
end

function can_wear_weapons()
	return not ascensionpath("Avatar of Boris") and not ascensionpath("Way of the Surprising Fist")
end

function can_eat_normal_food()
	return not ascensionpath("Avatar of Jarlsberg") and not ascensionpath("Zombie Slayer")
end

function can_drink_normal_booze()
	return not ascensionpath("Avatar of Jarlsberg") and not ascensionpath("KOLHS")
end

-- TODO: make this work with being in scope when loaded in paths/sneaky pete file
function sneaky_pete_motorcycle_upgrades()
	return session["sneaky pete motorcycle upgrades"] or {}
end

function have_unlocked_beach()
	-- TODO: Load page and check instead? When would it invalidate cached result?
	if ascensionpath("Avatar of Sneaky Pete") and sneaky_pete_motorcycle_upgrades()["Gas Tank"] == "Large Capacity Tank" then return true end
	if ascensionpath("Actually Ed the Undying") then return true end
	return have_item("bitchin' meatcar") or have_item("Desert Bus pass") or have_item("pumpkin carriage") or have_item("tin lizzie")
end
unlocked_beach = have_unlocked_beach

function have_unlocked_island()
	if ascensionpath("Avatar of Sneaky Pete") and sneaky_pete_motorcycle_upgrades()["Gas Tank"] == "Extra-Buoyant Tank" then return true end
	return have_item("dingy dinghy") or have_item("skeletal skiff") or have_item("junk junk")
end
unlocked_island = have_unlocked_island

local AT_accordions = nil
function AT_song_duration()
	if playerclass("Accordion Thief") then
		if not AT_accordions then
			AT_accordions = {}
			for a, b in pairs(datafile("items")) do
				if b.song_duration then
					table.insert(AT_accordions, { name = a, song_duration = b.song_duration })
				end
			end
			table.sort(AT_accordions, function(a, b) return a.song_duration > b.song_duration end)
		end
		--print(tostring(AT_accordions))
		for _, x in ipairs(AT_accordions) do
			if have_item(x.name) then
				return x.song_duration
			end
		end
	elseif have_item("antique accordion") then
		return 10
	elseif have_item("toy accordion") then
		return 5
	end
	return 0
end

function is_twohanded_weapon(item)
	local data = maybe_get_itemdata(item)
	local hands = (data or {}).weapon_hands or 0
	return hands >= 2
end

function requested_zone_id()
	return tonumber(params.whichzone) or tonumber(params.snarfblat)
end
