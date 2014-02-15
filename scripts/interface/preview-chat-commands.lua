register_setting {
	name = "preview chat commands",
	description = "Preview what chat commands will do",
	group = "chat",
	default_level = "standard",
}

local function preview_chat_commands(target)
	text = text:gsub("(</head>)", function(endtag)
		return [[
<script type="text/javascript">
var kolproxy_command_preview_timer
var kolproxy_command_last_content = ""
var kolproxy_command_regex = new RegExp("^/([^ ]*) (.*)")
var kolproxy_command_regex_bad = new RegExp("&&")
var kolproxy_command_preview_for = {}
kolproxy_command_preview_for["cast"] = true
kolproxy_command_preview_for["pull"] = true
kolproxy_command_preview_for["equip"] = true
kolproxy_command_preview_for["unequip"] = true
kolproxy_command_preview_for["closet"] = true
kolproxy_command_preview_for["uncloset"] = true
kolproxy_command_preview_for["eat"] = true
kolproxy_command_preview_for["drink"] = true
kolproxy_command_preview_for["chug"] = true
kolproxy_command_preview_for["use"] = true
kolproxy_command_preview_for["buy"] = true
kolproxy_command_preview_for["outfit"] = true
kolproxy_command_preview_for["aa"] = true
kolproxy_command_preview_for["autoattack"] = true
kolproxy_command_preview_for["fam"] = true
kolproxy_command_preview_for["familiar"] = true
kolproxy_command_preview_for["enthrone"] = true
kolproxy_command_preview_for["bjornify"] = true
kolproxy_command_preview_for["count"] = true
kolproxy_command_preview_for["cook"] = true
kolproxy_command_preview_for["mix"] = true
kolproxy_command_preview_for["smith"] = true
kolproxy_command_preview_for["paste"] = true
kolproxy_command_preview_for["make"] = true
kolproxy_command_preview_for["go"] = true
kolproxy_command_preview_for["shrug"] = true
kolproxy_command_preview_for["shrug!"] = true

function kolproxy_command_preview_triggered() {
	var line = $$("]]..target..[[").val()
	var m = line.match(kolproxy_command_regex)
	var should_hide = true
	if (m && !line.match(kolproxy_command_regex_bad)) {
		var cmd = m[1]
		var rest = m[2]
		if (kolproxy_command_preview_for[cmd]) {
			$$.get("/submitnewchat.php?graf=" + URLEncode("/" + cmd + "? " + rest) + "&j=1&pwd=" + pwdhash, function(data) {
				$$("#kolproxy_command_preview_div").show().html(data.output)
			}, "json")
			should_hide = false
		}
	}
	if (should_hide) {
		$$("#kolproxy_command_preview_div").hide()
	}
}

$$(function() {
$$("]]..target..[[").before('<div style="background-color: rgba(200, 200, 200, 0.9); display: none; padding: 5px; margin-bottom: 5px; position: relative; z-index: 1000; bottom: 2px;" id="kolproxy_command_preview_div"></div>')
setInterval(function() {
	var curcontent = $$("]]..target..[[").val()
	if (curcontent != kolproxy_command_last_content) {
		clearTimeout(kolproxy_command_preview_timer)
		kolproxy_command_preview_timer = setTimeout(kolproxy_command_preview_triggered, 450)
	}
	kolproxy_command_last_content = curcontent
	if (curcontent == "") {
		$$("#kolproxy_command_preview_div").hide()
	}
}, 100)
})

</script>
]] .. endtag
	end)
end

add_printer("/lchat.php", function()
	if not setting_enabled("preview chat commands") then return end
	preview_chat_commands("input[name=graf]")
end)

add_printer("/mchat.php", function()
	if not setting_enabled("preview chat commands") then return end
	preview_chat_commands("input[name=graf]")
end)
