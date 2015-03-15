local function get_aftercore_buffs(tbl)
	local buff_functions = {
		["Beaten Up"] = function()
			async_get_page("/bedazzle.php", { slot = 10, sticker = get_itemid("scratch 'n' sniff apple sticker"), pwd = session.pwd, action = "stick" })
		end,
		["Sleepy"] = function()
			use_item("decorative fountain")
		end,
	}
	for _, x in ipairs(tbl) do
		if not have_buff(x) then
			buff_functions[x]()
		end
	end
end

local zone_automation_times_left = 0
local autochoices = {}

local automate_zone_href = add_automation_script("automate-zone", function()
	if not autoattack_is_set() then
		stop "Setting an Auto-Attack is required for automated re-adventuring.<br><br>This can be done in KoL options &rarr; Combat, or with the /autoattack chat command (or the /aa abbreviation)."
	end
	local zoneid = tonumber(params.zoneid)
	local numtimes = tonumber(params.numtimes)
	if zoneid and numtimes then
--		autochoices["Don't Hold a Grudge"] = "Declare a thumb war"
--		autochoices["Having a Medicine Ball"] = "Gaze deeply into the mirror"
--		autochoices["Out in the Garden"] = "None of the above"
--		if ascensionstatus("Aftercore") then
--			autochoices["Disgustin' Junction"] = "Head down the tunnel"
--			autochoices["The Former or the Ladder"] = "Take the tunnel"
--			autochoices["Somewhat Higher and Mostly Dry"] = "Head down the dark tunnel"
--
--			autochoices["Foreshadowing Demon!"] = "Head towards all the trouble"
--			autochoices["You Must Choose Your Destruction!"] = "Follow the fists"
--			autochoices["A Test of Your Mettle"] = "Sure! Let's go kick its ass into next week!"
--			autochoices["A Maelstrom of Trouble"] = "Head Toward the Peril"
--			autochoices["To Get Groped or Get Mugged?"] = "Head Toward the Perv"
--			autochoices["A Choice to be Made"] = "Of course, little guy! Let's leap into the fray!"
--			autochoices["You May Be on Thin Ice"] = "Fight Back Your Chills"
--			autochoices["Some Sounds Most Unnerving"] = "Infernal Pachyderms Sound Pretty Neat"
--			autochoices["One More Demon to Slay"] = "Sure! I'll be wearing its guts like a wreath!"
--		end
		if params.noncombattitle and params.noncombatoption then
			autochoices[params.noncombattitle] = params.noncombatoption
		end
		zone_automation_times_left = numtimes
		for i = 1, numtimes do
			print("going for adv " .. i .. " / " .. numtimes)

			-- ...prepare, heal up, spend mp, etc...

			if perform_before_automated_readventuring then
				perform_before_automated_readventuring()
--			if hp() < maxhp() / 0.75 then
--				cast_skill("Cannelloni Cocoon")
--			end
			end

			-- adventure
			if locked() then
				text, url = get_page("/choice.php")
				text, url, advagain = handle_adventure_result(text, url, "?", nil, autochoices)
			else
				text, url, advagain = autoadventure { zoneid = zoneid, noncombatchoices = autochoices }
			end

			-- ...handle result...
			if text:contains("The turtle blinks at you with gratitude for freeing it from its brainwashing") then
				advagain = true
			end

			if not advagain and url:contains("choice.php") and locked() then
				text = turn_automation_decorate_noncombat_page(text, zoneid, zone_automation_times_left)
			end

			if perform_after_automated_readventuring then
				perform_after_automated_readventuring()
			end

			if advagain then
				zone_automation_times_left = zone_automation_times_left - 1
			else
				return text, url
			end
		end
		return text, url
	end
end)

function turn_automation_decorate_noncombat_page(pt, zoneid, timesleft)
	local adventure_title
	for x in pt:gmatch([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>([^<]*)</b></td></tr>]]) do
		if x == "Results:" then
		else
			adventure_title = x
		end
	end
	if adventure_title then
		adventure_title = adventure_title:gsub(" %(#[0-9]*%)$", "")
		pt = pt:gsub([[<input class=button type=submit value=".-">]], function(x)
			local val = x:match([[value="(.-)"]])
			return x .. string.format([[<br><a href="%s" style="color:green">{ Automate: %s &rarr; %s }</a>]], automate_zone_href { pwd = session.pwd, zoneid = zoneid, numtimes = timesleft, noncombattitle = adventure_title, noncombatoption = val }, adventure_title, val)
		end)
	end
	return pt
end

function show_links(match, link)
	if not setting_enabled("enable turnplaying automation") then return end
	local function newtext(x)
		return [[
<script language="javascript">
function automate_N_turns(url) {
	N = prompt('Re-adventure how many times?');
	if (N > 0) {
		top.mainpane.location.href = (url + "&numtimes=" + N);
	}
}
</script><br><a href="javascript:automate_N_turns(']] .. link(x) .. [[')" style="color:green">{ Re-adventure here N times }</a>]]
	end
	text = text:gsub("(" .. match .. ")", function(alltext, a, b, c) return alltext .. " " .. newtext(a, b, c) .. "\n" end)
end

local function autohref(z)
	return automate_zone_href { pwd = session.pwd, zoneid = z }
end

add_printer("/choice.php", function()
	show_links([[<a href="adventure.php%?snarfblat=([0-9]+)">Adventure [^<]+</a>]], autohref)
end)

add_printer("/adventure.php", function()
	show_links([[<a href="adventure.php%?snarfblat=([0-9]+)">Adventure [^<]+</a>]], autohref)
end)

add_printer("/fight.php", function()
	show_links([[<a href="adventure.php%?snarfblat=([0-9]+)">Adventure [^<]+</a>]], autohref)
end)

add_printer("/ocean.php", function()
	show_links([[<a href="adventure.php%?snarfblat=([0-9]+)">Adventure [^<]+</a>]], autohref)
end)

add_printer("/tiles.php", function()
	show_links([[<a href="adventure.php%?snarfblat=([0-9]+)">Adventure [^<]+</a>]], autohref)
end)

-- TODO: merge!
local automate_rats_href = add_automation_script("automate-rats", function()
	local numtimes = tonumber(params.numtimes)
	if numtimes then
		for i = 1, numtimes do
			print("going for adv " .. i .. " / " .. numtimes)

			local pt, pturl = get_page("/cellar.php", { action = "autofaucet" })
			text, url, advagain = handle_adventure_result(pt, pturl, "?", nil, {})

			if not advagain then
				return text, url
			end
		end
		return text, url
	end
end)

add_printer("/fight.php", function()
	show_links([[<a href="cellar.php%?action=autofaucet">Fight another [^<]+</a>]], function()
		return automate_rats_href { pwd = session.pwd }
	end)
end)

--	add_printer("/lair3.php", function()
--		show_links([[<a href="lair3.php%?action=hedge">Adventure [^<]+</a>]], "...")
--	end)

--	add_printer("/fight.php", function()
--		show_links([[<a href="inv_use.php%?pwd=[0-9a-f]+&whichitem=2328">Use another drum machine</a>]], "automate-sandworms?")
--	end)

--	add_printer("/trickortreat.php", function()
--		show_links([[value="Hit the Streets %(1%)">]], "automate-trickortreat?")
--	end)
