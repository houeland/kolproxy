add_processor("/fight.php", function()
	if text:contains(">The Thing with no Name is destroyed. Way to go!<") then
		ascension["suburbandis.defeated thing with no name"] = "yes"
	end
end)

function macro_dis(whichskill)
  return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

]] .. noodles_action() .. [[

if (monstername Bat in the Spats)
  while !times 20
    use clumsiness bark
  endwhile
endif

if (monstername Thorax)
  while !times 20
    if match "draws back his big fist"
      use clumsiness bark
    endif
    if (!match "draws back his big fist")
      attack
    endif
  endwhile
endif

if (monstername Mammon the Elephant) || (monstername The Large-Bellied Snitch)
  while !times 20
    use dangerous jerkcicle, dangerous jerkcicle
  endwhile
endif

if (monstername Thug 1 and Thug 2)
  while !times 20
    use jar full of wind, jar full of wind
  endwhile
endif

if (monstername Terrible Pinch)
  while !times 20
    use jar full of wind
    cast Saucegeyser
  endwhile
endif

if (monstername The Thing with No Name)
  while !times 20
]] .. serpent_action() .. [[
  endwhile
endif

if (hasskill ]] .. whichskill .. [[)

  cast ]] .. whichskill .. [[

endif

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end

local script = nil

local function automate_dis_zone(zoneid, whichskill)
	local noncombatchoices = {
		["Foreshadowing Demon!"] = "Head towards all the trouble",
		["You Must Choose Your Destruction!"] = "Follow the fists",
		["A Test of Your Mettle"] = "Sure! Let's go kick its ass into next week!",
		["A Maelstrom of Trouble"] = "Head Toward the Peril",
		["To Get Groped or Get Mugged?"] = "Head Toward the Perv",
		["A Choice to be Made"] = "Of course, little guy! Let's leap into the fray!",
		["You May Be on Thin Ice"] = "Fight Back Your Chills",
		["Some Sounds Most Unnerving"] = "Infernal Pachyderms Sound Pretty Neat",
		["One More Demon to Slay"] = "Sure! I'll be wearing its guts like a wreath!",
	}
	script.ensure_buffs { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }
	script.heal_up()
	script.ensure_mp(100)
	result, resulturl, advagain = autoadventure {
		zoneid = zoneid,
		macro = macro_dis(whichskill),
		noncombatchoices = noncombatchoices,
	}
end

local folios_used = 0

local dis_href = add_automation_script("automate-suburbandis", function()
	if autoattack_is_set() then
		stop "Disable your autoattack. The Dis script will handle (most) combats automatically."
	end
	script = get_automation_scripts()
	maybe_pull_item("ring of conflict", 1)
	maybe_pull_item("sea salt scrubs")
	maybe_pull_item("Space Trip safety headphones")
	maybe_pull_item("clumsiness bark", 20)
	maybe_pull_item("jar full of wind", 20)
	maybe_pull_item("dangerous jerkcicle", 40)
	script.want_familiar "fairy"
	equip_item("sea salt scrubs", "shirt")
	equip_item("ring of conflict", "acc1")
	equip_item("Space Trip safety headphones", "acc2")
	local function run_turns()
		advagain = false
		if advs() == 0 then
			stop "Out of adventures."
		end
		if not have_buff("Dis Abled") then
			if folios_used < 2 then
				folios_used = folios_used + 1
				maybe_pull_item("devilish folio")
				use_item("devilish folio")
			end
			if not have_buff("Dis Abled") then
				stop "Use another devilish folio."
			end
		end
		if not have_item("vanity stone") or not have_item("furious stone") then
			-- grove: 277
			automate_dis_zone(277, "Torment Plant")
		elseif not have_item("lecherous stone") or not have_item("jealousy stone") then
			-- maelstrom: 278
			automate_dis_zone(278, "Pinch Ghost")
		elseif not have_item("avarice stone") or not have_item("gluttonous stone") then
			-- glacier: 279
			automate_dis_zone(279, "Tattle")
		else
			script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }
			script.heal_up()
			script.ensure_mp(100)
			local pt, url = post_page("/suburbandis.php", { pwd = session.pwd, action = "dothis" })
			result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_dis)
			return result, resulturl
		end
		if advagain then
			return run_turns()
		else
			return result, resulturl
		end
	end
	return run_turns()
end)

add_printer("/suburbandis.php", function()
	if not setting_enabled("enable turnplaying automation") or not ascensionstatus("Aftercore") then return end
	text = text:gsub([[(</table></center>)(</body>)]], [[%1<center><a href="]]..dis_href { pwd = session.pwd }..[[" style="color: green">{ Automate Dis }</a></center>%2]])
end)
