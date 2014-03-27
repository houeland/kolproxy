add_processor("/charsheet.php", function()
	session["cached avatar image"] = text:match([[<a href=account_avatar.php><img src="(.-)"]])
end)

add_processor("/account_avatar.php", function()
	session["cached avatar image"] = text:match([[checked value=%d+></td><td><img src="(.-)"]])
end)

add_processor("/inv_equip.php", function()
	if params.action then
	   --- should only invalidate cache on actual equip action
	   session["cached avatar image"] = nil
	end
end)

add_processor("/inventory.php", function()
	if requestpath == "/inv_equip.php" or params.action or params.type or params.whichoutfit then
		-- these should include any non-ajax equipment switches
		session["cached avatar image"] = nil
	end
end)

function avatar_image()
	if not session["cached avatar image"] then
		get_page("/account_avatar.php")
	end
	return session["cached avatar image"]
end

function get_wand_data()
	local wands = { "aluminum wand", "ebony wand", "hexagonal wand", "marble wand", "pine wand" }
	for _, x in ipairs(wands) do
		if have_item(x) then
			local itemid = get_itemid(x)
			local pt = get_page("/wand.php", { whichwand = itemid })
			if pt:contains("Zap an item") then
				if pt:contains(x) or pt:contains("Your wand ") or pt:contains("feels warm") or pt:contains("be careful") then
					return { name = x, itemid = itemid, heat = 1 }
				else
					return { name = x, itemid = itemid, heat = 0 }
				end
			end
		end
	end
	return nil
end

function retrieve_trailed_monster()
	local effectpt = get_page("/desc_effect.php", { whicheffect = "91635be2834f8a07c8ff9e3b47d2e43a" })
	local trailed = effectpt:match([[And by "wabbit" I mean "(.-)%."]])
	return trailed
end

function retrieve_raindoh_monster()
	local itempt = get_page("/desc_item.php", { whichitem = "965400716" })
	local copied = itempt:match([[with the soul of (.-) in it]])
	return copied
end
