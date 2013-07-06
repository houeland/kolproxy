add_always_adventure_warning(function()
	if equipment().weapon or equipment().offhand then
		if have_equipped_item("shining halo") or have_equipped_item("furry halo") or have_equipped_item("frosty halo") or have_equipped_item("time halo") then
			return "You have a halo equipped but are not unarmed.", "halo and not unarmed"
		end
	end
end)

add_always_adventure_warning(function()
	if have_equipped_item("time halo") then
		return "You have a time halo equipped.", "time halo equipped"
	end
end)

add_extra_ascension_adventure_warning(function()
	if have_intrinsic("Expert Timing") and (equipment().weapon or equipment().offhand) then
		return "You have expert timing but are not unarmed.", "expert timing and not unarmed"
	end
end)
