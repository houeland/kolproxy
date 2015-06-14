function show_dev_info()
	return get_current_kolproxy_version():contains("dev")
end

function raw_async_submit_page(rqtype, rqpath, rqparams)
	local f = kolproxycore_async_submit_page(rqtype, rqpath, rqparams)
	return function()
		local a, b, c = f()
		if a then
			return a, b
		else
			error("Error downloading page " .. tostring(rqpath) .. ":<br><br>" .. tostring(b))
		end
	end
end

function intercept_warning(warning)
	if not warning.id then
		error "No warning id!"
	end
	local warningid = warning.id:gsub("'", "")
	if session["warning-" .. warningid] then return end
	if session["warning-turn-" .. turnsthisrun() .. "-" .. warningid] then return end
	local head = [[<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script>top.charpane.location = "charpane.php"</script>]]
	local extratext = ""
	if not warning.norepeat and not warning.customaction then
		extratext = [[<p><a href="]]..make_resubmit_href()..[[">I fixed it, try again.</a></p>]]
	elseif warning.customaction then
		extratext = [[<p>{ ]] .. warning.customaction .. [[ }</p>]]
	end
	-- TODO: Use POST is original request was POST
	local session_disable_msg = [[<p><small><a href="#" onclick="var link = this; $.post('custom-settings', { pwd: ']] .. session.pwd .. [[', action: 'set state', name: 'warning-]] .. warningid .. [[', stateset: 'session', value: 'true', ajax: 1 }, function(res) { link.style.color = 'gray'; link.innerHTML = '(Disabled, trying again...)'; location.href = ']]..make_resubmit_href()..[[' }); return false;" style="color: ]] .. (warning.customdisablecolor or "darkorange") .. [[;">]] .. (warning.customdisablemsg or "I am sure! Do it anyway and disable this warning until I log out.") .. [[</a></small></p>]]
	local one_turn_disable_msg = [[<p><small><a href="#" onclick="var link = this; $.post('custom-settings', { pwd: ']] .. session.pwd .. [[', action: 'set state', name: 'warning-turn-]] .. turnsthisrun() .. [[-]] .. warningid .. [[', stateset: 'session', value: 'true', ajax: 1 }, function(res) { link.style.color = 'gray'; link.innerHTML = '(Disabled, trying again...)'; location.href = ']]..make_resubmit_href()..[[' }); return false;" style="color: ]] .. (warning.customdisablecolor or "darkorange") .. [[;">]] .. (warning.customdisablemsg or "I am sure! Do it for this turn.") .. [[</a></small></p>]]
	if warning.customdisablemsg then
		one_turn_disable_msg = ""
	end

	local msgtext = make_kol_html_frame([[<p>]] .. (warning.customwarningprefix or "Warning: ") .. warning.message .. [[</p>]] ..
		extratext .. session_disable_msg .. one_turn_disable_msg, (warning.customwarningprefix or "Warning: "), (warning.customdisablecolor or "darkorange"))
	text = [[<html><head>]] .. head .. [[</head><body>]] .. msgtext .. [[</body></html>]]
	return text, "/kolproxy-warning"
end


local after_pageload_cache = {}

function reset_pageload_cache()
	after_pageload_cache = {}
end

function get_cached_function(f)
-- 	print("get_cached_function", f)
	local v = after_pageload_cache[f]
	if v then
-- 		print("cached f")
		return v
	else
-- 		print("calling raw f")
-- 		v = log_time_interval("get_cached_function: " .. tostring(f), f)
		v = f()
		after_pageload_cache[f] = v
		return v
	end
end

function get_cached_item(name, f)
	local v = after_pageload_cache[name]
	if v then
		return v
	else
		v = f()
		after_pageload_cache[name] = v
		return v
	end
end

local submit_page_listeners = {}

function add_submit_page_listener(f)
	table.insert(submit_page_listeners, f)
end

-- TODO: improve async and after_pageload_cache interaction, after_pageload_cache should be cleared after every completed pageload/statuschange!
function do_async_submit_page(t, url, params)
--	kolproxy_debug_print("> do_async_submit_page()\n" .. debug.traceback(""))
	after_pageload_cache = {}
	local pt, pturl, tbl = nil, nil, nil
	if params then
		tbl = {}
		for a, b in pairs(params) do
			if type(b) == "string" then
				table.insert(tbl, { key = a, value = b })
			elseif type(b) == "number" then
				table.insert(tbl, { key = a, value = tostring(b) })
			else
				error("Unknown async_submit_page value type: " .. type(b))
			end
		end
	end
--	kolproxy_debug_print("< do_async_submit_page()")
	local ptf = raw_async_submit_page(t, url, tbl)
	for _, lf in ipairs(submit_page_listeners) do
		pcall(lf, ptf)
	end
	return ptf
end

function async_get_page(url, params) return do_async_submit_page("GET", url, params) end

function async_post_page(url, params) return do_async_submit_page("POST", url, params) end

function get_page(url, params) return async_get_page(url, params)() end

function post_page(url, params) return async_post_page(url, params)() end

function async_get_place(whichplace, action) return async_get_page("/place.php", { whichplace = whichplace, action = action }) end

function get_place(whichplace, action) return async_get_place(whichplace, action)() end


function make_href(url, params)
	if params then
		local tbl = {}
		for a, b in pairs(params) do
			if type(b) == "string" then
				table.insert(tbl, { key = a, value = b })
			elseif type(b) == "number" then
				table.insert(tbl, { key = a, value = tostring(b) })
			else
				print("DEBUG make_href error for:", a, b)
				error("Unknown make_href value type: " .. type(b))
			end
		end
		return raw_make_href(url, tbl)
	else
		return raw_make_href(url, nil)
	end
end

local strthing_reported = {}
function run_file_with_environment(filename, orgenv, prefillenv)
	local env = {}
	env._G_envname = "kolproxy-core-functions env " .. filename
	local env_store = {}
	env_store._G_envname = "kolproxy-core-functions env_store " .. filename
	-- HACK: API change
	if not prefillenv.add_printer_raw then
		prefillenv.add_printer_raw = prefillenv.add_printer
	end
	function env.add_printer(file, func)
		prefillenv.add_printer_raw(file, func, filename)
	end
	if not prefillenv.add_processor_raw then
		prefillenv.add_processor_raw = prefillenv.add_processor
	end
	function env.add_processor(file, func)
		prefillenv.add_processor_raw(file, func, filename)
	end
	if not prefillenv.add_automator_raw then
		prefillenv.add_automator_raw = prefillenv.add_automator
	end
	function env.add_automator(file, func)
		prefillenv.add_automator_raw(file, func, filename)
	end
	-- HACK: This is a weird workaround, to get util functions to refer to our environment
	local hack_functions = {
		"add_automation_script",
		"add_itemdrop_counter",
		"__raw_add_warning",
		"__raw_add_extra_warning",
		"__raw_add_notice",
		"add_ascension_zone_check",
		"add_aftercore_zone_check",
		"add_always_zone_check",
		"add_extra_ascension_warning",
		"add_ascension_warning",
		"add_extra_always_warning",
		"add_always_warning",
		"add_ascension_warning",
		"add_aftercore_warning",
		"add_always_adventure_warning",
		"add_extra_always_adventure_warning",
		"add_ascension_adventure_warning",
		"add_extra_ascension_adventure_warning",
		"add_aftercore_adventure_warning",
		"add_chat_redirect",
		"add_chat_command",
		"add_chat_alias",
		"add_raw_chat_script_redirect",
	}
	for x in table.values(hack_functions) do
		env_store[x] = _G[x]
	end
	for x in table.values(hack_functions) do
		setfenv(_G[x], env)
	end

	local __allow_global_writes = true
	local function p_none() end
	setmetatable(env, { __index = function(t, k)
		local v = rawget(env_store, k)
		if v ~= nil then return v end
		local v = rawget(prefillenv, k)
		if v ~= nil then return v end
		v = rawget(orgenv, k)
		if v ~= nil then return v end
		v = _G[k]
		if v ~= nil then return v end
		if debug_undeclared_variables then
			local strthing = k .. ":" .. filename
			if not strthing_reported[strthing] then
				print("DEBUG didn't find variable", k, "for", filename)
				--print("DEBUG:", debug.traceback("missing:" .. strthing))
				strthing_reported[strthing] = true
			end
			local f = io.open("logs/info/DEBUG-strthing-reported.txt", "a+")
			f:write(strthing.."\n")
			f:close()
		end
		return nil
	end, __newindex = function(t, k, v)
		if error_on_writing_text_or_url and (k == "text" or k == "url") then
			error "You can't write to 'text' or 'url' from add_processor, that's just for registering game state changes. You might want add_printer() instead for changing what's displayed?"
		end
		if (k == "__allow_global_writes" or not __allow_global_writes) and k ~= "text" and k ~= "url" then
			rawset(env_store, k, v)
		else
			orgenv[k] = v
		end
	end })
	local f, e = loadfile("scripts/" .. filename)
	if not f then error(e, 2) end
	setfenv(f, env)

	f()

	__allow_global_writes = rawget(env_store, "__allow_global_writes")
end

function load_script_files(env)
	local function add_do_nothing_function(name)
		if not env[name] then
			env[name] = function() end
		end
	end
	add_do_nothing_function("add_processor")
	add_do_nothing_function("add_printer")
	add_do_nothing_function("add_choice_text")
	add_do_nothing_function("add_automator")
	add_do_nothing_function("add_interceptor")
	add_do_nothing_function("add_chat_printer")
	add_do_nothing_function("add_json_chat_printer")
	add_do_nothing_function("add_chat_trigger")

	local global_env = {}
	local function load_file(category, name)
		--print("DEBUG: load_file()", category, name)
		local warn = true
		run_file_with_environment(name, global_env, env)
		warn = false
	end

	run_file_with_environment("kolproxy-internal/loaders.lua", { load_file = load_file }, {})

	global_env.register_setting = nil

	return global_env
end

function make_kol_html_frame(contents, title, bgcolor)
	return [[<center><table  width=95%  cellspacing=0 cellpadding=0><tr><td style="color: white; background-color: ]] .. (bgcolor or "green") .. [[;" align=center><b>]] .. (title or "Results:") .. [[</b></td></tr><tr><td style="padding: 5px; border: 1px solid ]]..(bgcolor or "green")..[[;"><center><table><tr><td>]] .. tostring(contents) .. [[</td></tr></table></center></td></tr><tr><td height=4></td></tr></table></center>]]
end

function add_raw_message_to_page(pagetext, msg)
	local pre_, dv_, mid_, end_, post_ = pagetext:match("^(.+)(<div style='overflow: auto'><center><table)(.+)(</body></html>)(.*)$")
	if pre_ and dv_ and mid_ and end_ and post_ then
		local wrappedmsg = [[<center><table width=95%><tr><td>]] .. msg .. [[</td></tr></table></center>]]
		return pre_ .. wrappedmsg .. "<br>" .. dv_ .. mid_ .. end_ .. post_
	elseif pagetext:match("<body>") then
		return pagetext:gsub("<body>", function(a) return a .. msg end)
	else
		return msg .. pagetext
	end
end

function add_message_to_page(pagetext, msg, title, color)
	return add_raw_message_to_page(pagetext, make_kol_html_frame(msg, title, color))
end

function add_colored_message_to_page(pagetext, msg, color) -- TODO: Remove
	print("WARNING: add_colored_message_to_page(pagetext, msg, color) is deprecated")
	return add_message_to_page(pagetext, "<pre>" .. msg .. "</pre>", "Result:", color)
end

function add_formatted_colored_message_to_page(pagetext, msg, color) -- TODO: Remove
	print("WARNING: add_formatted_colored_message_to_page(pagetext, msg, color) is deprecated")
	return add_message_to_page(pagetext, msg, "Result:", color)
end

local have_loaded_main = false
function run_functions(p, pagetext, run)
	original_page_text = pagetext

	if p == "/fight.php" then
		if newly_started_fight then
			if get_monstername() then
				pagetext = run("start fight:" .. get_monstername(), pagetext)
			end
			pagetext = run("start fight", pagetext)
		end

		pagetext = pagetext:gsub([[(<td[^>]-><img src="http://images.kingdomofloathing.com/itemimages/)([^"]+.gif)(" width=30 height=30 alt="[^"]+" title=")([^"]+)("></td><td[^>]->)(.-)(</td></tr>)]], function(pre, itemimage, mid, title, td, msg, post)
			item_image = itemimage
			item_name = title
			if item_name then
				msg = run("used combat item: " .. item_name, msg)
			end
			msg = run("used combat item", msg)
			item_image = nil
			item_name = nil
			return pre .. itemimage .. mid .. title .. td .. msg .. post
		end)

		pagetext = pagetext:gsub([[(<!%-%-familiarmessage%-%-><center><table>.-</table></center>)]], function(msg)
			familiarmessage_picture = msg:match([[<!%-%-familiarmessage%-%-><center><table><tr><td align=center valign=center><img src="http://images.kingdomofloathing.com/itemimages/([^"]+).gif" width=30 height=30></td>]])
			if familiarmessage_picture then
				msg = run("familiar message: " .. familiarmessage_picture, msg)
			end
			msg = run("familiar message", msg)
			return msg
		end)
	end

	if original_page_text:contains("You acquire ") and original_page_text:contains([[table class="item"]]) then
		pagetext = pagetext:gsub([[<center><table class="item" style="float: none" rel="[^"]*"><tr><td><img src="http://images.kingdomofloathing.com/itemimages/[^"]+.gif" alt="[^"]*" title="[^"]*" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire .-</td></tr></table></center>]], function(droptext)
			item_image = droptext:match([[src="http://images.kingdomofloathing.com/itemimages/([^"]+).gif"]])
			item_name = droptext:match([[title="([^"]*)"]])
			msg = droptext
			if item_name then
				msg = run("item drop: " .. item_name, msg)
			end
			msg = run("item drop", msg)
-- 			print("item capture", pre, rel, mid, dropinfo, post)
-- 			local msg = pre .. rel .. mid .. "<span style=\"color: darkgreen\">" .. dropinfo .. "</span>" .. post
-- 			if string.match(rel, "u=u") then
-- 				msg = pre .. rel .. mid .. "<span style=\"color: darkgreen\">" .. dropinfo .. "</span> [use]" .. post
-- 				http://localhost:18481/inv_use.php?pwd=xxx&which=3&whichitem=3236
-- 			elseif string.match(rel, "u=q") then
-- 				msg = pre .. rel .. mid .. "<span style=\"color: darkgreen\">" .. dropinfo .. "</span> [equip]" .. post
-- 				http://localhost:18481/inv_equip.php?pwd=xxx&which=2&action=equip&whichitem=2813
-- 			end
			return msg
		end)
	end

--[[
Possible ways to use items:

inv_use -> inv_use
  GET inv_use.php whichitem=ITEMID ajax=1 pwd=PWD -> inv_use.php whichitem=ITEMID ajax=1 pwd=PWD

  GET inv_use.php ajax=1 whichitem=ITEMID itemquantity=N quantity=N pwd=PWD -> inv_use.php ajax=1 whichitem=ITEMID itemquantity=N quantity=N pwd=PWD

inv_use -> inventory
  GET inv_use.php pwd=PWD whichitem=ITEMID -> inventory.php action=message

multiuse -> multiuse
  GET multiuse.php whichitem=ITEMID action=useitem ajax=1 quantity=N pwd=PWD -> multiuse.php whichitem=ITEMID action=useitem ajax=1 quantity=N pwd=PWD

  POST multiuse.php [action=useitem pwd=PWD quantity=N whichitem=ITEMID] -> multiuse.php

new inv_spleen
--]]

	if (requestpath == "/inv_use.php") or (requestpath == "/inv_spleen.php") or (p == "/multiuse.php" and params.action == "useitem") then
		item_image = nil
		item_name = maybe_get_itemname(tonumber(params.whichitem))
		if item_name then
			pagetext = run("use item: " .. item_name, pagetext)
		end
		pagetext = run("use item", pagetext)
		item_image = nil
		item_name = nil
	end

	if p == "/fight.php" and pagetext:contains(">You win the fight!<!--WINWINWIN--><") then
		local mn = get_monstername()
		if mn then
			pagetext = run("won fight: " .. mn, pagetext)
		end
		pagetext = run("won fight", pagetext)
	end

	if p == "/place.php" and params.whichplace then
		if params.action then
			pagetext = run("place:" .. params.whichplace .. ":" .. params.action, pagetext)
		end
		pagetext = run("place:" .. params.whichplace, pagetext)
	end

	pagetext = run(p, pagetext)

	-- TODO: Redo, assistance automation should only run on some pages
	if p ~= "/charpane.php" and p ~= "/game.php" and not p:contains("chat.php") and not p:contains("menu.php") then
		pagetext = run("all pages", pagetext)
	end

	return pagetext
end

function can_read_state()
	if kolproxy_can_read_state() then
		return pcall(status)
	end
end
