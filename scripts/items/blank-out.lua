add_processor("/fight.php", function()
	if text:contains("part of your handful of Blank-Out") then
		increase_ascension_counter("item.glob of blank-out.used")
	end

	if text:contains("you notice that the last of the Blank-Out") then
		reset_ascension_counter("item.glob of blank-out.used")
	end
end)

local function get_remaining_uses_message()
	return string.format("{ %s remaining }", make_plural(5 - get_ascension_counter("item.glob of blank-out.used"), "use", "uses"))
end

add_printer("/fight.php", function()
	text = text:gsub([[glob of Blank%-Out %([0-9]-%)]], function(x)
		return x .. "&nbsp;" .. get_remaining_uses_message()
	end)
end)
	

add_printer("/inventory.php", function()
	text = text:gsub([[(<b class="ircm">)(.-)(</b>&nbsp;<span>[^<]*</span>)]], function(pre, itemname, post)
		-- Support both inventory images turned on and off
		if itemname:contains("glob of Blank-Out") then
			return pre .. itemname .. post .. [[ <font style="color: green;">]] .. get_remaining_uses_message() .. [[</font>]]
		else
			return false
		end
	end)
end)
