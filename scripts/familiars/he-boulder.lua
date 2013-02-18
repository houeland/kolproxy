add_printer("familiar message: heboulder", function()
	text = text:gsub([[([a-z]+ eye)]], function(eye)
		local colors = {
			["red eye"] = "red",
			["blue eye"] = "blue",
			["yellow eye"] = "goldenrod",
		}
		if colors[eye] then
			local point_skillid = nil
			for x in original_page_text:gmatch("<option.-</option>") do
-- 				print("opt", x)
				local v = x:match([[value="([0-9]-)".-Point at your opponent]])
				if v and tonumber(v) then
					point_skillid = tonumber(v)
					break
				end
			end
-- 			print("point skillid", point_skillid)
			if point_skillid then
				return [[<a href="]]..make_href("/fight.php", { action = "skill", whichskill = point_skillid })..[[" style="color: ]] .. colors[eye] .. [[">]] .. eye .. [[</a>]]
			else
				return [[<span style="color: ]] .. colors[eye] .. [[">]] .. eye .. [[</span>]]
			end
		end
	end)
end)

add_printer("/charpane.php", function() -- TODO: generalize! and work for normal?
	if text:match("<!%-%- charpane normal") then
	elseif text:match("<!%-%- charpane compact") then
		text = text:gsub([[(<td><img src=%b"" class=hand alt=%b"" title="Everything Looks [A-Za-z]+" onClick=%b''[^>]-></td>)(<td>%b()</td>)]], function(img, duration)
			local title = img:match([[title="([^"]+)"]])
			local colors = {
				["Everything Looks Red"] = "red",
				["Everything Looks Blue"] = "blue",
				["Everything Looks Yellow"] = "goldenrod",
			}
			if colors[title] then
				return img:gsub([[<td>]], [[<td style="background-color: ]] .. colors[title] .. [[">]]) .. duration:gsub([[<td>(%([0-9]-%))</td>]], [[<td style="color: ]] .. colors[title] .. [[">%1</td>]])
			end
		end)
	end
end)
