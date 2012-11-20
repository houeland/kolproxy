local enthroned_familiars_datafile = load_datafile("enthroned-familiars")

add_processor("/familiar.php", function()
	session["cached enthroned familiar"] = nil
end)

add_automator("all pages", function()
	if have_equipped("Crown of Thrones") and not session["cached enthroned familiar"] then
		local pt = get_page("/desc_item.php", { whichitem = 239178788 })
		local line = pt:match([[>Current Occupant.-<br>]])
		local famtype = line:match("<b>.+, the (.-)</b><br>")
		if line:match([[<b>Nobody</b>]]) then
			famtype = "none"
		end
		session["cached enthroned familiar"] = famtype
	end
end)

function get_equipment_bonuses()
	local bonuses = {}
	if have_equipped("Crown of Thrones") then
		local famtype = session["cached enthroned familiar"]
		if famtype and famtype ~= "none" then
			for a, b in pairs(enthroned_familiars_datafile[famtype] or {}) do
				bonuses[a] = (bonuses[a] or 0) + b
			end
		end
	end
	return bonuses
end
