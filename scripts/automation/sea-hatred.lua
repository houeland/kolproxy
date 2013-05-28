local hatred_href = setup_turnplaying_script {
	name = "automate-sea-hatred",
	description = "Automate sea (scholar library / hatred boss, not automated yet)",
	when = function() return ascension["zones.sea.deepcity reached"] and not ascension["zones.sea.deepcity temple finished"] end,
	macro = nil,
	preparation = function()
		maybe_pull_item("sea salt scrubs", 1)
		maybe_pull_item("Mer-kin scholar mask", 1)
		maybe_pull_item("Mer-kin scholar tailpiece", 1)
	end,
	autoinform = false,
	adventuring = function()
		advagain = false
		script.want_familiar "Grouper Groupie"
		hidden_inform "doing scholar/hatred path"
		stop "TODO: Use 10 Mer-kin wordquizzes. Get 3 noncombats, use killscroll, healscroll, knucklebone, cast deep dark visions. Use dreadscroll, guess sushi one. Wear 3 prayerbeads, kill temple boss."
		if not ascension["zones.sea.read darkscroll prophecy"] then
		else
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end,
}
