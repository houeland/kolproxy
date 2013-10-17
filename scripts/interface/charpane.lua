add_printer("/charpane.php", function()
kolproxy_log_time_interval("do charpane lines", function()
	for _, x in ipairs(run_charpane_line_functions()) do
		print_charpane_value(x)
	end
	text = print_charpane_lines(text)
end)
end)

