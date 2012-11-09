dont_slime = {
	"coconut shell",
	"little paper umbrella",
	"magical ice cubes",

	"Knob Goblin elite helm",
	"Knob Goblin elite polearm",
	"Knob Goblin elite pants",

	"filthy knitted dread sack",
	"filthy corduroys",

	"Dyspepsi%-Cola shield",
	"Cloaca%-Cola shield",
	"meat shield",
	"hot plate",

	"BRICKO bulwark",

	"Bjorn's Hammer",
	"Mace of the Tortoise",
	"Pasta of Peril",
	"5%-Alarm Saucepan",
	"Disco Banjo",
	"Rock and Roll Legend",

	"acoustic guitarrr",

	"spangly sombrero",
	"spangly mariachi pants",

	"ring of conflict",

	"cane%-mail shirt",
	"pin%-stripe slacks",

	-- including items from the pull/closet list would be nice
}

add_printer("/inventory.php", function()
	for x, name in pairs(dont_slime) do
		-- inventory images visible
		text = text:gsub("(<b class=\"ircm\">" .. name .. "</b>.-<a href=\")([^\"]-)(\">%[give to slimeling%]</a>)", "%1javascript:if (confirm('Are you sure you want to lose this item?')) { location.href = '%2'; }%3")
		-- inventory images hidden
		text = text:gsub("(<b class=\"ircm\"><a[^>]->" .. name .. "</a></b>.-<a href=\")([^\"]-)(\">%[give to slimeling%]</a>)", "%1javascript:if (confirm('Are you sure you want to lose this item?')) { location.href = '%2'; }%3")
	end
end)

-- add_printer("/charpane.php", function()
-- 	if familiarpicture() == "slimeling" then
-- 		bonus = string.format("+%.1f%%", fairy_bonus(buffedfamiliarweight()))
-- 		compact = bonus
-- 		normal = bonus .. " items"
-- 		print_charpane_infoline(compact, normal)
-- 	end
-- end)
