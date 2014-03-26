register_setting {
	name = "improve typography",
	description = "Improve formatting and typography",
	group = "other",
	default_level = "enthusiast",
	beta_version = true,
}

add_printer("all pages", function()
	if not setting_enabled("improve typography") then return end
	if text:contains("<html") then
--		text = text:gsub(" %-%- ", "<wbr>&mdash;<wbr>")
		text = text:gsub("</head>", [[
<style type="text/css">
blockquote {
	text-align: justify;
	-moz-hyphens: auto;
	-ms-hyphens: auto;
	-o-hyphens: auto;
	-webkit-hyphens: auto;
	hyphens: auto;
	___disabled_background-color: beige;
}
___disabled_p {
	text-align: justify;
	-moz-hyphens: auto;
	-ms-hyphens: auto;
	-o-hyphens: auto;
	-webkit-hyphens: auto;
	hyphens: auto;
	___disabled_background-color: azure;
}
</style>
%0
]])
	end
end)

-- TODO: apply to beginning of choice encounters
