add_ascension_adventure_warning(function(zoneid)
	if level() >= 12 then
		local warn_zone =
			(zoneid == 131) or
			(zoneid == 134) or
			(zoneid == 26 and have_equipped_item("beer helmet") and have_equipped_item("distressed denim pants") and have_equipped_item("bejeweled pledge pin")) or
			(zoneid == 27 and have_equipped_item("reinforced beaded headband") and have_equipped_item("bullet-proof corduroys") and have_equipped_item("round purple sunglasses"))
		if warn_zone and not have_item("dictionary") and not have_item("abridged dictionary") then
			if get_page("/questlog.php", { which = 1 }):contains([[<b>A Quest, LOL</b>]]) then
				return "You might want to buy an abridged dictionary before the pirates disappear when starting the war.", "buy abridged dictionary before starting war"
			end
		end	
	end
end)
