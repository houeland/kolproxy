add_printer("/casino.php", function()
	text = text:gsub([[<a href="bet.php">.-</a>]], "")
end)
