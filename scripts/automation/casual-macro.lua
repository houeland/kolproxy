function casual_macro_runaway_most(good_monsters)
	local tbl = {}
	for x in table.values(good_monsters) do
		table.insert(tbl, "monstername " .. x)
	end
	return [[
if hascombatitem rock band flyers
	cast entangling noodles
	use rock band flyers
endif

if ]] .. table.concat(tbl, " || ") .. [[

]] .. casual_macro_kill() .. [[

endif
]] .. casual_macro_runaway()
end

function casual_macro_kill()
	return [[
skill wave of sauce
repeat
]]
end

function casual_macro_runaway_all()
	return [[
if hascombatitem rock band flyers
	cast entangling noodles
	use rock band flyers
endif

]].. casual_macro_runaway()
end

function casual_macro_insults()
	return [[	
cast entangling noodles
use The Big Book of Pirate Insults

]] .. casual_macro_runaway()
end

function macro_pickpocket_eye()
	return [[	
cast entangling noodles
if hascombatitem rock band flyers
	use rock band flyers
endif
if (monstername "giant skeelton")

]] .. casual_macro_kill() .. [[
endif

while !(match "a prize inside it" || pastround 15)
	use divine cracker, divine cracker
endwhile

]] .. casual_macro_runaway()
end

function casual_macro_putty()
	return [[
cast entangling noodles
if hascombatitem rock band flyers
	use rock band flyers, spooky putty sheet
else
	use spooky putty sheet
endif
]] .. casual_macro_kill()
end

function casual_macro_pickpocket()
	return [[
cast entangling noodles
if hascombatitem rock band flyers
	use rock band flyers
endif

while !(match "a prize inside it" || pastround 15)
	use divine cracker, divine cracker
endwhile

]] .. casual_macro_runaway()
end

function casual_macro_runaway()
	return [[
if hascombatitem glob of Blank-Out
	use glob of Blank-Out
endif
if hascombatitem green smoke bomb
	use green smoke bomb, green smoke bomb
	repeat
endif
if hascombatitem tattered scrap of paper
	use tattered scrap of paper, tattered scrap of paper
	repeat
endif
]]
end

function casual_macro_orc_chasm()
  return [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

cast Entangling Noodles

]] .. COMMON_MACROSTUFF_FLYERS .. [[

if monstername rampaging adding machine
  use 334 scroll, 334 scroll
  use 30669 scroll, 33398 scroll
  use 64067 scroll, 668 scroll
endif

]] .. casual_macro_runaway()
end
