local damageitem = "divine can of silly string"

function macro_dis()
  return [[
]] .. COMMON_MACROSTUFF_START(20, 40) .. [[

]] .. noodles_action() .. [[

if (monstername Thorax) || (monstername Bat in the Spats)
  while !times 20
    use clumsiness bark
  endwhile
endif

if (monstername Mammon the Elephant) || (monstername The Large-Bellied Snitch)
  while !times 20
    use dangerous jerkcicle, dangerous jerkcicle
  endwhile
endif

if (monstername Thug 1 and Thug 2)
  while !times 20
    use jar full of wind, jar full of wind
  endwhile
endif

if (monstername Terrible Pinch)
  while !times 20
    use jar full of wind, ]] .. damageitem .. [[

  endwhile
endif

if (monstername The Thing with No Name)
  while !times 20
]] .. serpent_action() .. [[
  endwhile
endif

while !times 5
]] .. serpent_action() .. [[
endwhile

]]
end

local script = nil

local function maybe_pull_item(name, amount)
	amount = amount or 1
	if count(name) < amount then
		async_post_page("/storage.php", { action = "pull", whichitem1 = get_itemid(name), howmany1 = amount - count(name), pwd = session.pwd, ajax = 1 })
		if amount > 1 and count(name) < amount then
			critical("Couldn't pull " .. tostring(amount) .. "x " .. tostring(name))
		end
	end
end

local function automate_dis_zone(zoneid)
	local noncombatchoices = {
		["Foreshadowing Demon!"] = "Head towards all the trouble",
		["You Must Choose Your Destruction!"] = "Follow the fists",
		["A Test of Your Mettle"] = "Sure! Let's go kick its ass into next week!",
		["A Maelstrom of Trouble"] = "Head Toward the Peril",
		["To Get Groped or Get Mugged?"] = "Head Toward the Perv",
		["A Choice to be Made"] = "Of course, little guy! Let's leap into the fray!",
		["You May Be on Thin Ice"] = "Fight Back Your Chills",
		["Some Sounds Most Unnerving"] = "Infernal Pachyderms Sound Pretty Neat",
		["One More Demon to Slay"] = "Sure! I'll be wearing its guts like a wreath!",
	}
	script.ensure_buffs { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }
	script.heal_up()
	script.ensure_mp(100)
	result, resulturl, advagain = autoadventure {
		zoneid = zoneid,
		macro = macro_dis(),
		noncombatchoices = noncombatchoices,
	}
end

local folios_used = 0

local dis_href = add_automation_script("automate-suburbandis", function()
	if autoattack_is_set() then
		stop "Disable your autoattack. The Dis script will handle (most) combats automatically."
	end
	script = get_automation_scripts()
	maybe_pull_item("ring of conflict")
	maybe_pull_item("sea salt scrubs")
	maybe_pull_item("Space Trip safety headphones")
	maybe_pull_item("clumsiness bark", 20)
	maybe_pull_item("jar full of wind", 20)
	maybe_pull_item("dangerous jerkcicle", 40)
	maybe_pull_item(damageitem, 40)
	script.want_familiar "Slimeling even in fist"
	equip_item("sea salt scrubs", "shirt")
	equip_item("ring of conflict", "acc1")
	equip_item("Space Trip safety headphones", "acc2")
	local function run_turns()
		advagain = false
		if advs() == 0 then
			stop "Out of adventures."
		end
		if not buff("Dis Abled") then
			if folios_used < 2 then
				folios_used = folios_used + 1
				maybe_pull_item("devilish folio")
				use_item("devilish folio")
			end
			if not buff("Dis Abled") then
				stop "Use another devilish folio."
			end
		end
		if not have("vanity stone") or not have("furious stone") then
			-- grove: 277
			automate_dis_zone(277)
		elseif not have("lecherous stone") or not have("jealousy stone") then
			-- maelstrom: 278
			automate_dis_zone(278)
		elseif not have("avarice stone") or not have("gluttonous stone") then
			-- glacier: 279
			automate_dis_zone(279)
		else
			script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }
			script.heal_up()
			script.ensure_mp(100)
			local pt, url = post_page("/suburbandis.php", { pwd = session.pwd, action = "dothis" })
			result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_dis())
			return result, resulturl
		end
		if advagain then
			return run_turns()
		else
			return result, resulturl
		end
	end
	return run_turns()
end)

add_printer("/suburbandis.php", function()
	if not setting_enabled("enable turnplaying automation") or ascensionstatus() ~= "Aftercore" then return end
	text = text:gsub([[(</table></center>)(</body>)]], [[%1<center><a href="]]..dis_href { pwd = session.pwd }..[[" style="color: green">{ Automate Dis }</a></center>%2]])
end)
