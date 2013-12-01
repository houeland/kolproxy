add_printer("/familiar.php", function()
	text = text:gsub([[(<option value=[0-9]+.->)(.-)(</option>)]], function(pre, x, post)
		local name = x:gsub([[ %([0-9]*%)$]], "")
		local d = datafile("hatrack")[name]
		if d then
			return pre .. x .. " { " .. d.description .. " }" .. post
		end
	end)
end)
