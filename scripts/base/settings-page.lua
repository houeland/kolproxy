local settings = {}
local settings_order = {}
local settings_order_counter = 0

local setting_levels = {
	limited = 1,
	standard = 2,
	detailed = 3,
	enthusiast = 4,
}

function register_setting(tbl)
	check_supported_table_values(tbl, { "hidden" }, { "name", "description", "group", "default_level" })
	settings[tbl.name] = tbl
	settings_order_counter = settings_order_counter + 1
	settings_order[tbl.name] = settings_order_counter
end

--register_setting {
--	name = "show charpane lines",
--	description = "Show additional information (semirare, turns played) on charpane",
--	group = "charpane",
--	default_level = "limited",
--}

register_setting {
	name = "run automation scripts",
	description = "Allow the kolproxy scripts to download pages (required for everything else)",
	group = "automation",
	default_level = "limited",
	hidden = true,
}

register_setting {
	name = "automate simple tasks",
	description = "Automatically complete simple puzzles that don't cost turns",
	group = "automation",
	default_level = "standard",
}

register_setting {
	name = "enable ascension assistance",
	description = "Enable ascension assistance (automatically completes simple ascension-relevant tasks)",
	group = "automation",
	default_level = "enthusiast",
}

register_setting {
	name = "enable adventure warnings",
	description = "Enable adventuring mistake warnings about semirares, not enough meat, etc.",
	group = "warnings",
	default_level = "limited",
}

register_setting {
	name = "enable experimental implementations",
	description = "Enable (beta) features that are still in development (<b>Not always accurate</b>, currently: mining prediction)",
	group = "other",
	default_level = "enthusiast",
}

register_setting {
	name = "show extra warnings",
	description = "Add many extra optional adventure warnings for things that are worth thinking about (but are often not actually mistakes)",
	group = "warnings",
	default_level = "detailed",
}

register_setting {
	name = "enable readventuring automation",
	description = "Enable re-adventuring automation (set a macro as your autoattack, and click the link to spend multiple turns in a row in the same place)",
	group = "automation",
	default_level = "standard",
}

register_setting {
	name = "enable turnplaying automation",
	description = "Enable turn-playing automation scripts (for completing quests in aftercore)",
	group = "automation",
	default_level = "standard",
}

register_setting {
	name = "enable turnplaying automation in-run",
	description = "Also enable turn-playing automation scripts in-run (e.g. the ascension automation script)",
	group = "automation",
	default_level = "detailed",
}

-- 	-- 		{ title = "Show PvP announcements in a separate tab", set = "character", name = "separate pvp announcements tab", field = "yesno" },



local setting_groups = {
	{ name = "charpane", title = "Character pane" },
	{ name = "warnings", title = "Adventure warnings" },
	{ name = "fight", title = "Fight" },
	{ name = "automation", title = "Automation" },
	{ name = "chat", title = "Chat" },
	{ name = "other", title = "Other" },
}

-- Recommended

-- Allow the kolproxy scripts to download pages (required for everything else)
-- Enable adventuring mistake warnings about semirares, not enough meat, etc.
-- Use faster custom kolproxy charpane (set compact or normal-mode charpane in KoL options)
-- Show modifier estimates (+noncombat%, +item%, +ML. Not always accurate)
-- Automatically complete simple puzzles that don't cost turns

-- Optional

-- Show monster stat estimates (HP, attack, defense, item drops. Not always accurate)
-- Use custom super-compact menupane
-- Add many extra optional adventure warnings for things that are worth thinking about (but often not mistakes)
-- Enable ascension assistance (automatically completes simple ascension-relevant tasks)
-- Enable re-adventuring automation (set a macro as your autoattack, and click the link to spend multiple turns in a row in the same place)
-- Enable turn-playing automation scripts (for completing quests in aftercore, or automating an entire ascension, etc.)
-- Enable (beta) features that are still in development

-- Chat

-- Preview what chat commands will do
-- Automatically open modern chat in right-hand frame
-- Disable dragging to sort tabs in modern chat
-- Don't unlisten to channels when closing their tab
-- Change modern chat modifier key to Ctrl+Shift
-- Ask chatbot for bounty/clover status on logon

function setting_enabled(name)
	if not can_read_state() then return false end
	local s = character["setting: " .. name]
	if s then
		local enabled = (s == "on")
-- 		print("DEBUG setting", name, enabled)
		return enabled
	else
		if not settings[name] then
			print("ERROR!!! SETTING NOT DEFINED!", name)
-- 			for a, b in pairs(settings) do
-- 				print("DEBUG, settings:", a, b)
-- 			end
			return false
		end
		local level = character["setting group: " .. (settings[name].group or "?")] or character["settings base level"] or "limited"
		local enabled = setting_levels[settings[name].default_level or "enthusiast"] <= setting_levels[level]
-- 		print("DEBUG setting defaulted", name, enabled)
		return enabled
	end
end

function character_setting(name, default)
	print("TODO: character_setting for", name)
	register_setting {
		name = name,
		description = nil,
		group = nil,
		default_level = "standard",
	}
	return function()
		return setting_enabled(name)
	end
end

-- add_printer("/account.php", function()
-- 	table = [[
-- 	<table  width=95%%  cellspacing=0 cellpadding=0>
-- 		<tr><td style="color: white;" align=center bgcolor=green><b>Kolproxy Options</b></td></tr>
-- 		<tr><td style="padding: 5px; border: 1px solid green;">
-- 			<center><table><tr><td>
-- 				<p><a href="custom-settings?pwd=]] .. session.pwd .. [[">Go to kolproxy settings</a></p>
-- 			</td></tr></table></center>
-- 		</td></tr>
-- 		<tr><td height=4></td></tr>
-- 	</table>
-- 	]]
-- 	text = string.gsub(text, [[<span id="ro">]], "\n" .. table .. "%0")
-- end)

-- function make_buttons(valuestr, value, options)
-- 	buttons = ""
-- 	for _, v in ipairs(options) do
-- 		if value == v.value then
-- 			buttons = buttons .. [[<input type="radio" name="]]..valuestr..[[" value="]] .. v.value .. [[" checked="yes">]] .. v.text
-- 		else
-- 			buttons = buttons .. [[<input type="radio" name="]]..valuestr..[[" value="]] .. v.value .. [[">]] .. v.text
-- 		end
-- 	end
-- 	return buttons
-- end

local function get_customize_features_page()
	local grouped = {}
	for _, x in ipairs(setting_groups) do
		grouped[x.name] = {}
	end
	for _, x in pairs(settings) do
		local g = x.group
		if not grouped[g] then g = "other" end
		table.insert(grouped[g], x)
	end
	local featurerows = {}
	local radio_ctr = 0
	for _, x in ipairs(setting_groups) do
		if #grouped[x.name] > 0 then
			table.sort(grouped[x.name], function(a, b) return settings_order[a.name] < settings_order[b.name] end)
			table.insert(featurerows, [[<tr class="trheader"><th colspan="4">]] .. x.title .. [[</th></tr>]])
		end
		for _, y in ipairs(grouped[x.name]) do
			radio_ctr = radio_ctr + 1
			local radio_name = "radio_" .. radio_ctr
			local onchecked = (character["setting: " .. y.name] == "on") and [[checked="checked"]] or ""
			local offchecked = (character["setting: " .. y.name] == "off") and [[checked="checked"]] or ""
			local defaultchecked = (character["setting: " .. y.name] == nil) and [[checked="checked"]] or ""
			local baselevel = character["settings base level"] or "limited"
			local defaultvalue = (setting_levels[y.default_level or "enthusiast"] <= setting_levels[baselevel]) and "on" or "off"
			local featuredesc = y.description and ([[<span title="Lua scripting syntax: setting_enabled(&quot;]] .. y.name .. [[&quot)">]] .. y.description .. [[</span>]]) or ([[<span style="color: red">No description (<tt>]] .. y.name .. [[</tt>)</span>]])
			if not y.hidden then
				table.insert(featurerows, [[<tr data-feature-name="]]..y.name..[["><td class="tdname">]] .. featuredesc .. [[</td>]] ..
					[[<td class="tdon"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..onchecked..[[>On</td>]] ..
					[[<td class="tdoff"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..offchecked..[[>Off</td>]] ..
					[[<td class="tddefault"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..defaultchecked..[[>Default (]]..defaultvalue..[[)</td></tr>]])
			end
		end
	end
	local explanation = [[<p>The base settings (limited/standard/detailed) activate different sets of features by default.<p>On this page, individual features can be customized. The settings work like this:<br>
	<ul>
	<li><b>On</b>: This feature will always be enabled.</li>
	<li><b>Off</b>: This feature will always be disabled.</li>
	<li><b>Default</b>: Use the base setting (currently: <i>]]..(character["settings base level"] or "limited")..[[</i>) to determine whether the feature will be enabled or disabled.</li>
	</ul>
	<p>(All settings are for the current character <i>]] .. playername() .. [[</i>.)</p>]]
	text = make_kol_html_frame(explanation .. [[<table class="featuretable">]] .. table.concat(featurerows, "\n") .. "</table>", "Feature customization")
	text = [[
		<html>
		<head>
			<script language="Javascript" src="http://images.kingdomofloathing.com/scripts/core.js"></script>
			<link rel="stylesheet" type="text/css" href="http://images.kingdomofloathing.com/styles.css">
			<style type="text/css">
				.featuretable { border: thin solid black }
				.featuretable { border-collapse: collapse }
				.featuretable .trheader { border: thin solid black; background-color: moccasin; }
				.featuretable td { padding: 5px; border-bottom: thin solid black; }
				.featuretable .tdname { border-right: thin dotted gray; }
				.featuretable .tdon { border-right: thin dotted gray; }
				.featuretable .tdoff { border-right: thin dotted gray; }
			</style>
			<script language="Javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
			<script type="text/javascript">
function changed_feature_setting(what) {
	var setting = $($(what).parents("tr")[0]).attr("data-feature-name")
	var c = $(what).parent("td").attr("class")
	if (c == "tdon") {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'setting: ' + setting, stateset:'character', value:'on', ajax: 1 })
	} else if (c == "tdoff") {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'setting: ' + setting, stateset:'character', value:'off', ajax: 1 })
	} else if (c == "tddefault") {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'setting: ' + setting, stateset:'character', value:'', ajax: 1 })
	}
}
			</script>
		</head>
		<body>]] .. text .. [[
		</body>
		</html>]]
	return text
end

add_printer("/custom-settings", function()
	if params.page == "customize features" then
		text = get_customize_features_page()
		return
	end
	local settingslist = {
		{ header = "Recommended" },
-- 		{ title = "Automate choice noncombats", set = "character", name = "automate choice noncombats", field = "yesno" },
		{ title = "Allow the kolproxy scripts to download pages (required for everything else)", set = "character", name = "run automation scripts", field = "yesno", default_yes = true, explanation = "This is required for other advanced functionality to work.<br><br>If this is disabled, then only the pages your browser specifically requests will be downloaded from the server. E.g. if you were to click the ascension checklist, it would try to download it from the KoL server and return an error message, instead of letting the script run and load your inventory/storage/closet.<br><br>You probably always want this enabled. If it's disabled, kolproxy scripts are limited to only parsing/changing page text." },
		{ title = "Enable adventuring mistake warnings about semirares, not enough meat, etc.", set = "character", name = "enable adventure warnings", field = "yesno", default_yes = true },
		{ title = "Use faster custom kolproxy charpane (set compact or normal-mode charpane in KoL options)", set = "character", name = "use custom kolproxy charpane", field = "yesno" },
		{ title = "Show modifier estimates (+noncombat%, +item%, +ML. <b>Not always accurate</b>)", set = "character", name = "show modifier estimates", field = "yesno" },
		{ title = "Automatically complete simple puzzles that don't cost turns", set = "character", name = "automate simple tasks", field = "yesno", explanation = "This enables the things kolproxy can do behind the scenes, such as using the plus sign when you get it, solving the strange leaflet when you use it, using evil eyes, etc.<br><br>You probably want this enabled unless there are bugs in the automation code." },
-- 		{ title = "Automate daily visits (rumpus room, garden, etc.)", set = "character", name = "automate daily visits", field = "yesno" },
		{ header = "Optional" },
		{ title = "Show monster stat estimates (HP, attack, defense, item drops. <b>Not always accurate</b>)", set = "character", name = "show monster stats", field = "yesno" },
		{ title = "Use custom super-compact menupane", set = "character", name = "enable super-compact menupane", field = "yesno" },
		{ title = "Add many extra optional adventure warnings for things that are worth thinking about (but often not mistakes)", set = "character", name = "show extra warnings", field = "yesno" },
		{ title = "Enable ascension assistance (automatically completes simple ascension-relevant tasks)", set = "character", name = "enable ascension assistance", field = "yesno" },
		{ title = "Enable re-adventuring automation (set a macro as your autoattack, and click the link to spend multiple turns in a row in the same place)", set = "character", name = "enable turn automation", field = "yesno" },
		{ title = "Enable turn-playing automation scripts (for completing quests in aftercore, or automating an entire ascension, etc.)", set = "character", name = "enable ascension automation", field = "yesno" },
		{ title = "Enable (beta) features that are still in development", set = "character", name = "enable experimental implementations", field = "yesno", explanation = "Current experimental implementations<br>(functional, but not polished and can contain bugs):<br><ul><li>Mining minigame helper<br>(works, but slows down loading the page)</li><li>Nemesis quest automation</li><li>Suburban Dis quest automation</li><li>Space shield generator quest automation</li></ul>" },
		{ header = "Chat" },
		{ title = "Preview what chat commands will do", set = "character", name = "preview chat commands", field = "yesno" },
		{ title = "Automatically open modern chat in right-hand frame", set = "character", name = "open chat on logon", field = "yesno" },
		{ title = "Disable dragging to sort tabs in modern chat", set = "character", name = "disable dragging chat tabs", field = "yesno" },
-- 		{ title = "Show PvP announcements in a separate tab", set = "character", name = "separate pvp announcements tab", field = "yesno" },
		{ title = "Don't unlisten to channels when closing their tab", set = "character", name = "do not unlisten when closing tabs", field = "yesno" },
		{ title = "Change modern chat modifier key to Ctrl+Shift", set = "character", name = "use ctrl+shift to change chat tabs", field = "yesno" },
		{ title = "Ask chatbot for bounty/clover status on logon", set = "character", name = "ask chatbot on logon", field = "yesno" },
-- 		{ title = "Aftercore logout outfit", set = "character", name = "logout outfit", field = "text", example = "Rollover" },
-- 		{ title = "Buffing outfit", set = "ascension", name = "buffing outfit", field = "text", example = "Buffing" },
-- 		{ title = "Buffing outfit (when auto-healing)", set = "ascension", name = "autoheal buffing outfit", field = "text", example = "Buffing" },
	}
	settingstext = ""
	for idx, s in pairs(settingslist) do
		local this_text = nil
		if s.header then
			this_text = "<h4>" .. s.header .. "</h4>"
		else
			value = get_state(s.set, s.name)
			namestr = "name-" .. tostring(idx)
			valuestr = "value-" .. tostring(idx)
			if s.field == "text" then
	-- 			example = [[(e.g. <i>]] .. s.example .. [[</i>)]]
	-- 			item_text = s.title .. [[ = <input name="]]..valuestr..[[" value="]] .. value .. [[">]] .. example
	-- 		elseif s.field == "number" then
	-- 			example = [[(e.g. <i>]] .. s.example .. [[</i>)]]
	-- 			item_text = s.title .. [[ = <input name="]]..valuestr..[[" value="]] .. value .. [[">]] .. example
			elseif s.field == "yesno" then
				if value == "yes" then
					checkbox_value = [[checked="checked" ]]
				elseif value == "no" then
					checkbox_value = [[]]
				else
					if s.default_yes then
						checkbox_value = [[checked="checked" ]]
					else
						checkbox_value = [[]]
					end
				end
				explanationmark = ""
				explanationtext = ""
				if s.explanation and false then
					explanationmark = [[<sup><b><a class='nounder' href="javascript:toggle('explanation-]]..tostring(idx)..[[')">(?)</a></b></sup>]]
					explanationtext = [[
	<div id='explanation-]]..tostring(idx)..[[' style="display: none"><center><div class="helpbox">]]..s.explanation..[[</div></center></div>]]
				end
				inputelem = [[<input type="checkbox" ]]..checkbox_value..[[name="]]..s.name..[[" id="id]]..s.name..[[" onChange="click_cb(this, ']]..s.name..[[', ']]..s.set..[[')"/>]]
				checkbox = [[<div><label style="padding: 3px" for="id]] .. s.name .. [[">]]..inputelem..s.title..[[</label>]]..explanationmark..[[</div>]]
				item_text = [[<div id="]] .. s.name .. [[" class="opt checkbox">]] .. checkbox .. [[<input type="hidden" class="stateset" value="]] .. s.set .. [[">]]..explanationtext..[[</div>]]
	-- 		elseif s.field == "option" then
	-- 			buttons = make_buttons(valuestr, value, s.values)
	-- 			item_text = s.title .. [[ = ]] .. buttons
	-- 		else
	-- 			item_text = s.title .. [[ = <input name="]]..valuestr..[[" value="]] .. value .. [[">]]
			end
			this_text = [[<p>
			<input type="hidden" name="]]..namestr..[[" value="]] .. s.name .. [[">
			]] .. item_text .. [[
			<input type="hidden" name="stateset-]]..idx..[[" value="]] .. s.set .. [[">
	</p>
	]]
		end
-- 		settingstext = settingstext .. this_text
	end
	local baselevel = character["settings base level"] or "limited"
	local limitedchecked = (baselevel == "limited") and [[checked="checked"]] or ""
	local standardchecked = (baselevel == "standard") and [[checked="checked"]] or ""
	local detailedchecked = (baselevel == "detailed") and [[checked="checked"]] or ""
	text = make_kol_html_frame([[
			<center><table><tr><td>
				<form action="custom-settings" method="post">
					<div class="radiochoice"><input type="radio" name="settinglevel" id="settingslimited" value="limited" ]]..limitedchecked..[[onChange="changed_settings()"><label for="settingslimited">Limited</label><br>(Most like regular KoL. Only some features enabled.)</div>
					<div class="radiochoice"><input type="radio" name="settinglevel" id="settingsstandard" value="standard" ]]..standardchecked..[[onChange="changed_settings()"><label for="settingsstandard">Standard</label><br>(Adds a default selection of useful features.)</div>
					<div class="radiochoice"><input type="radio" name="settinglevel" id="settingsdetailed" value="detailed" ]]..detailedchecked..[[onChange="changed_settings()"><label for="settingsdetailed">Detailed</label><br>(Adds many more features, for those who like to know and see everything.)</div>
				</form>
				<center><form action="custom-settings" method="post"><input type="hidden" name="page" value="customize features"><input type="hidden" name="pwd" value="]]..session.pwd..[["><input type="submit" value="Advanced: Customize features"></center>
			</td></tr></table></center>
]], "Kolproxy features") .. make_kol_html_frame([[
			<center><table><tr><td>
			<tr><td><center><a href="custom-logs?pwd=]]..session.pwd..[[">Parse ascension log</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-ascension-checklist&pwd=]]..session.pwd..[[">Pre-ascension pull stocking checklist</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-aftercore-automation&pwd=]]..session.pwd..[[">Aftercore automation scripts</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-mix-drinks&pwd=]]..session.pwd..[[">List advanced cocktails you can craft (preview)</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=display-tracked-variables&pwd=]]..session.pwd..[[">Display tracked game variables (preview)</a></center></td></tr>
			<tr><td><center><a href="http://www.houeland.com/kolproxy/wiki/" target="_blank">Kolproxy documentation</a> (opens in a new tab)</center></td></tr>
			</td></tr></table></center>
]], "Kolproxy special pages") .. make_kol_html_frame([[
			<center><table><tr><td>
			<tr><td><center><input type="button" value="Reload Lua script files" onclick="javascript:clear_lua_script_cache(this)"></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=lua-console&pwd=]]..session.pwd..[[">Interactive Lua console</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=add-log-notes&pwd=]]..session.pwd..[[">Add log notes</a></center></td></tr>
			</td></tr></table></center>
]], "Developer tools")
-- 	<table  width=95%%  cellspacing=0 cellpadding=0>
-- 		<tr><td style="color: white;" align=center bgcolor=green><b>Server settings</b></td></tr>
-- 		<tr><td style="padding: 5px; border: 1px solid green;">
-- 			<center><table><tr><td>
-- 				<form action="custom-store-settings" method="post">
-- 					<input type="hidden" name="pwd" value="]] .. session.pwd .. [[">
-- 					<input type="submit" value="Store kolproxy settings on server">
-- 				</form>
-- 				<form action="custom-load-settings" method="post">
-- 					<input type="hidden" name="pwd" value="]] .. session.pwd .. [[">
-- 					<input type="submit" value="Load kolproxy settings from server">
-- 				</form>
-- 			<tr><td><center><a href="account.php">Back to Account Menu</a></center></td></tr>
-- 			</td></tr></table></center>
-- 		</td></tr>
-- 		<tr><td height=4></td></tr>
-- 	</table>
-- 	]]
	text = [[
		<html>
		<head>
			<script language="Javascript" src="http://images.kingdomofloathing.com/scripts/core.js"></script>
			<link rel="stylesheet" type="text/css" href="http://images.kingdomofloathing.com/styles.css">
			<style type="text/css">
				.helpbox {
				   width: 500px;
				   border: 1px solid black;
				   padding: 5px;
				}
				.radiochoice {
					padding: 10px;
				}
			</style>
			<script language="Javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
			<script type="text/javascript">
function changed_settings() {
	if (document.getElementById("settingslimited").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'limited', ajax: 1 }, function (res) {
			top.charpane.location = "charpane.php"
		})
	} else if (document.getElementById("settingsstandard").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'standard', ajax: 1 }, function (res) {
			top.charpane.location = "charpane.php"
		})
	} else if (document.getElementById("settingsdetailed").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'detailed', ajax: 1 }, function (res) {
			top.charpane.location = "charpane.php"
		})
	}
}
function click_cb(cb, name, stateset) {
	var cur = "no"
	if (cb.checked) {
		cur = "yes"
	}
	$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:name, stateset:stateset, value:cur, ajax: 1 }, function (res) {
		enableDiv(label);
	});
	return true;
}
function clear_lua_script_cache(button) {
	var pwd = ']] .. session.pwd .. [['
	$.post('custom-clear-lua-script-cache', { pwd: pwd }, function (res) {
		button.value = 'Script cache cleared!'
		setTimeout(function() { button.value = 'Reload Lua script files again' }, 3000)
	});
}
			</script>
		</head>
		<body>]] .. text .. [[
		</body>
		</html>]]
--~ 	print("params", params)
end)
