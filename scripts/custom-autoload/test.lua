add_printer("/tutorial.php", function()
	print("Test 1 2 3")
end)

add_printer("/mchat.php", function()
	text = text:gsub([[parts%[1%].match%(/ /%)]], [[(%0 && !parts[1].match(/clan /))]])
end)
