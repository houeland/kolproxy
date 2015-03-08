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
	tbl.name = tbl.name or tbl.server_name
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
	name = "automate simple tasks",
	description = "Automatically complete simple puzzles and tasks that don't cost turns",
	group = "automation",
	default_level = "standard",
}

register_setting {
	name = "automate costly tasks",
	description = "Automatically complete tasks that consume resources as well",
	group = "automation",
	default_level = "detailed",
	parent = "automate simple tasks",
}

register_setting {
	name = "enable adventure warnings",
	description = "Enable important adventure warnings about semirares, not having enough meat, already having an outfit, etc.",
	group = "warnings",
	default_level = "limited",
}

register_setting {
	name = "show extra warnings",
	description = "Add many extra reminders for things that are worth thinking about but not necessarily mistakes",
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
	update_charpane = true,
	update_menupane = true,
}

register_setting {
	name = "enable turnplaying automation",
	description = "Enable turn-playing automation scripts (for automated zone re-adventuring, aftercore quests, entire ascension, etc.)",
	group = "automation",
	default_level = "standard",
}

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
	local stbl = settings[name]
	if stbl.parent and not setting_enabled(stbl.parent) then return false end
	if stbl.beta_version and not setting_enabled("enable experimental implementations") then return false end
	local s = character["setting: " .. name]
	if s then
		return (s == "on")
	else
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
	local js_children_visibility = {}
	local js_top_level_features = {}
	for _, x in pairs(settings) do
		local g = x.group
		if not grouped[g] then g = "other" end
		local parent = x.name:match("(.+)/") or x.parent
		if parent then
			if not children[parent] then
				children[parent] = {}
				js_children_visibility[parent] = {}
			end
			table.insert(children[parent], x)
			table.insert(js_children_visibility[parent], x.name)
		else
			table.insert(js_top_level_features, x.name)
			table.insert(grouped[g], x)
		end
	end
	local featurerows = {}
	local radio_ctr = 0
	local feature_radio_names = {}
	local all_default_values = {}
	local charpane_updaters = {}
	local menupane_updaters = {}
	for _, x in ipairs(setting_groups) do
		if #grouped[x.name] > 0 then
			table.sort(grouped[x.name], function(a, b) return settings_order[a.name] < settings_order[b.name] end)
			table.insert(featurerows, [[<tr class="trheader"><th colspan="4">]] .. x.title .. [[</th></tr>]])
		end
		local function insert_setting_row(y, parentname)
			radio_ctr = radio_ctr + 1
			local radio_name = "radio_" .. radio_ctr
			feature_radio_names[y.name] = radio_name
			if y.server_name then
				local featuredesc = y.description .. [[<span style="color: gray"> (built-in KoL option)</span>]]
				local trstyle = ""
				local onchecked = (tonumber(api_flag_config()[y.server_name]) == 1) and [[ checked="checked"]] or ""
				local offchecked = (tonumber(api_flag_config()[y.server_name]) == 0) and [[ checked="checked"]] or ""
				if y.server_inverted then
					-- CDM is crazy
					onchecked, offchecked = offchecked, onchecked
				end
				if parentname then
					trstyle = string.format([[ class="childof_%s"]], feature_radio_names[parentname])
					featuredesc = "&ndash;&nbsp;" .. featuredesc
				end
				charpane_updaters[y.name] = y.update_charpane and true or false
				menupane_updaters[y.name] = y.update_menupane and true or false
				table.insert(featurerows, [[<tr data-feature-name="]]..y.server_name..[["]]..trstyle..[[><td class="tdname">]] .. featuredesc .. [[</td>]] ..
					[[<td class="tdserveron"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..onchecked..[[>On</td>]] ..
					[[<td class="tdserveroff"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..offchecked..[[>Off</td>]] ..
					[[<td></td></tr>]])
			else
				local onchecked = (character["setting: " .. y.name] == "on") and [[ checked="checked"]] or ""
				local offchecked = (character["setting: " .. y.name] == "off") and [[ checked="checked"]] or ""
				local defaultchecked = (character["setting: " .. y.name] == nil) and [[ checked="checked"]] or ""
				local baselevel = character["settings base level"] or "limited"
				local defaultvalue = (setting_levels[y.default_level or "enthusiast"] <= setting_levels[baselevel]) and "on" or "off"
				local desc_beta = ""
				if y.beta_version then
					desc_beta = " (<b>experimental beta version</b>)"
				end
				local featuredesc = [[<span title="Lua scripting syntax: setting_enabled(&quot;]] .. y.name .. [[&quot)">]] .. y.description .. desc_beta .. [[</span>]]
				local trstyle = ""
				if parentname then
					trstyle = string.format([[ class="childof_%s"]], feature_radio_names[parentname])
					featuredesc = "&ndash;&nbsp;" .. featuredesc
				end
				all_default_values[y.name] = defaultvalue
				charpane_updaters[y.name] = y.update_charpane and true or false
				menupane_updaters[y.name] = y.update_menupane and true or false
				if not y.hidden then
					table.insert(featurerows, [[<tr data-feature-name="]]..y.name..[["]]..trstyle..[[><td class="tdname">]] .. featuredesc .. [[</td>]] ..
						[[<td class="tdon"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..onchecked..[[>On</td>]] ..
						[[<td class="tdoff"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..offchecked..[[>Off</td>]] ..
						[[<td class="tddefault"><input type="radio" name="]]..radio_name..[[" onChange="changed_feature_setting(this)"]]..defaultchecked..[[>Default (]]..defaultvalue..[[)</td></tr>]])
				end
			end
		end
		local function recurse(y)
			local tbl = children[y.name] or {}
			table.sort(tbl, function(a, b) return settings_order[a.name] < settings_order[b.name] end)
			for _, z in ipairs(tbl) do
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
				.featuretable .tdserveron { border-right: thin dotted gray; }
				.featuretable .tdserveroff { border-right: thin dotted gray; }
			</style>
			<script language="Javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
			<script type="text/javascript">
var all_default_values = ]] .. table_to_json(all_default_values) .. [[

var charpane_updaters = ]] .. table_to_json(charpane_updaters) .. [[

var menupane_updaters = ]] .. table_to_json(menupane_updaters) .. [[

var js_children_visibility = ]] .. tojson(js_children_visibility) .. [[

var js_top_level_features = ]] .. tojson(js_top_level_features) .. [[

var js_settings = ]] .. tojson(settings) .. [[

function is_enabled(feature) {
	var c = $("[data-feature-name='" + feature + "'] input").filter(function() { return this.checked }).parent().attr("class")
	if (c == "tdon") return true
	else if (c == "tdserveron") return true
	else if (c == "tddefault" && all_default_values[feature] == "on") return true
	return false
}

function update_feature_visibility(feature, parentvisible) {
	if (js_settings[feature].beta_version && !is_enabled("enable experimental implementations")) parentvisible = false
	$("[data-feature-name='" + feature + "']").toggle(parentvisible)
	var isenabled = parentvisible && is_enabled(feature)
	if (feature in js_children_visibility) {
		for (var i = 0; i < js_children_visibility[feature].length; i += 1) {
			update_feature_visibility(js_children_visibility[feature][i], isenabled)
		}
	}
}

function refresh_visibility() {
	for (var i_ = 0; i_ < js_top_level_features.length; i_ += 1) {
		update_feature_visibility(js_top_level_features[i_], true)
	}
}

function changed_feature_setting(what) {
	var setting = $($(what).parents("tr")[0]).attr("data-feature-name")
	var c = $(what).parent("td").attr("class")
	var update_charpane = charpane_updaters[setting]
	var update_menupane = menupane_updaters[setting]
	if (c == "tdon") {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'setting: ' + setting, stateset:'character', value:'"on"', ajax: 1 }, function(res) {
			if (update_charpane) top.charpane.location = "charpane.php"
			if (update_menupane) top.menupane.location = "topmenu.php"
		})
	} else if (c == "tdoff") {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'setting: ' + setting, stateset:'character', value:'"off"', ajax: 1 }, function(res) {
			if (update_charpane) top.charpane.location = "charpane.php"
			if (update_menupane) top.menupane.location = "topmenu.php"
		})
	} else if (c == "tddefault") {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'setting: ' + setting, stateset:'character', value:'', ajax: 1 }, function(res) {
			if (update_charpane) top.charpane.location = "charpane.php"
			if (update_menupane) top.menupane.location = "topmenu.php"
		})
	} else if (c == "tdserveron") {
		$.post('account.php', { pwd:']]..session.pwd..[[', am:1, action:'flag_' + setting, value:1, ajax: 1 }, function(res) {
			if (update_charpane) top.charpane.location = "charpane.php"
			if (update_menupane) top.menupane.location = "topmenu.php"
		})
	} else if (c == "tdserveroff") {
		$.post('account.php', { pwd:']]..session.pwd..[[', am:1, action:'flag_' + setting, value:0, ajax: 1 }, function(res) {
			if (update_charpane) top.charpane.location = "charpane.php"
			if (update_menupane) top.menupane.location = "topmenu.php"
		})
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

add_interceptor("/custom-settings", function()
	if params.pwd ~= session.pwd then
		error("Invalid pwd field")
	end

	if params.action == "set state" then
		if params.stateset and params.name and params.value then
			local value = params.value
			if value == "" then value = nil end
			set_state(params.stateset, params.name, value)
			return "Done.", requestpath
		end
	end

	if params.page == "customize features" then
		text = get_customize_features_page()
		return text, requestpath
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
]], "Configure kolproxy features") .. make_kol_html_frame([[
			<center><table><tr><td>
			<tr><td><center><a href="custom-logs?pwd=]]..session.pwd..[[">Parse ascension log</a></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=custom-aftercore-automation&pwd=]]..session.pwd..[[">Setup/run scripts</a></center></td></tr>
			<tr><td><center><a href="http://www.houeland.com/kolproxy/wiki/" target="_blank">Kolproxy documentation</a> (opens in a new tab)</center></td></tr>
			</td></tr></table></center>
]], "Kolproxy page links") .. make_kol_html_frame([[
			<center><table><tr><td>
			<tr><td><center><input type="button" value="Reload Lua script files" onclick="javascript:clear_lua_script_cache(this)"></center></td></tr>
			<tr><td><center><a href="kolproxy-automation-script?automation-script=lua-console&pwd=]]..session.pwd..[[">Interactive Lua console</a></center></td></tr>
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
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'"limited"', ajax: 1 }, function(res) {
			top.charpane.location = "charpane.php"
			top.menupane.location = "topmenu.php"
		})
	} else if (document.getElementById("settingsstandard").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'"standard"', ajax: 1 }, function(res) {
			top.charpane.location = "charpane.php"
			top.menupane.location = "topmenu.php"
		})
	} else if (document.getElementById("settingsdetailed").checked) {
		$.post('custom-settings', { pwd:']]..session.pwd..[[', action:'set state', name:'settings base level', stateset:'character', value:'"detailed"', ajax: 1 }, function(res) {
			top.charpane.location = "charpane.php"
			top.menupane.location = "topmenu.php"
		})
	}
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
	return text, requestpath
end)
