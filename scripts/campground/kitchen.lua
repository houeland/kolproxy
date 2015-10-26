function can_cook_advanced_items()
	local pt = get_page("/campground.php", { action = "inspectkitchen" })
	return pt:contains("Dramatic&trade; range")
end

function buy_and_install_dramatic_range_for_advanced_cooking()
	if can_cook_advanced_items() then
		error "Can already cook advanced items before trying to buy dramatic range"
	end
	if not have_item("Dramatic&trade; range") then
		buy_item("Dramatic&trade; range")
	end
	if not have_item("Dramatic&trade; range") then
		error "Couldn't buy dramatic range (for cooking)"
	end
	use_item("Dramatic&trade; range")
	return not have_item("Dramatic&trade; range")
end

