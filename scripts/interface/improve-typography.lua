register_setting {
	name = "enable experimental implementations/improve typography",
	description = "Improve formatting and typography (experimental)",
	group = "other",
	default_level = "enthusiast",
}

add_printer("all pages", function()
	if not setting_enabled("show extra notices") then return end
	if text:contains("<html") then
		text = text:gsub(" %-%- ", "<wbr>&mdash;<wbr>")
		text = text:gsub("</head>", [[
<style type="text/css">
blockquote { text-align: justify; background-color: beige }
</style>
%0
]])
	end
end)

-- TODO: apply to beginning of choice encounters
