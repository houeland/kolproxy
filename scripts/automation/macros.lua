function COMMON_MACROSTUFF_START(rounds, hplevel) 
	local lobsterwarning = ""
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

-- if monstername procrastination
--   abort procrastination
-- endif

-- if monstername lobsterfrogman
--   abort lobsterfrogman
-- endif

COMMON_MACROSTUFF_FLYERS = [[


if hascombatitem rock band flyers
  if hasskill Entangling Noodles
    cast Entangling Noodles
  endif
  if (hasskill Broadside) && (!hascombatitem Rain-Doh blue balls)
    cast Broadside
  endif
  use rock band flyers
endif

]]

function attack_action()
	return [[

    attack

]]
end

function cannon_action()
	return [[

    cast Cannelloni Cannon

]]
end

function elemental_damage_action()
	return [[

    cast Cannelloni Cannon

]]
end

function serpent_action()
	return [[

    cast Stringozzi Serpent

]]
end

function geyser_action()
	return [[

    cast Saucegeyser

]]
end

function shieldbutt_action()
	return [[

    cast Shieldbutt

]]
end

function noodles_action()
	return [[

  if hasskill Entangling Noodles
    cast Entangling Noodles
  endif

]]
end


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
  cast Cannelloni Cannon
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
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[

pickpocket

]] .. COMMON_MACROSTUFF_FLYERS .. [[

if hasskill Static Shock
  cast Static Shock
endif

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

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

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
  if have_equipped("Greatest American Pants") and macro_runawayfrom_monsters and macro_runawayfrom_monsters ~= "none" and get_daily_counter("item.fly away.free runaways") < 9 then
	maybe_runaway = [[

if hascombatitem rock band flyers
  if hasskill Entangling Noodles
    cast Entangling Noodles
  endif
  use rock band flyers
endif

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

  runaway
endif

abort Expected to run away!

]]
  end

  return [[

if hascombatitem Rain-Doh indigo cup
  use Rain-Doh indigo cup
endif

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_runaway .. [[

if hascombatitem Rain-Doh blue balls
  use Rain-Doh blue balls
endif

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]] .. (extrastuff or "") .. [[

if (monstername tetchy pirate) || (monstername toothy pirate) || (monstername tipsy pirate)
  use The Big Book of Pirate Insults
endif

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
  if not have_intrinsic("Gaze of the Volcano God") and have_equipped("Juju Mojo Mask") and (challenge == "boris" or challenge == "zombie") then
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

-- 
  local maybe_runaway = [[

]]
  if have_equipped("Greatest American Pants") and macro_runawayfrom_monsters and macro_runawayfrom_monsters ~= "none" and get_daily_counter("item.fly away.free runaways") < 9 then
	maybe_runaway = [[

if hascombatitem rock band flyers
  if hasskill Entangling Noodles
    cast Entangling Noodles
  endif
  use rock band flyers
endif

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

  runaway
endif

abort Expected to run away!

]]
  end

  return [[

]] .. set_gaze .. [[

if hascombatitem Rain-Doh indigo cup
  use Rain-Doh indigo cup
endif

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_runaway .. [[

if hascombatitem Rain-Doh blue balls
  use Rain-Doh blue balls
endif

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]] .. maybe_bellow .. [[

]] .. (extrastuff or "") .. [[

if monstername procrastination giant
  if hasskill banishing shout
    cast banishing shout
  endif
  while !times 5
]] .. maybe_belch .. [[
  endwhile
  abort no SC spell for procrastination giant
endif

if monstername animated nightstand
  while !times 7
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

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end

function macro_softcore_boris_crook()
  return [[
]] .. COMMON_MACROSTUFF_START(25, 35) .. [[

if hascombatitem Rain-Doh blue balls
  use Rain-Doh blue balls
  use Rain-Doh indigo cup
endif
if !hascombatitem Rain-Doh blue balls
  cast Broadside
endif

]] .. COMMON_MACROSTUFF_FLYERS .. [[

cast Intimidating Bellow

while (!match the crook brook) && (!match You acquire)
  use peppermint crook
endwhile

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

  if not have("668 scroll") and count("334 scroll") >= 2 then
    maybeuse334s = [[

  use 334 scroll
  use 334 scroll

]]
  end

  return [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

]] .. COMMON_MACROSTUFF_FLYERS .. [[

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

pickpocket

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

sub kill_cannon

]]..conditional_salve_action()..[[

  while !times 5
]] .. cannon_action() .. [[
  endwhile
endsub

sub kill_serpent

]]..conditional_salve_action()..[[

  while !times 3
]] .. serpent_action() .. [[
  endwhile
endsub

if monstername angry bassist
  call kill_cannon
endif

if monstername blue-haired girl
  call kill_cannon
endif

if monstername evil ex-girlfriend
  call kill_cannon
endif

if monstername peeved roommate
  call kill_cannon
endif

if monstername random scenester
  call kill_cannon
endif

if monstername drunken rat king
  call kill_serpent
endif

if monstername modern zmobie
  call kill_cannon
endif

if monstername conjoined zmombie
  call kill_cannon
endif

mark start_loop
while mppercentbelow 90
  call wait_and_stall
endwhile

]]..conditional_salve_action()..[[

if monstername chalkdust wraith
  cast Cannelloni Cannon
endif

if !monstername chalkdust wraith
  attack
endif

goto start_loop

]]
end

function macro_hardcore_boris(extrastuff)
  local maybe_bellow = [[

]]
  local maybe_belch = [[

]]
  local maybe_zombify = [[

]]
  local maybe_broadside = [[

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
  if level() >= 11 then
    maybe_broadside = [[

if hasskill Broadside
  cast Broadside
endif

]]
  end
  if get_daily_counter("zombie.bear arm Bear Hugs used") < 10 then
    maybe_zombify = [[

if hasskill Bear Hug
  cast Bear Hug
endif

]]
  end
  return [[

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_broadside .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]] .. maybe_bellow .. [[

]] .. (extrastuff or "") .. [[

if monstername procrastination giant
  if hasskill banishing shout
    cast banishing shout
  endif
  while !times 5
]] .. maybe_belch .. [[
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

if (monstername chalkdust wraith)
  if hasskill Kodiak Moment
    cast Kodiak Moment
  endif
  if hasskill Bilious Burst
    cast Bilious Burst
  endif
  cast Heroic Belch
endif

]] .. boris_action() .. [[

while !times 5
]] .. boris_cleave_action() .. [[
endwhile

]]
end

function make_cannonsniff_macro(name)
	local castolfaction = "cast Transcendent Olfaction"
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

if monstername ]] .. name .. [[


]] .. castolfaction .. [[


endif

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

while !times 3
]] .. cannon_action() .. [[
endwhile

]]..conditional_salve_action()..[[

while !times 2
]] .. cannon_action() .. [[
endwhile

]]
end

function macro_8bit_realm()
	local castolfaction = "cast Transcendent Olfaction"
	return [[
]] .. COMMON_MACROSTUFF_START(25, 30) .. [[

if monstername Blooper


]] .. castolfaction .. [[


endif

]]..conditional_salve_action()..[[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

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

]] .. noodles_action() .. [[

  call do_yellowray
  goto m_done
endif

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

while !times 3
]] .. cannon_action() .. [[
endwhile

mark m_done

]]
end

function macro_noodlecannon()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

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

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

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

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

while !times 5
]] .. cannon_action() .. [[
endwhile

]]
end

function macro_noodlegeyser(maxtimes)
	return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

while !times ]] .. maxtimes .. [[

]] .. geyser_action() .. [[

endwhile

]]
end

function macro_barrr()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. noodles_action() .. [[

use The Big Book of Pirate Insults

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

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

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

while !times 5
]] .. geyser_action() .. [[
endwhile

]]
end

function macro_hiddencity()
	local spheres = ascension["zone.hiddencity.sphere"] or {}
	local sphere_types = { "cracked", "mossy", "rough", "smooth" }
	local identify_macro = ""
	for x in table.values(sphere_types) do
		if have(x .. " stone sphere") then
			local known = false
			for y in table.values(spheres) do
				if y == x then
					known = true
				end
			end
			if not known then
				identify_macro = "use " .. x .. " stone sphere"
			end
		end
	end
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. noodles_action() .. [[

]] .. identify_macro .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

if hasskill Intimidating Bellow
  cast Intimidating Bellow
endif

if monstername protector
  while !times 5
]] .. elemental_damage_action() .. [[
  endwhile
endif

while !times 5
]] .. cannon_action() .. [[
endwhile

mark m_done

]]
end

function make_gremlin_macro(name, wrongmsg)
	return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

sub stall
]]..conditional_salve_action("goto do_return")..[[
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
    use rock band flyers, molybdenum magnet
	abort should be dead
  endif
  if match "]] .. wrongmsg .. [["
    goto done_loop
  endif
  call stall
  goto wait_loop
  mark done_loop
endif

]] .. noodles_action() .. [[

if hascombatitem rock band flyers
  use rock band flyers
endif

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end

function macro_bossbat()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

if monstername bodyguard
  pickpocket
]] .. noodles_action() .. [[

  if hasskill Static Shock
    cast Static Shock
  endif

]]..conditional_salve_action()..[[

  while !times 10
]] .. attack_action() .. [[
  endwhile
  goto m_done
endif

if hasskill Entangling Noodles
  cast Entangling Noodles
endif

]] .. COMMON_MACROSTUFF_FLYERS .. [[

]]..conditional_salve_action()..[[

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
	local castolfaction = "cast Transcendent Olfaction"
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

  if not have("668 scroll") and count("334 scroll") >= 2 then
    maybeuse334s = multiuse("334 scroll", "334 scroll")
  end

  local maybetrail = ""

  if false then
    maybetrail = [[

if monstername xxx pr0n


]] .. castolfaction .. [[


endif


]]

  end

  return [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

]] .. noodles_action() .. [[

]] .. COMMON_MACROSTUFF_FLYERS .. [[

if monstername rampaging adding machine

]] .. maybeuse334s .. [[

  if (hascombatitem 30669 scroll) && (hascombatitem 33398 scroll)
]] .. multiuse("30669 scroll", "33398 scroll") .. [[

  endif

  if (hascombatitem 668 scroll) && (hascombatitem 64067 scroll)
]] .. multiuse("668 scroll", "64067 scroll") .. [[

  endif
endif

]]..conditional_salve_action()..[[

while !times 3
]] .. serpent_action() .. [[
endwhile

]]
end
