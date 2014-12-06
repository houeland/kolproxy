local function set_avatar_image(imgsrc)
	if imgsrc then
		session["cached avatar image"] = imgsrc
		session["cached avatar image up-to-date"] = true
	end
end

add_processor("/charsheet.php", function()
	local imgsrc = text:match([[<a href=account_avatar.php><img src="(.-)"]])
	set_avatar_image(imgsrc)
end)

add_processor("/account_avatar.php", function()
	local imgsrc = text:match([[checked value=%d+></td><td><img src="(.-)"]])
	set_avatar_image(imgsrc)
end)

add_processor("/inv_equip.php", function()
	session["cached avatar image up-to-date"] = nil
end)

add_processor("/inventory.php", function()
	-- these should include any non-ajax equipment switches
	if requestpath == "/inv_equip.php" or params.action or params.type or params.whichoutfit then
		session["cached avatar image up-to-date"] = nil
	end
end)

function avatar_image()
	if not session["cached avatar image up-to-date"] and not locked() then
		get_page("/charsheet.php")
	end
	return session["cached avatar image"] or "http://images.kingdomofloathing.com/itemimages/blank.gif"
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

local counter_effect_tbl = {}
function add_counter_effect(f)
	table.insert(counter_effect_tbl, f)
end

function get_counter_effect_list()
	return counter_effect_tbl
end

function can_pvp_steal_item(item)
	local d = get_itemdata(item)
	if not d then return true end
	if not d.cantransfer then return false end
	if (d.sellvalue or 0) == 0 then return false end
	return true
end
