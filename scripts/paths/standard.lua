local unavailable_items = nil
local state_id = nil
function get_unavailable_items()
	if state_id ~= state_identifier() then
		unavailable_items = nil
		state_id = state_identifier()
	end
	if not unavailable_items then
		local standard = get_page("/standard.php")
		if not standard:contains("Item Unavailability Schedule") then
			print("WARNING: No schedule found on standard.php")
			return {}
		end
		unavailable_items = {}
		for name in standard:gmatch([[<span class="i">(.-)</span>]]) do
			name = name:gsub(", $", "")
			local itemid = maybe_get_itemid(name)
			if itemid then
				unavailable_items[name] = true
			end
		end
	end
	return unavailable_items
end

function item_is_unavailable(item)
	return get_unavailable_items()[get_itemname(item)] ~= nil
end
