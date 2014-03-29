--[[--
This file is licensed only under the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This file is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with kolproxy. If not, see <http://www.gnu.org/licenses/>.
--]]--

register_setting {
	name = "use custom bleary charpane",
	description = "Use bleary / ChIT version",
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
	parent = "use custom bleary charpane",
	update_charpane = true,
	beta_version = true,
}

register_setting {
	name = "display thrall as intrinsic",
	description = "Display pasta thrall as if it were an intrinsic",
	group = "charpane",
	default_level = "enthusiast",
	parent = "use custom bleary charpane",
	update_charpane = true,
	beta_version = true,
}

local function blue_progressbar(c, m)
	local pct = math.min(100, c * 100 / m)
	return string.format([[<div class="progressbox" title="%i / %i"><div class="progressbar" style="background-color: %s; width: %i%%"></div></div>]], c, m, "blue", pct)
end

local function color_progressbar(c, m, color, full)
	local pct = math.min(100, c * 100 / m)
	if pct == 100 then
		color = full
	elseif pct < 25 then
		color = "red"
	elseif pct < 75 then
		color = "orange"
	end
	return string.format([[<div class="progressbox" title="%i / %i"><div class="progressbar" style="background-color: %s; width: %i%%"></div></div>]], c, m, color, pct)
end

function bl_charpane_level_lines(lines)
	local _, have_level, need_level = level_progress()

	table.insert(lines, [[<table id='chit_character' class="chit_brick nospace"><tr><th colspan='3'>]])
	table.insert(lines, string.format([[<a class=nounder target=mainpane href="charsheet.php"><b>%s</b></a></th></tr>]], playername()))
	table.insert(lines, [[<tr><td class='avatar' rowspan='4'><img src="]] .. (avatar_image() or "http://images.kingdomofloathing.com/itemimages/blank.gif") .. [["></td>]])
	table.insert(lines, string.format([[<td class="label"><a target="mainpane" href="da.php?place=gate3" title="Visit your guild">%s</a></td>]], classdesc()))

	table.insert(lines, string.format([[<td class="level" rowspan="2" style="width:30px;"><a target="mainpane" href="council.php" title="Visit the Council">%d</a></td></tr>]], level()))

	table.insert(lines, string.format([[
<tr>
	<td class="info">%s</td>
</tr>
<tr>
	<td class="info">%s</td>
	<td class="turns" align="top" title="Turns played (this run)">%d/%s</td>
</tr>
]], ascensionpathname(), ascensionstatus(), daysthisrun(), turnsthisrun()))

	table.insert(lines, string.format([[
<tr>
	<td colspan="2">
		<div class="chit_resource">
			<div title="Meat" style="float:left">
				<span>%s</span><img src="http://images.kingdomofloathing.com/itemimages/meat.gif">
			</div>
			<div title="%s Adventures remaining" style="float:right">
				<span>%s</span><img src="http://images.kingdomofloathing.com/itemimages/slimhourglass.gif">
			</div>
		</div>
		<div style="clear:both"></div>
	</td>
</tr>
]], format_integer(meat()), format_integer(advs()), format_integer(advs())))

	table.insert(lines, string.format([[
<tr>
	<td class="progress" colspan="3" title="TODO moxie until level TODO (TODO substats needed)">
		<div class="progressbar" style="width:%f%%"></div>
	</td>
</tr>
</table>
]], (have_level * 100 / need_level)))


	table.insert(lines, [[<table id="chit_stats" class="chit_brick nospace">
<thead>
<tr>
	<th colspan="3">My Stats</th>
</tr>
</thead>
<tbody>]])

	local function add_stat_line(statname, buffed, base, raw_substat)
		local substat_level = math.floor(math.sqrt(raw_substat))
		local substat_base = substat_level * substat_level
		local have = raw_substat - substat_base
		local for_next = (substat_level + 1) * (substat_level + 1)
		local need = for_next - substat_base
		local p_of_the_way = have / need
		table.insert(lines, string.format([[
<tr>
	<td class="label">%s</td>
	<td class="info"><span style="color:blue">%s</span>&nbsp;&nbsp;(%s)</td>
	<td class="progress">%s</td>
</tr>]], statname, format_integer(buffed), format_integer(base), blue_progressbar(have, need)))
	end
	add_stat_line("Muscle", buffedmuscle(), basemuscle(), rawmuscle())
	add_stat_line("Myst", buffedmysticality(), basemysticality(), rawmysticality())
	add_stat_line("Moxie", buffedmoxie(), basemoxie(), rawmoxie())
	table.insert(lines, "</tbody><tbody>")

	local function add_organ_line(desc, full, fullmax)
		table.insert(lines, string.format([[
<tr>
<td class="label">%s</td>
<td class="info">%i / %i</td>
<td class="progress">%s</td>
</tr>]], desc, full, fullmax, color_progressbar(full, fullmax, "blue", "#bbb")))
	end
	add_organ_line("Stomach", fullness(), estimate_max_fullness())
	add_organ_line("Liver", drunkenness(), estimate_max_safe_drunkenness())
	add_organ_line("Spleen", spleen(), estimate_max_spleen())

	if playerclass("Seal Clubber") then
		add_organ_line("Fury", fury(), 5)
	end
	if playerclass("Sauceror") then
		add_organ_line("Soulsauce", soulsauce(), 100)
	end

	if ascensionstatus() == "Aftercore" then
		table.insert(lines, [[<tr><td colspan='3'><font size="2"><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></font></td></tr>]])
	end
	table.insert(lines, "</tbody>")
end

function bl_charpane_hpmp_lines(lines)
	table.insert(lines, [[<tbody>]])
	table.insert(lines, string.format([[
<tr>
	<td class="label">HP</td>
	<td class="info">%i&nbsp;/&nbsp;%i</td>
	<td class="progress">
		<div class="progressbox" title="%i / %i">
			<div class="progressbar" style="width:%d%%;background-color:green"></div>
		</div>
	</td>
</tr>]], hp(), maxhp(), hp(), maxhp(), hp() * 100 / maxhp()))

	table.insert(lines, string.format([[
<tr>
	<td class="label">MP</td>
	<td class="info">%i&nbsp;/&nbsp;%i</td>
	<td class="progress">
		<div class="progressbox" title="%i / %i">
			<div class="progressbar" style="width:%d%%;background-color:green"></div>
		</div>
	</td>
</tr>]], mp(), maxmp(), mp(), maxmp(), mp()*100/maxmp()))
	table.insert(lines, [[</tbody>]])
end

function bl_charpane_zone_lines(lines)
	table.insert(lines, [[<table id="chit_trail" class="chit_brick nospace">]])
	table.insert(lines, string.format([[<tr><th><a class="visit" target="mainpane" href="%s">Last Adventure</a></th></tr>]], work_around_broken_status_lastadv(lastadventuredata()).container or ""))
	table.insert(lines, string.format([[<tr><td><a target=mainpane href="%s">%s</a></td></tr>]], lastadventuredata().link, lastadventuredata().name))
	if setting_enabled("show multiple previous-adventure links") then
		local links = update_and_get_previous_adventure_links()
		for i = 2, 5 do
			if links[i] then
				table.insert(lines, string.format([[<tr><td><a target=mainpane href="%s">%s</a></td></tr>]], links[i].link, links[i].name))
			end
		end
	end
	table.insert(lines, [[</table>]])
end

function blpane_familiar_weight()
	if familiar("Reanimated Reanimator") then
		return string.format([[<a href="main.php?talktoreanimator=1" target="mainpane">%s</a>]], buffedfamiliarweight())
	else
		return buffedfamiliarweight()
	end
end

function bl_charpane_familiar(lines)
	table.insert(lines, [[<table id="chit_familiar" class="chit_brick nospace">]])
	if familiarid() ~= 0 then
		local fam_equip = maybe_get_itemdata(tonumber(status().equipment.familiarequip) or 0)
		table.insert(lines, string.format([[
<tr>
	<th width='40' id='weight'>%s</th>
	<th><a target=mainpane href="familiar.php" class="familiarpick" title="Visit your terrarium">%s</a></th>
	<th width="30">&nbsp;</th>
</tr>]], blpane_familiar_weight(), get_familiarname(familiarid())))

		table.insert(lines, string.format([[<tr><td><a href="familiar.php" target="mainpane"><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" width="30" height="30" class="chit_launcher" rel="chit_pickerfam"></td><td><!-- kolproxy charpane familiar text area --></td>]], familiarpicture()))
		if fam_equip then
			table.insert(lines, string.format([[<td><img class="chit_launcher" rel="chit_pickerfamequip" src="http://images.kingdomofloathing.com/itemimages/%s.gif"></td></tr>]], fam_equip.picture))
		else
			table.insert(lines,[[<td><img class="chit_launcher" rel="chit_pickerfequip" src="http://images.kingdomofloathing.com/itemimages/blank.gif"></td></tr>]] )
		end
	elseif ascensionpath("Avatar of Boris") then
		table.insert(lines, [[<tr><th>Clancy</th></tr>]] .. get_clancy_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Jarlsberg") then
		table.insert(lines, [[<center>]] .. get_companion_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Sneaky Pete") then
		table.insert(lines, get_motorbike_display())
	else
		table.insert(lines, [[<center><a href="familiar.php" target="mainpane">No familiar</a></center>]])
	end
	table.insert(lines, [[</table>]])
end

function bl_charpane_fam_picker(fams)
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

	local famequiptext = table.concat(charpane_familiarequip_list())
	return [[<div id="chit_pickerfam" class="chit_skeleton" style="display:none"><table class="chit_picker"><tr><th>Favorites</th></tr><tr><td>]] .. famchoosertext .. [[</td></tr></table></div>]] .. [[<div id="chit_pickerfamequip" class="chit_skeleton" style="display:none"><table class="chit_picker"><tr><th>Equip!</th></tr><tr><td>]] .. famequiptext .. [[</td></tr></table></div>]]
end

local function bl_charpane_thrall(lines)
	local thrall_format = [[<table id="chit_thrall" class="chit_brick nospace">
<tr>
	<th title="Thrall Level">%i</th>
	<th colspan="2" title="Pasta Thrall"><a class="hand" onClick='javascript:window.open("desc_guardian.php", "", "height=200,width=300")'>%s</a></th>
</tr>
<tr>
	<td class="icon" title="Thrall">
		<a class="chit_launcher" rel="chit_pickerthrall" href="#"><img title="Bind thy Thrall" src="http://images.kingdomofloathing.com/itemimages/%s.gif"></a>
	</td>
	<td>%s</td>
</tr></table>]]
	local thrall = get_current_pastathrall_info()
	table.insert(lines, string.format(thrall_format, thrall.level, thrall.name, thrall.picture, table.concat(thrall.abilities, ", ")))
end

local function make_compact_arrow(duration, upeffect)
	if upeffect then
		local skillid = tonumber(upeffect:match("skill:([0-9]+)"))
		local itemid = tonumber(upeffect:match("item:([0-9]+)"))
		local arrowclass = "blup"
		if duration <= 2 then arrowclass = "blrup" end
		if skillid then
			return string.format([[<div style="cursor: pointer;" class="%s" onclick="kolproxy_cast_skillid(%d, event.shiftKey)" data-skillid="%d"></div>]], arrowclass, skillid, skillid)
		elseif itemid then
			return string.format([[<div style="cursor: pointer;%s" class="%s" onclick="kolproxy_use_itemid(%d, event.shiftKey)" data-itemid="%d"></div>]], have_item(itemid) and "" or "opacity: 0.5;", arrowclass, itemid, itemid)
		end
	end
	return ""
end

function bl_charpane_buff_lines(lines)
	local buff_colors = {
		["On the Trail"] = "purple",
		["Everything Looks Red"] = "red",
		["Everything Looks Blue"] = "blue",
		["Everything Looks Yellow"] = "goldenrod",
	}
	local bufflines = {}

	local last_buff_type = nil
	local compact_class = ""

	if tonumber(api_flag_config().compacteffects) == 1 then
		compact_class = "compact"
	end

	for _, x in ipairs(get_sorted_buff_array()) do
		local styleinfo = ""
		local imgstyleinfo = ""
		local buff_type = "effect"
		local shrug_class = "shrug"
		if x.is_song then
			buff_type = "song"
		elseif x.duration == "&infin;" then
			buff_type = "intrinsic"
			shrug_class = "infinity"
		end

		if buff_type ~= last_buff_type then
			if last_buff_type ~= nil then table.insert(bufflines, "</tbody>") end
			table.insert(bufflines, string.format([[<tbody class="%s">]], buff_type))
		end
		last_buff_type = buff_type

		if buff_colors[x.title] then
			styleinfo = string.format([[ style="color: %s"]], buff_colors[x.title])
			imgstyleinfo = string.format([[ style="background-color: %s"]], buff_colors[x.title])
		end

		local strarrow = ""
		if tonumber(api_flag_config().compacteffects) == 1 then
			strarrow = make_compact_arrow(x.duration, x.upeffect)
		else
			strarrow = make_strarrow(x.upeffect)
		end

		local str = string.format([[<tr class="%s %s"><td class='icon'><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td class='info'>%s</td><td class='%s'>%s</td><td class='powerup'><span oncontextmenu="return maybe_shrug(&quot;%s&quot;)">%s</span></td></tr>]], buff_type, compact_class, x.imgname, x.descid, x.title, x.title,shrug_class,display_duration(x.duration), x.title, strarrow)
		table.insert(bufflines, str)
	end

	if playerclass("Pastamancer") and setting_enabled("display thrall as intrinsic") then
		if last_buff_type ~= "intrinsic" then
			if last_buff_type ~= nil then table.insert(bufflines, "</tbody>") end
				table.insert(bufflines, [[<tbody class="intrinsic">]])
		end
		local str = string.format([[<tr class="intrinsic %s"><td class='icon'><img src="http://images.kingdomofloathing.com/itemimages/%s.gif"></td><td class='info' colspan='3'>Lvl %d %s</td></tr>]], compact_class, maybe_get_pastathrall_img(pastathrallid()), pastathralllevel(), maybe_get_pastathrall_name(pastathrallid()))
		table.insert(bufflines, str)
	end
	if last_buff_type ~= nil then table.insert(bufflines, "</tbody>") end
	table.insert(lines, [[
<table id="chit_effects" class="chit_brick nospace">
	<thead>
		<tr>
			<th colspan="4">Effects</th>
		</tr>
	</thead>
]] .. table.concat(bufflines) .. [[
</table>]])
end

function charpane_bleary_js()
	return [[
<script type="text/javascript">
//Resize window
	$(window).resize(function() {
		var pad = 5
		var roofOffset = 4
		var floorOffset = 4
		var roof = $("#chit_roof")
		var walls = $("#chit_walls")
		var floor = $("#chit_floor")

		var roofHeight = roof ? roof.outerHeight(true) : 0
		var floorHeight = floor ? floor.outerHeight(true) : 0
		var availableHeight = $(document).height() - floorHeight - roofOffset - floorOffset - pad;

		if (floor) {
			floor.css({ "bottom": floorOffset + "px" });
		}

		if (roof) {
			roof.css({ "top": roofOffset + "px" });
			if (!walls || (roofHeight > availableHeight)) {
				roof.css("bottom", (floorOffset + floorHeight + pad) + "px");
			}
		}

		if (walls && (roofHeight >= availableHeight)) {
			walls.css("bottom", (floorOffset + floorHeight + pad) + "px");
		}

		else if (walls && (roofHeight < availableHeight)) {
			walls.css("bottom", (floorOffset + floorHeight + pad) + "px");
			if (roof) {
				walls.css("top", (roofOffset + roofHeight + pad) + "px");
			} else {
				walls.css("top", (roofOffset) + "px");
			}
		}
	});

	$(document).ready(function() {
		$(window).resize();

//Picker Launchers
	//use bind for multiple events (KoL uses jQuery 1.3, using multiple events for 'live' was added in jQuery 1.4)
	//$(".chit_launcher").live("click", function(e) {
	$(".chit_launcher").bind("click contextmenu", function(e) {
		var caller = $(this);
		var top = caller.offset().top + caller.height() + 2;
		var picker = $("#" + caller.attr("rel"));

		if (picker) {
			if (picker.is(':hidden')) {
				picker.css({
					'position': 'absolute',
					'top': top,
					'max-height': '93%',
					'overflow-y': 'auto'
				});
				if ((top + picker.height() + 30) > $(document).height()) {
					picker.css('top', ($(document).height() - picker.height() - 30))
				}
				picker.show()
			} else {
				picker.hide()
			}
		}
	return false
	});
	$(".chit_picker a.change").live("click", function(e) {
		$(this).closest(".chit_picker").find("tr.pickloader").show();
		$(this).closest(".chit_picker").find("tr.pickitem").hide();
		$(this).closest(".chit_picker").find("tr.florist").hide();
	});
	$(".chit_picker a.done").live("click", function(e) {
		$(this).closest(".chit_skeleton").hide();
	});
	$(".chit_picker tr.picknone").live("click", function(e) {
		$(this).closest(".chit_skeleton").hide();
	});
	$(".chit_picker th").live("click", function(e) {
		$(this).closest(".chit_skeleton").hide();
	});
	$(".chit_skeleton").live("click", function(e) {
		e.stopPropagation();
	});
	$(document).live("click", function(e) {
		$(".chit_skeleton").hide();
	});
//Tool Launchers
	$(".tool_launcher").live("click", function(e) {
		var caller = $(this);
		var bottom = $("#chit_toolbar").outerHeight() + 4 - 1;
		var tool = $("#chit_tool" + caller.attr("rel"));
		if (tool) {
			if (tool.is(':hidden')) {
				$(".chit_skeleton").hide();
				tool.css({
					'position': 'absolute',
					'left': '4px',
					'right': '4px',
					'bottom': bottom+'px'
				});
				tool.slideDown('fast');
			} else {
				tool.slideUp('fast');
			}
		}
	return false;
	});
	$("div.chit_skeleton table.chit_brick th").live("click", function(e) {
		$(this).closest("div.chit_skeleton").hide();
		e.stopPropagation();
	});
	$("div.chit_skeleton table.chit_brick th a").live("click", function(e) {
		e.stopPropagation();
	});
		})
	</script>
]]
end

function charpane_bleary_css()
	return [[
/*Defaults */
body {
	margin:0px;
	font-size:1em;
font-family:Arial,Helvetica,sans-serif;
}

a:hover {
	color:blue;
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
.hand {
	cursor:pointer;
}
.nospace {
	padding:0px;
	border-spacing:0px;
}

#chit_house {
}
#chit_roof {
	position:absolute;
	overflow-x:hidden;
	overflow-y:auto;
	margin:0px;
	top:4px;
	left:4px;
	right:4px
}
#chit_walls {
	border-top:1px solid #E0E0E0;
	border-bottom:1px solid #E0E0E0;
	margin:0px;
	left:4px;
	right:4px;
	position:absolute;
	overflow-x:hidden;
	overflow-y:auto;
}
#chit_floor {
	position:absolute;
	overflow-x:hidden;
	overflow-y:auto;
	margin:0px;
	left:4px;
	right:4px;
	bottom:4px
}
#chit_toolbar {
	border-collapse:separate;
	border:1px solid #D0D0D0;
	empty-cells:show;
	font-size:12px;
	font-weight:normal;
	margin:0px;
	width:100%;
	padding:1px 1px 1px 1px;
}
#chit_toolbar img {
	border:0px;
	width:16px;
	height:16px;
}

#chit_toolbar th {
	text-align:center;
	vertical-align:middle;
	background-color:#F0F0F0;
	padding:2px;
}

/* Table defaults */
table.chit_brick {
	background-color:white;
	border-collapse:separate;
	border:1px solid #D0D0D0;
	empty-cells:show;
	font-size:12px;
	font-weight:normal;
	margin-bottom:5px;
	width:100%;
	padding:1px 1px 0px 1px;
}
table.chit_brick:last-child {
	margin-bottom:0px;
}
table.chit_brick a {
	text-decoration:none;
}
table.chit_brick tr td a:hover {
	color:blue;
}
table.chit_brick img {
	border:0;
	margin:0;
	padding:0;
}
div.chit_skeleton table.chit_brick {
	margin-bottom:0px;
}
table.chit_brick th {
	word-wrap:break-word;
	max-width:200px;
	text-align:center;
	vertical-align:middle;
	background-color:#F0F0F0;
	padding:2px;
}
table.chit_brick th img {
	float:left;
}
div.chit_skeleton table.chit_brick th {
	background-color:#F0F0B0;
}

/* location: used for counter checkers locations */
table.chit_brick tr td.location {
	background-color:white;
	padding:3px 6px;
	text-align:left;
	color:#666666;
	line-height:1.4;
}
table.chit_brick tr td.location a {
	display:block;
	font-weight:bold;
}
table.chit_brick tr td.info {
	padding:3px;
}
table.chit_brick tr.helper th {
	background-color:#F0F0B0;
}
table.chit_brick tr.wellfed th {
	background-color:#F0F0B0;
}

table.chit_brick td {
	border:0px;
	text-align:center;
	vertical-align:middle;
}
table.chit_brick tr td.progress {
	padding:1px;
}
table.chit_brick tr td.icon {
	background-color:white;
	border:0px;
	padding:3px;
	width:30px;
	height:30px;
}
table.chit_brick tr td.icon img {
	border:0px;
	width:30px;
	height:30px;
}
table.chit_brick tr td.clancy img {
	background-color:white;
	padding:3px;
	border:0px;
	width:40px;
	height:80px;
}
table.chit_brick tr td.companion img {
	background-color:white;
	padding:3px;
	border:0px;
	width:80px;
	height:80px;
	padding:0px 0px 0px 0px;
	margin:-5px -5px -5px -5px;
}
table.chit_brick tr td.motorcycle img {
	text-align:center;
	height:70px;
	margin:-3px 0px -9px 0px;
}

/* section adds the light grey bar above the table row */
table.chit_brick tr.section td {
	border-top:1px solid #F0F0F0;
}

/* Florist Friars formatting */
td.florist {
	color:#606060;
	font-weight:bold;
	text-align:center;
	padding:0px;
	max-width:60px;
}
td.florist img {
	margin:-5px 2px 0px 2px;
	vertical-align:middle;
	height:40px;
}
tr.florist img {
	vertical-align:middle;
	max-height:50px;
}
tr.florist :first-line {
	font-weight:bold;
}

/* Character Panel */
#chit_character tr td.level {
	font-size:21px;
	background-color:#F8F8F8;
	width:40px;
}

#chit_character tr td.avatar {
	background-color:white;
	padding:2px;
	width:45px;
	vertical-align:middle;
}
#chit_character tr td.avatar img {
	height:75px;
	width: 45px;
}
#chit_character tr td.label {
	font-weight:bold;
	text-align:left;
	padding:1px 4px;
}
#chit_character tr td.info {
	color:#606060;
	text-align:left;
	padding:1px 4px;
}
#chit_character tr td.info a {
	font-weight:bold;
	white-space:nowrap;
}

#chit_character tr td.turns {
	border-top:1px solid white;
	background-color:#F8F8F8;
	padding:1px 4px;
}
#chit_character tr td.progress {
	border-top:1px solid #DDDDDD;
	height:5px;
}
#chit_character tr td.progress div.progressbar {
	height:5px;
}

.chit_resource {
	color:darkred;
	font-weight:bold;
	background-color:#F8F8F8;
	padding:0px 2px;
}
.chit_resource div span, .chit_resource div img {
	vertical-align:middle;
}
.chit_resource div img {
	max-width:12px;
	max-height:12px;
	padding-left:3px;
}

/* Stats Panel */
#chit_stats tbody tr:first-child td {
	border-top:1px solid #F0F0F0;
}

#chit_stats tr td.label, #chit_substats tr td.label, #chit_organs tr td.label {
	font-weight:bold;
	text-align:left;
	padding:2px;
	width:50px;
}
#chit_stats tr td.info, #chit_substats tr td.info tr td.info {
	color:#606060;
	font-weight:bold;
	text-align:right;
	padding:1px;
	width:50px;
}
#chit_stats tr td.fury {
	color:red;
	font-weight:900;
	text-align:center;
	padding:1px;
	max-width:50px;
}
#chit_organs tr td.info {
	color:#606060;
	font-weight:bold;
	text-align:center;
	padding:2px;
	width:40px;
	display:block;
}
#chit_stats tr td.info a, #chit_stats tr td.progress a {
	color:#606060;
	white-space:nowrap;
}
#chit_stats tr td.info a:hover, #chit_stats tr td.progress a:hover {
	color:blue;
}
#chit_stats.nobars tr td.info {
	width:135px;
}
#chit_stats tr td.progress, #chit_substats tr td.progress, #chit_organs tr td.progress {
	width:100%;
	padding:2px 2px 2px 2px;
	text-align:right;
	font-weight:bold;
	color:#A0A0A0;
}
#chit_stats tr td.history {
	color:#606060;
	font-weight:normal;
	text-align:left;
	padding:2px;
}
#chit_stats tr td.history a {
	font-weight:bold;
	color:#606060;
}
#chit_stats tr td.history a:hover {
	color:blue;
}

div.progressbox {
	padding:1px;
	background-color:#F0F0F0;
	border:1px solid #E0E0E0;
	height:6px
}
div.progressbar {
	height:100%;
	background-color:blue
}

/* Modifiers Panel */
#chit_modifiers tbody tr:first-child td {
	border-top:1px solid #F0F0F0;
}

#chit_modifiers tr td.label {
	font-weight:bold;
	text-align:left;
	padding:2px;
}
#chit_modifiers tr td.info{
	color:#606060;
	font-weight:bold;
	text-align:right;
	padding:2px;
}

/* MCD Panel + popup */
#chit_mcd tr th.busy {
	background-image:url(/images/relayimages/chit/busy.gif);
	background-position:5px center;
	background-repeat:no-repeat;
}
#chit_mcd td, #chit_pickermcd td {
	padding:2px 4px;
	text-align:left;
}
#chit_mcd tr:hover td, #chit_pickermcd tr:hover td {
	background-color:#F8F8F8;
}
#chit_mcd tr.current td, #chit_pickermcd tr.current td {
	background-color:#F0F0F0;
	font-weight:bold;
}
#chit_mcd td.level, #chit_pickermcd td.level {
	font-weight:bold;
	text-align:center;
	width:20px;
}
#chit_mcd td a, #chit_pickermcd td a {
	display:block;
}

/* Familiars Panel */
#chit_familiar tr td.progress {
	border-top:1px solid #DDDDDD;
}
#chit_familiar tr td.progress div.progressbar {
	height:4px;
}
#chit_familiar tr td.info {
	border-left:1px solid #F0F0F0;
	border-right:1px solid #F0F0F0;
	font-weight:bold;
	line-height:1.4;
}

/* Trail (Last Adventure) Panel */
#chit_trail tr td {
	padding:0px 4px 2px 4px;
	font-size:12px;
}
#chit_trail tr td.last {
	padding:2px 4px;
	font-size:12px;
	font-weight:bold;
}

/* Effects Panel */
#chit_effects a {
	text-decoration:none;
}
#chit_effects td.shrug a:hover, #chit_effects td.infinity a:hover, #chit_effects td.infizero a:hover {
	color:red;
}

#chit_effects tbody.intrinsics td.info {
	text-align:left;
}
#chit_effects td {
	border-bottom:1px solid #F0F0F0;
	vertical-align:middle;
	padding:0px;
}
#chit_effects tr:last-child td {
	border-bottom:3px solid #E0E0E0;
}
#chit_effects tbody:last-child tr:last-child td {
	border-bottom:0px;
}
#chit_effects td.icon {
	text-align:left;
	width:20px;
	padding:1px 2px;
}
#chit_effects td.icon img {
	border:0px;
	width:20px;
	height:20px;
}
#chit_effects td.noshrug, #chit_effects td.shrug {
	text-align:center;
	padding:0px 2px;
	width:25px;
}
#chit_effects td.shrug a, #chit_effects td.infinity a, #chit_effects td.infizero a {
	color:blue;
}
#chit_effects td.info {
	padding:1px 3px;
	text-align:left;
	font-size: 11px;
}
#chit_effects td.powerup {
	width:20px;
	text-align:center;
}
#chit_effects td.infinity {
	text-align:center;
	font-size:16px;
	font-weight:bold;
}
#chit_effects td.infizero {
	text-align:center;
	font-size:10px;
	font-weight:bold;
}
#chit_effects td.powerup a {
	display:block;
	height:100%;
}
#chit_effects td.right {
	text-align:right;
	padding-right:4px;
}


/* for compact effects list */

#chit_effects .compact td.shrug {
font-size: 11px;
}
#chit_effects .compact td.icon {
	text-align:left;
	width:15px;
	height: 15px;
	padding:1px 2px;
}
#chit_effects .compact td.icon img {
	border:0px;
	width:15px;
	height:15px;
}
#chit_effects .compact td.noshrug, #chit_effects td.shrug {
	text-align:center;
	padding:0px 2px;
	width:15px;
}

#chit_effects .compact td.powerup {
	width:15px;
	text-align:center;
}

.efmods {
	color:#686868; /* slightly darker than modspooky */
}
#chit_effects .efmods {
	font-size:10px;
}
.efmods .modcold {
	color:blue;
}
.efmods .modhot {
	color:red;
}
.efmods .modsleaze {
	color:purple;
}
.efmods .modspooky {
	color:#989898; /* slightly lighter than efmods */
}
.efmods .modstench {
	color:green;
}

/* chit_picker defines the popup details, use for companion/familiar, MCD, etc. */
table.chit_picker {
	width:100%;
	border:1px solid blue;
	font-size:12px;
	background-color:#F8F8F8;
	text-align:center;
	vertical-align:middle;
	padding:0px;
	border-spacing:0px;
}
table.chit_picker th {
	background-color:blue;
	color:white;
	padding:4px 12px;
	background-position:top right;
	background-image:none;
	background-repeat:no-repeat;
	cursor:pointer;
}
table.chit_picker th:hover {
	background-image:url(/images/closebutton.gif);
}

table.chit_picker td {
	border-left:0px;
	border-right:0px;
	border-top:0px solid #DDDDDD;
	border-bottom:1px solid white;
}
table.chit_picker tr.pickitem td {
}
table.chit_picker tr.picknone td.info {
	padding:8px;
	color:#333333;
}
table.chit_picker td.icon {
	width:30px;
	background-color:white;
}
table.chit_picker td.icon img {
	border:2px solid white;
}
table.chit_picker td.item {
	padding:0px 6px;
}
table.chit_picker tr.pickloader td.item {
	padding:4px 12px;
}
table.chit_picker tr.pickitem td.remove {
	border-left:4px solid red;
}
table.chit_picker tr.pickitem td.fold {
	border-left:4px solid orange;
}
table.chit_picker tr.pickitem td.make {
	border-left:4px solid orange;
}
table.chit_picker tr.pickitem td.inventory {
	border-left:4px solid green;
}
table.chit_picker tr.pickitem td.clancy {
	border-left:4px solid green;
}
table.chit_picker tr.pickitem td.retrieve {
	border-left:4px solid purple;
}
table.chit_picker tr.pickitem td.action {
	border-bottom:1px solid #E0E0E0;
	padding:4px 8px;
	font-weight:bold;
}
table.chit_picker tr td a {
/*	display:block;
	width:100%;
	height:	100%; */
	text-decoration:none;
	color:black;
}
table.chit_picker tr.pickitem a:hover {
	text-decoration:none;
	color:blue;
}

/* Familiar Panel */
#chit_pickerfam tr:hover td {
	background-color:#F0F0F0;
}

/* chit_skeleton */
div.chit_skeleton {
	position:absolute;
	display:block;
	z-index:10;
	right:10px;
	left:10px;
}

div.chit_skeleton table.chit_brick th {
	background-position:top right;
	background-image:none;
	background-repeat:no-repeat;
	cursor:pointer;
}
div.chit_skeleton table.chit_brick th:hover {
	background-image:url(/images/relayimages/chit/collapse.png);
}

/* Current Quests Panel (#nudges ID matched KOL usage) */
#nudges td.small {
	font-size:1em;
	border-top:1px solid #F0F0F0;
	padding:4px;
}

#nudges td a {
	display:inline;
}

#nudges div {
	padding-right:20px;
	text-align:left;
	line-height:1.4;
}

#nudges div .close {
	position:absolute;
	top:0px;
	right:0px;
	border:0px solid red;
	display:inline;
	height:10px;
	width:10px;
}

/* Elements Panel (KOLWiki Elements image) */
#chit_elements td {
	overflow-x:hidden;
}

#chit_elements td img {
	vertical-align:middle;
	text-align:center;
	width:100%;
	max-width:200px;
}

/* Toolbar Panel (icons + popups) */
#chit_toolbar {
	padding:0px;
	border-spacing:0px;
}
#chit_toolbar ul {
	list-style-type:none;
	margin:0px;
	padding:0px;
}

#chit_toolbar ul li {
	display:inline;
	margin:0px;
	padding:0px 3px;
	border:0px;
}
#chit_toolbar ul li a {
	margin:0px;
	padding:0px;
	border:0px;
}
#chit_toolbar ul li img {
	margin:0px;
	padding:0px;
	border:0px;
	vertical-align:middle;
}

.chit_chamber #chit_update th {
	background-color:#dce1f5;
}
#chit_update a {
	font-weight:bold;
}
#chit_update p {
	padding:4px;
	margin:0px;
}

#fam_equip {
	position:relative;
}
img#fam_equip {
	position:absolute;
	top:0;
	left:0;
	z-index:5;
}
#fam_lock {
	position:absolute;
	top:21px;
	left:17px;
	z-index:10;
	max-width:16px;
	max-height:16px;
	border:1px solid black;
}

/* Quests Tracker Panel added by ckb */
#chit_tracker tr td {
	padding:0px 4px 2px 4px;
	/* font-size:12px; */
	font-size:12px;
	text-align:left;
	border-top:1px solid #F0F0F0;
}
#chit_tracker td a {
	font-weight:bold;
}
#chit_tracker tr td table {
	width:100%;
	border:0px;
	padding:0px 0px 0px 0px;
}
#chit_tracker tr td table tr td {
	margin-bottom:0px;
	border:0px;
	padding:0px 0px 0px 0px;
}

/* Fancy Currency by DeadNed (#1909053)
   Not curently being used, but maybe... if I put in some time */
#chit_currency ul {
	margin:0;
	padding:0;
	list-style:none;
}
#chit_currency ul li {
	display:block;
	position:relative;
	float:left;
}
#chit_currency li ul {
	display:none;
}
#chit_currency ul li a {
	display:block;
	text-decoration:none;
	padding:5px 15px 5px 15px;
	background:#ffffff;
	margin-left:1px;
	white-space:nowrap;
	font-weight:bold;
	color:black;
	font-size:smaller;
}
#chit_currency ul li a:hover {
	background:#eeeeee;
}
#chit_currency li:hover ul {
	display:block;
	position:absolute;
}
#chit_currency li:hover li {
	float:none;
	font-size:12px;
}


.blup {

width: 13px;
height: 14px;
background-repeat: no-repeat;
background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAQAAABedl5ZAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAJ9JREFUGNOV0E8LwWAAx/FdV8prkOeZtcPyp0hYpjUHJamRXKyMNa/I+1PK/bl59nWRMIq+x8/l1884Gt8yfiK7bF1F/QO5JUePkBfhvFHbbOqQmDHyLGpP1De7TEiIiAmRJ1F5kMeMlDVzFmwIsKiad/KVp6akRGzxsZVULzMGOmVJgpsXFg51xoodjSL5+kDGnlaRAnw8enTy/4567wZAto4PusD6jAAAAABJRU5ErkJggg==);
}
.blrup {
width: 13px;
height: 14px;
background-repeat: no-repeat;
background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAATZJREFUeNq80stLAnEQB/Dv77UvhXXFyBCyIBEieggVqwimYvf+wc5dor1JJHSUII8VBEFgBBnBHtxVt/VXHjrUij0OzWEGhvkwMAyRUuK3QfGHmIrOVGo2LfrqZNjmj9B50oozIl5ShRLjQ3nqLLHVmai9mNO5YrhmpUKTtQYWivtz3Jetd5ifijprtg4j7iV2bZqq1jHsPiBRLCJdaqTZAC1nhS1HNwndswoFWNUaRr1nyEGAUfcR1paN+e29DA343XGe65NR/mGYULz+9S3CUWCY5R2Ergstm8XTiQO30/ZoDDi4H/uf0MZFMzapl+vl0CzblAgFUjJ4N1ey7o9jM6/HmDJJIFwF5QKMqpGT868NIjQQJmDkcpBhCCja9wgqpb3DI4SBh7HfhxB6ZIT82++9CTAAso5biZF3emoAAAAASUVORK5CYII=);

}


]]
end

add_interceptor("/charpane.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	if not pcall(turnsthisrun) then return end -- in afterlife
	if kolproxy_custom_charpane_mode() ~= "bleary" then return end

	local lines = {}

	local extra_js, fams = get_familiar_grid()

	table.insert(lines, [[<div id="chit_house"><div id="chit_roof" class="chit_chamber">]])
	bl_charpane_level_lines(lines)
	bl_charpane_hpmp_lines(lines)
	table.insert(lines, [[</table>]])

	bl_charpane_zone_lines(lines)
	bl_charpane_familiar(lines)
	if playerclass("Pastamancer") and not setting_enabled("display thrall as intrinsic") then
		bl_charpane_thrall(lines)
	end
	table.insert(lines, [[</div><!-- end roof -->]])

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

	table.insert(lines, [[<div id="chit_walls" class="chit_chamber">]])
	bl_charpane_buff_lines(lines)
	table.insert(lines, [[</div><!-- end walls -->
<div id="chit_floor" class="chit_chamber">
	<table id="chit_toolbar">
		<tr>
			<th>
				<ul style="float:left">
					<li><a href="charpane.php" title="Reload"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAI/SURBVDjLjZPbS9NhHMYH+zNidtCSQrqwQtY5y2QtT2QGrTZf13TkoYFlzsWa/tzcoR3cSc2xYUlGJfzAaIRltY0N12H5I+jaOxG8De+evhtdOP1hu3hv3sPzPO/z4SsBIPnfuvG8cbBlWiEVO5OUItA0VS8oxi9EdhXo+6yV3V3UGHRvVXHNfNv6zRfNuBZVoiFcB/3LdnQ8U+Gk+bhPVKB3qUOuf6/muaQR/qwDkZ9BRFdCmMr5EPz6BN7lMYylLGgNNaKqt3K0SKDnQ7us690t3rNsxeyvaUz+8OJpzo/QNzd8WTtcaQ7WlBmPvxhx1V2Pg7oDziIBimwwf3qAGWESkVwQ7owNujk1ztvk+cg4NnAUTT4FrrjqUKHdF9jxBfXr1rgjaSk4OlMcLrnOrJ7latxbL1V2lgvlbG9MtMTrMw1r1PImtfyn1n5q47TlBLf90n5NmalMtUdKZoyQMkLKlIGLjMyYhFpmlz3nGEVmFJlRZNaf7pIaEndM24XIjCOzjX9mm2S2JsqdkMYIqbB1j5C6yWzVk7YRFTsGFu7l+4nveExIA9aMCcOJh6DIoMigyOh+o4UryRWQOtIjaJtoziM1FD0mpE4uZcTc72gBaUyYKEI6khgqINXO3saR7kM8IZUVCRDS0Ucf+xFbCReQhr97MZ51wpWxYnhpCD3zOrT4lTisr+AJqVx0Fiiyr4/vhP4VyyMFIUWNqRrV96vWKXKckBoIqWzXYcoPDrUslDJoopuEVEpIB0sR+AuErIiZ6OqMKAAAAABJRU5ErkJggg=="></a></li>
					<!--<li><a class="tool_launcher" title="Elements" href="#" rel="elements"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA0JJREFUeNpUU01oXFUU/u59//PmvTd5k8ybmUxttS3ahIYEBCPFVAmFCoLNTgxCV8WFO3GhWFcu3AgiojsRdOOqiy4kWJA2VaiiBRGpRWY6mTRpMtM3/7/v3Xc9KUTaAx/3LM757ne/cy6TUuIwcpvHFG88XitxY32WW/MFzovTnIkMi2o+j/4omtG3Z5ZqP+KxYIcExevnnlHj+qcLdvHCi/5pnPJKCAwXDmdQozbQryFqb0Rqq/O12RAfHF/bCv8nyG1eOubI8Mqq/9ziS4XTsC2JoagiLQeYpqKA2QjUk5D9Hnpbm4grP/3Ay/310ns7TR7cuqxbSuaz1ezq4itHVnFX3cffcQURdFg8QIrPwACHGPwOdKtw3LOwUi+/Gg31ywcKVDD/tXnbff1MfgF/4T5JDjDFskhzwGUmHJk8UqJOdIhmnZ5SheEto9v65e1/3ix8x00jvz7vnoBmeVDgI8OK8HkJHi/S7Tl4Sh6WCMB7PsFDUntIntiwC2et3h57Q9XV3ELBnsWdCLBYAJMppIITCTBFpyMF+KAJ2RmBhS2CjrhThqYFiFvq8yp4vuDpWewkAjY1KFKBRrBJj0tk+mgI0T5oNoCGBuxxSJoKz+cRhziioq0LmdWR9CJEjCNWlEcYUT7kClITC7Lr0ARcggeM6UwmmIyoLnaEGu8r221PzFl9hsFIoqtINMk4LshhynVyOkUESZsaBx7kmLzIaejX9xHFTkUdP9Ru1ax47oUZEz/XxtTAIGMJQfthGgwWESh9DbxhQzZdJB0HylIBzd/ukALzhoqa/OZqpfvW3IqiukOOxo7AJOLgmkRaZzBoUfWhhNNNQbZtaKdOILy3i/qv2w3A+Z7vfPTUjUFl9NW1zSaOewy+whFuC7R3BZr3BVqUhw8EhmSgejJAz9BQuXkPg4n28fn61bJ6sE2yF314faNbiqvjtZWlacytmOhsCcgwQUzjZAWF9pmGUG2ivHEX4Z/h5x6zv3ziM+UXb6eTvdb7KbB3zi377rNPeyh6OtKC3NzvYlxuYHR7b1dL2p9keOuL8/V3kycIDmN25tpCRvYuZCCWPSaPTiVCZJH8m4W8eZRZVy421iqP1/8nwAD8GGnksWlP5wAAAABJRU5ErkJggg=="></a></li>-->
					<li><a class="tool_launcher" title="Modifiers" href="#" rel="modifiers"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGxSURBVDjLpVM9a8JQFL0vUUGFfowFpw4dxM2vf9G5newv6OIvEDoVOnUQf0G7CEYQHVzUVZQoaKFugoW20EUaTd5L+u6NSQORdvDC5dyEd+499ySPOY4Dh0TEK8rl8n0mk7lOJBIpVVWBMUaJAzCFEMA5B8MwPpfL5VOlUrklonegWq3qEr+c/2Nbq9VWHs9XkEwm0xLUy/Lzn5KbD1exaDR6FlpBURSq4/E4HJ2c4jMwmYpcw6vf31be2bAHQTPVHYEFyAr7VeEACzfAQKPuSmlCy7LINBcteifSx3ROWutzlCAZ3Z9Op9ButyEWi8F8Poder0drXTQ1SNUeqalt22EFQrgvC4UC5HI5mow1EjA/SjdEjEQiYAd+HV8BF5xwNBpBo9EgBZPJBDqdDimYzWbQ7XapmeA8rIDLiRjFYpEm4zTEfD7v19lslhSgJ2EFXBAOh0Oo1+vk/ng8Bk3TyBtd16HVarkrCRFWYFqmrwAzqMDzBhMVWNaeFSzT5P3BQJXI3G+9P14XC8c0t5tQg/V6/dLv9c+l3ATDFrvL5HZyCBxpv5Rvboxv3eOxQ6/zD+IbEqvBQWgxAAAAAElFTkSuQmCC"></a></li>]])
	if ascensionstatus() == "Aftercore" then
		table.insert(lines, string.format([[<li><a href="%s" target="mainpane" style="color: green">{ Get buffs }</a></li>]], make_get_buffs_href()))
	end
	table.insert(lines,[[</ul></th></tr></table></div><!-- end floor -->]])

	table.insert(lines, [[<div id="chit_closet">]])
	table.insert(lines, bl_charpane_fam_picker(fams))
	table.insert(lines, [[<div id="chit_toolmodifiers" class="chit_skeleton" style="display:none"><table id="chit_modifiers" class="chit_brick nospace">
<thead><tr><th>Modifiers</th></tr></thead><tbody>
<tr><td><!-- kolproxy charpane text area --></td></tr></tbody></table></div>]])
	table.insert(lines, [[</div><!-- end house -->]])

	local text = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>charpane</title>	<style type="text/css">
]] .. charpane_bleary_css() .. [[
	</style>

]] .. get_common_js() .. [[

]] .. charpane_bleary_js() .. [[

]] .. extra_js .. [[

</head>
<body>
]] .. table.concat(lines) .. [[
</body>
</html>]]
	return text, "/kolproxy-quick-charpane-normal"
end)
