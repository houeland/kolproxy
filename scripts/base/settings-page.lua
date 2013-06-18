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
	name = "show extra warnings",
	description = "Add many extra adventure warnings for things that are worth thinking about but not necessarily mistakes",
	group = "warnings",
	default_level = "detailed",
	parent = "enable adventure warnings",
}

register_setting {
	name = "show extra notices",
	description = "Also show extra informational notices that just provide alerts and don't indicate mistakes at all",
	group = "warnings",
	default_level = "enthusiast",
	parent = "enable adventure warnings",
}

register_setting {
	name = "enable experimental implementations",
	description = "Enable (beta) features that are still in development (<b>Not always accurate</b>)",
	group = "other",
	default_level = "enthusiast",
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

local function get_customize_features_page()
	local grouped = {}
	for _, x in ipairs(setting_groups) do
		grouped[x.name] = {}
	end
	local children = {}
	for _, x in pairs(settings) do
		local g = x.group
		if not grouped[g] then g = "other" end
		local parent = x.name:match("(.+)/") or x.parent
		if parent then
			if not children[parent] then
				children[parent] = {}
			end
			table.insert(children[parent], x)
		else
			table.insert(grouped[g], x)
		end
	end
	local featurerows = {}
	local radio_ctr = 0
	local feature_radio_names = {}
	local all_radio_names = {}
	local all_default_values = {}
	for _, x in ipairs(setting_groups) do
		if #grouped[x.name] > 0 then
			table.sort(grouped[x.name], function(a, b) return settings_order[a.name] < settings_order[b.name] end)
			table.insert(featurerows, [[<tr class="trheader"><th colspan="4">]] .. x.title .. [[</th></tr>]])
		end
		local function insert_setting_row(y, parentname)
			radio_ctr = radio_ctr + 1
			local radio_name = "radio_" .. radio_ctr
			feature_radio_names[y.name] = radio_name
			table.insert(all_radio_names, radio_name)
			local onchecked = (character["setting: " .. y.name] == "on") and [[ checked="checked"]] or ""
			local offchecked = (character["setting: " .. y.name] == "off") and [[ checked="checked"]] or ""
			local defaultchecked = (character["setting: " .. y.name] == nil) and [[ checked="checked"]] or ""
			local baselevel = character["settings base level"] or "limited"
			local defaultvalue = (setting_levels[y.default_level or "enthusiast"] <= setting_levels[baselevel]) and "on" or "off"
			local featuredesc = y.description and ([[<span title="Lua scripting syntax: setting_enabled(&quot;]] .. y.name .. [[&quot)">]] .. y.description .. [[</span>]]) or ([[<span style="color: red">No description (<tt>]] .. y.name .. [[</tt>)</span>]])
			local trstyle = ""
			if parentname then
				trstyle = string.format([[ class="childof_%s"]], feature_radio_names[parentname])
				featuredesc = "&ndash;&nbsp;" .. featuredesc
			end
			all_default_values[y.name] = defaultvalue
			if not y.hidden then
				table.insert(featurerows, [[<tr data-feature-name="]]..y.name..[["]]..trstyle..[[><td class="tdname">]] .. featuredesc .. [[</td>]] ..
					[[<td class="tdon"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..onchecked..[[>On</td>]] ..
					[[<td class="tdoff"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..offchecked..[[>Off</td>]] ..
					[[<td class="tddefault"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..defaultchecked..[[>Default (]]..defaultvalue..[[)</td></tr>]])
			end
		end
		local function recurse(y)
			for _, z in ipairs(children[y.name] or {}) do
				insert_setting_row(z, y.name)
				recurse(z)
			end
		end
		for _, y in ipairs(grouped[x.name]) do
			insert_setting_row(y)
			recurse(y)
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
var all_default_values = ]] .. table_to_json(all_default_values) .. [[

var all_radio_names = ]] .. table_to_json(all_radio_names) .. [[

function refresh_visibility() {
	var hidden = {}
	for (var i_ = 0; i_ < all_radio_names.length; i_ += 1) {
		for (var whichradio = 0; whichradio <= 2; whichradio += 1) {
			var radio = $("[name=" + all_radio_names[i_] + "]")[whichradio]
			if ($(radio).attr("checked")) {
				var fname = $($(radio).parents("tr")[0]).attr("data-feature-name")
				var c = $(radio).parent("td").attr("class")
				var isenabled = false
				if (c == "tdon") isenabled = true
				else if (c == "tddefault" && all_default_values[fname] == "on") isenabled = true
				if (isenabled && !hidden[fname]) {
					$(".childof_" + all_radio_names[i_]).show()
				} else {
					$(".childof_" + all_radio_names[i_]).hide()
					$(".childof_" + all_radio_names[i_]).each(function(x, y) { hidden[$(y).attr("data-feature-name")] = true })
				}
			}
		}
	}
}

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
	refresh_visibility()
}
			</script>
		</head>
		<body onload="refresh_visibility()">]] .. text .. [[
		</body>
		</html>]]
	return text
end

add_printer("/custom-settings", function()
	if params.page == "customize features" then
		text = get_customize_features_page()
		return
	end

	local baselevel = character["settings base level"] or "limited"
	local limitedchecked = (baselevel == "limited") and [[checked="checked" ]] or ""
	local standardchecked = (baselevel == "standard") and [[checked="checked" ]] or ""
	local detailedchecked = (baselevel == "detailed") and [[checked="checked" ]] or ""
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
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-aftercore-automation&pwd=]]..session.pwd..[[">Setup/run automation scripts</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-cosmic-kitchen&pwd=]]..session.pwd..[[">Cosmic kitchen dinner planner</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-choose-mad-tea-party-hat&pwd=]]..session.pwd..[[">Choose hat for mad tea party</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-modifier-maximizer&pwd=]]..session.pwd..[[">Modifier maximizer (preview)</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-compute-net-worth&pwd=]]..session.pwd..[[">Compute net worth (preview)</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=display-tracked-variables&pwd=]]..session.pwd..[[">Display tracked game variables (preview)</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-mix-drinks&pwd=]]..session.pwd..[[">List advanced cocktails you can craft (preview)</a></center></td></tr>
			<tr><td><center><a href="http://www.houeland.com/kolproxy/wiki/" target="_blank">Kolproxy documentation</a> (opens in a new tab)</center></td></tr>
			</td></tr></table></center>
]], "Kolproxy special pages") .. make_kol_html_frame([[
			<center><table><tr><td>
			<tr><td><center><input type="button" value="Reload Lua script files" onclick="javascript:clear_lua_script_cache(this)"></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=lua-console&pwd=]]..session.pwd..[[">Interactive Lua console</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=add-log-notes&pwd=]]..session.pwd..[[">Add log notes</a></center></td></tr>
			</td></tr></table></center>
]], "Developer tools")
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
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'limited', ajax: 1 }, function(res) {
			top.charpane.location = "charpane.php"
		})
	} else if (document.getElementById("settingsstandard").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'standard', ajax: 1 }, function(res) {
			top.charpane.location = "charpane.php"
		})
	} else if (document.getElementById("settingsdetailed").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'detailed', ajax: 1 }, function(res) {
			top.charpane.location = "charpane.php"
		})
	}
}
function click_cb(cb, name, stateset) {
	var cur = "no"
	if (cb.checked) {
		cur = "yes"
	}
	$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:name, stateset:stateset, value:cur, ajax: 1 }, function(res) {
		enableDiv(label);
	});
	return true;
}
function clear_lua_script_cache(button) {
	var pwd = ']] .. session.pwd .. [['
	$.post('custom-clear-lua-script-cache', { pwd: pwd }, function(res) {
		button.value = 'Script cache cleared!'
		setTimeout(function() { button.value = 'Reload Lua script files again' }, 3000)
	});
}
			</script>
		</head>
		<body>
]] .. text .. [[
		</body>
		</html>]]
end)
