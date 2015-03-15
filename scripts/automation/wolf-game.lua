function do_wolfgame_fight(initialpt)
	local monster = initialpt:match([[<span id='monname'>.-</span>]])
	print("INFO: wolf fight", monster)
	local mesmereyesed = not have_equipped_item("Mesmereyes&trade; contact lenses")
	local hit = false
	local thawed = not have_equipped_item("double-ice cap")
	local vibrated = not have_equipped_item("shock belt")
	local function do_round(pt)
		local action = nil
		local monsterhp = pt:match([["hp":"([0-9,]+)"]])
		if monsterhp then
			monsterhp = monsterhp:gsub(",", "")
			monsterhp = tonumber(monsterhp)
		end
		local breath, capacity = pt:match(">Breath: ([0-9,]+)/([0-9,]+)<")
		breath, capacity = tonumber(breath), tonumber(capacity)
		local offense = tonumber(pt:match(">Offense: ([0-9,]+)<"))
		if pt:contains("lost in your eyes") then
			mesmereyesed = true
		end
		if pt:match("You lose [0-9,]+ hit points") then
			hit = true
		end
		if pt:contains("thaw") then
			thawed = true
		end
		if pt:contains("stops vibrating") then
			vibrated = true
		end
		if pt:contains("inner wolf is exhausted") then
			print("INFO: lost wolf fight")
			return false, pt
		elseif pt:contains("clean up this town") then
			print("INFO: won wolf fight")
			return true, pt
		elseif pt:contains("puff dismissively") then
			print("INFO: skipped wolf fight")
			return true, pt
		elseif monster:contains("brick") then
			if breath == capacity then
				action = "blow"
			elseif breath <= 1 then
				action = "huff"
			elseif monsterhp and monsterhp <= offense * 10 then
				if not hit and not mesmereyesed then
					action = "huff"
				elseif hit and (not thawed or not vibrated) then
					action = "huff"
				else
					action = "blow"
				end
			else
				action = "blow"
			end
		else
			if breath == capacity then
				action = "puff"
			elseif not hit and not mesmereyesed then
				action = "huff"
			elseif hit and (not thawed or not vibrated) then
				action = "huff"
			elseif breath <= 1 then
				action = "huff"
			else
				action = "puff"
			end
		end
		print("INFO: wolf round", action, tojson { breath = breath, monsterhp = monsterhp, hp = hp(), hit = hit, thawed = thawed, vibrated = vibrated })
		local skillids = { huff = 7190, puff = 7191, blow = 7192 }
		local newpt = post_page("/fight.php", { whichskill = skillids[action], action = "skill" })
		return do_round(newpt)
	end
	return do_round(initialpt)
end

function do_wolfgame()
	local pt, pturl = get_page("/fight.php")
	if not pturl:contains("fight.php") and hp() == maxhp() then
		pt, pturl = get_place("ioty2014_wolf", "wolf_houserun")
	end
	if not pturl:contains("fight.php") then
		return pt, pturl
	end
	local ok, result = do_wolfgame_fight(pt)
	if ok then
		return do_wolfgame()
	end
	return result
end

local automate_wolfgame_href = add_automation_script("automate-wolfgame", do_wolfgame)

add_printer("/place.php", function()
	if not text:contains("Inner Wolf Status") then return end
	text = text:gsub([[(</table></center>)(</body>)]], [[%1<center><a href="]]..automate_wolfgame_href { pwd = session.pwd }..[[" style="color: green">{ Automate houses }</a></center>%2]])
end)
