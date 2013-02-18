local daily_skills = {}

local function burn_aftercore_mp(downto)
	if mp() >= downto then
		cast_skillid(8100)
	end
end

local function get_aftercore_buffs(tbl)
	local buff_functions = {
		["Beaten Up"] = function()
			async_get_page("/bedazzle.php", { slot = 10, sticker = get_itemid("scratch 'n' sniff apple sticker"), pwd = session.pwd, action = "stick" })
		end,
		["Sleepy"] = function()
			use_item("decorative fountain")
		end,
	}
	for x in table.values(tbl) do
		if not buff(x) then
			buff_functions[x]()
		end
	end
end

local automate_zone_href = add_automation_script("automate-zone", function()
	if not autoattack_is_set() then
		stop "Setting an Auto-Attack is required for automated re-adventuring. This can be done in KoL options &rarr; Combat, or with the /autoattack chat command (or the /aa abbreviation)."
	end
	local zoneid = tonumber(params.zoneid)
	local numtimes = tonumber(params.numtimes)
	if zoneid and numtimes then
		local autochoices = {}
		autochoices["Don't Hold a Grudge"] = "Declare a thumb war"
		autochoices["Having a Medicine Ball"] = "Gaze deeply into the mirror"
		autochoices["Out in the Garden"] = "None of the above"
		if ascensionstatus() == "Aftercore" then
			autochoices["Wheel in the Clouds in the Sky, Keep On Turning"] = "Leave the wheel alone"

			autochoices["Disgustin' Junction"] = "Head down the tunnel"
			autochoices["The Former or the Ladder"] = "Take the tunnel"
			autochoices["Somewhat Higher and Mostly Dry"] = "Head down the dark tunnel"

			autochoices["Foreshadowing Demon!"] = "Head towards all the trouble"
			autochoices["You Must Choose Your Destruction!"] = "Follow the fists"
			autochoices["A Test of Your Mettle"] = "Sure! Let's go kick its ass into next week!"
			autochoices["A Maelstrom of Trouble"] = "Head Toward the Peril"
			autochoices["To Get Groped or Get Mugged?"] = "Head Toward the Perv"
			autochoices["A Choice to be Made"] = "Of course, little guy! Let's leap into the fray!"
			autochoices["You May Be on Thin Ice"] = "Fight Back Your Chills"
			autochoices["Some Sounds Most Unnerving"] = "Infernal Pachyderms Sound Pretty Neat"
			autochoices["One More Demon to Slay"] = "Sure! I'll be wearing its guts like a wreath!"
		end
		for i = 1, numtimes do
			print("going for adv " .. i .. " / " .. numtimes)

			-- ...prepare, heal up, spend mp, etc...

-- 			if playername() == "Eleron" then
-- 				burn_aftercore_mp(100)
-- 				get_aftercore_buffs { "Beaten Up", "Sleepy" }
-- 				if hp() < maxhp() / 2 then
-- 					cast_skillid(3012)
-- 				end
-- 				if mp() < 200 then
-- 					use_item("ancient Magi-Wipes")
-- 					use_item("ancient Magi-Wipes")
-- 				end
-- 			end

			-- adventure
			text, url, advagain = autoadventure { zoneid = zoneid, noncombatchoices = autochoices }

			if url:contains("choice.php") and text:contains("name=whichchoice value=91") then
				local found, reached = compute_louvre_paths(91)
				if found.Muscle then
					local function go(cid)
						if reached[cid] ~= -1000 then
							go(reached[cid].whichchoice)
							async_post_page("/choice.php", { pwd = params.pwd, whichchoice = reached[cid].whichchoice, option = reached[cid].option })
						end
					end
					go(found.Muscle.whichchoice)
					text, url = post_page("/choice.php", { pwd = params.pwd, whichchoice = found.Muscle.whichchoice, option = found.Muscle.option })
					advagain = text:contains("You help him push his cart back onto dry land")
				end
			end

			-- ...handle result...
			if text:contains("The turtle blinks at you with gratitude for freeing it from its brainwashing") then
				advagain = true
			end

			if not advagain then
				return text, url
			end
		end
		return text, url
	end
end)

function show_links(match, link)
	if setting_enabled("run automation scripts") and setting_enabled("enable readventuring automation") then
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
