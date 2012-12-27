local colorMap = {
	water = "blue",
	nature = "green",
	fire = "red",
	lightning = "orange",
}

add_printer("/inventory.php", function()
	for x, y in pairs(get_stone_sphere_status().altars or {}) do
		text = text:gsub(y..[[ stone sphere]], [[%0 <span style="color:]]..colorMap[x]..[[;font-weight:bold">{&nbsp;]]..x..[[&nbsp;}</span>]])
	end
end)

add_printer("/fight.php", function()
	local sphereData = get_stone_sphere_status()
	local javascriptReplace = ""
	
	if sphereData.altars then
		for x, y in pairs(sphereData.altars) do
			text = text:gsub([[You hold the ]]..y..[[ stone sphere]], [[%0 <span style='font-weight:bold;color:]]..colorMap[x]..[[;'>{ ]]..x..[[ }</span>]])
			javascriptReplace = javascriptReplace .. [[$("#item_]]..get_itemid(y .. " stone sphere")..[[ span").html("]]..y..[[ stone sphere <span style='font-size:1.0em;font-weight:bold;color:]]..colorMap[x]..[[;'>{&nbsp;]]..x..[[&nbsp;}</span> (1)");]]
		end
	end

	if javascriptReplace ~= "" then
		text = text:gsub([[<script src='http://images.kingdomofloathing.com/scripts/actionbar.(%d+).js'></script>]],
[[%0<script type="text/javascript">
	function colorizeSpheres() {
		]]..javascriptReplace..[[
	}
	
	window.onload = colorizeSpheres;
</script>
]])
	end
end)

-- add_printer("/hiddencity.php", function()
-- 	local altars = {
-- 		["altar1.gif"] = "lightning",
-- 		["altar2.gif"] = "water",
-- 		["altar3.gif"] = "fire",
-- 		["altar4.gif"] = "nature",
-- 	}	
-- 	local sphereData = get_stone_sphere_status()
-- 	
-- 	if sphereData.altars then
-- 		for altarName,element in pairs(altars) do
-- 			if text:match(altarName) then
-- 				if sphereData.altars[element] and text:match([[option]]) then
-- 					local replaceText = text:match([[%b<>]]..sphereData.altars[element])
-- 					if replaceText then
-- 						local option = replaceText:match([[option value='%d+']])
-- 						text = text:gsub(option, option:gsub("stone sphere", "%0 {&nbsp;"..element.."&nbsp;}") .. " " .. [[style="font-weight:bold;color:]]..colorMap[element]..[[;" ]])
-- 						text = text:gsub(sphereData.altars[element]..[[ stone sphere]], [[%0 {&nbsp;]].. element ..[[&nbsp;}]])
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end)
