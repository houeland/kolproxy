whichboard = 16 -- load jarlsberg leaderboard

register_setting {
	name = "enable super-compact menupane",
	description = "Use custom super-compact menupane",
	group = nil,
	default_level = "detailed",
}

add_printer("/game.php", function()
	if setting_enabled("enable super-compact menupane") then
		text = text:gsub([[(<frameset id=menuset rows=)"30,*"(>)]], [[%1"100, *"%2]])
	end
end)

add_printer("/topmenu.php", function()
	if setting_enabled("enable super-compact menupane") then
		lairlink = [[<a target='mainpane' href='lair.php'>lair</a>]]
		if ascensionpathid() == 9 then
			lairlink = [[<a target='mainpane' href='place.php?whichplace=bugbearship'>ship</a>]]
		end
		text = [[
<!DOCTYPE html>
<html>
<head>
<style type='text/css'>.sep{font-size:6px;font-family:arial;margin:0;padding:0;line-height:100%;} .sep:after{content:"/"} a{color:#000;font-size:11px;font-family:arial;margin:0;padding:0;} .a{background-color:#eeeeee;} .abc{display:inline-block;text-align:center;padding:3px 7px;line-height:13px;vertical-align:top;height:100%;} .title a{font-size:13px;font-weight:bold;}</style>
<style>
html, body{
	height:100%;
}
.centerBox{
	text-align:left;
	height: 100%;
}

.centerBox.outerContainer{
	position:relative;
	left:50%;
	float:left;
	clear:both;
	margin:10px 0;
	margin:0px;
}
.centerBox.innerContainer{
	position:relative;
	left:-50%;
}
</style>
</head>
<body style='margin:0px;'>
	<div class='centerBox outerContainer'>
		<div class='centerBox innerContainer'>
			<div class='abc a'><span class='title'><a target='mainpane' href='inventory.php?which=1'>inv</a><span class="sep"></span><a target='mainpane' href='inventory.php?which=2'>ent</a><span class="sep"></span><a target='mainpane' href='inventory.php?which=3'>ory</a></span><br><a target='mainpane' href='inventory.php?which=4'>fav</a> <a target='mainpane' href='craft.php'>craft</a><br><a target='mainpane' href='sellstuff.php'>sell</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='main.php'>main</a> <a target='mainpane' href='messages.php'>mess</a></span><br><a target='mainpane' href='campground.php'>ca</a><span class="sep"></span><a target='mainpane' href='campground.php?action=telescopelow'>mp</a> <a target='mainpane' href='account.php'>opt</a> <a target='mainpane' href='custom-settings?pwd=]] .. session.pwd .. [['>kp</a><br><a target='mainpane' href='questlog.php?which=1'>qu</a><span class="sep"></span><a target='mainpane' href='questlog.php?which=4'>est</a> <a target='mainpane' href='skills.php'>skills</a> </div>

			<div class='abc a'><span class='title'><a target='mainpane' href='town_clan.php'>cl</a><span class="sep"></span><a target='mainpane' href='clan_office.php'>an</a> <a target='mainpane' href='clan_log.php?classic=true'>log</a></span><br><a target='mainpane' href='clan_raidlogs.php'>raid</a> <a target='mainpane' href='clan_slimetube.php'>sl</a> <a target='mainpane' href='clan_hobopolis.php'>sew</a><br><a target='mainpane' href='clan_viplounge.php'>VIP</a> <a target='mainpane' href='clan_stash.php'>stash</a> <a target='mainpane' href='clan_whitelist.php'>wl</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='town.php'>town</a> <a target='mainpane' href='town_wrong.php'>tra</a><span class="sep"></span><a target='mainpane' href='town_right.php'>cks</a></span><br><a target='mainpane' href='museum.php?place=leaderboards&whichboard=]]..whichboard..[['>board</a> <a target='mainpane' href='typeii.php'>t2</a> <a target='mainpane' href='guild.php'>guild</a> <br><a target='mainpane' href='manor.php'>ma</a><span class="sep"></span><a target='mainpane' href='manor2.php'>no</a><span class="sep"></span><a target='mainpane' href='manor3.php'>r</a></div>

			<div class='abc a'><span class='title'><a target='mainpane' href='council.php'>council</a> </span><br><a target='mainpane' href='mrstore.php'>mr</a> <a target='mainpane' href='store.php?whichstore=m'>store</a><br><a target='mainpane' href='storage.php?which=5'>hagnk</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='plains.php'>plains</a> </span><br><a target='mainpane' href='cobbsknob.php'>kn</a><span class="sep"></span><a target='mainpane' href='cobbsknob.php?action=tolabs'>ob</a><br><a target='mainpane' href='crypt.php'>cyr</a> <a target='mainpane' href='bathole.php'>bat</a> <a target='mainpane' href='beanstalk.php'>stalk</a></div>

			<div class='abc a'><span class='title'><a target='mainpane' href='mountains.php'>mount</a> <a target='mainpane' href='peevpee.php'>pvp</a></span><br><a target='mainpane' href='mclargehuge.php'>mcl</a> <a target='mainpane' href='cave.php'>cave</a> <a target='mainpane' href='tutorial.php'>noob</a><br><a target='mainpane' href='da.php'>da</a> <a target='mainpane' href='hermit.php'>hermit</a></div>

			<div class='abc'><span class='title'><a target='mainpane' href='beach.php'>beach</a></span><br><a target='mainpane' href='pyramid.php'>pyr</a> <a target='mainpane' href='shore.php'>shore</a> <br><a target='mainpane' href='mall.php'>mall</a> <a target='mainpane' href='bordertown.php'>border</a></div>

			<div class='abc a'><span class='title'><a target='mainpane' href='island.php'>island</a></span><br><a target='mainpane' href='cove.php'>cove</a> <a target='mainpane' href='volcanoisland.php'>vol</a><br><span class='title'>]]..lairlink..[[</span></div>

			<div class='abc'><span class='title'><a target='mainpane' href='woods.php'>woods</a> </span><br><a target='mainpane' href='tavern.php'>tavern</a> <a target='mainpane' href='forestvillage.php?place=untinker'>unt</a><br><a target='mainpane' href='friars.php'>friars</a> <a target='mainpane' href='bhh.php'>bhh</a> </div>

			<div class='abc a'><span class='title'><a target='_top' href='logout.php'>log out</a></span><br><a target='kolcalendar' href='http://noblesse-oblige.org/calendar/'>cal</a> <a target='koldonate' href='donatepopup.php'>donate</a><br><a target='mainpane' href='adminmail.php'>bug</a> <a href='http://radio.kingdomofloathing.com/' target='kolradio'>radio</a></div>
		</div>
	</div>
</body>
</html>
]]
	end
end)
