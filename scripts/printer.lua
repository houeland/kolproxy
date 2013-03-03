-- printer.lua

-- io = nil
os = nil
-- debug = nil
require = nil
module = nil
package = nil
set_state = nil

local printers = {}
local noncombat_choice_texts = {}

-- TODO: probably shouldn't be handled like this(?)
function set_state()
	error "You can't change state (counters, etc.) from add_printer, that's just for changing what's displayed. You might want add_processor() instead for registering game state changes?"
end

function wrapped_function()

reset_pageload_cache()

local mods = {}

kolproxy_log_time_interval("mods setup", function()
-- if text:match([[src="[^"]*%?[^"]*.js"]]) then
-- 	print("\n\n\n=======\n\n\n", "Warning: ? query js file (CDM should fix this)", path, text:match([[src="[^"]*%?[^"]*.js"]]), "\n\n\n=======\n\n\n")
-- end

if path == "/login.php" then
	local current_version = get_current_kolproxy_version()
	local latest_version = get_latest_kolproxy_version()
	mods["/login.php"] = {
--		[ [[<input class=button type=submit value="Log In" name=submitbutton id=submitbutton>]] ] = [[<input class="button" type="submit" value="Log In" style="color: gray" name="submitbutton" id="submitbutton" disabled="disabled">]],
--		["<font size=1>If you've forgotten your password"] = [[<div id="jswarning" style="color: red">You have to turn on javascript, otherwise you'll submit your password in cleartext!</div><script type="text/javascript">if (md5s) { document.getElementById('jswarning').style.display = 'none'; document.getElementById('submitbutton').value = 'Log In'; document.getElementById('submitbutton').disabled = ''; document.getElementById('submitbutton').style.color = 'black'; }</script>%0]],
	}
	if current_version ~= "3.8-beta" then
		mods["/login.php"]["An Adventurer is You!<br>"] = [[An Adventurer is You!<br><a href="http://www.houeland.com/kolproxy/wiki/Installation" target="_blank" style="color: red; text-decoration: none;">{ Kolproxy v]]..current_version..[[ incorrect installation. }</a><br><a href="http://www.houeland.com/kolproxy/wiki/Installation" target="_blank" style="color: red; font-size: smaller;">{ Click here to download a working version. }</a>]]
	elseif latest_version and current_version ~= latest_version and latest_version ~= "3.8-alpha" then
		print("current version", current_version, "latest version", latest_version)
		mods["/login.php"]["An Adventurer is You!<br>"] = [[An Adventurer is You!<br><a href="http://www.houeland.com/kolproxy/wiki/Installation" target="_blank" style="color: darkorange; text-decoration: none;">{ Kolproxy v]]..current_version..[[, latest version is v]]..latest_version..[[ }</a><br><a href="http://www.houeland.com/kolproxy/wiki/Installation" target="_blank" style="color: darkorange; font-size: smaller;">{ Click here to upgrade. }</a>]]
	else
		mods["/login.php"]["An Adventurer is You!<br>"] = [[An Adventurer is You!<br><span style="color: green">{ Kolproxy v]]..current_version..[[ }</span><br>]]
	end
end

-- mods["/bhh.php"] = {
-- 	["<form method=post action=bhh.php><input type=hidden name=pwd value=%x+><input type=hidden name=action value=\"abandonbounty\"><center><input type=submit class=button value=\"I Give Up!\"></center></form>"] =
-- 		"<center><a href=\"automate-bhh\" style=\"color:green\">{ automate }</a></center><p>%0",
-- }

mods["/showplayer.php"] = { -- This can also be done by adding header_noframecheck=1 to the URL query
	[ [[if %(parent.frames.length == 0%) location.href="game.php";]] ] = ""
}

mods["/peevpee.php"] = {
	[ [[if %(parent.frames.length == 0%) location.href="game.php";]] ] = ""
}

local pwd = "?"

if can_read_state() then
	pwd = session.pwd
end

mods["/compactmenu.php"] = {
	[ [[(<option value="logout.php">Log Out</option>.-)(</select>)]] ] = [[%1
<option value="nothing">- Select -</option>%2]],
	[ [[<option value="account.php">Account Menu</option>]] ] = [[%0<option value="custom-settings?pwd=]] .. pwd .. [[">Kolproxy Settings</option>]],
}

mods["/topmenu.php"] = {
	[ [[(<option value="logout.php">Log Out</option>.-)(</select>)]] ] = [[%1
<option value="nothing">- Select -</option>%2]],
	[ [[<option value="account.php">Options</option>]] ] = [[%0<option value="custom-settings?pwd=]] .. pwd .. [[">Kolproxy Settings</option>]],
}

mods["/main.php"] = {
	[ [[title="Bottom Edge".-</table>]] ] = [[%0<table><tr><td><a href="custom-settings?pwd=]] .. pwd .. [[" style="color: green">{ Kolproxy settings and tools }</a></td></tr></table>]]
}

mods["/charsheet.php"] = {
	[ [[>Ascensions:</a></td><td><b>[0-9,.]-</b>]] ] = [[%0 <a href="custom-logs?pwd=]] .. pwd .. [[" style="color:green">{ View logs }</a>]]
}

mods["/loggedout.php"] = {
	[ [[</body>]] ] = [[<center><a href="]]..make_href("/kolproxy-shutdown", { secretkey = get_shutdown_secret_key() })..[[" style="color: green">{ Close kolproxy }</a></center>%0]],
}

end)

kolproxy_log_time_interval("mods run", function()
for from, to in pairs(mods[path] or {}) do
	text = text:gsub(from, to, 1)
end
end)

if not can_read_state() then
	return text
end

function get_noncombat_choice_spoilers(advtitle)
	return noncombat_choice_texts[advtitle]
end

if path == "/charpane.php" then
	text = text:gsub([[(<td align=right>Meat:.-)(</table>)]], "%1<!-- charpane compact text space -->%2")
	text = text:gsub([[(src="http://images.kingdomofloathing.com/itemimages/hourglass.gif".-</table>)]], "%1<!-- charpane normal text space -->")
	text = text:gsub([[(src=http://images.kingdomofloathing.com/itemimages/slimhourglass.gif.-</table>)]], "%1<!-- charpane normal text space -->")

	text = text:gsub([[(<a target=mainpane href="familiar.php" class="familiarpick"><img src="http://images.kingdomofloathing.com/itemimages/)([^"]-)(.gif" width=30 height=30 border=0></a><br>)([0-9]+)( lb.-)(</center>)]], "%1%2%3%4%5<!-- charpane compact familiar text space type{%2} weight{%4} -->%6") -- TODO-future: redo without .-?
	text = text:gsub([[(<a target=mainpane href="familiar.php" class="familiarpick"><img src="http://images.kingdomofloathing.com/itemimages/)([^"]-)(.gif" width=30 height=30 border=0>.- <b>)([0-9]+)(</b> pound .-)(</table></center>)]], "%1%2%3%4%5<!-- charpane normal familiar text space type{%2} weight{%4} -->%6") -- TODO-future: redo without .-!
end

kolproxy_log_time_interval("setup variables", setup_variables)

reset_charpane_values()

kolproxy_log_time_interval("do run_functions", function()
if path == "/charpane.php" and text:contains("inf_small.gif") then
	-- Hack for valhalla
else
	text = run_functions(path, text, function(target, pt)
		for _, x in ipairs(printers[target] or {}) do
			getfenv(x.f).text = pt
-- 			kolproxy_log_time_interval("run:" .. tostring(x.scriptname), x.f)
			x.f()
			pt = getfenv(x.f).text
		end
		return pt
	end)
end
end)

if path == "/fight.php" then
	if text:contains("state['fightover'] = true;") or text:contains("<!--WINWINWIN-->") or text:contains("You slink away, dejected and defeated.") then -- TODO: HACK! state fightover only works with combat bar enabled!!
-- 	print("resetting fight state!")
		reset_fight_state()
	end
end

if path == "/charpane.php" then
kolproxy_log_time_interval("do charpane lines", function()
	text = print_charpane_lines(text)
end)
end

-- TODO: Redo!
if choice_adventure_number or path == "/choice.php" then
	text = do_choice_page_printing(text, title, adventure_title, choice_adventure_number)
end

if text:contains("charpane.php") then
	if path:contains("afterlife.php") or path:contains("charpane.php") then
	else
		-- ensure API load before returning page
		kolproxy_log_time_interval("do ensure-status", status)
	end
end

--text = text:gsub("</head>", function(head) return string.format([[<script type="text/javascript">var kolproxy_effective_url = %q</script>%s]], path .. query, head) end)

return text

end



local envstoreinfo = loadfile("scripts/setup-environment.lua")()

function dofile(f)
	load_script("../" .. f)
end

load_script("base/util.lua")

load_script("base/choice-page.lua")

envstoreinfo.g_env.setup_functions()
tostring = envstoreinfo.g_env.tostring

local function add_printer_raw(file, func, scriptname)
	if not printers[file] then printers[file] = {} end
	table.insert(printers[file], { f = func, scriptname = scriptname })
end

local function add_choice_text_raw(title, data)
	if not noncombat_choice_texts[title] then noncombat_choice_texts[title] = {} end
	table.insert(noncombat_choice_texts[title], data)
end

envstoreinfo.g_env.load_script_files {
	add_printer_raw = add_printer_raw,
	add_choice_text = add_choice_text_raw,
}

function run_wrapped_function(f_env)
	envstoreinfo.f_store = f_env
	envstoreinfo.f_store.input_params = envstoreinfo.f_store.raw_input_params
	envstoreinfo.f_store.params = envstoreinfo.g_env.parse_params(envstoreinfo.f_store.raw_input_params)

	envstoreinfo.store_target = envstoreinfo.f_store
	envstoreinfo.store_target_name = "f_store"
	return wrapped_function()
end

return run_wrapped_function
