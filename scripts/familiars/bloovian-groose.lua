add_always_adventure_warning(function()
	if buff("Just the Best Anapests") then
		return "You might want to shrug Just the Best Anapests before adventuring, otherwise the game text will not be recognized.", "shrug Just the Best Anapests"
	end
end)

add_extra_ascension_adventure_warning(function()
	if have("groose grease") and spleen() <= 11 then
		return "You might want to use your groose grease first.", "use groose grease"
	end
end)

add_automator("use item: groose grease", function()
	if not setting_enabled("automate simple tasks") then return end
	if buff("Just the Best Anapests") then
		async_get_page("/charsheet.php", { pwd = session.pwd, ajax = 1, action = "unbuff", whichbuff = 1003 })
		text = text:gsub("<b>Just the Best Anapests</b>", [[%0 <span style="color: green">{ Shrugged. }</span>]])
	end
end)
