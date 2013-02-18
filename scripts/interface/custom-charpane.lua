-- TODO: merge common code

-- TODO: custom buff coloring, sort order?

-- game.php
-- <frameset id=mainset cols="120,*">
-- <frameset id=mainset cols="200,*">

-- TODO: allow custom frame layouts?

register_setting {
	name = "use custom kolproxy charpane",
	description = "Replace character pane with speedy custom kolproxy version",
	group = "charpane",
	default_level = "standard",
}

register_setting {
	name = "use custom kolproxy charpane/use compact mode",
	description = "Use compact mode for custom kolproxy charpane",
	group = "charpane",
	default_level = "detailed",
}

register_setting {
	name = "show buff extension arrows",
	description = "Show up-arrows for extending buffs (currently only on custom charpane)",
	group = "charpane",
	default_level = "standard",
}

register_setting {
	name = "show multiple previous-adventure links",
	description = "Show multiple previous-adventure links (currently only on custom charpane)",
	group = "charpane",
	default_level = "detailed",
}

add_printer("/game.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	text = text:gsub([[(<frameset id=mainset cols=)"120,%*"(>)]], [[%1"200, *"%2]])
end)

local function display_duration(x)
	local desc = "(" .. display_value(x) .. ")"
	if desc:len() >= 6 then
		desc = [[<span style="font-size: 80%">]] .. desc .. [[</span>]]
	end
	return desc
end

local function get_clancy_display()
	local instruments = {
		"whelp",
		"volley",
		"fairy",
	}
	if clancy_wantsattention() then
		return [[<a href="main.php?action=clancy" target="mainpane">Clancy</a> (! lvl ]] .. clancy_level() .. ", " .. (instruments[clancy_instrumentid()] or "?") .. " !)"
	else
		return [[Clancy (lvl ]] .. clancy_level() .. ", " .. (instruments[clancy_instrumentid()] or "?") .. ")"
	end
end

function get_companion_display()
	local jarlcompanion = tonumber(status().jarlcompanion)
	local working_lunch = have_skill("Working Lunch") and 1 or 0
	local name = "ID: " .. (status().jarlcompanion or "?")
	local bonus = "?"
	if jarlcompanion == 1 then
		name = "Eggman"
		bonus = string.format("+%d%%&nbsp;items", 50 + 25 * working_lunch)
	elseif jarlcompanion == 2 then
		name = "Horse"
		bonus = string.format("+%d%%&nbsp;initiative", 50 + 25 * working_lunch)
	elseif jarlcompanion == 3 then
		name = "Hippo"
		bonus = "+" .. (3 + working_lunch * 1.5) .. "&nbsp;stats"
	elseif jarlcompanion == 4 then
		name = "Puff"
		bonus = string.format("+%d&nbsp;ML", 20 + 10 * working_lunch)
	else
		return [[Companion ID: ]] .. (status().jarlcompanion or "?")
	end
	return string.format("Companion: %s (%s)", name, bonus)
end

local function kolproxy_custom_charpane_mode()
	if setting_enabled("use custom kolproxy charpane/use compact mode") then
		return "compact"
	else
		return "normal"
	end
end

local function buff_sort_func(a, b)
	if a.duration ~= b.duration then
		if type(a.duration) == type(b.duration) then
			return a.duration < b.duration
		else
			return (b.duration == "&infin;")
		end
	end
	if a.title ~= b.title then return a.title < b.title end
	if a.imgname ~= b.imgname then return a.imgname < b.imgname end
	return a.descid < b.descid
end

local familiarfaves = nil
local familiarfaves_id = nil
local expired_fams = nil

add_processor("/familiar.php", function()
	if params.action == "fave" then
		-- Needs to go via session to communicate between processor/interceptor
		session.have_familiarfaves = "no"
	end
end)

local function get_familiar_grid()
	fams_per_line = 1000

	local faveid = ascensionpathid() .. "/" .. ascensionstatus()
	if not familiarfaves or familiarfaved_id ~= faveid or session.have_familiarfaves ~= "yes" then
-- 		print("DEBUG: loading familiar favorites")

		expired_fams = {}

		local cppt_f = async_get_page("/charpane.php")

		local fampt = get_page("/familiar.php")
		for x in fampt:gmatch([[<tr class="expired"><td valign=center><input type=radio name=newfam value=([0-9]*)>]]) do
			expired_fams[tonumber(x)] = true
		end
		for x in fampt:gmatch([[<tr class="expired">(.-)</tr>]]) do
			local famid = tonumber(x:match([[onClick='fam%(([0-9]+)%)']]))
			if famid then
				expired_fams[famid] = true
			end
		end

		familiarfaves = cppt_f():match("var FAMILIARFAVES = %[.-%];") or "{ Fake no faves text }"
		familiarfaved_id = faveid
		session.have_familiarfaves = "yes"
	end
	return make_familiar_grid(familiarfaves:match("var FAMILIARFAVES = %[(.-)%];"), session.pwd, expired_fams)
end

local function get_familiar_grid_line(fams)
	local curfampic = familiarpicture()
	local current_is_a_fave = false
	for a, b in pairs(fams) do
		if familiarid() == b.id then
			curfampic = b.pic
			current_is_a_fave = true
		end
	end

	local famnames = {}
	for a, b in pairs(fams) do
		table.insert(famnames, a)
	end
	table.sort(famnames)
	if not current_is_a_fave then
		table.insert(famnames, curfampic)
	end

	fams[curfampic] = { link = string.format([[<a href="familiar.php" target="mainpane"><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" width="30" height="30" style="border: solid thin gray"></a>]], familiarpicture()) }

	local famchoosertext = ""
	local spacetimer = 1
	for _, b in ipairs(famnames) do
		famchoosertext = famchoosertext .. fams[b].link
		if spacetimer >= fams_per_line then
			famchoosertext = famchoosertext .. "<br>"
			spacetimer = 1
		else
			spacetimer = spacetimer + 1
		end
	end
	return famchoosertext
end

local function pathdesc()
	local prefix = ""
	if ascensionstatus() == "Hardcore" then
		prefix = "HC"
	elseif ascensionstatus() == "Softcore" then
		prefix = "SC"
	end
	if moonsign() == "Bad Moon" then
		return "BM"
	elseif ascensionpathname() == "Teetotaler" then
		return prefix .. "T"
	elseif ascensionpathname() == "Boozetafarian" then
		return prefix .. "B"
	elseif ascensionpathname() == "Oxygenarian" then
		return prefix .. "O"
	elseif ascensionpathid() == 0 or ascensionpathname() == "" then
		if prefix ~= "" then
			return prefix .. "NP"
		else
			return ""
		end
	else
		return prefix .. "Challenge"
	end
end

local function classdesc()
	local descs = {
		compact = { "SC", "TT", "PM", "S", "DB", "AT", nil, nil, nil, nil, "AoB", "ZM", nil, "AoJ" },
		normal = { "Seal Clubber", "Turtle Tamer", "Pastamancer", "Sauceror", "Disco Bandit", "Accordion Thief", nil, nil, nil, nil, "Avatar of Boris", "Zombie Master", nil, "Avatar of Jarlsberg" },
	}
	return descs[kolproxy_custom_charpane_mode()][classid()] or "?"
end

local function classpathdesc()
	local p = pathdesc()
	if p ~= "" then
		return string.format("%s %s", p, classdesc())
	else
		return classdesc()
	end
end

local function format_hpmp(c, m)
	if c == m then
		return string.format([[<span style="color: green">%s</span>]], format_integer(c))
	elseif c < m * 0.25 then
		return string.format([[<span style="color: red">%s&nbsp;/&nbsp;%s</span>]], format_integer(c), format_integer(m))
	else
		return string.format([[%s&nbsp;/&nbsp;%s]], format_integer(c), format_integer(m))
	end
end

local function get_srdata(SRtitle)
	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())
	local value = ""
	local color = "black"
	if SRnow then
		color = "green"
	end
	if table.maxn(good_numbers) > 0 then
		value = table.concat(good_numbers, ", ")
	else
		value = "?"
	end

	if (not lastsemi) and (not is_first_semi) then
		lastsemi = "?"
	end
	
	local tooltip = ""
	if table.maxn(all_numbers) > 0 then
		tooltip = tooltip .. "Fortune cookie numbers: " .. table.concat(all_numbers, ", ")
	else
		tooltip = tooltip .. "Fortune cookie numbers: ?"
	end

	if SRmin and SRmax and SRmax >= 0 then
		if value == "?" then
			value = SRmin .. " to " .. SRmax
		end
		tooltip = tooltip .. ", range = " .. SRmin .. " to " .. SRmax
	else
		if value ~= "?" then
			value = value .. " ?"
		end
		tooltip = tooltip .. ", range = ?"
	end

	if lastsemi then
		tooltip = tooltip .. ", last semirare = " .. lastsemi
	end
	local bgcolor = "white"
	local showlast = nil
	if SRnow then
		bgcolor = "lightgreen"
	end

	local srdata = string.format([[%s: <span style="color: %s" title="%s"><b>%s</b></span>]], SRtitle, color, tooltip, value)
	if SRnow and lastsemi then
		srdata = srdata .. string.format([[<br>Last SR: %s]], lastsemi)
	end

	return bgcolor, srdata
end

local function make_optimize_diet_href()
	return make_href("/kolproxy-frame-page", { url = "http://www.houeland.com" .. make_href("/kol/diets", {
		foodspace = math.max(0, estimate_max_fullness() - fullness()),
		boozespace = math.max(0, estimate_max_safe_drunkenness() - drunkenness()),
		spleenspace = math.max(0, estimate_max_spleen() - spleen()),
	}), pwd = session.pwd })
end

local function make_get_buffs_href()
	return make_href("/kolproxy-frame-page", { url = "http://kol.obeliks.de" .. make_href("/buffbot/buff", { style = "kol", target = playername() }), pwd = session.pwd })
end

local function get_common_js()
	return [[

	<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/charpane.4.js"></script>
	
	<script type="text/javascript">
		function popup_effect(descid) {
			var w = window.open("desc_effect.php?whicheffect=" + descid, "effect", "height=200,width=300")
			if (w.focus) w.focus()
		}
		function maybe_shrug(buffname) {
			$.get("/submitnewchat.php?graf=" + URLEncode("/shrug " + buffname) + "&pwd=]] .. session.pwd .. [[", function(data) {
				if (data.match(/action=unbuff/)) {
					var whichbuff = data.match(/whichbuff=([0-9]*)/)[1]
					if (confirm("Do you want to shrug off " + buffname + "?")) {
						$.ajax({
							type: 'GET', url: 'charsheet.php?pwd=]] .. session.pwd .. [[&ajax=1&action=unbuff&whichbuff=' + whichbuff + '&noredirect=1',
							cache: false,
							global: false,
							success: function(out) {
								if (out.match(/no\|/)) {
									var parts = out.split(/\|/)
									alert("Unable to shrug " + buffname + " because you are " + parts[1] + ".")
									return
								}
								var $eff = $(top.mainpane.document).find('#effdiv');
								if ($eff.length == 0) {
									var d = top.mainpane.document.createElement('DIV');
									d.id = 'effdiv';
									var b = top.mainpane.document.body;
									if ($('#content_').length > 0) {
										b = $('#content_ div:first')[0];
									}
									b.insertBefore(d, b.firstChild);
									$eff = $(d);
								}
								$eff.find('a[name="effdivtop"]').remove().end()
									.prepend('<a name="effdivtop"></a><center>' + out + '</center>').css('display','block');
								if (!window.dontscroll || (window.dontscroll && dontscroll==0)) {
									top.mainpane.document.location = top.mainpane.document.location + "#effdivtop";
								}
							}
						})
					}
				} else if (data.match(/requires a soft green echo eyedrop antidote/)) {
					alert("That requires a soft green echo eyedrop antidote.")
				} else {
					alert("Can't shrug that.")
				}
			})
			return false
		}
		function cast_skillid(skillid) {
			$.ajax({
				type: 'GET',
				url: "/skills.php?whichskill=" + skillid + "&quantity=1&action=Skillz&ajax=1&targetplayer=]] .. playerid() .. [[&pwd=]] .. session.pwd .. [[",
				cache: false,
				global: false,
				success: function(out) {
					if (out.match(/no\|/)) {
						var parts = out.split(/\|/)
						alert("Error extending buff: " + parts[1] + ".")
						return
					}
					var $eff = $(top.mainpane.document).find('#effdiv');
					if ($eff.length == 0) {
						var d = top.mainpane.document.createElement('DIV');
						d.id = 'effdiv';
						var b = top.mainpane.document.body;
						if ($('#content_').length > 0) {
							b = $('#content_ div:first')[0];
						}
						b.insertBefore(d, b.firstChild);
						$eff = $(d);
					}
					$eff.find('a[name="effdivtop"]').remove().end()
						.prepend('<a name="effdivtop"></a><center>' + out + '</center>').css('display','block');
					if (!window.dontscroll || (window.dontscroll && dontscroll==0)) {
						top.mainpane.document.location = top.mainpane.document.location + "#effdivtop";
					}
				}
			})
			return false
		}
	</script>

	<script type="text/javascript">

// ====================================================================
//       URLEncode and URLDecode functions
//
// Copyright Albion Research Ltd. 2002
// http://www.albionresearch.com/
//
// You may copy these functions providing that 
// (a) you leave this copyright notice intact, and 
// (b) if you use these functions on a publicly accessible
//     web site you include a credit somewhere on the web site 
//     with a link back to http://www.albionresarch.com/
//
// If you find or fix any bugs, please let us know at albionresearch.com
//
// SpecialThanks to Neelesh Thakur for being the first to
// report a bug in URLDecode() - now fixed 2003-02-19.
// ====================================================================
function URLEncode(x)
{
	// The Javascript escape and unescape functions do not correspond
	// with what browsers actually do...
	var SAFECHARS = "0123456789" +					// Numeric
					"ABCDEFGHIJKLMNOPQRSTUVWXYZ" +	// Alphabetic
					"abcdefghijklmnopqrstuvwxyz" +
					"-_.!~*'()";					// RFC2396 Mark characters
	var HEX = "0123456789ABCDEF";

	var plaintext = x;
	var encoded = "";
	for (var i = 0; i < plaintext.length; i++ ) {
		var ch = plaintext.charAt(i);
		if (ch=="+") {
			encoded+="%2B";
		} else if (ch == " ") {
		    encoded += "+";				// x-www-urlencoded, rather than %20
		} else if (SAFECHARS.indexOf(ch) != -1) {
		    encoded += ch;
		} else {
		    var charCode = ch.charCodeAt(0);
			if (charCode > 255) {
			    alert( "Unicode Character '" + ch + "' cannot be encoded using standard URL encoding.\n" +
				        "(URL encoding only supports 8-bit characters.)\n" +
						"A space will be substituted." );
				encoded += "+";
			} else {
				encoded += "%";
				encoded += HEX.charAt((charCode >> 4) & 0xF);
				encoded += HEX.charAt(charCode & 0xF);
			}
		}
	} // for

	return encoded;
};

	</script>

	<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>

]]
end

local buff_extension_info = nil
local function get_buff_extension_info()
	if not buff_extension_info then
		buff_extension_info = load_buff_extension_info()
	end
	return buff_extension_info
end

local cached_workarounds = {}
local function work_around_broken_status_lastadv(advdata)
	if advdata.container == "place.php" then
		print "WARNING: Working around status lastadv.container server API bug. Shout at CDMoyer!"
		if not cached_workarounds[advdata.name] then
			async_post_page("/account.php", { am = 1, pwd = session.pwd, action = "flag_compactchar", value = 0, ajax = 1 })
			local pt = get_page("/charpane.php")
			local real_container = pt:match([[href="(place.php%?whichplace=[^"]-)"]])
			if real_container then
				advdata.container = real_container
			end
			cached_workarounds[advdata.name] = advdata
		end
		return cached_workarounds[advdata.name]
	else
		return advdata
	end
end

local previous_adventures_tbl = {}
local function update_and_get_previous_adventure_links()
	if not previous_adventures_tbl[1] or previous_adventures_tbl[1].name ~= lastadventuredata().name then
		local newtbl = {}
		table.insert(newtbl, work_around_broken_status_lastadv(lastadventuredata()))
		for _, x in ipairs(previous_adventures_tbl) do
			if x.name ~= lastadventuredata().name and #newtbl < 5 then
				table.insert(newtbl, x)
			end
		end
		previous_adventures_tbl = newtbl
	end
	return previous_adventures_tbl
end

add_interceptor("/charpane.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	if not pcall(turnsthisrun) then return end -- in afterlife
	if kolproxy_custom_charpane_mode() ~= "compact" then return end
	local extra_js, fams = get_familiar_grid()
-- 	print(table_to_str(fams))

-- name
-- level / progress
-- mus / mys / mox
-- full / drunk / spleen
-- hp / maxhp
-- mp / maxmp
-- meat
-- advs / turnsplayed
-- mcd ??
-- zone
-- semirare
-- familiar, weight, bonus
-- buffs

	local bgcolor, srdata = get_srdata("SR")

	local lines = {}
	table.insert(lines, string.format([[<a class="nounder" target="mainpane" href="charsheet.php"><b>%s</b></a> <span class="tiny">(%s)</span><br>]], playername(), classpathdesc()))
	table.insert(lines, string.format([[Level: <b>%s</b> <span class="tiny">(%s to go)</span><br>]], round_down(level() + level_progress(), 1), format_integer(substats_for_level(level() + 1) - rawmainstat())))
-- 	table.insert(lines, string.format([[Mainstat: <b><span style="color: blue; font-weight: bold;">%s</span> (%s)</b><br>]], format_integer(buffedmainstat()), format_integer(basemainstat())))
	table.insert(lines, string.format([[Buffed: <b><span style="color: blue; font-weight: bold;">%s</span></b> / <b><span style="color: blue; font-weight: bold;">%s</span></b> / <b><span style="color: blue; font-weight: bold;">%s</span></b><br>]], format_integer(buffedmuscle()), format_integer(buffedmysticality()), format_integer(buffedmoxie())))
	table.insert(lines, string.format([[Base: <b>%s</b> / <b>%s</b> / <b>%s</b><br>]], format_integer(basemuscle()), format_integer(basemysticality()), format_integer(basemoxie())))
	table.insert(lines, string.format([[Organs: <b>%s</b> / <b>%s</b> / <b>%s</b><br>]], estimate_max_fullness() - fullness(), estimate_max_safe_drunkenness() - drunkenness(), estimate_max_spleen() - spleen()))
--	table.insert(lines, string.format([[Organs: <b>%s</b>/%s, <b>%s</b>/%s, <b>%s</b>/%s<br>]], fullness(), estimate_max_fullness(), drunkenness(), estimate_max_safe_drunkenness(), spleen(), estimate_max_spleen()))
	if ascensionstatus() == "Aftercore" then
		table.insert(lines, [[<center><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></center><br>]])
	else
		table.insert(lines, "")
	end
	table.insert(lines, string.format([[HP: <b>%s</b><br>]], format_hpmp(hp(), maxhp())))
	if ascensionpathid() == 10 then
		table.insert(lines, string.format([[Horde: <b>%s</b><br>]], horde_size()))
	else
		table.insert(lines, string.format([[MP: <b>%s</b><br>]], format_hpmp(mp(), maxmp())))
	end
	table.insert(lines, string.format([[Meat: <b>%s</b><br>]], format_integer(meat())))
	table.insert(lines, string.format([[Turns: <b>%s</b> <span class="tiny">(%s played, day %s)</span><br>]], advs(), turnsthisrun(), daysthisrun()))
	table.insert(lines, string.format([[<a href="%s" target="mainpane">Zone</a>: <b><a href="%s" target="mainpane">%s</a></b><br>]], work_around_broken_status_lastadv(lastadventuredata()).container or "", lastadventuredata().link, lastadventuredata().name))
	local links = update_and_get_previous_adventure_links()
	if setting_enabled("show multiple previous-adventure links") then
		for i = 2, 5 do
			if links[i] then
				table.insert(lines, string.format([[<small><a href="%s" target="mainpane">Zone</a>: <a href="%s" target="mainpane">%s</a></small><br>]], links[i].container or "", links[i].link, links[i].name))
			end
		end
	end
	table.insert(lines, "<!-- kolproxy charpane text area --><br>")

	table.insert(lines, srdata .. "<br>")

	local next_bee_turn = ascension["bee turn"]
	local bee_value = nil
	if next_bee_turn then
		local turnmin = next_bee_turn - turnsthisrun()
		local turnmax = next_bee_turn + 5 - turnsthisrun()
		if turnmax >= 0 then
			if turnmin < 0 then turnmin = 0 end
			bee_value = turnmin .. "-" .. turnmax
		end
	else
-- 		bee_value = "?"
	end
	if bee_value then
		table.insert(lines, string.format([[Bee: %s<br>]], bee_value))
	end

	for _, x in ipairs(ascension["turn counters"] or {}) do
		local turns = x.turn + x.length - turnsthisrun()
		if turns >= 0 then
			if turnsleft == 0 then
				table.insert(lines, string.format([[%s: <b style="color: green">%s</b><br>]], x.name, turns))
			else
				table.insert(lines, string.format([[%s: <b>%s</b><br>]], x.name, turns))
			end
		end
	end

	table.insert(lines, "<br>")

	local function get_equip_line(tbl)
		local equipstr = ""
		local eq = equipment()
		for _, x in pairs(tbl) do
			if eq[x] then
				preload_item_api_data(eq[x])
			end
		end
		for _, x in ipairs(tbl) do
			local pic = "blank"
			if eq[x] then
-- 				pic = item_api_data(eq[x]).picture
				local isok, thepic = pcall(function() return item_api_data(eq[x]).picture end)
				if isok then
					pic = thepic
				else
					pic = "nopic"
				end
			end
			equipstr = equipstr .. string.format([[<img src="http://images.kingdomofloathing.com/itemimages/%s.gif" width="30" height="30" style="border: solid thin lightgray;">]], pic)
		end
		return equipstr
	end
	table.insert(lines, string.format("<center>%s<br>%s</center><br>", get_equip_line { "hat", "container", "shirt", "weapon", "offhand" }, get_equip_line { "pants", "acc1", "acc2", "acc3", "familiarequip" }))

	if familiarid() ~= 0 then
		table.insert(lines, "<center>" .. get_familiar_grid_line(fams) .. "</center>")
		table.insert(lines, string.format([[<center>%s lbs.<!-- kolproxy charpane familiar text area --></center><br>]], buffedfamiliarweight()))
	elseif ascensionpathid() == 8 then
		table.insert(lines, [[<center>]] .. get_clancy_display() .. [[</center><br>]])
	elseif ascensionpath("Avatar of Jarlsberg") then
		table.insert(lines, [[<center>]] .. get_companion_display() .. [[</center><br>]])
	else
		table.insert(lines, [[<center><a href="familiar.php" target="mainpane">No familiar</a></center><br>]])
	end

	local buff_colors = {
		["On the Trail"] = "purple",
		["Everything Looks Red"] = "red",
		["Everything Looks Blue"] = "blue",
		["Everything Looks Yellow"] = "goldenrod",
	}
	local sorting = {}
	for descid, x in pairs(status().effects) do
		table.insert(sorting, { title = x[1], duration = tonumber(x[2]), imgname = x[3], descid = descid }) -- HACK: tonumber is a workaround for CDM effects being strings or numbers randomly
	end
	for descid, x in pairs(status().intrinsics) do
		table.insert(sorting, { title = x[1], duration = "&infin;", imgname = x[2], descid = descid })
	end
	table.sort(sorting, buff_sort_func)

	local bufflines = {}

	if setting_enabled("show buff extension arrows") then
		local buffinfo = get_buff_extension_info()
		local curbuffline = nil
		for _, x in ipairs(sorting) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local strarrow = ""
			local bi = buffinfo[x.title]
			if bi and have_skill(bi.skillname) and mp() >= bi.mpcost then
				strarrow = string.format([[<img src="%s" style="cursor: pointer;" onclick="cast_skillid(%d)">]], "http://images.kingdomofloathing.com/otherimages/bugbear/uparrow.gif", bi.skillid)
			end
			local str = string.format([[<td title="%s"%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td title="%s"%s>%s</td>]], x.title, imgstyleinfo, x.imgname, x.descid, x.title, x.title, styleinfo, display_duration(x.duration))
			if not curbuffline then
				curbuffline = "<td>" .. strarrow .. "</td>" .. str
			else
				table.insert(bufflines, string.format([[<tr>%s<td>&nbsp;</td>%s<td>%s</td></tr>]], curbuffline, str, strarrow))
				curbuffline = nil
			end
		end
		if curbuffline then
			table.insert(bufflines, string.format([[<tr>%s<td></td><td></td><td></td></tr>]], curbuffline))
		end
	else
		local curbuffline = nil
		for _, x in ipairs(sorting) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local str = string.format([[<td title="%s"%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td title="%s"%s>%s</td>]], x.title, imgstyleinfo, x.imgname, x.descid, x.title, x.title, styleinfo, display_duration(x.duration))
			if not curbuffline then
				curbuffline = str
			else
				table.insert(bufflines, string.format([[<tr>%s<td>&nbsp;</td>%s</tr>]], curbuffline, str))
				curbuffline = nil
			end
		end
		if curbuffline then
			table.insert(bufflines, string.format([[<tr>%s<td></td><td></td></tr>]], curbuffline))
		end
	end

	table.insert(lines, [[<center><table>]] .. table.concat(bufflines) .. [[</table></center>]])

	if ascensionstatus() == "Aftercore" then
		table.insert(lines, [[<center><a href="]]..make_get_buffs_href()..[[" target="mainpane" style="color: green">{ Get buffs }</a></center>]])
	end

	local text = [[
<html>
<head>
	<style type="text/css">
body {
	font-family: Arial, Helvetica, sans-serif;
	background-color: ]] .. bgcolor .. [[;
	color: black;
	font-size: 0.8em;
}
td {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 0.8em;
}
a:link { color: black; }
a:visited {	color: black; }
a:active { color: black; }
.nounder { text-decoration: none; }
.tiny { font-size: 0.9em; }
	</style>

]] .. get_common_js() .. [[

]] .. extra_js .. [[

</head>
<body>
]] .. table.concat(lines) .. [[
</body>
</html>]]
	return text, "/kolproxy-quick-charpane-compact"
end)



add_interceptor("/charpane.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	if not pcall(turnsthisrun) then return end -- in afterlife
	if kolproxy_custom_charpane_mode() ~= "normal" then return end

	local lines = {}

	local extra_js, fams = get_familiar_grid()

	local bgcolor, srdata = get_srdata("Semirare")

	local _, have_level, need_level = level_progress()
	local function make_progress_bar(have, need, width, height)
		local filled_width = math.floor((have / need) * width)
		local remaining_width = width - filled_width
		return string.format([[<table title='%s / %s' cellpadding=0 cellspacing=0 style='border: 1px solid #5A5A5A'><tr><td height=%d width=%s bgcolor=#5A5A5A></td><td width=%s bgcolor=white></td></tr></table>]], format_integer(have), format_integer(need), height, filled_width, remaining_width)
	end
	table.insert(lines, [[<center>]])
	table.insert(lines, string.format([[<a class=nounder target=mainpane href="charsheet.php"><b>%s</b></a><br>Level %s<br>%s]], playername(), level(), classdesc()))
	table.insert(lines, make_progress_bar(have_level, need_level, 100, 5))
	table.insert(lines, [[</center><br>]])
	table.insert(lines, [[<table align=center>]])
	local function add_stat_line(statname, buffed, base, raw_substat)
		local substat_level = math.floor(math.sqrt(raw_substat))
		local substat_base = substat_level * substat_level
		local have = raw_substat - substat_base
		local need = (substat_level + 1) * (substat_level + 1) - substat_base
		table.insert(lines, string.format([[<tr><td align=right>%s</td><td align=left><b><font color=blue>%s</font>&nbsp;(%s)</b>%s</td></tr>]], statname, format_integer(buffed), format_integer(base), make_progress_bar(have, need, 50, 3)))
	end
	add_stat_line("Muscle:", buffedmuscle(), basemuscle(), rawmuscle())
	add_stat_line("Mysticality:", buffedmysticality(), basemysticality(), rawmysticality())
	add_stat_line("Moxie:", buffedmoxie(), basemoxie(), rawmoxie())
	local function add_organ_line(organdescs, amountstr)
		local desc = random_choice(organdescs)
		table.insert(lines, string.format([[<tr><td align=right>%s</td><td><b>%s</b></td></tr>]], desc, amountstr))
	end
	add_organ_line({ "Engorgement:", "Gluttony:", "Satiation:" }, fullness() .. " / " .. estimate_max_fullness())
	add_organ_line({ "Inebriety:", "Temulency:", "Tipsiness:" }, drunkenness() .. " / " .. estimate_max_safe_drunkenness())
	add_organ_line({ "Melancholy:", "Moroseness:", "Spleen:" }, spleen() .. " / " .. estimate_max_spleen())
	table.insert(lines, [[</table>]])
	if ascensionstatus() == "Aftercore" then
		table.insert(lines, [[<center><font size="2"><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></font></center>]])
	end

	table.insert(lines, [[<table cellpadding=3 align=center>]])
	table.insert(lines, string.format([[<tr><td align=center><img src="http://images.kingdomofloathing.com/itemimages/hp.gif" class=hand title="Hit Points" alt="Hit Points"><br><span class=black>%s</span></td>]], format_hpmp(hp(), maxhp())))
	if ascensionpathid() == 10 then
		table.insert(lines, string.format([[<td align=center><img src="http://images.kingdomofloathing.com/otherimages/zombies/horde_15.gif"  height=35 class=hand title="Horde (%s zombie(s))" alt="Horde (%s zombie(s))"><br><span class=black>%s</span></td></tr>]], horde_size(), horde_size(), horde_size()))
	else
		local mpname = ({ "Muscularity Points", "Muscularity Points", "Mana Points", "Mana Points", "Mojo Points", "Mojo Points" })[classid()] or "MP"
		table.insert(lines, string.format([[<td align=center><img src="http://images.kingdomofloathing.com/itemimages/mp.gif" class=hand title="%s" alt="%s"><br><span class=black>%s</span></td></tr>]], mpname, mpname, format_hpmp(mp(), maxmp())))
	end
	table.insert(lines, string.format([[<tr><td align=center><img src="http://images.kingdomofloathing.com/itemimages/meat.gif" class=hand title="Meat" alt="Meat"><br><span class=black>%s</span></td>]], format_integer(meat())))
	table.insert(lines, string.format([[<td align=center><img src="http://images.kingdomofloathing.com/itemimages/hourglass.gif" class=hand title="Adventures Remaining" alt="Adventures Remaining"><br><span class=black>%s</span></td></tr>]], format_integer(advs())))
	table.insert(lines, [[</table>]])

	table.insert(lines, [[<center><font size="2">]]..srdata..[[</font></center>]])
	table.insert(lines, string.format([[<center><font size="2">Turns played: <b>%s</b> (day %s)</font></center>]], turnsthisrun(), daysthisrun()))
	table.insert(lines, "<!-- kolproxy charpane text area -->")
	table.insert(lines, [[<br><center>]])
	table.insert(lines, string.format([[<font size=2><b><a class=nounder href="%s" target=mainpane>Last Adventure:</a></b></font><br><font size=2><a target=mainpane href="%s">%s</a></font><br>]], work_around_broken_status_lastadv(lastadventuredata()).container or "", lastadventuredata().link, lastadventuredata().name))
	if setting_enabled("show multiple previous-adventure links") then
		local links = update_and_get_previous_adventure_links()
		for i = 2, 5 do
			if links[i] then
				table.insert(lines, string.format([[<font size=1><a target=mainpane href="%s">%s</a></font><br>]], links[i].link, links[i].name))
			end
		end
	end
	table.insert(lines, [[</center><br>]])

	-- TODO: make bee counter generic and auto-insert

	for _, x in ipairs(ascension["turn counters"] or {}) do
		local turns = x.turn + x.length - turnsthisrun()
		if turns >= 0 then
			if turnsleft == 0 then
				table.insert(lines, string.format([[%s: <b style="color: green">%s</b>]], x.name, turns))
			else
				table.insert(lines, string.format([[%s: <b>%s</b>]], x.name, turns))
			end
		end
	end

	table.insert(lines, "")

	if familiarid() ~= 0 then
		table.insert(lines, "<center>" .. get_familiar_grid_line(fams) .. "</center>")
		table.insert(lines, string.format([[<center><font size=2>%s lbs.<!-- kolproxy charpane familiar text area --></font></center>]], buffedfamiliarweight()))
	elseif ascensionpathid() == 8 then
		table.insert(lines, [[<center>]] .. get_clancy_display() .. [[</center><br>]])
	elseif ascensionpath("Avatar of Jarlsberg") then
		table.insert(lines, [[<center>]] .. get_companion_display() .. [[</center><br>]])
	else
		table.insert(lines, [[<center><a href="familiar.php" target="mainpane">No familiar</a></center>]])
	end

	local buff_colors = {
		["On the Trail"] = "purple",
		["Everything Looks Red"] = "red",
		["Everything Looks Blue"] = "blue",
		["Everything Looks Yellow"] = "goldenrod",
	}
	local sorting = {}
	for descid, x in pairs(status().effects) do
		table.insert(sorting, { title = x[1], duration = tonumber(x[2]), imgname = x[3], descid = descid }) -- HACK: tonumber is a workaround for CDM effects being strings or numbers randomly
	end
	for descid, x in pairs(status().intrinsics) do
		table.insert(sorting, { title = x[1], duration = "&infin;", imgname = x[2], descid = descid })
	end
	table.sort(sorting, buff_sort_func)

	local bufflines = {}

	if setting_enabled("show buff extension arrows") then
		local buffinfo = get_buff_extension_info()
		for _, x in ipairs(sorting) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local strarrow = ""
			local bi = buffinfo[x.title]
			if bi and have_skill(bi.skillname) and mp() >= bi.mpcost then
				strarrow = string.format([[<img src="%s" style="cursor: pointer;" onclick="cast_skillid(%d)">]], "http://images.kingdomofloathing.com/otherimages/bugbear/uparrow.gif", bi.skillid)
			end
			local str = string.format([[<tr><td>%s</td><td%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td valign="center"%s><font size=2>%s %s</font><br></td></tr>]], strarrow, imgstyleinfo, x.imgname, x.descid, x.title, styleinfo, x.title, display_duration(x.duration))
			table.insert(bufflines, str)
		end
	else
		for _, x in ipairs(sorting) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local str = string.format([[<tr><td%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td valign="center"%s><font size=2>%s %s</font><br></td></tr>]], imgstyleinfo, x.imgname, x.descid, x.title, styleinfo, x.title, display_duration(x.duration))
			table.insert(bufflines, str)
		end
	end

	table.insert(lines, [[<br>]])
	table.insert(lines, [[<center><table>]] .. table.concat(bufflines) .. [[</table></center>]])

	if ascensionstatus() == "Aftercore" then
		table.insert(lines, [[<center><a href="]]..make_get_buffs_href()..[[" target="mainpane" style="color: green">{ Get buffs }</a></center>]])
	end

	local text = [[
<!DOCTYPE html>
<html>
<head>
	<style type="text/css">
body {
	font-family: Arial, Helvetica, sans-serif;
	background-color: ]] .. bgcolor .. [[;
	color: black;
}
td {
	font-family: Arial, Helvetica, sans-serif;
}
a:link { color: black; }
a:visited {	color: black; }
a:active { color: black; }
.nounder { text-decoration: none; }
.tiny { font-size: 0.9em; }
.black {
   font-weight: bold;
   color: black;
   font-size: smaller;
}
	</style>

]] .. get_common_js() .. [[

]] .. extra_js .. [[

</head>
<body>
]] .. table.concat(lines) .. [[
</body>
</html>]]
	return text, "/kolproxy-quick-charpane-normal"
end)
