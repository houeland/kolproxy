add_processor("/fight.php", function()
	if text:contains("You groan and loosen your overtaxed belt.") then
		increase_daily_counter("pantsgiving bonus fullness")
	end
end)
