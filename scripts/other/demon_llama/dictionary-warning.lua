add_ascension_adventure_warning(function(zoneid)
	if level() >= 12 then
		local warn_zone =
			(zoneid == 131) or
			(zoneid == 134) or
			(zoneid == 26 and have_equipped("beer helmet") and have_equipped("distressed denim pants") and have_equipped("bejeweled pledge pin")) or
			(zoneid == 27 and have_equipped("reinforced beaded headband") and have_equipped("bullet-proof corduroys") and have_equipped("round purple sunglasses"))
		if warn_zone and not have("dictionary") and not have("abridged dictionary") then
			if get_page("/questlog.php", { which = 1 }):contains([[<b>A Quest, LOL</b>]]) then
				return "You might want to buy an abridged dictionary before the pirates disappear when starting the war.", "buy abridged dictionary before starting war"
			end
		end	
	end
end)
