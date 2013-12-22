function COMMON_MACROSTUFF_START(rounds, hplevel) 
	local lobsterwarning = ""
	if session["__script.cannot restore HP"] then
		hplevel = 0
	end
	if level() < 10 then
		lobsterwarning = [[

if monstername lobsterfrogman
  abort LFM
endif


]]
	end
	return [[


abort pastround ]] .. rounds .. [[

abort hppercentbelow ]] .. hplevel .. [[

scrollwhendone

if monstername rampaging adding machine
  abort Adding machine
endif

]] .. lobsterwarning .. [[

if monstername clingy pirate
  if hascombatitem cocktail napkin
    use cocktail napkin
  endif
endif


]]
end

function attack_action()
	return [[

    attack

]]
end

function cast_olfaction()
	return [[

if hasskill Transcendent Olfaction
  cast Transcendent Olfaction
endif

]]
end

function maybe_macro_cast_skill(names)
	if type(names) == "string" then
		names = { names }
	end
	for _, x in ipairs(names) do
		if have_skill(x) then
			return [[


	cast ]] .. x .. [[



]]
		end
	end
end

function macro_cast_skill(names)
	local command = maybe_macro_cast_skill(names)
	if command then return command end
	print("WARNING: No skills found: ", tostring(names))
	return [[

abort No useful skill found.

]]
end

function cannon_action()
	if have_skill("Crab Claw Technique") and have_equipped_item("Rock and Roll Legend") and not maybe_macro_cast_skill { "Cannelloni Cannon", "Saucestorm" } then
		return attack_action()
	end
	return macro_cast_skill { "Cannelloni Cannon", "Saucestorm", "Bawdy Refrain" }
end

function elemental_damage_action()
	return macro_cast_skill { "Cannelloni Cannon", "Saucestorm", "Bawdy Refrain" }
end

function serpent_action()
	return macro_cast_skill { "Stringozzi Serpent", "Saucegeyser", "Weapon of the Pastalord", "Saucestorm", "Cannelloni Cannon", "Cone of Zydeco" }
end

function geyser_action()
	return macro_cast_skill { "Saucegeyser", "Weapon of the Pastalord" }
end

function shieldbutt_action()
	return macro_cast_skill { "Shieldbutt", "Cannelloni Cannon", "Saucestorm" }
end

function maybe_stun_monster(is_dangerous)
	local want_stun = true
	if is_dangerous == false and not have_item("rock band flyers") then
		want_stun = false
	end
	local can_stun = true
	local can_stagger = true
	local mname = fight["currently fighting"] and fight["currently fighting"].name
	local cfm = getCurrentFightMonster()
	if mname == "oil tycoon" then
		can_stun = false
	end
	local macrolines = {}
	table.insert(macrolines, "")
	if want_stun and can_stun then
		if have_item("Rain-Doh blue balls") then
			if have_skill("Ambidextrous Funkslinging") then
				table.insert(macrolines, [[use Rain-Doh blue balls, Rain-Doh indigo cup]])
			else
				table.insert(macrolines, [[
					use Rain-Doh blue balls
					use Rain-Doh indigo cup]])
			end
		else
			table.insert(macrolines, [[
				if hasskill Broadside
					cast Broadside
				endif
				if hasskill Blend
					cast Blend
				endif]])
		end
		if playerclass("Turtle Tamer") then
			table.insert(macrolines, [[
				if hasskill Shell Up
					cast Shell Up
				endif]])
		end
		if playerclass("Pastamancer") then
			table.insert(macrolines, [[
				if hasskill Entangling Noodles
					cast Entangling Noodles
				endif]])
		end
		if playerclass("Sauceror") and (is_dangerous or level() >= 10) then
			table.insert(macrolines, [[
				if hasskill Soul Bubble
					cast Soul Bubble
				endif]])
		end
		if playerclass("Accordion Thief") then
			table.insert(macrolines, [[
				if hasskill Accordion Bash
					cast Accordion Bash
				endif]])
			if have_equipped_item("Rock and Roll Legend") or have_equipped_item("peace accordion") then
				table.insert(macrolines, [[
					if hasskill Cadenza
						cast Cadenza
					endif]])
			end
		end
	end

	if can_stagger then
		if playerclass("Sauceror") and have_skill("Itchy Curse Finger") then
			table.insert(macrolines, [[
				if hasskill Curse of Weaksauce
					cast Curse of Weaksauce
				endif]])
		end
	end

	table.insert(macrolines, [[
		if hasskill Steal Accordion
			cast Steal Accordion
		endif
		if hascombatitem rock band flyers
			use rock band flyers
		endif]])

	table.insert(macrolines, "")

	return table.concat(macrolines, "\n\n")
end

function macro_killing_begins()
-- use Cadenza?
	return ""
end

noodles_action = maybe_stun_monster

function conditional_salve_action(extra)
	return [[

if hppercentbelow 75
  cast Saucy Salve

]] .. (extra or "") .. [[

endif
]]
end

function stasis_action()
	if classid() == 5 then
		return [[

  cast Suckerpunch

]]
	elseif challenge == "fist" then
		return [[

  cast Sing

]]
	else
		return [[

  use seal tooth

]]
	end
end

-- TODO: hacked in suckerpunch/sing, fix
function stall_action()
	return conditional_salve_action("goto stall_do_return") .. [[
  if hasskill Static Shock
	cast Static Shock
	goto stall_do_return
  endif
  if hascombatitem seal tooth
	use seal tooth
	goto stall_do_return
  endif
  if hascombatitem spices
	use spices
	goto stall_do_return
  endif
  if hasskill suckerpunch
    cast suckerpunch
	goto stall_do_return
  endif
  cast sing
  mark stall_do_return

]]
end

function fist_action()
  return [[

if (monstername ghuol whelp || monstername chalkdust wraith || monstername ghost)

]] .. elemental_damage_action() .. [[

endif

if !(monstername ghuol whelp || monstername chalkdust wraith) && hasskill Drunken Baby Style
  cast Drunken Baby Style
endif

if !(monstername ghuol whelp || monstername chalkdust wraith) && !hasskill Drunken Baby Style
  cast Flying Fire Fist
endif

]]
end

function boris_action()
  return [[

if hasskill Throw Shield
  cast Throw Shield
endif

cast Mighty Axing

]]
end

function boris_cleave_action()
  return [[

if hasskill Throw Shield
  cast Throw Shield
endif

  if hasskill Cleave
    cast Cleave
  endif
  if !hasskill Cleave
]] .. boris_action() .. [[
  endif

]]
end

function macro_autoattack()
	return [[
]] .. COMMON_MACROSTUFF_START(25, 50) .. [[

pickpocket

]] .. maybe_stun_monster(false) .. [[

if hasskill Static Shock
  cast Static Shock
endif

]] .. macro_killing_begins() .. [[

]]..conditional_salve_action()..[[

while !times 15
]] .. attack_action() .. [[
endwhile

while !times 5
]] .. cannon_action() .. [[
endwhile

]]
end

function macro_fist()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]]..conditional_salve_action()..[[

while !times 5
]]..fist_action()..[[
  mark w_done
endwhile

]]
end

function macro_softcore(extrastuff)
  -- TODO: set correct gaze
  local maybe_runaway = [[

]]
  if have_equipped_item("Greatest American Pants") and macro_runawayfrom_monsters and macro_runawayfrom_monsters ~= "none" and get_daily_counter("item.fly away.free runaways") < 9 then
	maybe_runaway = [[

]] .. maybe_stun_monster() .. [[

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

  runaway
endif

abort Expected to run away!

]]
  end

  return [[

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_runaway .. [[

]] .. maybe_stun_monster() .. [[

]] .. (extrastuff or "") .. [[

if (monstername tetchy pirate) || (monstername toothy pirate) || (monstername tipsy pirate)
  use The Big Book of Pirate Insults
endif

]] .. macro_killing_begins() .. [[

]] .. serpent_action() .. [[

]]
end

function set_gaze_action()
  if challenge == "zombie" then
    return [[

cast Infectious Bite
if hasskill Devour Minions
  cast Devour Minions
endif

]]
  end
  return boris_action()
end

function macro_softcore_boris(extrastuff)
  local set_gaze = ""
  if not have_intrinsic("Gaze of the Volcano God") and have_equipped_item("Juju Mojo Mask") and (challenge == "boris" or challenge == "zombie") then
    if have_intrinsic("Gaze of the Trickster God") or have_intrinsic("Gaze of the Lightning God") then
      stop("TODO: Somehow have the wrong gaze on!")
    end
    set_gaze = [[

]] .. COMMON_MACROSTUFF_START(20, 25) .. [[

if hasskill Intimidating Bellow
  cast Intimidating Bellow
endif

if !hasskill Intimidating Bellow
]] .. set_gaze_action() .. [[
endif

]]
  end
  local maybe_bellow = [[

]]
  if mp() >= 20 and have_skill("Louder Bellows") then
    maybe_bellow = [[

if hasskill Intimidating Bellow
  cast Intimidating Bellow
endif

]]
  end

  local maybe_belch = [[

]]
  if fullness() >= 15 then
	maybe_belch = [[

if hasskill Heroic Belch
  cast Heroic Belch
endif

]]
  end

  local maybe_runaway = [[

]]
  if have_equipped_item("Greatest American Pants") and macro_runawayfrom_monsters and macro_runawayfrom_monsters ~= "none" and get_daily_counter("item.fly away.free runaways") < 9 then
	maybe_runaway = [[

]] .. maybe_stun_monster() .. [[

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

  runaway
endif

abort Expected to run away!

]]
  end

  return [[

]] .. set_gaze .. [[

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_runaway .. [[

]] .. maybe_stun_monster() .. [[

]] .. maybe_bellow .. [[

]] .. (extrastuff or "") .. [[

if monstername procrastination giant
  if hasskill banishing shout
    cast banishing shout
  endif
  while !times 5
]] .. maybe_belch .. [[

    if hasskill Boil
      cast Boil
    endif
  endwhile
  abort no SC spell for procrastination giant
endif

if monstername animated nightstand
  while !times 7
    if hasskill Slice
      cast Slice
    endif
    use orange agent
  endwhile
endif

if (monstername tetchy pirate) || (monstername toothy pirate) || (monstername tipsy pirate)
  use The Big Book of Pirate Insults
  while !times 3
]] .. boris_cleave_action() .. [[
  endwhile
endif

if (monstername senile lihc) || (monstername slick lihc) || (monstername drunk goat) || (monstername sabre-toothed goat) || (monstername chatty pirate) || (monstername clingy pirate) || (monstername crusty pirate) || (monstername 7-foot dwarf) || (monstername 7-foot dwarf captain)
  if hasskill banishing shout
    cast banishing shout
  endif
endif

]] .. boris_action() .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end

function macro_softcore_boris_crook()
  return [[
]] .. COMMON_MACROSTUFF_START(25, 35) .. [[

]] .. maybe_stun_monster() .. [[

cast Intimidating Bellow

while (!match the crook brook) && (!match You acquire)
  use peppermint crook
endwhile

]] .. macro_killing_begins() .. [[

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end

function macro_softcore_boris_bonerdagon()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

while !times 10
  attack
endwhile

]]
end

function macro_softcore_boris_gremlin(name, wrongmsg)
	local stasis_action = "use seal tooth"
	if not have_item("seal tooth") then
		stasis_action = "use spectre scepter"
	end
	return [[
]] .. COMMON_MACROSTUFF_START(25, 40) .. [[

if hascombatitem Rain-Doh blue balls
  use Rain-Doh blue balls
  use Rain-Doh indigo cup
endif
if !hascombatitem Rain-Doh blue balls
  if hasskill Broadside
    cast Broadside
  endif
endif

if hascombatitem rock band flyers
  use rock band flyers
endif

if monstername ]] .. name .. [[

  if hasskill Intimidating Bellow
    cast Intimidating Bellow
  endif

  mark wait_loop
  if match "whips out a"
    use molybdenum magnet
	abort Gremlin should be dead now!
  endif
  if match "]] .. wrongmsg .. [["

    goto done_loop
  endif

]] .. stasis_action .. [[

  goto wait_loop

  mark done_loop
endif

if hasskill banishing shout
  cast banishing shout
endif

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end


function macro_softcore_boris_orc_chasm()
  local maybeuse334s = ""

  if not have_item("668 scroll") and count_item("334 scroll") >= 2 then
    maybeuse334s = [[

  use 334 scroll
  use 334 scroll

]]
  end

  return [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

]] .. maybe_stun_monster() .. [[

if monstername rampaging adding machine

]] .. maybeuse334s .. [[

  if (hascombatitem 30669 scroll) && (hascombatitem 33398 scroll)
    use 30669 scroll
    use 33398 scroll
  endif
  if (hascombatitem 668 scroll) && (hascombatitem 64067 scroll)
    use 668 scroll
    use 64067 scroll
  endif
endif

if (monstername flaming troll) || (monstername Spam Witch) || (monstername 1335 HaX0r)
  cast Banishing Shout
endif

]] .. macro_killing_begins() .. [[

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end


function macro_stasis()
	return [[
]] .. COMMON_MACROSTUFF_START(25, 30) .. [[

sub wait_and_stall
  if pastround 20
]] .. cannon_action() .. [[
    goto do_return
  endif

]]..conditional_salve_action("goto do_return")..[[

  if hasskill Static Shock
    cast Static Shock
    goto do_return
  endif

]] .. stasis_action() .. [[

  mark do_return
endsub


sub kill_cannon

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]]..conditional_salve_action()..[[

  while !times 5
]] .. cannon_action() .. [[
  endwhile
  abort Should be dead!
endsub

sub kill_serpent

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]]..conditional_salve_action()..[[

  while !times 3
]] .. serpent_action() .. [[
  endwhile
  abort Should be dead!
endsub

if (monstername angry bassist) || (monstername blue-haired girl) || (monstername evil ex-girlfriend) || (monstername peeved roommate) || (monstername random scenester)
  call kill_cannon
endif

if monstername drunken rat king
  call kill_serpent
endif

if (monstername modern zmobie) || (monstername conjoined zmombie)
  call kill_cannon
endif

pickpocket

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

mark start_loop
while mppercentbelow 90
  call wait_and_stall
endwhile

]]..conditional_salve_action()..[[

if monstername chalkdust wraith

]] .. elemental_damage_action() .. [[

endif

if !monstername chalkdust wraith
  attack
endif

goto start_loop

]]
end

function macro_hardcore_boris(extrastuff)
  local hplevel = 35
  if challenge == "jarlsberg" then
    hplevel = 10
  end
  local maybe_bellow = [[

]]
  local maybe_belch = [[

]]
  local maybe_zombify = [[

]]
  if mp() >= 20 and have_skill("Louder Bellows") then
    maybe_bellow = [[

if hasskill Intimidating Bellow
  cast Intimidating Bellow
endif

]]
    if fullness() >= 15 then
	  maybe_belch = [[

if hasskill Heroic Belch
  cast Heroic Belch
endif

]]
    end
  end
  if get_daily_counter("zombie.bear arm Bear Hugs used") < 10 then
    maybe_zombify = [[

if hasskill Bear Hug
  cast Bear Hug
endif

]]
  end
  return [[

]] .. COMMON_MACROSTUFF_START(20, hplevel) .. [[

]] .. maybe_stun_monster() .. [[

]] .. maybe_bellow .. [[

]] .. (extrastuff or "") .. [[

if monstername procrastination giant
  if hasskill banishing shout
    cast banishing shout
  endif
  while !times 5
]] .. maybe_belch .. [[
    if hasskill Slice
      cast Slice
    endif
    if hasskill Fry
      cast Fry
    endif
    if hasskill Grill
      cast Grill
    endif
    if hasskill Boil
      cast Boil
    endif
  endwhile
]] .. maybe_zombify .. [[
  abort no HC spell for procrastination giant
endif

if monstername animated nightstand
  while !times 5
]] .. maybe_belch .. [[
  endwhile
]] .. maybe_zombify .. [[
endif

if (monstername tetchy pirate) || (monstername toothy pirate) || (monstername tipsy pirate)
  if hasskill Broadside
	cast Broadside
  endif
  use The Big Book of Pirate Insults
  while !times 3
]] .. boris_cleave_action() .. [[
  endwhile
endif

if (monstername senile lihc) || (monstername slick lihc)
  if hasskill banishing shout
    cast banishing shout
  endif
endif

]] .. macro_killing_begins() .. [[

if (monstername chalkdust wraith) || (monstername Ghost)
  if hasskill Kodiak Moment
    cast Kodiak Moment
  endif
  if hasskill Bilious Burst
    cast Bilious Burst
  endif
  if hasskill Curdle
    cast Curdle
  endif
  cast Heroic Belch
endif

]] .. boris_action() .. [[

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end

function make_sniff_macro(name, action)
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

if monstername ]] .. name .. [[

]] .. cast_olfaction() .. [[

endif

]] .. macro_killing_begins() .. [[

]]..conditional_salve_action()..[[

while !times 3
]] .. action() .. [[
endwhile

]]..conditional_salve_action()..[[

while !times 2
]] .. action() .. [[
endwhile

]]
end

function make_cannonsniff_macro(name)
	local cfm = getCurrentFightMonster()
	--print("DEBUG: making cannonsniff macro for", name, "vs", cfm)
	local physresist = 0
	local cfmhp = 10
	local elem = nil
	if cfm and cfm.Stats and cfm.Stats.Phys then
		physresist = tonumber(cfm.Stats.Phys)
	end
	if cfm and cfm.Stats and cfm.Stats.HP then
		cfmhp = tonumber(cfm.Stats.HP)
	end
	if cfm and cfm.Stats and cfm.Stats.Element then
		elem = cfm.Stats.Element
	end
	if physresist == 0 and cfmhp >= 100 and not elem then
		return make_sniff_macro(name, serpent_action)
	else
		return make_sniff_macro(name, cannon_action)
	end
end

function macro_romanticarrow()
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

cast romantic arrow

if (match "too stunned by your beauty")

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

cast poison arrow

cast fingertrap arrow

cast poison arrow

cast fingertrap arrow

cast poison arrow

cast fingertrap arrow

cast glove arrow

while !times 5
]] .. serpent_action() .. [[
endwhile

endif

]]
end

function macro_8bit_realm()
	return [[
]] .. COMMON_MACROSTUFF_START(25, 30) .. [[

if monstername Blooper


]] .. cast_olfaction() .. [[


endif

]]..conditional_salve_action()..[[

]] .. maybe_stun_monster(false) .. [[

]] .. macro_killing_begins() .. [[

while !times 20

]] .. stasis_action() .. [[

endwhile

while !times 3
]] .. cannon_action() .. [[
endwhile

]]
end

function make_yellowray_macro(name)
	return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[
sub stall
]] .. stall_action() .. [[
endsub

sub do_yellowray
  if hascombatitem unbearable light
    use unbearable light
  endif
  while !times 15
	if match "yellow eye"
	  cast Point at your opponent
	  goto yellowray_done
	endif
	call stall
  endwhile
  mark yellowray_done
endsub

if monstername ]] .. name .. [[

]] .. maybe_stun_monster() .. [[

  call do_yellowray
  goto m_done
endif

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

while !times 3
]] .. cannon_action() .. [[
endwhile

mark m_done

]]
end

function macro_noodlecannon()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

]] .. conditional_salve_action() .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. cannon_action() .. [[
endwhile

if monstername mobile armored sweat lodge
  while !times 5
]] .. cannon_action() .. [[
  endwhile
endif

]]
end

function macro_noodleserpent()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end

function macro_ppnoodlecannon()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[
pickpocket

if hasskill Smash & Graaagh
  cast Smash & Graaagh
endif

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

while !times 5
]] .. cannon_action() .. [[
endwhile

]]
end

function macro_noodlegeyser(maxtimes)
	return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[

]] .. maybe_stun_monster(true) .. [[

]] .. macro_killing_begins() .. [[

while !times ]] .. maxtimes .. [[

]] .. geyser_action() .. [[

endwhile

]]
end

function macro_barrr()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

use The Big Book of Pirate Insults

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

while !times 3
]] .. cannon_action() .. [[
endwhile

while !times 3
]] .. serpent_action() .. [[
endwhile

]]
end

function macro_spookyraven() 
  return [[
]]..COMMON_MACROSTUFF_START(20, 5) .. [[

]] .. maybe_stun_monster(true) .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. geyser_action() .. [[
endwhile

]]
end

function macro_hiddencity()
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

if hasskill Intimidating Bellow
  cast Intimidating Bellow
endif

if monstername protector
  while !times 5
]] .. elemental_damage_action() .. [[
  endwhile
endif

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end

function make_gremlin_macro(name, wrongmsg)
	local maybeheal = ""
	if not have_skill("Tao of the Terrapin") then
		maybeheal = [[
  if (!hppercentbelow 90) && (hasskill Tattle) && (!mpbelow 25)
    cast Tattle
    goto do_return
  endif
  if hasskill Saucy Salve
	cast Saucy Salve
	goto do_return
  endif
  if hasskill Lasagna Bandages
	cast Lasagna Bandages
	goto do_return
  endif
]]
	end
	local use_magnet = [[use molybdenum magnet]]
	if have_skill("Ambidextrous Funkslinging") then
		use_magnet = [[use rock band flyers, molybdenum magnet]]
	end
	return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

sub stall
]]..conditional_salve_action("goto do_return")..[[

]]..maybeheal..[[

  if hasskill Static Shock
	cast Static Shock
	goto do_return
  endif
  if hascombatitem seal tooth
	use seal tooth
	goto do_return
  endif
  if hascombatitem spices
	use spices
	goto do_return
  endif
  if hasskill suckerpunch
    cast suckerpunch
	goto do_return
  endif
  cast sing
  mark do_return
endsub

if monstername ]] .. name .. [[

  mark wait_loop
  if match "whips out a"

]] .. use_magnet .. [[

	abort should be dead
  endif
  if match "]] .. wrongmsg .. [["
    goto done_loop
  endif
  call stall
  goto wait_loop
  mark done_loop
endif

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end

function macro_bossbat()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

while !times 3
]] .. cannon_action() .. [[
endwhile

mark m_done

]]
end

function macro_spooky_forest_runaway()
  return [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

if monstername bar
  runaway
endif

if monstername spooky mummy
  runaway
endif

if monstername spooky vampire
  runaway
endif

if monstername triffid
  runaway
endif

if monstername warwelf
  runaway
endif

if monstername wolfman
  runaway
endif

]]
end

function macro_orc_chasm()
  local maybeuse334s = ""
  local function multiuse(item1, item2)
    if have_skill("Ambidextrous Funkslinging") then
      return [[

  use ]]..item1..[[, ]]..item2..[[

]]
    else
      return [[

  use ]]..item1..[[

  use ]]..item2..[[

]]
    end
  end

  if not have_item("668 scroll") and count_item("334 scroll") >= 2 then
    maybeuse334s = multiuse("334 scroll", "334 scroll")
  end

  local maybetrail = ""

  if false then
    maybetrail = [[

if monstername xxx pr0n


]] .. cast_olfaction() .. [[


endif


]]

  end

  return [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

]] .. maybe_stun_monster() .. [[

if monstername rampaging adding machine

]] .. maybeuse334s .. [[

  if (hascombatitem 30669 scroll) && (hascombatitem 33398 scroll)
]] .. multiuse("30669 scroll", "33398 scroll") .. [[

  endif

  if (hascombatitem 668 scroll) && (hascombatitem 64067 scroll)
]] .. multiuse("668 scroll", "64067 scroll") .. [[

  endif
endif

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

while !times 3
]] .. serpent_action() .. [[
endwhile

]]
end

function macro_softcore_lfm()
  local maybe_blackbox = [[

if monstername lobsterfrogman
  use Rain-Doh black box
endif

]]
  if count_item("barrel of gunpowder") >= 4 then
    maybe_blackbox = ""
  end
  return [[

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

]] .. maybe_blackbox .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end
