register_setting {
	name = "show shop item count",
	description = "Display number of items you already have for shop-type crafting (cosmic kitchen)",
	group = "other",
	default_level = "detailed",
}

add_printer("/shop.php", function()
	if not setting_enabled("show shop item count") then return end
	text = text:gsub([[(<input type=radio name=whichitem value=)([0-9]+)(>)]], function(a, b, c)
		local itemid = tonumber(b)
		return string.format([[<span style="color: green">{%d}</span>]], count_item(itemid)) .. a .. b .. c
	end)
end)
