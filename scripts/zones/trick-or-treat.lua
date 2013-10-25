add_printer("/choice.php", function()
	if not text:contains("<b>Trick or Treat!</b>") or not text:contains("/house_") then return end
	text = text:gsub("<div (id=house.-</div)", function(housediv)
		if housediv:contains([[class='faded']]) then return end
		if housediv:contains("/house_d") then
			return [[<div ]].. housediv:gsub([[style='position: absolute;]], [[%0 background-color: darkorange;]]):gsub("<img  src=", [[<img style="opacity: 0.5" src=]])
		elseif housediv:contains("/house_l") then
			return [[<div ]].. housediv:gsub([[style='position: absolute;]], [[%0 background-color: green;]]):gsub("<img  src=", [[<img style="opacity: 0.5" src=]])
		elseif housediv:contains("/starhouse") then
			return [[<div ]].. housediv:gsub([[style='position: absolute;]], [[%0 background-color: yellow;]]):gsub("<img  src=", [[<img style="opacity: 0.5" src=]])
		end
	end)
end)

--[[--
houses = {}
for whichhouse, img in pt:gmatch("whichhouse=([0-9]*)><img(.-)>") do
  houses[whichhouse] = img:match("otherimages/trickortreat/(house_.-.gif)")
end
print(tostring(houses))
--]]--
