register_setting {
	name = "enable super-compact menupane",
	description = "Use custom super-compact menupane",
	group = nil,
	default_level = "detailed",
	update_menupane = true,
}

register_setting {
	name = "enable bleary menupane",
	description = "Use bleary's version",
	group = nil,
	default_level = "enthusiast",
	parent = "enable super-compact menupane",
	update_menupane = true,
	beta_version = true,
}

register_setting {
	name = "enable most-recently-used list",
	description = "Keep track of and present the ten most-recently-used skills, items, and shop purchases",
	group = nil,
	default_level = "detailed",
	parent = "enable bleary menupane",
	update_menupane = true,
	beta_version = true,
}

add_printer("/game.php", function()
	if setting_enabled("enable super-compact menupane") then
		text = text:gsub([[(<frameset id=menuset rows=)"30,*"(>)]], [[%1"100, *"%2]])
	end
end)

local museum_href = add_automation_script("latest-leaderboard", function()
	local pt = get_page("/museum.php")
	local highest = nil
	for xt in pt:gmatch("whichboard=([0-9]+)") do
		local x = tonumber(xt)
		if x and x > (highest or -1) and x ~= 999 then
			highest = x
		end
	end
	return get_page("/museum.php", { place = "leaderboards", whichboard = highest })
end)

add_processor("/storage.php", function()
	if params.action and ascensionstatus("Softcore") then
		session["topmenu storage pulls display"] = nil
	end
end)

add_printer("all pages", function()
	if not setting_enabled("enable super-compact menupane") then return end
	if locked() then return end
	if session["topmenu storage pulls display"] == tostring(ascensionstatus()) .. ":" .. tostring(ascensionpathname()) then return end
	if text:contains("</head>") then
		text = text:gsub("</head>", [[<script type="text/javascript">top.menupane.location = "topmenu.php"</script>
</head>]])
	end
end)

add_printer("/storage.php", function()
	if not setting_enabled("enable super-compact menupane") then return end
	if locked() then return end
	if session["topmenu storage pulls display"] == tostring(ascensionstatus()) .. ":" .. tostring(ascensionpathname()) then return end
	text = text:gsub("<script", [[<script type="text/javascript">top.menupane.location = "topmenu.php"</script><script]], 1)
end)

function pullsleft()
	if ascensionstatus("Hardcore") then return 0 end
	if ascensionstatus("Aftercore") then return 1000 end
	local pt = get_page("/storage.php", { which = 5 })
	if pt:contains("You may not take any more") then
		return 0
	else
		return tonumber(pt:match([[<span class="pullsleft">(.-)</span>]]))
	end
end

local function get_mrulist()
	return session["mrulist"] or { mru = {}, paramlookup = {} }
end

local function stack_mrulist_command(desc, params)
	local mrulist = get_mrulist()
	-- desc must be a string for json reasons
	if mrulist.paramlookup[desc] then
		--- command in the table
		for i, v in ipairs(mrulist.mru) do
			if v == desc then
				-- remove previous spot
				table.remove(mrulist.mru, i)
				break
			end
		end
	else
		-- new command, save params
		mrulist.paramlookup[desc] = params
	end
	table.insert(mrulist.mru, desc)
	while #mrulist.mru > 10 do
		-- keep it at 10 items
		local dropped = table.remove(mrulist.mru, 1)
		mrulist.paramlookup[dropped] = nil
	end
	session["mrulist"] = mrulist
end

add_interceptor("/topmenu.php", function()
	if not setting_enabled("enable super-compact menupane") then return end
	local hagnk_pulls = ""
	if ascensionstatus("Softcore") then
		hagnk_pulls = " (?)"
		if not locked() then
			local pt = get_page("/storage.php", { which = 5 })
			local pulls = pullsleft()
			if pulls and pulls >= 0 then
				hagnk_pulls = " (" .. pulls .. ")"
			end
			session["topmenu storage pulls display"] = tostring(ascensionstatus()) .. ":" .. tostring(ascensionpathname())
		end
	else
		session["topmenu storage pulls display"] = tostring(ascensionstatus()) .. ":" .. tostring(ascensionpathname())
	end
	local lairlink = [[<a target='mainpane' href='place.php?whichplace=nstower'>lair</a>]]
	if ascensionpathid() == 9 then
		lairlink = [[<a target='mainpane' href='place.php?whichplace=bugbearship'>ship</a>]]
	end
	if playername():match("^Devster[0-9]+$") then
		lairlink = lairlink .. [[ <span class='title'><a target='mainpane' href='devster.php'>dev</a></span>]]
	end

	local my_levels = {}
	for l = 2, math.min(13, level()) do
		table.insert(my_levels, ".abc .child a.l" .. l)
	end
	local mru_list = {}
	if setting_enabled("enable bleary menupane") and setting_enabled("enable most-recently-used list") then
		table.insert(mru_list, [[<div class='abc'><select id="mrulist"><option></option>]])
		local session_mru = get_mrulist()
		for i = #session_mru.mru, 1, -1 do
			local v = session_mru.mru[i]
			local explan_txt = ""
			local mru_params = session_mru.paramlookup[v]
			local n = tonumber(mru_params.bufftimes) or tonumber(mru_params.quantity) or tonumber(mru_params.howmany) or 1
			local count = ""
			if n > 1 then
				count = n .. "x"
			end
			if mru_params.whichstore then
				explan_txt = string.format([[buy %s %s]], maybe_get_itemname(tonumber(mru_params.whichitem)), count )
			elseif mru_params.whichskill then
				explan_txt = string.format([[cast %s %s]], maybe_get_skillname(tonumber(mru_params.whichskill)), count )
			elseif mru_params.whichitem then
				explan_txt = string.format([[use %s %s]], maybe_get_itemname(tonumber(mru_params.whichitem)), count )
			end
			table.insert(mru_list, string.format([[<option params='%s'>%s</option>]], tojson(mru_params), explan_txt))
		end
		table.insert(mru_list, "</select></div>")
	end

	if setting_enabled("enable bleary menupane") then
		return make_bleary_topmenu_html(lairlink, hagnk_pulls, my_levels, mru_list)
	else
		return make_compact_topmenu_html(lairlink, hagnk_pulls)
	end
end)

add_processor("/runskillz.php", function()
	if not setting_enabled("enable most-recently-used list") then return end
	if params and params.whichskill then
		local desc = string.format("cast %i %i", tonumber(params.quantity or 1), tonumber(params.whichskill))
		stack_mrulist_command(desc, params)
	end
end)

add_processor("/inv_use.php", function()
	if not setting_enabled("enable most-recently-used list") then return end
	local desc = string.format("use %i %i", tonumber(params.quantity or 1), tonumber(params.whichitem))
	stack_mrulist_command(desc, params)
end)


add_processor("/multiuse.php", function()
	if not setting_enabled("enable most-recently-used list") then return end
	local desc = string.format("use %i %i", tonumber(params.quantity or 1), tonumber(params.whichitem))
	stack_mrulist_command(desc, params)
end)

-- TODO: convert to shop.php(?)
add_processor("/store.php", function()
	if not setting_enabled("enable most-recently-used list") then return end
	if params and params.whichitem then
		local desc = string.format("buy %i %i", tonumber(params.howmany or 1), tonumber(params.whichitem))
		stack_mrulist_command(desc, params)
	end
end)

make_compact_topmenu_html = function(lairlink, hagnk_pulls)
	return [[
<!DOCTYPE html>
<html>
<head>
<style type='text/css'>
.sep { font-size: 6px; font-family: arial; margin:0; padding:0; line-height:100%; }
.sep:after { content: "/" }
a { color: #000; font-size: 11px; font-family: arial; margin: 0; padding:0; }
.a { background-color: #eeeeee; }
.abc { display: inline-block; text-align: center; padding: 3px 7px; line-height: 13px; vertical-align: top; height: 100%; }
.title a { font-size: 13px; font-weight: bold; }
</style>
<style>
html, body {
	height:100%;
}
.centerBox {
	text-align:left;
	height: 100%;
}

.centerBox.outerContainer {
	position: relative;
	left: 50%;
	float: left;
	clear: both;
	margin: 10px 0;
	margin: 0px;
}
.centerBox.innerContainer {
	position: relative;
	left: -50%;
}
</style>
</head>
<body style='margin: 0px;'>
	<div class='centerBox outerContainer'>
		<div class='centerBox innerContainer'>
			<div class='abc a'><span class='title'><a target='mainpane' href='inventory.php?which=1'>inv</a><span class="sep"></span><a target='mainpane' href='inventory.php?which=2'>ent</a><span class="sep"></span><a target='mainpane' href='inventory.php?which=3'>ory</a></span><br><a target='mainpane' href='inventory.php?which=f0'>fav</a> <a target='mainpane' href='craft.php'>craft</a><br><a target='mainpane' href='sellstuff.php'>sell</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='main.php'>main</a> <a target='mainpane' href='messages.php'>inbox</a></span><br><a target='mainpane' href='campground.php'>ca</a><span class="sep"></span><a target='mainpane' href='campground.php?action=telescopelow'>mp</a> <a target='mainpane' href='account.php'>opt</a> <a target='mainpane' href='custom-settings?pwd=]] .. session.pwd .. [['>kp</a><br><a target='mainpane' href='questlog.php?which=1'>qu</a><span class="sep"></span><a target='mainpane' href='questlog.php?which=4'>est</a> <a target='mainpane' href='skills.php'>skills</a> </div>

			<div class='abc a'><span class='title'><a target='mainpane' href='town_clan.php'>cl</a><span class="sep"></span><a target='mainpane' href='clan_office.php'>an</a> <a target='mainpane' href='clan_log.php?classic=true'>log</a></span><br><a target='mainpane' href='clan_raidlogs.php'>raid</a> <a target='mainpane' href='clan_slimetube.php'>sl</a> <a target='mainpane' href='clan_hobopolis.php'>sew</a><br><a target='mainpane' href='clan_viplounge.php'>VIP</a> <a target='mainpane' href='clan_stash.php'>stash</a> <a target='mainpane' href='clan_whitelist.php'>wl</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='town.php'>town</a> <a target='mainpane' href='town_wrong.php'>tra</a><span class="sep"></span><a target='mainpane' href='town_right.php'>cks</a></span><br><a target='mainpane' href=']]..museum_href { pwd = session.pwd }..[['>boa</a><span class="sep"></span><a target='mainpane' href='museum.php?floor=1&place=leaderboards&whichboard=999'>rds</a> <a target='mainpane' href='guild.php'>guild</a> <br><a target='mainpane' href='manor.php'>ma</a><span class="sep"></span><a target='mainpane' href='manor2.php'>no</a><span class="sep"></span><a target='mainpane' href='manor3.php'>r</a> <a target='mainpane' href='galaktik.php'>doc</a></div>

			<div class='abc a'><span class='title'><a target='mainpane' href='council.php'>council</a> </span><br><a target='mainpane' href='mrstore.php'>mr</a> <a target='mainpane' href='shop.php?whichshop=generalstore'>store</a><br><a target='mainpane' href='storage.php?which=5'>hagnk]] .. hagnk_pulls .. [[</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='place.php?whichplace=plains'>plains</a> </span><br><a target='mainpane' href='cobbsknob.php'>kn</a><span class="sep"></span><a target='mainpane' href='cobbsknob.php?action=tolabs'>ob</a> <a target='mainpane' href='place.php?whichplace=bathole'>bat</a><br><a target='mainpane' href='crypt.php'>cyr</a> <a target='mainpane' href='place.php?whichplace=beanstalk'>sta</a><span class="sep"></span><a target='mainpane' href='place.php?whichplace=giantcastle'>lk</a></div>

			<div class='abc a'><span class='title'><a target='mainpane' href='mountains.php'>mount</a> <a target='mainpane' href='peevpee.php'>pvp</a></span><br><a target='mainpane' href='place.php?whichplace=mclargehuge'>mcl</a> <a target='mainpane' href='place.php?whichplace=highlands'>high</a> <a target='mainpane' href='cave.php'>cave</a><br><a target='mainpane' href='da.php'>da</a> <a target='mainpane' href='hermit.php'>hermit</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='place.php?whichplace=desertbeach'>beach</a></span><br><a target='mainpane' href='place.php?whichplace=pyramid'>pyr</a><br><a target='mainpane' href='mall.php'>mall</a> <a target='mainpane' href='bordertown.php'>border</a></div>

			<div class='abc a'><span class='title'><a target='mainpane' href='island.php'>island</a></span><br><a target='mainpane' href='cove.php'>cove</a> <a target='mainpane' href='volcanoisland.php'>vol</a><br><span class='title'>]]..lairlink..[[</span></div>

			<div class='abc'><span class='title'><a target='mainpane' href='woods.php'>woods</a> </span><br><a target='mainpane' href='tavern.php'>tavern</a> <a target='mainpane' href='place.php?whichplace=forestvillage&action=fv_untinker'>unt</a><br><a target='mainpane' href='place.php?whichplace=forestvillage&action=fv_friar'>fl</a> <a target='mainpane' href='friars.php'>friars</a> <a target='mainpane' href='bhh.php'>bhh</a> </div>

			<div class='abc a'><span class='title'><a target='_top' href='logout.php'>log out</a></span><br><a target='kolcalendar' href='http://noblesse-oblige.org/calendar/'>cal</a> <a target='koldonate' href='donatepopup.php'>donate</a><br><a target='mainpane' href='adminmail.php'>bug</a> <a target='mainpane' href='community.php'>comm</a></div>
		</div>
	</div>
</body>
</html>
]]
end

make_bleary_topmenu_html = function(lairlink, hagnk_pulls, my_levels, mru_list)
	return [[
<!DOCTYPE html>
<html>
<head>
<style type='text/css'>
a {
	color: #000;
	font-size: 11px;
	font-family: arial,Helvetica,sans-serif;
	margin: 0;
	padding: 0;
}

.abc:nth-child(even) { background-color: #f0f0f0; }

.sep { width: 10px; }

body { text-align: center; }

.abc {
	display: inline-block;
	text-align: center;
	padding: 3px 3px 3px 3px;
	line-height: 13px;
	vertical-align: top;
}

.abc a {
	font-size: 13px;
	color: blue;
	padding: 0px 0px 0px 1px;
}

.abc .child a {
	font-size: 11px;
	color: #aaa;
}

.abc:hover .child a { color: black; }

.abc:hover { background: #ddd; }

]] .. table.concat(my_levels, ", ") .. [[ {
	color: black;
}

</style>
<script language=Javascript src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script language="javascript">
function dojax(dourl, method, success_msg, params) {
	$.ajax({
		type: method || 'GET', url: dourl, cache: false,
		data: params || null,
		global: false,
async: false,
		success: function (out) {
			if (out.match(/no\|/)) {
				var parts = out.split(/\|/)
				alert("Error doing: " + success_msg + ".")
				return
			}
			var eff = $(top.mainpane.document).find('#effdiv');
			if (eff.length == 0) {
				var d = top.mainpane.document.createElement('DIV');
				d.id = 'effdiv';
				var b = top.mainpane.document.body;
				if ($('#content_').length > 0) {
					b = $('#content_ div:first')[0];
				}
				b.insertBefore(d, b.firstChild);
				eff = $(d);
			}
			eff.find('a[name="effdivtop"]').remove().end().prepend('<a name="effdivtop"></a><center>' + out + '</center>').css('display','block');
			if (!window.dontscroll || (window.dontscroll && dontscroll==0)) {
				top.mainpane.document.location = top.mainpane.document.location + "#effdivtop";
			}
}})}

$(document).ready(function() {
$("#mrulist").change(function() {
	var sel_opt = $("#mrulist option:selected")
	var params = JSON.parse(sel_opt.attr("params"))
	var url = "/inv_use.php"
	if (params['whichskill']) url = "/runskillz.php"
	if (params['whichstore']) url = "/store.php"
	dojax(url, "GET", sel_opt.attr("text"), params)
	top.menupane.location = "topmenu.php"
})

})
</script>

</head>
<body style='margin: 0px;'>
  <div class='abc'>
    <span class='title'><a target='mainpane' href='inventory.php?which=1'>inv</a><a target='mainpane' href='inventory.php?which=2'>ent</a><a target='mainpane' href='inventory.php?which=3'>ory</a></span>
    <div class='child'>
      <a target='mainpane' href='inventory.php?which=f0'>fav</a> <a target='mainpane' href='craft.php'>craft</a><br>
      <a target='mainpane' href='sellstuff.php'>sell</a> <a target='mainpane' href='mall.php'>mall</a> <a target='mainpane' href='storage.php?which=5'>hagnk</a>
    </div>
  </div>

  <div class='abc'>
    <a target='mainpane' href='main.php'>main</a> <a target='mainpane' href='messages.php'>msgs</a>
    <div class='child'>
      <a target='mainpane' href='campground.php'>camp</a> <a target='mainpane' href='account.php'>acct</a><br>
      <a target='mainpane' href='skills.php'>skills</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='town_clan.php'>cl</a><a target='mainpane' href='clan_office.php'>an</a> <a target='mainpane' href='clan_log.php?classic=true'>log</a></span>
    <div class='child'>
      <a target='mainpane' href='clan_raidlogs.php'>raid</a>
      <a target='mainpane' href='clan_slimetube.php'>slime</a>
      <a target='mainpane' href='clan_hobopolis.php'>swrs</a><br>
      <a target='mainpane' href='clan_stash.php'>stash</a>
      <a target='mainpane' href='clan_viplounge.php'>VIP</a>
      <a target='mainpane' href='clan_whitelist.php'>wl</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='town.php'>town</a> <a target='mainpane' href='town_wrong.php'>wr</a> <a target='mainpane' href='town_right.php'>ri</a></span>
    <div class='child'>
      <a target='mainpane' href='guild.php'>guild</a> <a target='mainpane' href='galaktik.php'>doc</a><br>
      <a target='mainpane' href='manor.php'>manor</a> <a target='mainpane' href='manor2.php'>2</a> <a target='mainpane' href='manor3.php'>3</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='council.php'>council</a> <a target='mainpane' href='peevpee.php'>pvp</a></span>
    <div class='child'>
      <a target='mainpane' href='mrstore.php'>mr</a> <a target='mainpane' href='shop.php?whichshop=generalstore'>store</a><br>
      <a target='mainpane' href='place.php?whichplace=forestvillage&action=fv_friar'>florist</a>
      <a target='mainpane' href='bhh.php'>bhh</a>
      <a target='mainpane' href='campground.php?action=telescopelow'>scope</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='place.php?whichplace=plains'>plains</a></span>
    <div class='child'>
      <a target='mainpane' href='cobbsknob.php' class="l5">knob</a> <a target='mainpane' href='cobbsknob.php?action=tolabs' class="l5">2</a>
      <a target='mainpane' class="l4" href='place.php?whichplace=bathole'>bat</a><br>
      <a target='mainpane' href='crypt.php' class="l7">cyr</a> <a target='mainpane' href='place.php?whichplace=beanstalk' class="l10">stalk</a> <a target='mainpane' href='place.php?whichplace=giantcastle' class="l10">castle</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='mountains.php'>mountains</a></span>
    <div class='child'>
      <a target='mainpane' href='place.php?whichplace=mclargehuge' class="l8">mchuge</a> <a target='mainpane' href='place.php?whichplace=highlands' class="l9">hghlnds</a><br>
      <a target='mainpane' href='cave.php'>cave</a>
      <a target='mainpane' href='da.php'>da</a> <a target='mainpane' href='hermit.php'>hermit</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='place.php?whichplace=desertbeach'>beach</a> <a target='mainpane' href='island.php'>islnd</a></span>
    <div class='child'>
      <a target='mainpane' href='place.php?whichplace=pyramid' class="l11">pyr</a>
       <a target='mainpane' href='bordertown.php'>border</a><br>
      <a target='mainpane' href='cove.php'>cove</a> <a target='mainpane' href='volcanoisland.php'>vol</a>
      <a target='mainpane' href='lair.php' class="l13">lair</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='mainpane' href='woods.php'>woods</a></span>
    <div class='child'>
      <a target='mainpane' href='tavern.php' class="l3">tavern</a> <a target='mainpane' href='place.php?whichplace=forestvillage&action=fv_untinker'>unt</a><br />
      <a target='mainpane' href="place.php?whichplace=hiddencity" class="l11">city</a>
      <a target='mainpane' href='friars.php' class="l6">friars</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a target='_top' href='topmenu.php'>info</a></span>
    <div class='child'>
      <a target='kolcalendar' href='http://noblesse-oblige.org/calendar/'>cal</a>
      <a target='mainpane' href='/kolproxy-automation-script?pwd=]] .. session.pwd .. [[&amp;automation-script=latest-leaderboard'>board</a>
      <a target='mainpane' href='typeii.php'>t2</a><br>
      <a target='mainpane' href='questlog.php?which=1'>qlog</a>
      <a target='mainpane' href='questlog.php?which=4'>note</a>
    </div>
  </div>

  <div class='abc'>
    <span class='title'><a href='topmenu.php'>misc</a> <a target=
      'mainpane' href=
      'custom-settings?pwd=]] .. session.pwd .. [['>kprox</a>
    </span>
    <div class='child'>
      <a target='_top' href='logout.php'>log out</a>
      <a target='mainpane' href='/bl-lua-console'>lua</a>
      <a target='koldonate' href='donatepopup.php'>donate</a><br>
      <a target='mainpane' href='adminmail.php'>bug</a> <a href='http://radio.kingdomofloathing.com/' target='kolradio'>radio</a>
    </div>
  </div>

]] .. table.concat(mru_list, "\n") .. [[

</body>
</html>
]]
end
