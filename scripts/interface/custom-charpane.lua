-- TODO: merge common code

-- TODO: custom buff coloring, sort order?

-- game.php
-- <frameset id=mainset cols="120,*">
-- <frameset id=mainset cols="200,*">

-- TODO: allow custom frame layouts?

register_setting {
	name = "use custom kolproxy charpane",
	description = "Replace character pane with speedy kolproxy version",
	group = "charpane",
	default_level = "standard",
	update_charpane = true,
}

register_setting {
	name = "use custom bleary charpane",
	description = "Use prettier bleary / ChIT version",
	group = "charpane",
	default_level = "standard",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
}

register_setting {
	server_name = "compactchar",
	description = "Use compact character pane",
	group = "charpane",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
}

register_setting {
	server_name = "hideefarrows",
	server_inverted = true,
	description = "Show effect replenishment arrows",
	group = "charpane",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
}

register_setting {
	name = "show multiple previous-adventure links",
	description = "Show multiple previous-adventure links",
	group = "charpane",
	default_level = "detailed",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
}

register_setting {
	name = "display counters as effects",
	description = "Display turn counters etc. as if they were effects",
	group = "charpane",
	default_level = "enthusiast",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
	beta_version = true,
}

register_setting {
	server_name = "compacteffects",
	description = "Use compact effects list",
	group = "charpane",
	default_level = "enthusiast",
	update_charpane = true,
}

register_setting {
	server_name = "swapfam",
	description = "Display familiar below effects",
	group = "charpane",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
}

register_setting {
	name = "display songs above other effects",
	description = "Display AT songs above other effects",
	group = "charpane",
	default_level = "enthusiast",
	parent = "use custom kolproxy charpane",
	update_charpane = true,
}

add_printer("/game.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	text = text:gsub([[(<frameset id=mainset cols=)"120,%*"(>)]], [[%1"200, *"%2]])
end)

function display_duration(x)
	local d = x.durationdesc or x.duration
	if d == "" then return d end
	local desc = display_value(d)
	if x.maxduration and x.maxduration > x.duration then
		desc = display_value(d) .. "-" .. display_value(x.maxduration)
	end
	if x.backgroundcolor then
		desc = "[" .. desc .. "]"
	else
		desc = "(" .. desc .. ")"
	end
	if desc:len() >= 6 then
		desc = [[<span style="font-size: 80%">]] .. desc .. [[</span>]]
	end
	return desc
end

function get_clancy_display()
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

function get_motorbike_display()
	local lovehate = {}
	if petelove() > 1 then
		table.insert(lovehate, tostring(petelove()) .. " love")
	end
	if petehate() > 1 then
		table.insert(lovehate, tostring(petehate()) .. " hate")
	end
	local pic = can_upgrade_sneaky_pete_motorcycle() and "motorbike_anim.gif" or "motorbike.gif"
	return [[<a target=mainpane href=main.php?action=motorcycle><img src=http://images.kingdomofloathing.com/itemimages/]] .. pic .. [[ width=30 height=30 border=0 alt="Your Motorcycle" title="Your Motorcycle"></a><br>]] .. table.concat(lovehate, ", ") .. "<br>"
end

function kolproxy_custom_charpane_mode()
	if setting_enabled("use custom bleary charpane") then
		return "bleary"
	elseif tonumber(api_flag_config().compactchar) ~= 0 then
		return "compact"
	else
		return "normal"
	end
end

local function buff_sort_func(a, b)
	local group_order = {
		song = 50,
		effect = 100,
		intrinsic = 200,
		thrall = 250,
	}
	if not a.group or not b.group or not group_order[a.group] or not group_order[b.group] then
		print("DEBUG", tostring(a), tostring(b))
	end
	if a.group ~= b.group then return group_order[a.group] < group_order[b.group] end
	if a.duration ~= b.duration then
		if type(a.duration) == type(b.duration) then
			return a.duration < b.duration
		else
			return (b.duration == "&infin;")
		end
	end
	if a.special ~= b.special then return a.special end
	if a.title ~= b.title then return a.title < b.title end
	if a.imgname ~= b.imgname then return a.imgname < b.imgname end
	return a.descid < b.descid
end

local AT_songs = nil
local function is_AT_songname(buffname)
	if not AT_songs then
		local AT_skills = {}
		for x, y in pairs(datafile("skills")) do
			AT_skills[x] = y.accordion_thief_song
		end
		AT_songs = {}
		for x, y in pairs(datafile("buffs")) do
			if y.cast_skill and AT_skills[y.cast_skill] then
				AT_songs[x] = true
			end
		end
	end
	return AT_songs[buffname]
end

add_counter_effect(function()
	if pastathrall() then
		local thrall = get_current_pastathrall_info()
		return { title = string.format("Lvl %d %s", thrall.level, thrall.name), imgname = thrall.picture, group = "thrall" }
	end
end)

add_counter_effect(function()
	local tbl = {}
	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi, lastturn = get_semirare_info(turnsthisrun())
	for _, x in ipairs(good_numbers or {}) do
		table.insert(tbl, { title = "Semirare number", duration = x, imgname = "fortune", group = "effect" })
	end
	return tbl
end)

function get_sorted_buff_array()
	local buff_colors = {
		["On the Trail"] = "purple",
		["Everything Looks Red"] = "red",
		["Everything Looks Blue"] = "blue",
		["Everything Looks Yellow"] = "goldenrod",
	}
	local sorting = {}
	for descid, x in pairs(status().effects) do
		-- WORKAROUND: tonumber is a workaround for CDM effects being strings or numbers randomly. TODO: put workaround in api.lua
		local group = "effect"
		if setting_enabled("display songs above other effects") and is_AT_songname(x[1]) then
			group = "song"
		end
		table.insert(sorting, { title = x[1], duration = tonumber(x[2]), imgname = x[3], descid = descid, upeffect = x[4], group = group, color = buff_colors[x[1]] })
	end
	for descid, x in pairs(status().intrinsics) do
		local group = "intrinsic"
		table.insert(sorting, { title = x[1], duration = "&infin;", imgname = x[2], descid = descid, group = group, color = buff_colors[x[1]] })
	end
	if setting_enabled("display counters as effects") then
		for _, tblf in ipairs(get_counter_effect_list()) do
			local tbl = tblf()
			if not tbl then
			else
				if tbl.title then tbl = { tbl } end
				for _, x in ipairs(tbl) do
					x.backgroundcolor = "moccasin"
					x.descid = ""
					x.duration = x.duration or ""
					table.insert(sorting, x)
				end
			end
		end
	end

	table.sort(sorting, buff_sort_func)
	return sorting
end

function make_strarrow(upeffect)
	-- TODO: put skillid and itemid in buff table instead of parsing here
	if upeffect then
		local skillid = tonumber(upeffect:match("skill:([0-9]+)"))
		local itemid = tonumber(upeffect:match("item:([0-9]+)"))
		if skillid then
			return string.format([[<img src="%s" style="cursor: pointer;" class="strarrowskill" data-skillid="%d">]], "http://images.kingdomofloathing.com/otherimages/bugbear/uparrow.gif", skillid, skillid)
		elseif itemid then
			return string.format([[<img src="%s" style="cursor: pointer;%s" class="strarrowitem" data-itemid="%d">]], "http://images.kingdomofloathing.com/otherimages/bugbear/uparrow.gif", have_item(itemid) and "" or "opacity: 0.5;", itemid, itemid)
		end
	end
	return ""
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

function get_familiar_grid()
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

function get_initials(str)
	if not str then return str end
	if str:len() <= 6 then return str end
	local compacted = ""
	for x in (" " .. str):gmatch(" (.)") do
		compacted = compacted .. x
	end
	return compacted
end

-- TODO: charpane-specific names, or move to a more generic file
function pathdesc()
	local prefix = ""
	if ascensionstatus("Hardcore") then
		prefix = "HC"
	elseif ascensionstatus("Softcore") then
		prefix = "SC"
	end
	if moonsign() == "Bad Moon" then
		return "BM"
	elseif ascensionpathid() == 0 or ascensionpathname() == "" then
		if prefix ~= "" then
			return prefix .. "NP"
		else
			return ""
		end
	else
		local suffix = get_initials(ascensionpathname()) or "?"
		return prefix .. suffix
	end
end

function classdesc()
	if kolproxy_custom_charpane_mode() ~= "compact" then
		return maybe_playerclassname() or "?"
	else
		return get_initials(maybe_playerclassname()) or "?"
	end
end

function classdesc_compact()
	return get_initials(maybe_playerclassname()) or "?"
end

function classpathdesc()
	local p = pathdesc()
	if p ~= "" then
		return string.format("%s %s", p, classdesc())
	else
		return classdesc()
	end
end

function format_hpmp(c, m)
	if c == m then
		return string.format([[<span style="color: green">%s</span>]], format_integer(c))
	elseif c < m * 0.25 then
		return string.format([[<span style="color: red">%s&nbsp;/&nbsp;%s</span>]], format_integer(c), format_integer(m))
	else
		return string.format([[%s&nbsp;/&nbsp;%s]], format_integer(c), format_integer(m))
	end
end

function make_optimize_diet_href()
	local myitems = {}
	if have_item("tiny plastic sword") then table.insert(myitems, "tps") end
	if have_item("tuxedo shirt") then table.insert(myitems, "tuxedo") end
	-- Tuxedo shirt is cheap, use webpage default even if we don't have it
	local myperms = {}
	if have_skill("Saucemaven") then table.insert(myperms, "saucemaven") end
	if have_skill("Pizza Lover") then table.insert(myperms, "pizzalover") end
	if not next(myperms) then myperms = { "none" } end
	return make_href("/kolproxy-frame-page", { url = "http://www.houeland.com" .. make_href("/kol/diets", {
		foodspace = math.max(0, estimate_max_fullness() - fullness()),
		boozespace = math.max(0, estimate_max_safe_drunkenness() - drunkenness()),
		spleenspace = math.max(0, estimate_max_spleen() - spleen()),
		itemsavailable = table.concat(myitems),
		permsavailable = table.concat(myperms),
		classid = classid(),
	}), pwd = session.pwd })
end

function make_get_buffs_href()
	return make_href("/kolproxy-frame-page", { url = "http://kol.obeliks.de" .. make_href("/buffbot/buff", { style = "kol", target = playername() }), pwd = session.pwd })
end

local shrug_buff_href = add_automation_script("custom-shrug-buff", function()
	local chatpt = get_page("/submitnewchat.php", { graf = "/shrug " .. params.buffname, pwd = session.pwd })
	if chatpt:contains("action=unbuff") then
		local whichbuff = chatpt:match("whichbuff=([0-9]*)")
		return tojson { whichbuff = whichbuff }, "json"
	end

	local function hardshrug_feedback(x)
		local pt = get_page("/charpane.php")
		for tr in pt:gmatch("<tr>.-</tr>") do
			local effid = tr:match([[onClick='eff%("(.-)"%);']])
			if effid == x.descid then
				--local shrug1 = tr:match([[oncontextmenu='return shrug%(([0-9]+), ".-"%);']])
				local buffid1, shrugitem1 = tr:match([[oncontextmenu='return hardshrug%(([0-9]+), ".-","(.-)"%);']])
				if buffid1 and shrugitem1 then
					return tojson { whichbuff = buffid1, remover = shrugitem1 }, "json"
				end
				local buffid2 = tr:match([[oncontextmenu='return hardshrug%(([0-9]+), ".-"%);']])
				if buffid2 then
					return tojson { whichbuff = buffid2, remover = "soft green echo eyedrop antidote" }, "json"
				end
			end
		end
		return tojson { error_message = "Cannot shrug." }, "json"
	end

	for _, x in ipairs(get_sorted_buff_array()) do
		if x.title == params.buffname then
			return hardshrug_feedback(x)
		end
	end
	return tojson { error_message = "Nothing to shrug." }, "json"
end)

function get_common_js()
	return [[

	<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/charpane.4.js"></script>
	<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/window.20111231.js"></script>
	<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>

	<script type="text/javascript">
		function popup_effect(descid) {
			var w = window.open("desc_effect.php?whicheffect=" + descid, "effect", "height=200,width=300")
			if (w.focus) w.focus()
		}
		function maybe_shrug(buffname) {
			$.getJSON("]] .. shrug_buff_href { pwd = session.pwd } .. [[&buffname=" + URLEncode(buffname), function(data) {
				if (data.whichbuff) {
					var shrugurl = 'charsheet.php?pwd=]] .. session.pwd .. [[&ajax=1&action=unbuff&whichbuff=' + data.whichbuff + '&noredirect=1'
					var confirmmsg = "Do you want to shrug off " + buffname + "?"
					if (data.remover) {
						var aan = data.remover.match(/^[aeiou]/) ? 'an' : 'a'
						shrugurl = 'uneffect.php?cp=1&ajax=1&pwd=]] .. session.pwd .. [[&using=1&whicheffect=' + data.whichbuff
						confirmmsg = "Do you really want to remove " + buffname + "?\n\nNOTE:\nThis will consume "+aan+ " "+ data.remover + "."
					}
					if (confirm(confirmmsg)) {
						$.ajax({
							type: 'GET', url: shrugurl,
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
				} else {
					alert("Can't shrug that.")
				}
			})
			return false
		}
		function kolproxy_use_itemid(itemid, domulti) {
			var quantity = 1
			if (domulti) {
				quantity = 0
				var newquantity = prompt("How many times?")
				if (newquantity >= 1) quantity = newquantity
			}
			var use_url = "/inv_use.php?whichitem=" + itemid + "&ajax=1&pwd=]] .. session.pwd .. [["
			if (quantity != 1) {
				use_url = "/multiuse.php?whichitem=" + itemid + "&quantity=" + quantity + "&ajax=1&action=useitem&pwd=]] .. session.pwd .. [["
			}
			$.ajax({
				type: 'GET',
				url: use_url,
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
		function kolproxy_cast_skillid(skillid, domulti) {
			var quantity = 1
			if (domulti) {
				quantity = 0
				var newquantity = prompt("How many times?")
				if (newquantity >= 1) quantity = newquantity
			}
			if (quantity <= 0) return
			$.ajax({
				type: 'GET',
				url: "/runskillz.php?whichskill=" + skillid + "&ajax=1&action=Skillz&targetplayer=]] .. playerid() .. [[&quantity=" + quantity + "&pwd=]] .. session.pwd .. [[",
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
		$(document).ready(function() {
			$('.strarrowskill').click(function(e) { kolproxy_cast_skillid($(this).attr("data-skillid"), e.shiftKey); return false })
			$('.strarrowskill').bind('contextmenu', function(e) { kolproxy_cast_skillid($(this).attr("data-skillid"), true); return false })
			$('.strarrowitem').click(function(e) { kolproxy_use_itemid($(this).attr("data-itemid"), e.shiftKey); return false })
			$('.strarrowitem').bind('contextmenu', function(e) { kolproxy_use_itemid($(this).attr("data-itemid"), true); return false })
		})
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

]] .. get_outfit_slots_script()
end

local cached_workarounds = {}
function work_around_broken_status_lastadv(advdata)
	if advdata.container == "place.php" then
		print("ERROR: Status API place.php bug should be fixed already, this should not happen!")
		if not cached_workarounds[advdata.name] then
			print([[INFO: Working around server API bug (for ]] .. tostring(advdata.name) .. [[). Shout at CDMoyer about lastadv.container bug for place.php!]])
			local should_be = api_flag_config().compactchar or 0
			async_post_page("/account.php", { am = 1, pwd = session.pwd, action = "flag_compactchar", value = 0, ajax = 1 })
			local ptf = async_get_page("/charpane.php")
			async_post_page("/account.php", { am = 1, pwd = session.pwd, action = "flag_compactchar", value = should_be, ajax = 1 })
			local real_container = ptf():match([[href="(place.php%?whichplace=[^"]-)"]])
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
function update_and_get_previous_adventure_links()
	if not previous_adventures_tbl[1] or previous_adventures_tbl[1].name ~= lastadventuredata().name then
		local newtbl = {}
		table.insert(newtbl, work_around_broken_status_lastadv(lastadventuredata()))
		for _, x in ipairs(previous_adventures_tbl) do
			if x.name ~= lastadventuredata().name and not newtbl[5] then
				table.insert(newtbl, x)
			end
		end
		previous_adventures_tbl = newtbl
	end
	return previous_adventures_tbl
end

function compact_charpane_level_lines(lines)
	table.insert(lines, string.format([[<a class="nounder" target="mainpane" href="charsheet.php"><b>%s</b></a> <span class="tiny">(%s)</span><br>]], playername(), classpathdesc()))
	table.insert(lines, string.format([[Level: <b>%s</b> <span class="tiny">(%s to go)</span><br>]], round_down(level() + level_progress(), 1), format_integer(substats_for_level(level() + 1) - rawmainstat())))
-- 	table.insert(lines, string.format([[Mainstat: <b><span style="color: blue; font-weight: bold;">%s</span> (%s)</b><br>]], format_integer(buffedmainstat()), format_integer(basemainstat())))
	table.insert(lines, string.format([[Buffed: <b><span style="color: blue; font-weight: bold;">%s</span></b> / <b><span style="color: blue; font-weight: bold;">%s</span></b> / <b><span style="color: blue; font-weight: bold;">%s</span></b><br>]], format_integer(buffedmuscle()), format_integer(buffedmysticality()), format_integer(buffedmoxie())))
	table.insert(lines, string.format([[Base: <b>%s</b> / <b>%s</b> / <b>%s</b><br>]], format_integer(basemuscle()), format_integer(basemysticality()), format_integer(basemoxie())))
	table.insert(lines, string.format([[Organs: <b>%s</b> / <b>%s</b> / <b>%s</b><br>]], estimate_max_fullness() - fullness(), estimate_max_safe_drunkenness() - drunkenness(), estimate_max_spleen() - spleen()))
--	table.insert(lines, string.format([[Organs: <b>%s</b>/%s, <b>%s</b>/%s, <b>%s</b>/%s<br>]], fullness(), estimate_max_fullness(), drunkenness(), estimate_max_safe_drunkenness(), spleen(), estimate_max_spleen()))
	if ascensionstatus("Aftercore") then
		table.insert(lines, [[<center><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></center><br>]])
	else
		table.insert(lines, "")
	end
end

function full_charpane_level_lines(lines)
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
	if ascensionstatus("Aftercore") then
		table.insert(lines, [[<center><font size="2"><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></font></center>]])
	end
end

function compact_charpane_hpmp_lines(lines)
	table.insert(lines, string.format([[HP: <b>%s</b><br>]], format_hpmp(hp(), maxhp())))
	if ascensionpath("Zombie Slayer") then
		table.insert(lines, string.format([[Horde: <b>%s</b><br>]], horde_size()))
	else
		table.insert(lines, string.format([[MP: <b>%s</b><br>]], format_hpmp(mp(), maxmp())))
	end
	if playerclass("Seal Clubber") then
		table.insert(lines, string.format([[Fury: <b>%s</b><br>]], fury()))
	end
	if playerclass("Sauceror") then
		table.insert(lines, string.format([[Soulsauce: <b>%s</b><br>]], soulsauce()))
	end
	if ascensionpath("Heavy Rains") then
		if heavyrains_thunder() then
			table.insert(lines, string.format([[dB: <b>%s</b> [%s]<br>]], heavyrains_thunder(), get_daily_counter("thunder fights won")))
		end
		if heavyrains_rain() then
			table.insert(lines, string.format([[Drops: <b>%s</b> [%s]<br>]], heavyrains_rain(), get_daily_counter("rain fights won")))
		end
		if heavyrains_lightning() then
			table.insert(lines, string.format([[Bolts: <b>%s</b><br>]], heavyrains_lightning()))
		end
		table.insert(lines, string.format([[Depth: <b>%+d</b><br>]], get_water_depth_modifier()))
	end
	table.insert(lines, string.format([[Meat: <b>%s</b><br>]], format_integer(meat())))
	table.insert(lines, string.format([[Turns: <b>%s</b> <span class="tiny">(%s played, day %s)</span><br>]], advs(), turnsthisrun(), daysthisrun()))
end


function full_charpane_hpmp_lines(lines)
	if playerclass("Seal Clubber") then
		table.insert(lines, string.format([[<center>Fury: <b>%d gal.</b></center>]], fury()))
	end
	if playerclass("Sauceror") then
		table.insert(lines, string.format([[<center>Soulsauce: <b>%s</b></center>]], soulsauce()))
	end
	if ascensionpath("Heavy Rains") then
		if heavyrains_thunder() then
			table.insert(lines, string.format([[<center>Thunder: <b>%d dBs</b> [%s]</center>]], heavyrains_thunder(), get_daily_counter("thunder fights won")))
		end
		if heavyrains_thunder() then
			table.insert(lines, string.format([[<center>Rain: <b>%d drops</b> [%s]</center>]], heavyrains_rain(), get_daily_counter("rain fights won")))
		end
		if heavyrains_lightning() then
			table.insert(lines, string.format([[<center>Lightning: <b>%d bolts</b></center>]], heavyrains_lightning()))
		end
		table.insert(lines, string.format([[<center>Depth: <b>%+d</b></center>]], get_water_depth_modifier()))
	end

	table.insert(lines, [[<table cellpadding=3 align=center>]])
	table.insert(lines, string.format([[<tr><td align=center><img src="http://images.kingdomofloathing.com/itemimages/hp.gif" class=hand title="Hit Points" alt="Hit Points"><br><span class=black>%s</span></td>]], format_hpmp(hp(), maxhp())))
	if ascensionpath("Zombie Slayer") then
		table.insert(lines, string.format([[<td align=center><img src="http://images.kingdomofloathing.com/otherimages/zombies/horde_15.gif"  height=35 class=hand title="Horde (%s zombie(s))" alt="Horde (%s zombie(s))"><br><span class=black>%s</span></td></tr>]], horde_size(), horde_size(), horde_size()))
	else
		local mpname = ({ "Muscularity Points", "Muscularity Points", "Mana Points", "Mana Points", "Mojo Points", "Mojo Points" })[classid()] or "MP"
		table.insert(lines, string.format([[<td align=center><img src="http://images.kingdomofloathing.com/itemimages/mp.gif" class=hand title="%s" alt="%s"><br><span class=black>%s</span></td></tr>]], mpname, mpname, format_hpmp(mp(), maxmp())))
	end
	table.insert(lines, string.format([[<tr><td align=center><img src="http://images.kingdomofloathing.com/itemimages/meat.gif" class=hand title="Meat" alt="Meat"><br><span class=black>%s</span></td>]], format_integer(meat())))
	table.insert(lines, string.format([[<td align=center><img src="http://images.kingdomofloathing.com/itemimages/hourglass.gif" class=hand title="Adventures Remaining" alt="Adventures Remaining"><br><span class=black>%s</span></td></tr>]], format_integer(advs())))
	table.insert(lines, [[</table>]])
end

function compact_charpane_zone_lines(lines)
	table.insert(lines, string.format([[<a href="%s" target="mainpane">Zone</a>: <b><a href="%s" target="mainpane">%s</a></b><br>]], work_around_broken_status_lastadv(lastadventuredata()).container or "", lastadventuredata().link, lastadventuredata().name))
	local links = update_and_get_previous_adventure_links()
	if setting_enabled("show multiple previous-adventure links") then
		for i = 2, 5 do
			if links[i] then
				table.insert(lines, string.format([[<small><a href="%s" target="mainpane">Zone</a>: <a href="%s" target="mainpane">%s</a></small><br>]], links[i].container or "", links[i].link, links[i].name))
			end
		end
	end
end

function full_charpane_zone_lines(lines)
	table.insert(lines, [[<center>]])
	table.insert(lines, string.format([[<font size=2><b><a class=nounder href="%s" target=mainpane>Last Adventure:</a></b></font><br><font size=2><a target=mainpane href="%s">%s</a></font><br>]], work_around_broken_status_lastadv(lastadventuredata()).container or "", lastadventuredata().link, lastadventuredata().name))
	if setting_enabled("show multiple previous-adventure links") then
		local links = update_and_get_previous_adventure_links()
		for i = 2, 5 do
			if links[i] then
				table.insert(lines, string.format([[<font size=1><a target=mainpane href="%s">%s</a></font><br>]], links[i].link, links[i].name))
			end
		end
	end
	table.insert(lines, [[</center>]])
end

function charpane_equipment_line(slots)
	local equipstr = ""
	local eq = equipment()
	for _, x in pairs(slots) do
		if eq[x] then
			preload_item_api_data(eq[x])
		end
	end
	local icons = {}
	for _, x in ipairs(slots) do
		local pic = "blank"
		local descid = 0
		if eq[x] then
			local isok, thepic, thedescid = pcall(function()
				local data = item_api_data(eq[x])
				return data.picture, data.descid
			end)
			if isok then
				pic = thepic
				descid = thedescid
			else
				pic = "nopic"
				descid = 0
			end
		end
		table.insert(icons, string.format([[<img src="http://images.kingdomofloathing.com/itemimages/%s.gif" width="30" height="30" style="border: solid thin lightgray;" class="hand" onClick="descitem(%d, 0, event)">]], pic, descid))
	end
	return string.format([[<span style="white-space: nowrap">%s</span>]], table.concat(icons))
end

function charpane_familiar_setup_link()
	if familiar("Reanimated Reanimator") then
		return "main.php?talktoreanimator=1", "chat"
	elseif familiar("Grim Brother") then
		return string.format("familiar.php?action=chatgrim&pwd=%s", session.pwd), "talk"
	elseif familiar("Mini-Crimbot") then
		return "main.php?action=minicrimbot", "config"
	end
end

function charpane_familiar_weight_line()
	local link, title = charpane_familiar_setup_link()
	if link and title then
		return string.format([[%s lbs. (<a href="%s" target="mainpane">%s</a>)]], buffedfamiliarweight(), link, title)
	else
		return string.format("%s lbs.", buffedfamiliarweight())
	end
end

local function describe_pastathrall()
	local thrall = get_current_pastathrall_info()
	return string.format([[Lvl. %d %s <span style="white-space: nowrap">(%s)</span>]], thrall.level, thrall.name, thrall.effect)
end

function compact_charpane_familiar_lines(lines, fams)
	if pastathrallid() ~= 0 then
		table.insert(lines, string.format("<center>%s</center>", describe_pastathrall()))
	end
	if familiarid() ~= 0 then
		table.insert(lines, "<center>" .. get_familiar_grid_line(fams) .. "</center>")
		table.insert(lines, string.format([[<center>%s<!-- kolproxy charpane familiar text area --></center>]], charpane_familiar_weight_line()))
	elseif ascensionpath("Avatar of Boris") then
		table.insert(lines, [[<center>]] .. get_clancy_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Jarlsberg") then
		table.insert(lines, [[<center>]] .. get_companion_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Sneaky Pete") then
		table.insert(lines, [[<center>]] .. get_motorbike_display() .. [[</center>]])
	else
		table.insert(lines, [[<center><a href="familiar.php" target="mainpane">No familiar</a></center>]])
	end
end

function full_charpane_familiar_lines(lines, fams)
	if pastathrallid() ~= 0 then
		table.insert(lines, string.format("<center><font size=2>%s</font></center>", describe_pastathrall()))
	end
	if familiarid() ~= 0 then
		table.insert(lines, "<center>" .. get_familiar_grid_line(fams) .. "</center>")
		table.insert(lines, string.format([[<center><font size=2>%s<!-- kolproxy charpane familiar text area --></font></center>]], charpane_familiar_weight_line()))
	elseif ascensionpath("Avatar of Boris") then
		table.insert(lines, [[<center>]] .. get_clancy_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Jarlsberg") then
		table.insert(lines, [[<center>]] .. get_companion_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Sneaky Pete") then
		table.insert(lines, [[<center>]] .. get_motorbike_display() .. [[</center>]])
	else
		table.insert(lines, [[<center><a href="familiar.php" target="mainpane">No familiar</a></center>]])
	end
end

function compact_charpane_buff_lines(lines)
	local buff_colors = {
		["On the Trail"] = "purple",
		["Everything Looks Red"] = "red",
		["Everything Looks Blue"] = "blue",
		["Everything Looks Yellow"] = "goldenrod",
	}
	local bufflines = {}

	if tonumber(api_flag_config().hideefarrows) ~= 1 then
		local curbuffline = nil
		for _, x in ipairs(get_sorted_buff_array()) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local strarrow = make_strarrow(x.upeffect)
			local str = string.format([[<td title="%s"%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td title="%s"%s>%s</td>]], x.title, imgstyleinfo, x.imgname, x.descid, x.title, x.title, styleinfo, display_duration(x))
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
		for _, x in ipairs(get_sorted_buff_array()) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local str = string.format([[<td title="%s"%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td title="%s"%s>%s</td>]], x.title, imgstyleinfo, x.imgname, x.descid, x.title, x.title, styleinfo, display_duration(x))
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

	if ascensionstatus("Aftercore") then
		table.insert(lines, [[<center><a href="]]..make_get_buffs_href()..[[" target="mainpane" style="color: green">{ Get buffs }</a></center>]])
	end
end

function full_charpane_buff_lines(lines)
	local buff_colors = {
		["On the Trail"] = "purple",
		["Everything Looks Red"] = "red",
		["Everything Looks Blue"] = "blue",
		["Everything Looks Yellow"] = "goldenrod",
	}
	local bufflines = {}

	if tonumber(api_flag_config().hideefarrows) ~= 1 then
		for _, x in ipairs(get_sorted_buff_array()) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local strarrow = make_strarrow(x.upeffect)
			local str = string.format([[<tr><td>%s</td><td%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td valign="center"%s><font size=2>%s %s</font><br></td></tr>]], strarrow, imgstyleinfo, x.imgname, x.descid, x.title, styleinfo, x.title, display_duration(x))
			table.insert(bufflines, str)
		end
	else
		for _, x in ipairs(get_sorted_buff_array()) do
			local styleinfo = ""
			local imgstyleinfo = ""
			if buff_colors[x.title] then
				styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
				imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
			end
			local str = string.format([[<tr><td%s><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="width: 25px; height: 25px; cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td valign="center"%s><font size=2>%s %s</font><br></td></tr>]], imgstyleinfo, x.imgname, x.descid, x.title, styleinfo, x.title, display_duration(x))
			table.insert(bufflines, str)
		end
	end

	table.insert(lines, [[<br>]])
	table.insert(lines, [[<center><table>]] .. table.concat(bufflines) .. [[</table></center>]])

	if ascensionstatus("Aftercore") then
		table.insert(lines, [[<center><a href="]]..make_get_buffs_href()..[[" target="mainpane" style="color: green">{ Get buffs }</a></center>]])
	end
end

function compact_charpane_infolines(lines)
	for _, x in ipairs(run_charpane_line_functions()) do
		local name = x.compactname or x.name or "{nil}"
		local value = x.compactvalue or x.value or "{nil}"
		local ct_pre = name
		local ct_value = "<b>" .. value .. "</b>"
		local color = x.color or "black"
		if x.link then
			ct_pre = [[<a target="mainpane" href="]] .. x.link .. [[" style="color:]] .. color .. [[">]] .. name .. [[</a>]]
			if not x.link_name_only then
				ct_value = [[<a target="mainpane" href="]] .. x.link .. [[" style="color:]] .. color .. [["><b>]] .. value .. [[</b></a>]]
			end
		end
		if x.tooltip then
			table.insert(lines, string.format([[<span style="color:%s" title="%s">%s: %s<sup style="font-size: 50%%">(?)</sup></span><br>]], color, x.tooltip, ct_pre, ct_value))
		else
			table.insert(lines, string.format([[<span style="color:%s">%s: %s</span><br>]], color, ct_pre, ct_value))
		end
	end
end

add_interceptor("/charpane.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	if not pcall(turnsthisrun) then return end -- in afterlife
	if kolproxy_custom_charpane_mode() ~= "compact" then return end
	local extra_js, fams = get_familiar_grid()

	local lines = {}
	compact_charpane_level_lines(lines)
	compact_charpane_hpmp_lines(lines)
	compact_charpane_zone_lines(lines)

	table.insert(lines, "<br>")
	table.insert(lines, "<!-- kolproxy charpane text area -->")
	compact_charpane_infolines(lines)

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

	table.insert(lines, "<center>" .. get_outfit_slots_line() .. "</center>")
	table.insert(lines, string.format("<center>%s%s</center>", charpane_equipment_line { "hat", "container", "shirt", "weapon", "offhand" }, charpane_equipment_line { "pants", "acc1", "acc2", "acc3", "familiarequip" }))

	if tonumber(api_flag_config().swapfam) ~= 1 then
		compact_charpane_familiar_lines(lines, fams)
		table.insert(lines, "<br>")
		compact_charpane_buff_lines(lines)
	else
		compact_charpane_buff_lines(lines)
		table.insert(lines, "<br>")
		compact_charpane_familiar_lines(lines, fams)
	end

	local text = [[
<html>
<head>
	<style type="text/css">
body {
	font-family: Arial, Helvetica, sans-serif;
	color: black;
	font-size: 0.8em;
}
td {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 0.8em;
}
a:link { color: black; }
a:visited { color: black; }
a:active { color: black; }
.nounder { text-decoration: none; }
.tiny { font-size: 0.8em; }
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

	full_charpane_level_lines(lines)
	full_charpane_hpmp_lines(lines)

	table.insert(lines, string.format([[<center><font size="2">Turns played: <b>%s</b> (day %s)</font></center>]], turnsthisrun(), daysthisrun()))
	table.insert(lines, "<!-- kolproxy charpane text area -->")

	table.insert(lines, "<br>")
	full_charpane_zone_lines(lines)

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

	if tonumber(api_flag_config().swapfam) ~= 1 then
		table.insert(lines, "<br>")
		full_charpane_familiar_lines(lines, fams)
		full_charpane_buff_lines(lines)
	else
		full_charpane_buff_lines(lines)
		table.insert(lines, "<br>")
		full_charpane_familiar_lines(lines, fams)
	end

	local text = [[
<!DOCTYPE html>
<html>
<head>
	<style type="text/css">
body {
	font-family: Arial, Helvetica, sans-serif;
	color: black;
}
td {
	font-family: Arial, Helvetica, sans-serif;
}
a:link { color: black; }
a:visited { color: black; }
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

function charpane_familiarequip_list()
	local fam_equips = {}
	for x, y in pairs(datafile("items")) do
		if y.equipment_slot == "familiarequip" and have_item(x) then
			local style = ""
			if have_equipped_item(x) then style = [[style="border: solid thin gray"]] end
			table.insert(fam_equips, string.format([[<a href="/inv_equip.php?pwd=%s&which=2&action=equip&whichitem=%i"><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" %s title="%s" alt="%s"></a>]], session.pwd, y.id, y.picture, style, x,x))
		end
	end
	return fam_equips
end
