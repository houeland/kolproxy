function COMMON_MACROSTUFF_START(rounds, hplevel)
	local mname = fight["currently fighting"] and fight["currently fighting"].name or "?"
	if session["__script.cannot restore HP"] or ascensionpath("Actually Ed the Undying") then
		hplevel = 0
	elseif mname == "Green Ops Soldier" then
		hplevel = 10
	end
	local lobsterwarning = ""
	if level() < 10 then
		lobsterwarning = [[

if monstername lobsterfrogman
	abort LFM
endif

if monstername ninja snowman assassin
	abort assassin
endif

]]
	end
	local petemug = ""
	local banish = ""
	if ascensionpath("Avatar of Sneaky Pete") then
		if mname:match("^oil ") or mname:contains("nightstand") then
		elseif automation_sneaky_pete_want_hate() then
			petemug = [[

pickpocket

]]
		else
			petemug = [[

if hasskill Mug for the Audience
	cast Mug for the Audience
endif

]]
		end
		banish = pete_banish()
	end
	return [[


abort pastround ]] .. rounds .. [[

abort hppercentbelow ]] .. hplevel .. [[

scrollwhendone

]] .. lobsterwarning .. [[

if (monstername clingy pirate) && (hascombatitem cocktail napkin)
	use cocktail napkin
endif

]] .. petemug .. [[

if (monstername Racecar Bob) || (monstername Bob Racecar)
	if (hascombatitem disposable instant camera)
		use disposable instant camera
	endif
endif

]] .. banish

end

function attack_action()
	return [[

attack

]]
end

function cast_olfaction(name)
	if ascensionpath("Avatar of Sneaky Pete") and retrieve_pete_friend() == name then
		return ""
	end
	return [[

if (monstername ]] .. name .. [[)

	if hasskill Transcendent Olfaction
		cast Transcendent Olfaction
	endif

	if hasskill Make Friends
		cast Make Friends
	endif
endif

]]
end


-- Bottom two lists are for banishing two monsters in a zone
-- NB: in the palindome, give one monster to smoke grenade, the rest to walkaway, since it can't be used multiple times
-- NB: don't banish tomb servant, because we might need the tower item
function pete_banish()
	return [[
if (monstername animated mahogany nightstand) || (monstername Bullet Bill) || (monstername pygmy witch lawyer) || (monstername pygmy orderlies) || (monstername bookbat) || (monstername A.M.C. gremlin) || (monstername Box) || (monstername Trouser Snake) || (monstername tomb asp)
	if hasskill Walk Away From Explosion
		cast Walk Away From Explosion
	endif

	if (hascombatitem smoke grenade)
		use smoke grenade
	endif
endif

if (monstername senile lihc) || (monstername chatty pirate) || (monstername mad wino) || (monstername plaid ghost) || (monstername Evil Olive) || (monstername Taco Cat) || (monstername Flock of Stab-bats)
	if hasskill Walk Away From Explosion
		cast Walk Away From Explosion
	endif
endif

if (monstername slick lihc) || (monstername crusty pirate) || (monstername skeletal sommelier) || (monstername possessed laundry press) || (monstername Tan Gnat)
	if (hascombatitem smoke grenade)
		use smoke grenade
	endif
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

local function using_accordion()
	if not equipment().weapon then return false end
	local itemdata = maybe_get_itemdata(equipment().weapon)
	if not itemdata then return false end
	return itemdata.song_duration ~= nil
end

local function using_club()
	if not equipment().weapon then return false end
	local itemdata = maybe_get_itemdata(equipment().weapon)
	if not itemdata then return false end
	if not itemdata.weapon_type then return false end
	return itemdata.weapon_type:contains("club")
end

local function using_moxie_weapon()
	if not equipment().weapon then return false end
	local itemdata = maybe_get_itemdata(equipment().weapon)
	if not itemdata then return false end
	return itemdata.attack_state == "Moxie" or have_equipped_item("Frankly Mr. Shank")
end

local function using_muscle_weapon()
	if not equipment().weapon then return false end
	local itemdata = maybe_get_itemdata(equipment().weapon)
	if not itemdata then return false end
	return itemdata.attack_state ~= "Moxie"
end

function macro_sneaky_pete_action()
	local weapondata = equipment().weapon and maybe_get_itemdata(equipment().weapon)
	if weapondata and weapondata.attack_stat == "Muscle" then
		return [[

if (hasskill Smoke Break)
	cast Smoke Break
endif

if (hasskill Pop Wheelie)
	cast Pop Wheelie
endif

if (hasskill Flash Headlight)
	cast Flash Headlight
endif

if (!hasskill Pop Wheelie) && (!hasskill Flash Headlight)
	attack
endif

]]
	end
	local cfm = getCurrentFightMonster()
	if cfm and cfm.Stats and cfm.Stats.physicalresistpercent and tonumber(cfm.Stats.physicalresistpercent) and tonumber(cfm.Stats.physicalresistpercent) > 40 then
		return [[

if (hasskill Smoke Break)
	cast Smoke Break
endif

if (hasskill Flash Headlight)
	cast Flash Headlight
endif

]] .. attack_action()
	end
	if cfm and cfm.Stats and cfm.Stats.Atk and (cfm.Stats.Atk - buffedmoxie() >= 5 or (cfm.Stats.HP > 50 and cfm.Stats.Def - buffedmoxie() >= -20)) then
		return [[
if (hasskill Pop Wheelie)
	cast Pop Wheelie

]] .. attack_action() .. [[

endif

]] .. attack_action()
	end
	return attack_action()
end

local function can_kill_with_attack()
	return not have_buff("QWOPped Up")
end

local function can_easily_attack_with_weapon()
	if not can_kill_with_attack() then return false end
	local cfm = getCurrentFightMonster()
	if not (cfm and cfm.Stats and cfm.Stats.Atk) then return false end
	if cfm.Stats.physicalresistpercent and tonumber(cfm.Stats.physicalresistpercent) and tonumber(cfm.Stats.physicalresistpercent) > 40 then return false end
	if using_moxie_weapon() and buffedmoxie() - cfm.Stats.Atk >= 25 then
		print_ascensiondebug("easy moxie attack", buffedmoxie(), tojson(cfm.Stats))
		return true
	elseif using_muscle_weapon() and buffedmuscle() - cfm.Stats.Atk >= 25 and buffedmoxie() - cfm.Stats.Atk >= -25 then
		print_ascensiondebug("easy muscle attack", buffedmuscle(), tojson(cfm.Stats))
		return true
	else
		return false
	end
end

local function cannot_use_undying()
	return ascensionpath("Actually Ed the Undying") and times_used_undying() >= 2
end

function cannon_action()
	if can_kill_with_attack() and have_skill("Crab Claw Technique") and using_accordion() and not maybe_macro_cast_skill { "Cannelloni Cannon", "Saucestorm" } then
		return attack_action()
	elseif ascensionpath("Avatar of Sneaky Pete") then
		return macro_sneaky_pete_action()
	elseif mp() <= 20 and can_easily_attack_with_weapon() then
		return attack_action()
	end
	local cfm = getCurrentFightMonster()
	local elem = cfm and cfm.Stats and cfm.Stats.Element
	local tough_opponent = cfm and cfm.Stats and (tonumber(cfm.Stats.HP) or 0) >= 500
	local prefer_big_spell = tough_opponent or cannot_use_undying()
	if prefer_big_spell then
		local skill = maybe_macro_cast_skill {
			"Saucegeyser",
			elem ~= "Hot" and "Roar of the Lion" or "???",
		}
		if skill then return skill end
	end
	local good_skill = maybe_macro_cast_skill {
		(pastathrall() and have_equipped_item("Hand that Rocks the Ladle")) and "Utensil Twist" or "???",
		pastathrall() and "Cannelloni Cannon" or "???",
		"Saucestorm",
		"Cannelloni Cannon",
		fury() >= 1 and "Furious Wallop" or "???",
	}
	if good_skill then return good_skill end
	if can_easily_attack_with_weapon() then
		return attack_action()
	end
	return macro_cast_skill {
		"Bawdy Refrain",
		"Saucegeyser",
		"Kneebutt",
		"Toss",
		"Clobber",
		"Ravioli Shurikens",
		not cannot_use_undying() and "Fist of the Mummy" or "???",
		elem ~= "Hot" and "Roar of the Lion" or "???",
		elem ~= "Spooky" and "Howl of the Jackal" or "???",
		not cannot_use_undying() and "Mild Curse" or "???",
	}
end

function estimate_elemental_weapon_damage_sum()
	return estimate_bonus("Cold Damage") + estimate_bonus("Hot Damage") + estimate_bonus("Sleaze Damage") + estimate_bonus("Spooky Damage") + estimate_bonus("Stench Damage")
end

function elemental_damage_action()
	if have_skill("Smoke Break") then
		return [[

if (hasskill Smoke Break)
	cast Smoke Break
endif

]] .. attack_action()
	elseif ascensionpath("Avatar of Sneaky Pete") and estimate_elemental_weapon_damage_sum() >= 10 then
		return attack_action()
	end
	return macro_cast_skill { pastathrall() and "Cannelloni Cannon" or "???", "Saucestorm", "Cannelloni Cannon", "Bawdy Refrain", "Fist of the Mummy" }
end

function serpent_action()
	if ascensionpath("Avatar of Sneaky Pete") then
		return macro_sneaky_pete_action()
	end
	local skill_list = { "Stringozzi Serpent", "Saucegeyser", "Weapon of the Pastalord", "Saucestorm", "Cannelloni Cannon", "Cone of Zydeco", fury() >= 1 and "Furious Wallop" or "???", "Kneebutt" }
	if not maybe_macro_cast_skill(skill_list) and can_easily_attack_with_weapon() then
		return attack_action()
	end
	return maybe_macro_cast_skill(skill_list) or cannon_action()
end

function geyser_action()
	if ascensionpath("Avatar of Sneaky Pete") then
		local mname = fight["currently fighting"] and fight["currently fighting"].name or "?"
		if mname:contains("nightstand") and have_skill("Peel Out") and ascensionstatus("Hardcore") then
			if petelove() >= 20 and buffedmoxie() >= 100 and have_skill("Pop Wheelie") and have_skill("Snap Fingers") then
				return [[

cast Pop Wheelie
cast Pop Wheelie
cast Pop Wheelie
attack
attack
attack

]]
			else
				return [[

cast Peel Out

]]
			end
		end
		return macro_sneaky_pete_action()
	end
	return maybe_macro_cast_skill { "Saucegeyser", "Weapon of the Pastalord" } or serpent_action()
end

function shieldbutt_action()
	return macro_cast_skill { "Shieldbutt", "Cannelloni Cannon", "Saucestorm", fury() >= 1 and "Furious Wallop" or "???" }
end

function maybe_stun_monster(is_dangerous)
	local want_stun = true
	if ascensionpath("Avatar of Sneaky Pete") and automation_sneaky_pete_want_hate() then
	elseif is_dangerous == false and not have_item("rock band flyers") then
		want_stun = false
	end
	local can_stun = true
	local can_stagger = true
	local mname = fight["currently fighting"] and fight["currently fighting"].name or "?"
	local cfm = getCurrentFightMonster()
	if mname:match("^oil ") then
		can_stun = false
	end
	if cfm and cfm.Stats and cfm.Stats.staggerimmune then
		can_stun = false
		can_stagger = false
	end
	local macrolines = {}
	local function cast_if_haveskill(x) -- TODO: make a global function and use everywhere
		if have_skill(x) then
			table.insert(macrolines, "if (hasskill " .. x .. ")")
			table.insert(macrolines, "	cast " .. x)
			table.insert(macrolines, "endif")
		end
	end
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
			for _, x in ipairs { "Broadside", "Blend", "Snap Fingers" } do
				cast_if_haveskill(x)
			end
		end
		if ascensionpath("Avatar of Sneaky Pete") then
			if automation_sneaky_pete_want_hate() and have_skill("Jump Shark") then
				if have_item("Rain-Doh blue balls") or have_skill("Snap Fingers") or is_dangerous == false then
					cast_if_haveskill("Snap Fingers")
					cast_if_haveskill("Jump Shark")
				end
			elseif not automation_sneaky_pete_want_hate() and have_skill("Fix Jukebox") and petelove() < 20 then
				if have_item("Rain-Doh blue balls") or have_skill("Snap Fingers") or is_dangerous == false then
					cast_if_haveskill("Snap Fingers")
					cast_if_haveskill("Fix Jukebox")
				end
			end
		end
		if playerclass("Turtle Tamer") then
			cast_if_haveskill("Shell Up")
		end
		if playerclass("Pastamancer") then
			cast_if_haveskill("Entangling Noodles")
		end
		if playerclass("Sauceror") and (is_dangerous or level() >= 10) then
			table.insert(macrolines, [[
				if hasskill Soul Bubble
					cast Soul Bubble
				endif]])
		end
		if playerclass("Accordion Thief") then
			cast_if_haveskill("Accordion Bash")
			if have_equipped_item("Rock and Roll Legend") or have_equipped_item("peace accordion") then
				cast_if_haveskill("Cadenza")
			end
		end
	end

	if can_stagger then
		if playerclass("Sauceror") and have_skill("Itchy Curse Finger") then
			cast_if_haveskill("Curse of Weaksauce")
		end
		table.insert(macrolines, [[
			if hasskill Pocket Crumbs
				cast Pocket Crumbs
			endif]])
	end

	if playerclass("Accordion Thief") then
		table.insert(macrolines, [[
			if hasskill Steal Accordion
				cast Steal Accordion
			endif]])
	end

	if have_item("rock band flyers") then
		table.insert(macrolines, [[
			if hascombatitem rock band flyers
				use rock band flyers
			endif]])
	end

	local _tbl, unknown_potions, unknown_effects = get_dod_potion_status()
	for _, x in ipairs(unknown_effects) do
		if x == "booze" then
			for _, y in ipairs(unknown_potions) do
				if have_item(y) then
					table.insert(macrolines, "use " .. y)
					break
				end
			end
		end
	end

	table.insert(macrolines, macro_maybe_runaway())

	table.insert(macrolines, "")

	return table.concat(macrolines, "\n")
end

function macro_killing_begins()
-- use Cadenza?
	return ""
end

noodles_action = maybe_stun_monster

function conditional_salve_action(extra)
	if not have_skill("Saucy Salve") then
		return [[



]]
	else
		return [[

if hppercentbelow 75
	cast Saucy Salve

]] .. (extra or "") .. [[

endif
]]
	end
end

function stasis_action()
	if playerclass("Disco Bandit") then
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
	local macrolines = {}
	table.insert(macrolines, conditional_salve_action("goto stall_do_return"))
	if have_equipped_item("Pantsgiving") then
		table.insert(macrolines, "if (hasskill Pocket Crumbs)")
		table.insert(macrolines, "	cast Pocket Crumbs")
		table.insert(macrolines, "	goto stall_do_return")
		table.insert(macrolines, "endif")
	end
	if have_skill("Curse of Weaksauce") then
		table.insert(macrolines, "if (hasskill Curse of Weaksauce)")
		table.insert(macrolines, "	cast Curse of Weaksauce")
		table.insert(macrolines, "	goto stall_do_return")
		table.insert(macrolines, "endif")
	end
	if have_item("seal tooth") then
		table.insert(macrolines, "use seal tooth")
		table.insert(macrolines, "goto stall_do_return")
	elseif have_item("spices") then
		table.insert(macrolines, "use seal tooth")
		table.insert(macrolines, "goto stall_do_return")
	end
	if have_skill("Suckerpunch") then
		table.insert(macrolines, "if (hasskill Suckerpunch)")
		table.insert(macrolines, "	cast Suckerpunch")
		table.insert(macrolines, "	goto stall_do_return")
		table.insert(macrolines, "endif")
	end
	if have_skill("Sing") then
		table.insert(macrolines, "if (hasskill Sing)")
		table.insert(macrolines, "	cast Sing")
		table.insert(macrolines, "	goto stall_do_return")
		table.insert(macrolines, "endif")
	end
	if have_item("spectre scepter") then
		table.insert(macrolines, "use spectre scepter")
		table.insert(macrolines, "goto stall_do_return")
	end
	table.insert(macrolines, "abort Need stalling skill or item")
	table.insert(macrolines, "mark stall_do_return")
	return table.concat(macrolines, "\n")
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

function macro_autoattack(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
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

local macro_runawayfrom_monsters = nil
function set_macro_runawayfrom_monsters(tbl)
	macro_runawayfrom_monsters = tbl
end

function macro_maybe_runaway()
	if macro_runawayfrom_monsters then
		if have_equipped_item("Greatest American Pants") and get_daily_counter("item.fly away.free runaways") < 3 then
			return [[

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

	runaway
endif

]]
		elseif have_skill("Peel Out") and (get_remaining_peel_outs() or 0) >= 1 and mp() >= 15 then
			return [[

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

	if (hasskill Peel Out)
		cast Peel Out
	endif
endif

]]
		elseif have_equipped_item("Greatest American Pants") and get_daily_counter("item.fly away.free runaways") < 9 then
			return [[

if ]] .. "(monstername " .. table.concat(macro_runawayfrom_monsters, ") || (monstername ") .. ")" .. [[

	runaway
endif

]]
		end
	end
	return [[

]]
end

function macro_softcore(extrastuff)
	if extrastuff and extrastuff:contains("fight.php") then
		-- TODO: temporary workaround for macros getting the fight page as input now
		extrastuff = nil
	end
	-- TODO: set correct gaze
	return [[

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

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
	if extrastuff and extrastuff:contains("fight.php") then
		-- TODO: temporary workaround for macros getting the fight page as input now
		extrastuff = nil
	end
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

  return [[

]] .. set_gaze .. [[

]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

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


function macro_stasis(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	elseif maxhp() < 30 or maxmp() < 30 or not have_skill("Tao of the Terrapin") then
		return macro_noodlecannon()
	end
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

  while !times 10
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

if (monstername angry bassist) || (monstername blue-haired girl) || (monstername evil ex-girlfriend) || (monstername peeved roommate) || (monstername random scenester) || (monstername black crayon)
  call kill_cannon
endif

if monstername drunken rat king
  call kill_serpent
endif

if (monstername modern zmobie) || (monstername conjoined zmombie)
  call kill_cannon
endif

if (monstername ninja snowman assassin) || (monstername lobsterfrogman)
  call kill_serpent
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
	if extrastuff and extrastuff:contains("fight.php") then
		-- TODO: temporary workaround for macros getting the fight page as input now
		extrastuff = nil
	end
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

]] .. cast_olfaction(name) .. [[

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

local function make_cannonsniff_macro_raw(name)
	local cfm = getCurrentFightMonster()
	--print("DEBUG: making cannonsniff macro for", name, "vs", cfm)
	local physresist = 0
	local cfmhp = 10
	local elem = nil
	if cfm and cfm.Stats and cfm.Stats.physicalresistpercent then
		physresist = tonumber(cfm.Stats.physicalresistpercent)
	end
	if cfm and cfm.Stats and cfm.Stats.HP then
		cfmhp = tonumber(cfm.Stats.HP)
	end
	if cfm and cfm.Stats and cfm.Stats.Element then
		elem = cfm.Stats.Element
	end
	if physresist <= 60 and cfmhp >= 100 and not elem then
		return make_sniff_macro(name, serpent_action)
	else
		return make_sniff_macro(name, cannon_action)
	end
end

function make_cannonsniff_macro(name)
	return function()
		return make_cannonsniff_macro_raw(name)
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

function macro_reanimatorwink()
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

cast wink at

if (match "begins calculating how much")

]] .. maybe_stun_monster(true) .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. serpent_action() .. [[
endwhile

endif

]]
end


function macro_8bit_realm(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
	local stasispart = [[

while !times 20

]] .. stasis_action() .. [[

endwhile

]]
	if not can_change_familiar() then
		stasispart = ""
	end
	return [[
]] .. COMMON_MACROSTUFF_START(25, 30) .. [[

]] .. cast_olfaction("Blooper") .. [[

]] .. conditional_salve_action() .. [[

]] .. maybe_stun_monster(false) .. [[

]] .. macro_killing_begins() .. [[


]] .. stasispart .. [[


while !times 3
]] .. cannon_action() .. [[
endwhile

]]
end

local function use_if_have_item(x)
	if have_item(x) then
		return [[use ]] .. x
	else
		return ""
	end
end

function make_yellowray_macro(name)
	if script_use_unified_kill_macro() then
		return function(pt)
			add_macro_target("yellowraypatternmatch", name)
			return macro_kill_monster(pt)
		end
	end
	return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[
sub stall

]] .. stall_action() .. [[

endsub

sub do_yellowray

]] .. use_if_have_item("Golden Light") .. [[

]] .. use_if_have_item("unbearable light") .. [[

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

local function macro_noodlecannon_raw()
	return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. maybe_stun_monster() .. [[

]] .. conditional_salve_action() .. [[

]] .. macro_killing_begins() .. [[

while !times 11
]] .. cannon_action() .. [[

endwhile

if monstername mobile armored sweat lodge
	while !times 5
]] .. cannon_action() .. [[
	endwhile
endif

]]
end

function macro_noodlecannon(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
	return macro_noodlecannon_raw()
end

local function macro_noodleserpent_raw()
	return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

]] .. maybe_stun_monster() .. [[

]] .. macro_killing_begins() .. [[

]] .. conditional_salve_action() .. [[

while !times 7
]] .. serpent_action() .. [[
endwhile

]]
end

function macro_noodleserpent(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
	return macro_noodleserpent_raw()
end

function macro_ppnoodlecannon(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
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

function macro_noodlegeyser_raw(maxtimes)
		return [[
]] .. COMMON_MACROSTUFF_START(20, 25) .. [[

]] .. maybe_stun_monster(true) .. [[

]] .. macro_killing_begins() .. [[

while !times ]] .. maxtimes .. [[

]] .. geyser_action() .. [[

endwhile

]]
end

function macro_noodlegeyser(maxtimes)
	return function(pt)
		if script_use_unified_kill_macro() then
			return macro_kill_monster(pt)
		end
		return macro_noodlegeyser_raw(maxtimes)
	end
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

function macro_spookyraven(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
	return [[
]]..COMMON_MACROSTUFF_START(20, 5) .. [[

]] .. maybe_stun_monster(true) .. [[

]] .. macro_killing_begins() .. [[

while !times 5
]] .. geyser_action() .. [[
endwhile

]]
end

function macro_hiddencity(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
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
	if have_skill("Ambidextrous Funkslinging") and have_item("rock band flyers") then
		use_magnet = [[use rock band flyers, molybdenum magnet]]
	end
	return [[
]] .. COMMON_MACROSTUFF_START(25, 20) .. [[

sub stall

]]..maybeheal..[[

]]..stall_action()..[[

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

function macro_bossbat(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
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
    maybetrail = cast_olfaction("xxx pr0n") 
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

function macro_kill_ns(pt)
	if script_use_unified_kill_macro() then
		return macro_kill_monster(pt)
	end
	return [[
]] .. COMMON_MACROSTUFF_START(20, 30) .. [[

if monstername Avatar of Jarlsberg
  if hasskill Smoke Break
    cast Smoke Break
  endif
  if hasskill Throw Shield
    cast Throw Shield
  endif
  if hasskill Pop Wheelie
    cast Pop Wheelie
    if hasskill Pop Wheelie
      cast Pop Wheelie
      if hasskill Pop Wheelie
        cast Pop Wheelie
      endif
    endif
  endif
endif

while !times 15
  attack
endwhile

]]
end

-- TODO: move to other file
function get_equipment_absorption()
	local da = 0
	for _, slot in ipairs { "hat", "shirt", "pants" } do
		local itemid = equipment()[slot]
		if itemid then
			local itemdata = maybe_get_itemdata(itemid)
			if itemdata then
				da = da + (itemdata.power or 0)
				if have_skill("Tao of the Terrapin") and (slot == "hat" or slot == "pants") then
					da = da + (itemdata.power or 0)
				end
			end
		end
	end
	return da
end

function is_wearing_shield()
	if not equipment().offhand then return false end
	local itemdata = maybe_get_itemdata(equipment().offhand)
	if itemdata and itemdata.is_shield then
		return true
	else
		return false
	end
end

function estimate_current_monster_fight_damage(cfm, bonuses)
	local monster_attack = cfm.Stats.Atk
	local defend_stat = buffedmoxie()
	if buffedmuscle() > defend_stat and have_skill("Hero of the Half-Shell") and is_wearing_shield() then
		defend_stat = buffedmuscle()
	end
	local DA = math.minmax(10, get_equipment_absorption() + bonuses["Damage Absorption"], 1000)
	local DR = bonuses["Damage Reduction"]
	local diff = math.max(0, monster_attack - defend_stat)
	local base_dmg = diff + 0.225 * monster_attack - DR
	local absorbmod = 1.1 - math.sqrt(DA / 1000)
	local elementalmod = 1 -- TODO: implement
	--print("DEBUG: base damage", 0.20 * monster_attack, "to", 0.25 * monster_attack)
	--print("DEBUG: after reduction", 0.225 * monster_attack, "to", base_dmg)
	--print("DEBUG: absorb", DA, "(", absorbmod, ")")
	--print("DEBUG: final damage", base_dmg * absorbmod * elementalmod)
	return math.max(1, base_dmg * absorbmod * elementalmod)
end

local macro_target = {}
function reset_macro_target()
	macro_target = {}
end

function add_macro_target(a, b)
	macro_target[a] = b or true
end

local function want_generic_banish(name, priority)
	-- TODO: mahogany nightstand
	-- TODO: handle grouping, pick first-encountered
	local monsters = {
		["Bullet Bill"] = 1,
		["chatty pirate"] = 1,
		["crusty pirate"] = 2,
		["bookbat"] = 1,
		["slick lihc"] = 1,
		["senile lihc"] = 2,
		["sabre-toothed goat"] = 1,
		["drunk goat"] = 2,
		["Mismatched Twins"] = 1,
		["Creepy Ginger Twin"] = 2,
		["Protagonist"] = 1,
		["Procrastination Giant"] = 1,
		["Flock of Stab-bats"] = 1,
		["Taco Cat"] = 2,
		["coaltergeist"] = 1,
		["possessed laundry press"] = 1,
		["plaid ghost"] = 2,
		["skeletal sommelier"] = 1,
		["mad wino"] = 2,
		["pygmy orderlies"] = 1,
		["pygmy witch nurse"] = 2,
		["pygmy witch lawyer"] = 1,
		["tomb asp"] = 1,
		["A.M.C. gremlin"] = 1,
		["warehouse janitor"] = 1,
		["Knob Goblin Harem Guard"] = 1,
		["Knob Goblin Madam"] = 2,
	}
	return name and monsters[name] == (priority or 1)
end

local function want_super_pickpocket(name)
	local monsters = {
		["larval filthworm"] = true,
		["filthworm drone"] = true,
		["filthworm royal guard"] = true,
		["elephant (meatcar?) topiary animal"] = true,
		["spider (duck?) topiary animal"] = true,
		["bearpig topiary animal"] = true,
		["warehouse clerk"] = count_item("warehouse inventory page") <= 1,
		["warehouse guard"] = count_item("warehouse map page") <= 1,
	}
	return name and monsters[name]
end

local function want_super_itemdrop(name)
	local monsters = {
		["mountain man"] = true,
		["cleanly pirate"] = not have_item("rigging shampoo"),
		["creamy pirate"] = not have_item("ball polish"),
		["curmudgeonly pirate"] = not have_item("mizzenmast mop"),
		["possessed wine rack"] = true,
		["cabinet of Dr. Limpieza"] = true,
		["warehouse clerk"] = count_item("warehouse inventory page") <= 1,
		["warehouse guard"] = count_item("warehouse map page") <= 1,
		["larval filthworm"] = true,
		["filthworm drone"] = true,
		["filthworm royal guard"] = true,
	}
	return name and monsters[name]
end

macro_kill_monster_text = ""
function macro_kill_monster(pt)
	pt = pt or ""
	local pt_monster_name = nil
	local function monstername(str)
		-- WORKAROUND: Regular functionality not currently available while automating
		if str then
			return get_monstername() == str
		end
		if not pt_monster_name then
			local monster_name
			for spantext in pt:gmatch([[<span.-</span>]]) do
				if spantext:contains("monname") then
					monster_name = spantext:match([[<span [^>]*id=['"]monname['"][^>]*>(.-)</span>]]) or monster_name
					if monster_name then
						pt_monster_name = monster_name:gsub("^[^ ]* ", "")
					end
				end
			end
		end
		return pt_monster_name or ""
	end
	local cfm = getCurrentFightMonster()
	if not cfm or not cfm.Stats or not cfm.Stats.Atk then
		print_ascensiondebug("macro_kill generation", "cfm incomplete when generating combat macro", tostring(cfm))
		print_ascensiondebug("macro_kill generation", "monster", get_monstername())
		return macro_noodleserpent_raw
	end
	local bonuses = estimate_current_bonuses()
	bonuses.add(estimate_fight_page_bonuses(pt))
	local monster_damage = estimate_current_monster_fight_damage(cfm, bonuses)
	local physically_resistant = tonumber(cfm.Stats.physicalresistpercent) and tonumber(cfm.Stats.physicalresistpercent) >= 67
	macro_kill_monster_text = pt

	local use_initial_tbl = {}
	if have_equipped_item("Pantsgiving") then
		table.insert(use_initial_tbl, "cast Pocket Crumbs")
	end
	if (cfm.Stats.stunresistpercent or 0) <= 20 then
		table.insert(use_initial_tbl, [[
if hasskill Summon Love Gnats
	cast Summon Love Gnats
endif]])
	end

	if macro_target.yellowraypatternmatch and get_monstername():lower():contains(macro_target.yellowraypatternmatch:lower()) then
		if have_skill("Wrath of Ra") then
			print_ascensiondebug("macro: using Wrath of Ra!")
			table.insert(use_initial_tbl, [[cast Wrath of Ra]])
		end
	end

	if have_skill("Curse of Vacation") and want_generic_banish(get_monstername()) then
		table.insert(use_initial_tbl, [[cast Curse of Vacation]])
	end

	local really_want_to_kill = false
	if cannot_use_undying() then really_want_to_kill = true end
	local raindoh_flyers_list = {}
	if macro_target.itemcopy and macro_target.itemcopy[get_monstername()] and have_item("Rain-Doh black box") then
		print_ascensiondebug("macro: using Rain-Doh black box!")
		table.insert(raindoh_flyers_list, "Rain-Doh black box")
	end
	if macro_target.familiarcopy and macro_target.familiarcopy[get_monstername()] and familiar("Reanimated Reanimator") then
		table.insert(use_initial_tbl, [[
if hasskill Wink at
	cast Wink at
endif]])
		really_want_to_kill = true
	end

	if have_skill("Lash of the Cobra") and want_super_pickpocket(get_monstername()) then
		print_ascensiondebug("macro: using Lash of the Cobra!")
		table.insert(use_initial_tbl, [[cast Lash of the Cobra]])
	elseif have_item("talisman of Renenutet") and want_super_itemdrop(get_monstername()) then
		print_ascensiondebug("macro: using talisman of Renenutet!")
		table.insert(use_initial_tbl, [[use talisman of Renenutet]])
		used_undying() -- Fake undying as workaround to trigger big spells
		used_undying()
		used_undying()
		really_want_to_kill = true
	end

	if have_item("rock band flyers") and not really_want_to_kill then
		print_ascensiondebug("macro: using rock band flyers!")
		table.insert(raindoh_flyers_list, "rock band flyers")
	end
	if have_item("Rain-Doh indigo cup") then
		table.insert(raindoh_flyers_list, "Rain-Doh indigo cup")
	end
	if have_item("Rain-Doh blue balls") then
		table.insert(raindoh_flyers_list, "Rain-Doh blue balls")
	end
	if have_skill("Ambidextrous Funkslinging") and raindoh_flyers_list[2] then
		table.insert(use_initial_tbl, string.format("use %s, %s", raindoh_flyers_list[1], raindoh_flyers_list[2]))
	elseif raindoh_flyers_list[1] then
		table.insert(use_initial_tbl, string.format("use %s", raindoh_flyers_list[1]))
	end

	if false and (cfm.Stats.stunresistpercent or 0) <= 20 then
		table.insert(use_initial_tbl, [[
if hasskill Summon Love Stinkbug
	cast Summon Love Stinkbug
endif]])
	end

	if not cfm.Stats.staggerimmune then
		table.insert(use_initial_tbl, [[
if hasskill Summon Love Mosquito
	cast Summon Love Mosquito
endif
if hasskill Summon Love Scarabs
	cast Summon Love Scarabs
endif]])
	end

	if have_equipped_item("Thor's Pliers") and not cfm.Stats.staggerimmune then
		table.insert(use_initial_tbl, "cast Ply Reality")
	end

	if have_equipped_item("Pantsgiving") and not cfm.Stats.staggerimmune then
		table.insert(use_initial_tbl, "cast Air Dirty Laundry")
	end

	use_initial_stuff = table.concat(use_initial_tbl, [[


]])

	print_ascensiondebug("macro_kill", get_monstername(), script_want_2_day_SCHR(), playerclass("Seal Clubber"), not pt:contains("Procrastination Giant"), using_club(), not physically_resistant, use_crumbs, use_raindoh_flyers)

	local function heavy_rains_spell()
		if have_skill("Saucestorm") then
			return [[
if hasskill Curse of Weaksauce
	cast Curse of Weaksauce
endif
if hasskill Thunderstrike
	cast Thunderstrike
endif

]] .. use_initial_stuff .. [[

cast Saucestorm
cast Saucestorm
cast Saucestorm
cast Saucestorm
cast Saucestorm

abort hppercentbelow 30
abort mpbelow 50

cast Saucestorm
cast Saucestorm
cast Saucestorm
cast Saucestorm
cast Saucestorm
]]
		else
			return [[abort heavy rains boss]]
		end
	end

	local function heavy_rains_attack()
		if have_skill("Lunging Thrust-Smack") then
			return [[
if hasskill Curse of Weaksauce
	cast Curse of Weaksauce
endif
if hasskill Thunderstrike
	cast Thunderstrike
endif

]] .. use_initial_stuff .. [[

cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
cast Lunging Thrust-Smack

abort hppercentbelow 30
abort mpbelow 50

cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
cast Lunging Thrust-Smack
]]
		else
			return [[abort heavy rains boss - no spells]]
		end
	end

	-- TODO: get proper monster resistance information in data files!
	if monstername("storm cow") then
		return [[abort storm cow]]
	elseif monstername("Aquabat") then
		return heavy_rains_spell()
	elseif monstername("Aquagoblin") then
		-- dangerous, removes buffs and fought while dressed up in goblin gear
		if have_item("Rain-Doh blue balls") and have_skill("Saucestorm") then
			return heavy_rains_spell()
		else
			return [[abort heavy rains boss - dangerous]]
		end
	elseif monstername("Auqadargon") then
		return heavy_rains_spell()
	elseif monstername("Gurgle") then
		return heavy_rains_attack()
	elseif monstername("Lord Soggyraven") then
		return heavy_rains_spell()
	elseif monstername("Protector Spurt") then
		return heavy_rains_spell()
	elseif monstername("Dr. Aquard") then
		return heavy_rains_attack()
	elseif monstername("The Aquaman") then
		return heavy_rains_spell()
	elseif monstername("Big Wisnaqua") then
		return heavy_rains_spell()
	elseif monstername("The Rain King") then
		if have_equipped_item("Rain-Doh green lantern") then
			return heavy_rains_spell()
		else
			return [[abort heavy rains boss]]
		end
	elseif have_skill("Lightning Strike") and heavyrains_lightning() >= 25 and not cfm.Stats.boss then
		return use_initial_stuff .. [[

cast Lightning Strike
]]
	elseif script_want_2_day_SCHR() and playerclass("Seal Clubber") and not pt:contains("Procrastination Giant") and (using_club() or equipment().weapon == get_itemid("Thor's Pliers")) and not physically_resistant and have_skill("Lunging Thrust-Smack") then
		return use_initial_stuff .. [[

cast lunging thrust-smack
cast lunging thrust-smack

abort hppercentbelow 50

cast lunging thrust-smack
cast lunging thrust-smack
cast lunging thrust-smack
]]
	elseif playerclass("Sauceror") and have_skill("Itchy Curse Finger") and have_skill("Curse of Weaksauce") and have_skill("Saucegeyser") then
-- TODO: merge all banish handling for boris/heavy rains/etc.
		return [[
cast Curse of Weaksauce

if (monstername animated mahogany nightstand) || (monstername drunk goat) || (monstername pygmy witch lawyer) || (monstername pygmy orderlies) || (monstername skeletal sommelier) || (monstername possessed laundry press) || (monstername flock of stab-bats) || (monstername tomb asp) || (monstername senile lihc) || (monstername big wheelin' twins)
	if hasskill Thunder Clap
		cast Thunder Clap
	endif
endif

if (monstername sabre-toothed goat) || (monstername slick lihc) || (monstername mad wino) || (monstername pygmy orderlies) || (monstername plaid ghost) || (monstername taco cat) || (monstername troll twins)
	if hasskill Talk About Politics
		cast Talk About Politics
	endif
endif

]] .. use_initial_stuff .. [[

cast Saucegeyser
cast Saucegeyser
cast Saucegeyser

abort hppercentbelow 50
abort mpbelow 50

cast Saucegeyser
cast Saucegeyser
cast Saucegeyser
cast Saucegeyser
cast Saucegeyser
]]
	elseif pt:contains("Green Ops Soldier") then
		return macro_noodlegeyser_raw(5)
	elseif playerclass("Sauceror") and have_skill("Saucestorm") then
		local maybe_weaksauce = ""
		if have_skill("Itchy Curse Finger") and have_skill("Curse of Weaksauce") then
			maybe_weaksauce = [[

cast Curse of Weaksauce

]]
		end
		return maybe_weaksauce .. [[

if (monstername animated mahogany nightstand) || (monstername drunk goat) || (monstername pygmy witch lawyer) || (monstername pygmy orderlies) || (monstername skeletal sommelier) || (monstername possessed laundry press) || (monstername flock of stab-bats) || (monstername tomb asp) || (monstername senile lihc) || (monstername big wheelin' twins)
	if hasskill Thunder Clap
		cast Thunder Clap
	endif
endif

if (monstername sabre-toothed goat) || (monstername slick lihc) || (monstername mad wino) || (monstername pygmy orderlies) || (monstername plaid ghost) || (monstername taco cat) || (monstername troll twins)
	if hasskill Talk About Politics
		cast Talk About Politics
	endif
endif

]] .. use_initial_stuff .. [[

cast Saucestorm
cast Saucestorm
cast Saucestorm

abort hppercentbelow 50
abort mpbelow 50

cast Saucestorm
cast Saucestorm
cast Saucestorm
cast Saucestorm
cast Saucestorm
]]
	elseif physically_resistant then
		return [[
]] .. COMMON_MACROSTUFF_START(20, 35) .. [[

]] .. use_initial_stuff .. [[

]] .. conditional_salve_action() .. [[

while !times 11

]] .. elemental_damage_action() .. [[

endwhile]]
	else
		local action = ""
		if level() >= 9 and meat() >= 1000 then
			action = serpent_action()
		else
			action = cannon_action()
		end
		local actionstr = action:gsub("^%s*", ""):gsub("%s*$", "")
		print_ascensiondebug("macro action:", actionstr)
		return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

]] .. use_initial_stuff .. [[

]] .. conditional_salve_action() .. [[

while !times 7

]] .. action .. [[

endwhile]]
	end
end
