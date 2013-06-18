sugar_sheet_items = {
	"sugar shotgun",
	"sugar shillelagh",
	"sugar shank",
	"sugar chapeau",
	"sugar shorts",
	"sugar shield",
	"sugar shirt",
}

add_processor("/fight.php", function()
	if newly_started_fight then
		for _, x in ipairs(sugar_sheet_items) do
			if have_equipped(x) then
				increase_ascension_counter("sugar sheet." .. x .. ".fights used", count_equipped_item(x))
			end
		end
	end
end)
