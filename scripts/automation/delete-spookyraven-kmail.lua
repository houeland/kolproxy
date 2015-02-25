register_setting {
	name = "delete spookyraven kmails",
	description = "Automatically delete kmails about the Spookyraven quest",
	group = "other",
	default_level = "detailed",
}

local function should_delete(x)
	if tonumber(x.fromid) == 0 and x.fromname == "Lady Spookyraven's Ghost" and x.message:contains("I'd really like to go dancing one last time, and I need your help.") then
		return true
	elseif tonumber(x.fromid) == 0 and x.fromname == "Lady Spookyraven's Ghost" and x.message:contains("To the third floor of the Manor!") then
		return true
	elseif tonumber(x.fromid) == 0 and x.fromname == "The Loathing Postal Service" and x.message:contains("We found this telegram at the bottom of an old bin of mail.") then
		return true
	elseif tonumber(x.fromid) == 0 and x.fromname == "The Loathing Postal Service" and x.message:contains("One of my agents found a copy of a telegram in the Council's fileroom") then
		return true
	else
		return false
	end
end

local deleted_kmail = false
add_automator("all pages", function()
	if deleted_kmail then return end
	if not setting_enabled("delete spookyraven kmails") then return end
	deleted_kmail = true
	local kmails = fromjson(get_page("/api.php", { what = "kmail", count = 10, ["for"] = "testing" }))
	for _, x in ipairs(kmails) do
		if should_delete(x) then
			async_post_page("/messages.php", { the_action = "delete", pwd = session.pwd, box = "Inbox", ["sel" .. x.id] = "on" })
		end
	end
end)
