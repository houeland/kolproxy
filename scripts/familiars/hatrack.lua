add_printer("/familiar.php", function()
	text = text:gsub([[with your</td><td><select name=whichitem>.-</select>]], function(selecttext)
		return selecttext:gsub([[(<option value=[0-9]*>)(.-)(</option>)]], function(pre, x, post)
			local name = x:gsub([[ %([0-9]*%)$]], "")
			local desc = datafile("hatrack")[name]
			if desc then
				return pre .. x .. " { " .. desc .. " }" .. post
			end
		end)
	end)
end)
