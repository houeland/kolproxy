local href = add_automation_script("view-ascension-logs", function()
	local secretkey = kolproxy_md5("kolproxylogparse:" .. status().eleronkey .. ":kolproxylogparse")
	local log_list = fromjson(kolproxy_list_ascension_logs(playerid(), secretkey))
	local lines = {}
	for _, x in ipairs(log_list) do
		local viewurl = make_href("/kol/viewlog", { logid = x.logid })
		local commenturl = make_href("/kolproxy/ascension-comments-form", { logid = x.logid, commentkey = x.commentkey, author = playername() })
		table.insert(lines, string.format([[Ascension %d: <a href="http://www.houeland.com%s">View log</a>, <a href="http://www.houeland.com%s">add comments</a>]], x.ascensionnumber, viewurl, commenturl))
	end
	return [[
<html>
<head>
</head>
<body>
<div id="loglist"></div>

]] .. table.concat(lines, "<br>") .. [[

</body>
</html>
]]
end)
