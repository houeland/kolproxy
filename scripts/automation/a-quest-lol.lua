local roflmao_href = setup_turnplaying_script {
	name = "automate-a-quest-lol",
	description = "Do Baron Rof L'm Fao quest (for facsimile dictionary)",
	when = function() return not quest_completed("A Quest, LOL") end,
	macro = [[

scrollwhendone

abort pastround 20
abort hppercentbelow 50

if monstername rampaging adding machine
  use 668 scroll
  use 64067 scroll
endif

while !times 5
  cast Cannelloni Cannon
endwhile

]],
	preparation = function()
		maybe_pull_item("668 scroll", 1)
		maybe_pull_item("64067 scroll", 1)
	end,
	adventuring = function()
		advagain = false
		if have_item("64735 scroll") then
			result, resulturl = use_item("64735 scroll")()
			advagain = false
		else
			result, resulturl, advagain = autoadventure {
				zoneid = 80,
				macro = automation_macro,
			}
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end
}
