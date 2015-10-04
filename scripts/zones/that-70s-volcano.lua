local velvet_items = {
	"smooth velvet hanky",
	"smooth velvet hat",
	"smooth velvet pants",
	"smooth velvet pocket square",
	"smooth velvet shirt",
	"smooth velvet socks",
}

local wear_velvet_href = add_automation_script("custom-choose-mad-tea-party-hat", function()
	for _, x in ipairs(velvet_items) do
		if not have_item(x) then
			pull_storage_item(x)
		end
	end
	local have_all = true
	for _, x in ipairs(velvet_items) do
		have_all = have_all and have_item(x)
	end
	if not have_all then
		local text, url = get_place("airport_hot", "airport4_zone1")
		return add_message_to_page(text, "Couldn't pull all velvet equipment.", nil, "darkorange"), url
	end
	set_equipment {
		hat = "smooth velvet hat",
		shirt = "smooth velvet shirt",
		pants = "smooth velvet pants",
		acc1 = "smooth velvet hanky",
		acc2 = "smooth velvet pocket square",
		acc3 = "smooth velvet socks",
	}
	local text, url = get_place("airport_hot", "airport4_zone1")
	return add_message_to_page(text, "Done."), url
end)

add_printer("choice: The Towering Inferno Discotheque", function()
	if not have_unlimited_storage_access() then return end
	if text:match([[currently rocking a Disco Style level of <b>[0-5]</b>]]) then
		text = text:gsub("<form ", function(form)
			return string.format([[<p><a style="color: green" href="%s">{ Pull and wear velvet equipment }</a></p>]], wear_velvet_href { pwd = session.pwd }) .. form
		end, 1)
	end
end)
