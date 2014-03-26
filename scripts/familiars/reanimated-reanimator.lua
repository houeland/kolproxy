add_processor("familiar message: reanimator", function()
	if text:contains("nods and begins calculating how much glow-juice he'll need") then
		start_wandering_copied_monster(3)
	end
end)

add_processor("/fight.php", function()
	if text:contains("You stop for a moment because you feel the hairs on the back of your neck stand up") then
		encountered_wandering_copied_monster()
	end
end)

function update_reanimated_reanimator_bonuses_cache()
	local pt = get_page("/main.php", { talktoreanimator = 1 })
	local parts = pt:match("including:<br><b>.-</b>") or ""
	local legs = tonumber(parts:match(">([0-9]*) leg")) or 0
	local skulls = tonumber(parts:match(">([0-9]*) skull")) or 0
	session["familiar.reanimator cached bonuses up-to-date"] = true
	session["familiar.reanimator cached bonuses"] = { legs = legs, skulls = skulls }
end

function reset_reanimated_reanimator_bonuses_cache()
	session["familiar.reanimator cached bonuses up-to-date"] = nil
end

function estimate_reanimated_reanimator_bonuses()
	local cached = session["familiar.reanimator cached bonuses"] or {}
	local bonuses = make_bonuses_table {}
	-- TODO: volleyball bonus
	bonuses = bonuses + { ["Stats Per Fight"] = volleyball_bonus(buffedfamiliarweight()) }
	if (cached.legs or 0) >= 5 then bonuses = bonuses + { ["Item Drops from Monsters"] = fairy_bonus(cached.legs) } end
	if (cached.skulls or 0) >= 5 then bonuses = bonuses + { ["Meat from Monsters"] = leprechaun_bonus(cached.skulls) } end
	return bonuses
end

add_processor("/familiar.php", function()
	reset_reanimated_reanimator_bonuses_cache()
end)

add_processor("/fight.php", function()
	if familiar("Reanimated Reanimator") then
		reset_reanimated_reanimator_bonuses_cache()
	end
end)

add_automator("all pages", function()
	if familiar("Reanimated Reanimator") and not locked() and not session["familiar.reanimator cached bonuses up-to-date"] then
		update_reanimated_reanimator_bonuses_cache()
	end
end)
