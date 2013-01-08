local space_href = setup_turnplaying_script {
	name = "automate-a-quest-lol",
	description = "Do Baron Rof L'm Fao quest (for facsimile dictionary, <b>not implemented yet</b>)",
	when = function() return false end,
	macro = nil,
	preparation = function()
	end,
	adventuring = function()
		advagain = false
		__set_turnplaying_result(result, resulturl, advagain)
	end
}
