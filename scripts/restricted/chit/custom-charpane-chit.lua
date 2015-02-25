--[[--
This file is licensed only under the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This file is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with kolproxy. If not, see <http://www.gnu.org/licenses/>.
--]]--

local function chit_progressbar(c, m, color)
	local pct = math.min(100, c * 100 / m)
	return string.format([[<div class="progressbox" title="%i / %i"><div class="progressbar" style="background-color: %s; width: %i%%"></div></div>]], c, m, color, pct)
end

local function blue_progressbar(c, m)
	return chit_progressbar(c, m, "blue")
end

local function color_progressbar(c, m, color, fullcolor)
	local pct = math.min(100, c * 100 / m)
	if pct == 100 then
		color = fullcolor
	elseif pct < 25 then
		color = "red"
	elseif pct < 75 then
		color = "orange"
	else
		color = "blue"
	end
	return chit_progressbar(c, m, color)
end

local function chit_progressline(label, info, bar)
	return string.format([[
<tr>
	<td class="label">%s</td>
	<td class="info">%s</td>
	<td class="progress">%s</td>
</tr>]], label, info, bar)
end

local function progresscolor(c, m, thresholds)
	local pct = math.min(100, c * 100 / m)
	local color = "blue"
	if thresholds ~= nil then
		local sorted = {}
		for lvl in pairs(thresholds) do
			table.insert(sorted, lvl)
		end
		table.sort(sorted)
		for _, lvl in ipairs(sorted) do
			if pct >= lvl then
				color = thresholds[lvl]
			end
		end
	end
	return color
end


local function custom_progressbar(c, m, thresholds)
	local color = progresscolor(c, m, thresholds)
	return chit_progressbar(c, m, color)
end

local function bl_compact()
	return tonumber(api_flag_config().compactchar) ~= 0
end

local function guild_link()
	local guild = "/guild.php"
	if ascensionpath("Avatar of Boris") then
		guild = "/da.php?place=gate1"
	elseif ascensionpath("Zombie Slayer") then
		guild = "/campground.php?action=grave"
	elseif ascensionpath("Avatar of Jarlsberg") then
		guild = "/da.php?place=gate2"
	elseif ascensionpath("Avatar of Sneaky Pete") then
		guild = "/da.php?place=gate3"
	end
	return guild
end

local function bl_charpane_level_lines(lines)
	local partial_level, have_level, need_level = level_progress()
	table.insert(lines, string.format([[<table id='chit_character' class="chit_brick nospace"><tr><th colspan='3'>]]))
	table.insert(lines, string.format([[<a class=nounder target=mainpane href="charsheet.php"><b>%s</b></a></th></tr>]], playername()))
	table.insert(lines, [[<tr><td class='avatar' rowspan='4'><img src="]] .. (avatar_image() or "http://images.kingdomofloathing.com/itemimages/blank.gif") .. [["></td>]])
	table.insert(lines, string.format([[<td class="label"><a target="mainpane" href="%s" title="Visit your guild">%s</a></td>]], guild_link(), classdesc()))

	table.insert(lines, string.format([[<td class="level" rowspan="2" style="width:30px;"><a target="mainpane" href="council.php" title="Visit the Council">%s</a></td></tr>]], round_down(level() + partial_level, 1)))

	local display_path_name = ascensionpathname()
	if display_path_name == classdesc() then
		-- some paths only have one class
		display_path_name = ""
	end
	table.insert(lines, string.format([[
<tr>
	<td class="info">%s</td>
</tr>
<tr>
	<td class="info">%s</td>
	<td class="turns" align="top" title="Turns played (this run)">%d/%s</td>
</tr>
]], display_path_name, ascensionstatus(), daysthisrun(), turnsthisrun()))

	table.insert(lines, string.format([[
<tr>
	<td>
		<div class="chit_resource">
			<div title="Meat" style="float:left">
				<img src="http://images.kingdomofloathing.com/itemimages/meat.gif"><span>%s</span>
			</div>
		</div>
	</td>
	<td>
		<div class="chit_resource">
			<div title="%s Adventures remaining" style="float:right">
				<img src="http://images.kingdomofloathing.com/itemimages/slimhourglass.gif"><span>%s</span>
			</div>
		</div>
	</td>
</tr>
]], format_integer(meat()), format_integer(advs()), format_integer(advs())))

	table.insert(lines, string.format([[
<tr>
	<td class="progress" colspan="3" title="%d substats until level %d">
		<div class="progressbar" style="width:%f%%"></div>
	</td>
</tr>
</table>
]], need_level - have_level, level() + 1, partial_level * 100))
end

local function bl_path_resources_compact() -- TODO: move to other file and only wrap result in chit_resource
	local function makespan(amount, name, icon)
		amount = amount or 0
		return string.format([[<span title="%d %s" style="white-space: nowrap"><img src="http://images.kingdomofloathing.com/itemimages/%s">%d</span>]], amount, name, icon, amount)
	end
	if ascensionpath("Heavy Rains") then
		return [[
<div class="chit_resource"><div>
	]] .. makespan(heavyrains_thunder(), "thunder", "echo.gif") .. [[
	]] .. makespan(heavyrains_rain(), "rain", "familiar31.gif") .. [[
	]] .. makespan(heavyrains_lightning(), "lightning", "cloudlightning.gif") .. [[
</div></div>
]]
	elseif ascensionpath("Actually Ed the Undying") then
		return [[
<div class="chit_resource"><div>
	]] .. makespan(count_item("Ka coin"), "Ka", "kacoin.gif") .. [[
</div></div>
]]
	end
	return ""
end

local function bl_charpane_level_lines_compact(lines)
	local partial_level, have_level, need_level = level_progress()
	table.insert(lines, string.format([[<table id='chit_character' class="chit_brick nospace compact">]]))
--	table.insert(lines, string.format([[<a class=nounder target=mainpane href="charsheet.php"><b>%s</b></a></th></tr>]], playername()))
	table.insert(lines, [[<tr><td class='compactavatar' rowspan='4'><img src="]] .. (avatar_image() or "http://images.kingdomofloathing.com/itemimages/blank.gif") .. [["></td>]])
	table.insert(lines, string.format([[<td class="label"><a target="mainpane" href="charsheet.php">%s</a></td>]], playername()))
	table.insert(lines, string.format([[<td class="level" rowspan="2" style="width:30px;"><a target="mainpane" href="council.php" title="Visit the Council">%s</a></td></tr>]], round_down(level() + partial_level, 1)))
	table.insert(lines, string.format([[<tr><td class="label"><a target="mainpane" href="%s" title="Visit your guild">%s %s</a></td></tr>]], guild_link(), pathdesc(), classdesc_compact()))

	table.insert(lines, string.format([[
<tr>
	<td>%s</td>
	<td class="turns" align="top" title="Turns played (this run)">%d/%s</td>
</tr>
<tr>
	<td>
		<div class="chit_resource">
			<div title="Meat">
				<img src="http://images.kingdomofloathing.com/itemimages/meat.gif"><span>%s</span>
			</div>
		</div>
	</td>
	<td>
		<div class="chit_resource">
			<div title="%s Adventures remaining" class="nowrap">
				<img src="http://images.kingdomofloathing.com/itemimages/slimhourglass.gif"><span>%s</span>
			</div>
		</div>
	</td>
</tr>
]], bl_path_resources_compact(), daysthisrun(), turnsthisrun(), format_integer(meat()), format_integer(advs()), format_integer(advs())))

	table.insert(lines, string.format([[
<tr>
	<td class="progress" colspan="3" title="%d substats until level %d">
		<div class="progressbar" style="width:%f%%"></div>
	</td>
</tr>
</table>
]], need_level - have_level, level() + 1, partial_level * 100))
end

local function maximizer_link(bonus)
	return modifier_maximizer_href { whichbonus = bonus, pwd = session.pwd }
end

local function bl_charpane_mystats_lines(lines)
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
		table.insert(lines, chit_progressline(statname, string.format([[<span style="color:blue">%s</span>&nbsp;&nbsp;(%s)]], format_integer(buffed), format_integer(base)), blue_progressbar(have, need)))
	end
	add_stat_line("Muscle", buffedmuscle(), basemuscle(), rawmuscle())
	add_stat_line("Myst", buffedmysticality(), basemysticality(), rawmysticality())
	add_stat_line("Moxie", buffedmoxie(), basemoxie(), rawmoxie())
	table.insert(lines, "</tbody><tbody>")

	local function add_organ_line(desc, full, fullmax)
		table.insert(lines, chit_progressline(desc, string.format("%i&nbsp;/&nbsp;%i", full, fullmax), color_progressbar(full, fullmax, "blue", "#bbb")))
	end
	add_organ_line("Stomach", fullness(), estimate_max_fullness())
	add_organ_line("Liver", drunkenness(), estimate_max_safe_drunkenness())
	if setting_enabled("show spleen counter") then
		add_organ_line("Spleen", spleen(), estimate_max_spleen())
	end

	if playerclass("Seal Clubber") then
		add_organ_line("Fury", fury(), 5)
	end
	if playerclass("Sauceror") then
		add_organ_line("Soulsauce", soulsauce(), 100)
	end

	if ascensionstatus("Aftercore") then
		table.insert(lines, [[<tr><td colspan='3'><font size="2"><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></font></td></tr>]])
	end
	table.insert(lines, [[</tbody>]])
	table.insert(lines, [[<tbody>]])
	table.insert(lines, chit_progressline("HP", string.format([[<a href="%s">%i</a>&nbsp;/&nbsp;<a href="%s">%i</a>]], script_heal_up_href { pwd = session.pwd }, hp(), script_heal_up_href { pwd = session.pwd, force_heal_up = 1 }, maxhp()), color_progressbar(hp(), maxhp(), "blue", "green")))
	if ascensionpath("Zombie Slayer") then
		table.insert(lines, chit_progressline("Horde", horde_size(), color_progressbar(0, 100, "blue", "green")))
	else
		table.insert(lines, chit_progressline("MP", string.format([[%i&nbsp;/&nbsp;%i]], mp(), maxmp()), color_progressbar(mp(), maxmp(), "blue", "green")))
	end
	table.insert(lines, [[</tbody>]])
	table.insert(lines, [[</table>]])
	local resources = bl_path_resources_compact()
	if resources ~= "" then
		table.insert(lines, string.format([[<center>%s</center>]], resources))
	end
end

local function cast_cocoon(str)
	return string.format([[<span style="cursor: pointer;" onclick="kolproxy_cast_skillid(%d, event.shiftKey)" data-skillid="%d">%s</span>]], 3012, 3012, str)
end

local function bl_compact_stats_bars(lines)
	local function stat_line(raw_substat)
		local substat_level = math.floor(math.sqrt(raw_substat))
		local substat_base = substat_level * substat_level
		local have = raw_substat - substat_base
		local for_next = (substat_level + 1) * (substat_level + 1)
		local need = for_next - substat_base
		local p_of_the_way = have / need
		return custom_progressbar(have, need)
	end
	local stat_cells = [[<td class="label"><a href="%s" target="mainpane">%s</a></td><td class="info"><span style="color:blue">%s</span>&nbsp;&nbsp;(%s)</td>]]

	table.insert(lines, "<tr>")
	table.insert(lines, "<td><table><tr>")
	table.insert(lines, string.format(stat_cells, maximizer_link("Muscle"), "Mus", display_value(buffedmuscle()), display_value(basemuscle())))
	table.insert(lines, "</tr><tr>")
	table.insert(lines, "<td class='statbar' colspan='2'>" .. stat_line(rawmuscle()) .. "</td>")
	table.insert(lines, "</tr><tr>")
	table.insert(lines, string.format(stat_cells, maximizer_link("Mysticality"), "Mys", display_value(buffedmysticality()), display_value(basemysticality())))
	table.insert(lines, "</tr><tr>")
	table.insert(lines, "<td class='statbar' colspan='2'>" .. stat_line(rawmysticality()) .. "</td>")
	table.insert(lines, "</tr><tr>")
	table.insert(lines, string.format(stat_cells, maximizer_link("Moxie"), "Mox", display_value(buffedmoxie()), display_value(basemoxie())))
	table.insert(lines, "</tr><tr>")
	table.insert(lines, "<td class='statbar' colspan='2'>" .. stat_line(rawmoxie()) .. "</td>")
	table.insert(lines, "</tr><tr></table></td><td><table><tr>")
	table.insert(lines, string.format([[<td class="label"><a href="%s" target="mainpane">HP</a></td><td class="info">%s&nbsp/&nbsp;%s</td>]], maximizer_link("Max HP"), cast_cocoon(display_value(hp())), cast_cocoon(display_value(maxhp()))))
	table.insert(lines, "</tr><tr>")
	table.insert(lines, string.format([[<td class='statbar' colspan='2'>%s</td>]], custom_progressbar(hp(), maxhp(), { [0] = "red", [50] = "orange", [75] = "green" })))
	table.insert(lines, "</tr><tr>")
	if ascensionpath("Zombie Slayer") then
		table.insert(lines, string.format([[<td class="label">Horde</td><td class="info">%s</td>]], horde_size()))
	else
		table.insert(lines, string.format([[<td class="label"><a href="%s" target="mainpane">MP</a></td><td class="info">%s&nbsp;/&nbsp;%s</td>]], maximizer_link("Max MP"), display_value(mp()), display_value(maxmp())))
	end
	table.insert(lines, "</tr><tr>")
	table.insert(lines, string.format([[<td class='statbar' colspan='2'>%s</td>]], custom_progressbar(mp(), maxmp(), { [0] = "red", [50] = "orange", [75] = "green" })))
	table.insert(lines, "</tr><tr>")
	table.insert(lines, string.format([[<td class="label"><a href="%s" target="mainpane" >ML</a></td><td class="info">%+d</td>]], maximizer_link("Monster Level"), estimate_bonus("Monster Level")))
	table.insert(lines, "</tr><tr>")
	table.insert(lines, string.format([[<td class='statbar' colspan='2'>%s</td>]], custom_progressbar(mcd(), maxmcd(), { [0] = "red", [50] = "orange", [75] = "green" })))
	table.insert(lines, "</tr></table></td></tr>")
end

local function bl_compact_organ_bars(lines)
	table.insert(lines, "<tr><td colspan='2'><table id='compact_organs'>")

	local function add_organ_cells(full, fullmax)
		table.insert(lines, string.format([[<td class="info">%i / %i</td>]], full, fullmax))
	end
	table.insert(lines, "<tr>")
	local organ_fmt = [[<td class="info"><span class="label">%s</span>&nbsp;%i&nbsp;/&nbsp;%i</td>]]
	table.insert(lines, string.format(organ_fmt, "F:", fullness(), estimate_max_fullness()))
	table.insert(lines, string.format(organ_fmt, "D:", drunkenness(), estimate_max_safe_drunkenness()))
	if setting_enabled("show spleen counter") then
		table.insert(lines, string.format(organ_fmt, "S:", spleen(), estimate_max_spleen()))
	end
	table.insert(lines, "</tr><tr>")
	table.insert(lines, "<td>")
	table.insert(lines, custom_progressbar(fullness(), estimate_max_fullness(), { [0] = "green", [50] = "orange", [75] = "red", [100] = "gray" }))
	table.insert(lines, "</td><td>")
	table.insert(lines, custom_progressbar(drunkenness(), estimate_max_safe_drunkenness(), { [0] = "green", [50] = "orange", [75] = "red", [100] = "gray" }))
	table.insert(lines, "</td>")
	if setting_enabled("show spleen counter") then
		table.insert(lines, "<td>")
		table.insert(lines, custom_progressbar(spleen(), estimate_max_spleen(), { [0] = "green", [50] = "orange", [75] = "red", [100] = "gray" }))
		table.insert(lines, "</td>")
	end
	table.insert(lines, "</tr>")
	if ascensionstatus("Aftercore") then
		table.insert(lines, [[<tr><td colspan='3'><font size="2"><a href="]] .. make_optimize_diet_href() .. [[" target="mainpane" style="color: green">{ Optimize diet }</a></font></td></tr>]])
	end
	table.insert(lines, "</table></td></tr>")
end

local function bl_compact_stats_panel(lines)
	table.insert(lines, [[<table id="chit_stats" class="chit_brick nospace compact">
<tbody>]])

	bl_compact_organ_bars(lines)
	bl_compact_stats_bars(lines)

--	if playerclass("Seal Clubber") then
--		add_organ_line("Fury", fury(), 5)
--	end
--	if playerclass("Sauceror") then
--		add_organ_line("Soulsauce", soulsauce(), 100)
--	end

	table.insert(lines, "</tbody>")
	table.insert(lines, "</table>")
end

local function bl_charpane_zone_lines(lines)
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

local function blpane_familiar_weight()
	if familiar("Reanimated Reanimator") then
		return string.format([[<a href="main.php?talktoreanimator=1" target="mainpane">%s</a>]], buffedfamiliarweight())
	else
		return string.format([[<a href="%s" target="mainpane">%s</a>]], maximizer_link("Familiar Weight"), buffedfamiliarweight())
	end
end

local function familiar_info_line(faminfo)
	local ret = faminfo.info
	if faminfo.type == "counter" then
		if faminfo.max then
			ret = string.format("%d&nbsp;/&nbsp;%d %s", faminfo.count, faminfo.max, faminfo.info)
		else
			ret = string.format("%d %s", faminfo.count, faminfo.info)
		end
		if faminfo.extra_info then
			ret = ret .. string.format(" <span class='extrainfo'>(%s)</span>", faminfo.extra_info)
		end
	end
	return ret
end

local function bl_charpane_familiar(lines)
	table.insert(lines, [[<table id="chit_familiar" class="chit_brick nospace">]])
	if familiarid() ~= 0 then
		local fam_equip = maybe_get_itemdata(tonumber(status().equipment.familiarequip) or 0)
		table.insert(lines, string.format([[
<tr>
	<th width='40' id='weight'>%s</th>
	<th><a target=mainpane href="familiar.php" class="familiarpick" title="Visit your terrarium">%s</a></th>
	<th width="30">&nbsp;</th>
</tr>]], blpane_familiar_weight(), maybe_get_familiarname(familiarid()) or "?"))

		local famtextinfo = ""
		local link, title = charpane_familiar_setup_link()
		if link and title then
			famtextinfo = string.format([[<div class='faminfo'>(<a href="%s" target="mainpane">%s</a>)</div>]], link, title)
		end

		table.insert(lines, string.format([[<tr><td><a href="familiar.php" target="mainpane"><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" width="30" height="30" class="chit_launcher" rel="chit_pickerfam"></td><td>%s<!-- kolproxy charpane familiar text area --></td>]], familiarpicture(), famtextinfo))
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

local function compact_motorbike_display()
	local lovehate = { val = 0, type="love", color="blue", posf = function(pct) return 50 end }
	local moto_lines = [[<tr><td class="icon"><a href="main.php?action=motorcycle" target="mainpane"><img src="http://images.kingdomofloathing.com/itemimages/%s" width="20" height="20"></td>
<td class="famname"><a target=mainpane href="main.php?action=motorcycle">Motorcycle</a></td>
<td class='weight'>%s</th>
<td class=>%s</td></tr><tr><td colspan='4'><div class="progressbox"><div class="progressbar" style="background-color: %s; width: %i%%; position:absolute; left: %d%%"></div></div></td></tr>]]
	if petelove() > 1 then
		lovehate.val = petelove()
		lovehate.type = "love"
		lovehate.color = "blue"
		lovehate.posf = function(pct) return 50 end
	elseif petehate() > 1 then
		lovehate.val = petehate()
		lovehate.type = "hate"
		lovehate.color = "red"
		lovehate.posf = function(pct) return 50 - pct end
	end
	local maxlove = 30
	if have_equipped_item("Sneaky Pete's leather jacket (collar popped)") or have_equipped_item("Sneaky Pete's leather jacket") then
		maxlove = 50
	end
	local pct = math.floor(lovehate.val * 50 / maxlove)

	local pic = can_upgrade_sneaky_pete_motorcycle() and "motorbike_anim.gif" or "motorbike.gif"
	return string.format(moto_lines, pic, lovehate.val, lovehate.type, lovehate.color, pct, lovehate.posf(pct))
end

local function bl_charpane_compact_familiar(lines)
	table.insert(lines, [[<table id="chit_familiar" class="chit_brick nospace compact">]])
	if familiarid() ~= 0 then
		local fam_equip = maybe_get_itemdata(tonumber(status().equipment.familiarequip) or 0) or {}
		table.insert(lines, string.format([[
<tr><td class="icon"><a href="familiar.php" target="mainpane"><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" width="20" height="20" class="chit_launcher" rel="chit_pickerfam"></td>
<td class="famname"><a target=mainpane href="familiar.php" class="familiarpick" title="Visit your terrarium">%s</a></td>
<td class='weight'>%s</td>
<td class="equip"><img class="chit_launcher" rel="chit_pickerfamequip" src="http://images.kingdomofloathing.com/itemimages/%s.gif"></td></tr>]],
					familiarpicture(), maybe_get_familiarname(familiarid()) or "?", blpane_familiar_weight(),
					fam_equip.picture or "blank"))
		local faminfos = get_tracked_familiar_info(familiarpicture())
		if faminfos[1] then
			table.insert(lines, [[<tr><td colspan='4' class='info'>]])
			for _, faminfo in ipairs(faminfos) do
				table.insert(lines,"<div class='faminfo'>" .. familiar_info_line(faminfo) .. "</div>")
			end
			table.insert(lines, [[</td></tr>]])
		end
		local link, title = charpane_familiar_setup_link()
		if link and title then
			table.insert(lines, [[<tr><td colspan='4' class='info'>]])
			table.insert(lines, string.format([[<div class='faminfo'>(<a href="%s" target="mainpane">%s</a>)</div>]], link, title))
			table.insert(lines, [[</td></tr>]])
		end
	elseif ascensionpath("Avatar of Boris") then
		table.insert(lines, [[<tr><th>Clancy</th></tr>]] .. get_clancy_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Jarlsberg") then
		table.insert(lines, [[<center>]] .. get_companion_display() .. [[</center>]])
	elseif ascensionpath("Avatar of Sneaky Pete") then
		table.insert(lines, compact_motorbike_display())
	else
		table.insert(lines, [[<tr><td class="icon"><a href="familiar.php" target="mainpane"><img src="http://images.kingdomofloathing.com/itemimages/blank.gif" width="20" height="20" class="chit_launcher" rel="chit_pickerfam" style="border: 1px solid #f0f0f0;"></td><td><a href="familiar.php" target="mainpane">No familiar</a><td class='weight'>0</td><td class="equip"><img src="http://images.kingdomofloathing.com/itemimages/blank.gif"></td></tr>]])
	end
	if pastathrall() and not setting_enabled("display counters as effects") then
		local thrall = get_current_pastathrall_info()
		table.insert(lines, string.format([[<tr><td class='icon'><img src="http://images.kingdomofloathing.com/itemimages/%s.gif"></td><td class='famname'>%s</td><td class='weight'>%s</td></tr>]], thrall.picture, thrall.name, thrall.level))
		table.insert(lines, string.format([[<tr><td class='info' colspan='4'>%s</td></tr>]], table.concat(thrall.abilities, ", ")))
	end
	table.insert(lines, [[</table>]])
end

local function bl_charpane_fam_picker(fams)
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
			return string.format([[<div style="cursor: pointer;" class="strarrowskill %s" data-skillid="%d"></div>]], arrowclass, skillid)
		elseif itemid then
			return string.format([[<div style="cursor: pointer;%s" class="strarrowitem %s" data-itemid="%d"></div>]], have_item(itemid) and "" or "opacity: 0.5;", arrowclass, itemid)
		end
	end
	return ""
end

local function bl_charpane_buff_lines(lines)
	local bufflines = {}

	local last_buff_type = nil

	for _, x in ipairs(get_sorted_buff_array()) do
		local trstyle = ""
		local styleinfo = ""
		local imgstyleinfo = ""
		local buff_type = x.group
		local shrug_class = "shrug"
		if x.duration == "&infin;" then
			shrug_class = "infinity"
		end

		if buff_type ~= last_buff_type then
			if last_buff_type ~= nil then table.insert(bufflines, "</tbody>") end
			table.insert(bufflines, string.format([[<tbody class="%s">]], buff_type))
		end
		last_buff_type = buff_type

		if x.backgroundcolor then
			trstyle = string.format([[ style="background-color: %s; font-style: italic"]], x.backgroundcolor)
		elseif x.color then
			styleinfo = string.format([[ style="color: %s"]], x.color)
			imgstyleinfo = string.format([[ style="background-color: %s"]], x.color)
		end

		local strarrow = ""
		if tonumber(api_flag_config().compacteffects) == 1 then
			strarrow = make_compact_arrow(x.duration, x.upeffect)
		else
			strarrow = make_strarrow(x.upeffect)
		end

		local str = string.format([[<tr class="%s"%s><td class='icon'><img src="http://images.kingdomofloathing.com/itemimages/%s.gif" style="cursor: pointer;" onClick='popup_effect("%s");' oncontextmenu="return maybe_shrug(&quot;%s&quot;);"></td><td class='info'><div>%s</div></td><td class='%s'>%s</td><td class='powerup'>%s</td></tr>]], buff_type, trstyle, x.imgname, x.descid, x.title, x.title, shrug_class, display_duration(x), strarrow)
		table.insert(bufflines, str)
	end

	if last_buff_type ~= nil then table.insert(bufflines, "</tbody>") end
	if tonumber(api_flag_config().compacteffects) == 1 then
		table.insert(lines, [[<table id="chit_effects" class="chit_brick compact nospace">]])
	else
		table.insert(lines, [[<table id="chit_effects" class="chit_brick nospace">]])
	end
	table.insert(lines, [[

<col class="icon"></col>
<col class="info"></col>
<col class="shrug"></col>
<col class="powerup"></col>

]])
	if bl_compact() and tonumber(api_flag_config().compacteffects) == 1 then
	else
		table.insert(lines, [[<thead>
			<tr>
				<th colspan="4">Effects</th>
			</tr>
		</thead>]])
	end
	table.insert(lines, table.concat(bufflines))
	table.insert(lines, [[</table>]])
end

local function charpane_bleary_js()
-- TODO: remove javascript resizing if possible
	return [[
<script type="text/javascript">
	$(document).ready(function() {
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

local function bl_charpane_modifier_estimate_lines(lines)
	table.insert(lines, string.format([[<table id="chit_modifiers" class="%s">]], bl_compact() and "chit_brick compact nospace" or "chit_brick nospace"))
	table.insert(lines, [[<thead><tr><th colspan="2">Modifiers</th></tr></thead><tbody>]])
	for _, mod_info in ipairs(run_charpane_line_functions()) do
		if mod_info.compactname == "ML" and bl_compact() then
			-- ML is already in the above panel
		else
			local label = bl_compact() and mod_info.compactname or mod_info.normalname or mod_info.name
			if mod_info.link then
				label = string.format([[<a target="mainpane" href="%s">%s</a>]], mod_info.link, label)
			end
			local tooltip = ""
			if mod_info.tooltip then
				tooltip = string.format([[<sup style="font-size: 50%%" title="%s">(?)</sup>]], mod_info.tooltip)
			end
			table.insert(lines, string.format([[<tr><td class="label">%s%s</td><td class="info">%s</td></tr>]], label, tooltip, mod_info.value or mod_info.compactvalue or mod_info.normalvalue))
		end
	end
	table.insert(lines, [[</tbody></table>]])
end

local function bl_charpane_equipment(lines)
	table.insert(lines, string.format([[<table id="chit_equipment" class="chit_brick compact nospace"><tr><td>]]))
	table.insert(lines, string.format([[<center style="font-size: 80%%">%s</center>]], get_outfit_slots_line()))
	table.insert(lines, string.format([[<center style="line-height: 0px">%s%s</center>]], charpane_equipment_line { "hat", "container", "shirt", "weapon", "offhand" }, charpane_equipment_line { "pants", "acc1", "acc2", "acc3", "familiarequip" }))
	table.insert(lines, [[</td></tr></table>]])
end

add_interceptor("/charpane.php", function()
	if not setting_enabled("use custom kolproxy charpane") then return end
	if not pcall(turnsthisrun) then return end -- in afterlife
	if kolproxy_custom_charpane_mode() ~= "bleary" then return end

	local lines = {}

	local extra_js, fams = get_familiar_grid()

	table.insert(lines, [[<div id="chit_house">]])
--	table.insert(lines, [[<div id="chit_roof" class="chit_chamber">]])
--	table.insert(lines, [[</div><!-- end roof -->]])

	table.insert(lines, [[<div id="chit_walls" class="chit_chamber">]])
	if bl_compact() then
		bl_charpane_level_lines_compact(lines)
		bl_compact_stats_panel(lines)
	else
		bl_charpane_level_lines(lines)
		bl_charpane_mystats_lines(lines)
	end
	bl_charpane_equipment(lines)
	-- TODO: move to new function
	if setting_enabled("show modifier estimates") then
		bl_charpane_modifier_estimate_lines(lines)
	end
	bl_charpane_zone_lines(lines)
	if bl_compact() then
		bl_charpane_compact_familiar(lines)
	else
		bl_charpane_familiar(lines)
		if pastathrall() and not setting_enabled("display counters as effects") then
			bl_charpane_thrall(lines)
		end
	end
	bl_charpane_buff_lines(lines)
	if not setting_enabled("show modifier estimates") or ascensionstatus("Aftercore") then
		table.insert(lines, [[<table id="chit_toolbar">
		<tr>
			<th>
				<ul style="float:left">
					<li><a href="charpane.php" title="Reload"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAI/SURBVDjLjZPbS9NhHMYH+zNidtCSQrqwQtY5y2QtT2QGrTZf13TkoYFlzsWa/tzcoR3cSc2xYUlGJfzAaIRltY0N12H5I+jaOxG8De+evhtdOP1hu3hv3sPzPO/z4SsBIPnfuvG8cbBlWiEVO5OUItA0VS8oxi9EdhXo+6yV3V3UGHRvVXHNfNv6zRfNuBZVoiFcB/3LdnQ8U+Gk+bhPVKB3qUOuf6/muaQR/qwDkZ9BRFdCmMr5EPz6BN7lMYylLGgNNaKqt3K0SKDnQ7us690t3rNsxeyvaUz+8OJpzo/QNzd8WTtcaQ7WlBmPvxhx1V2Pg7oDziIBimwwf3qAGWESkVwQ7owNujk1ztvk+cg4NnAUTT4FrrjqUKHdF9jxBfXr1rgjaSk4OlMcLrnOrJ7latxbL1V2lgvlbG9MtMTrMw1r1PImtfyn1n5q47TlBLf90n5NmalMtUdKZoyQMkLKlIGLjMyYhFpmlz3nGEVmFJlRZNaf7pIaEndM24XIjCOzjX9mm2S2JsqdkMYIqbB1j5C6yWzVk7YRFTsGFu7l+4nveExIA9aMCcOJh6DIoMigyOh+o4UryRWQOtIjaJtoziM1FD0mpE4uZcTc72gBaUyYKEI6khgqINXO3saR7kM8IZUVCRDS0Ucf+xFbCReQhr97MZ51wpWxYnhpCD3zOrT4lTisr+AJqVx0Fiiyr4/vhP4VyyMFIUWNqRrV96vWKXKckBoIqWzXYcoPDrUslDJoopuEVEpIB0sR+AuErIiZ6OqMKAAAAABJRU5ErkJggg=="></a></li>]])
--					<li><a class="tool_launcher" title="Elements" href="#" rel="elements"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA0JJREFUeNpUU01oXFUU/u59//PmvTd5k8ybmUxttS3ahIYEBCPFVAmFCoLNTgxCV8WFO3GhWFcu3AgiojsRdOOqiy4kWJA2VaiiBRGpRWY6mTRpMtM3/7/v3Xc9KUTaAx/3LM757ne/cy6TUuIwcpvHFG88XitxY32WW/MFzovTnIkMi2o+j/4omtG3Z5ZqP+KxYIcExevnnlHj+qcLdvHCi/5pnPJKCAwXDmdQozbQryFqb0Rqq/O12RAfHF/bCv8nyG1eOubI8Mqq/9ziS4XTsC2JoagiLQeYpqKA2QjUk5D9Hnpbm4grP/3Ay/310ns7TR7cuqxbSuaz1ezq4itHVnFX3cffcQURdFg8QIrPwACHGPwOdKtw3LOwUi+/Gg31ywcKVDD/tXnbff1MfgF/4T5JDjDFskhzwGUmHJk8UqJOdIhmnZ5SheEto9v65e1/3ix8x00jvz7vnoBmeVDgI8OK8HkJHi/S7Tl4Sh6WCMB7PsFDUntIntiwC2et3h57Q9XV3ELBnsWdCLBYAJMppIITCTBFpyMF+KAJ2RmBhS2CjrhThqYFiFvq8yp4vuDpWewkAjY1KFKBRrBJj0tk+mgI0T5oNoCGBuxxSJoKz+cRhziioq0LmdWR9CJEjCNWlEcYUT7kClITC7Lr0ARcggeM6UwmmIyoLnaEGu8r221PzFl9hsFIoqtINMk4LshhynVyOkUESZsaBx7kmLzIaejX9xHFTkUdP9Ru1ax47oUZEz/XxtTAIGMJQfthGgwWESh9DbxhQzZdJB0HylIBzd/ukALzhoqa/OZqpfvW3IqiukOOxo7AJOLgmkRaZzBoUfWhhNNNQbZtaKdOILy3i/qv2w3A+Z7vfPTUjUFl9NW1zSaOewy+whFuC7R3BZr3BVqUhw8EhmSgejJAz9BQuXkPg4n28fn61bJ6sE2yF314faNbiqvjtZWlacytmOhsCcgwQUzjZAWF9pmGUG2ivHEX4Z/h5x6zv3ziM+UXb6eTvdb7KbB3zi377rNPeyh6OtKC3NzvYlxuYHR7b1dL2p9keOuL8/V3kycIDmN25tpCRvYuZCCWPSaPTiVCZJH8m4W8eZRZVy421iqP1/8nwAD8GGnksWlP5wAAAABJRU5ErkJggg=="></a></li>]])
		if not setting_enabled("show modifier estimates") then
			table.insert(lines, [[<li><a class="tool_launcher" title="Modifiers" href="#" rel="modifiers"><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGxSURBVDjLpVM9a8JQFL0vUUGFfowFpw4dxM2vf9G5newv6OIvEDoVOnUQf0G7CEYQHVzUVZQoaKFugoW20EUaTd5L+u6NSQORdvDC5dyEd+499ySPOY4Dh0TEK8rl8n0mk7lOJBIpVVWBMUaJAzCFEMA5B8MwPpfL5VOlUrklonegWq3qEr+c/2Nbq9VWHs9XkEwm0xLUy/Lzn5KbD1exaDR6FlpBURSq4/E4HJ2c4jMwmYpcw6vf31be2bAHQTPVHYEFyAr7VeEACzfAQKPuSmlCy7LINBcteifSx3ROWutzlCAZ3Z9Op9ButyEWi8F8Poder0drXTQ1SNUeqalt22EFQrgvC4UC5HI5mow1EjA/SjdEjEQiYAd+HV8BF5xwNBpBo9EgBZPJBDqdDimYzWbQ7XapmeA8rIDLiRjFYpEm4zTEfD7v19lslhSgJ2EFXBAOh0Oo1+vk/ng8Bk3TyBtd16HVarkrCRFWYFqmrwAzqMDzBhMVWNaeFSzT5P3BQJXI3G+9P14XC8c0t5tQg/V6/dLv9c+l3ATDFrvL5HZyCBxpv5Rvboxv3eOxQ6/zD+IbEqvBQWgxAAAAAElFTkSuQmCC"></a></li>]])
		end
		if ascensionstatus("Aftercore") then
			table.insert(lines, string.format([[<li><a href="%s" target="mainpane" style="color: green">{ Get buffs }</a></li>]], make_get_buffs_href()))
		end
		table.insert(lines,[[</ul></th></tr></table>]])
	end
	table.insert(lines, [[</div><!-- end walls -->]])
--	table.insert(lines, [[<div id="chit_floor" class="chit_chamber">]])
--	table.insert(lines,[[</div><!-- end floor -->]])

	table.insert(lines, [[<div id="chit_closet">]])
	table.insert(lines, bl_charpane_fam_picker(fams))
	table.insert(lines, [[<div id="chit_toolmodifiers" class="chit_skeleton" style="display:none"><table id="chit_modifiers" class="chit_brick nospace">
<thead><tr><th>Modifiers</th></tr></thead><tbody>
<tr><td><!-- kolproxy charpane text area --></td></tr></tbody></table></div>]])
	table.insert(lines, [[</div><!-- end house -->]])

	local text = [[
<!DOCTYPE html>
<html>
<head>
<title>KoL custom charpane</title>
<link rel="stylesheet" type="text/css" href="/kolproxy-fileserver?filename=chit/chit-stylesheet.css&pwd=]] .. session.pwd .. [[">

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
