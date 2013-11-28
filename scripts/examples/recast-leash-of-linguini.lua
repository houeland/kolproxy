add_automator("all pages", function()
	if ascensionstatus("Aftercore") and buffturns("Leash of Linguini") < 10 and mp() >= 50 then
		cast_skill("Leash of Linguini")
	end
end)

add_automator("all pages", function()
	if ascensionstatus("Aftercore") then
		local script = get_automation_scripts()
		script.ensure_buff_turns("Leash of Linguini", 20)
		script.ensure_mp(20)
	end
end)
