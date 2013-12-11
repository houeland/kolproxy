local spell_estimators = {}
function add_spell_estimator(spellname, f)
	spell_estimators[spellname] = f
end

function estimate_spell(spellname)
	local f = spell_estimators[spellname]
	if f then
		return f()
	end
end

local function calcdmg(basedmgmin, basedmgmax, mystmult, cap, element)
	local bonusdmg = estimate_bonus("Spell Damage") + estimate_bonus("Damage to " .. element .. " Spells")
	local mystbonus = math.floor(mystmult * buffedmysticality())
	local mindmg = basedmgmin + mystbonus + bonusdmg
	local maxdmg = basedmgmax + mystbonus + bonusdmg
	if cap and mindmg > cap then mindmg = cap end
	if cap and maxdmg > cap then maxdmg = cap end
	local critchance = math.max(0, math.min(1, 0.09 + estimate_bonus("% Chance of Spell Critical Hit") / 100))
	local critdmgmult = 2
	local spellmult = math.max(0, 1 + estimate_bonus("Spell Damage %") / 100)

	local avgcritmult = (1 - critchance) + (critchance * critdmgmult)
	local avgsum = 0
	local avgcount = (basedmgmax - basedmgmin + 1)
	for i = basedmgmin, basedmgmax do
		local idmg = i + mystbonus + bonusdmg
		if cap and idmg > cap then idmg = cap end
		avgsum = avgsum + idmg * spellmult * avgcritmult
	end

	return { min = math.floor(mindmg * spellmult), avg = avgsum / avgcount, max = math.floor(maxdmg * spellmult * critdmgmult), element = element }
end

local function pastacap(cap)
	if pastathrall() and have_skill("Bringing Up the Rear") then
		return cap * 2
	else
		return cap
	end
end

local function pastamp(mp)
	if pastathrall() and have_skill("Thrall Unit Tactics") then
		return mp / 2
	else
		return mp
	end
end

local function pastatune(f)
	if have_intrinsic("Spirit of Garlic") then
		return {
			{ probability = 1, sources = { f("Stench") } }
		}
	end
	error "TODO: Not implemented yet."
end

local function pastahalftune(f)
	if have_intrinsic("Spirit of Garlic") then
		local dmg2 = f("Stench")
		dmg2.min = math.floor(dmg2.min / 2)
		dmg2.avg = math.floor(dmg2.avg / 2)
		dmg2.max = math.floor(dmg2.max / 2)
		local dmg1 = { min = dmg2.min, avg = dmg2.avg, max = dmg2.max, element = "Physical" }
		return {
			{ probability = 1, sources = { dmg1, dmg2 } }
		}
	end
	error "TODO: Not implemented yet."
end

add_spell_estimator("Cannelloni Cannon", function()
	local function f(e) return calcdmg(16, 32, 0.25, pastacap(50), e) end
	return { mpcost = pastamp(8), damage = pastatune(f) }
end)

add_spell_estimator("Stringozzi Serpent", function()
	local dmg = calcdmg(16, 32, 0.25, pastacap(75), "Physical")
	return { mpcost = pastamp(16), damage = { { probability = 1, sources = { dmg, dmg } } } }
end)

add_spell_estimator("Stuffed Mortar Shell", function()
	local function f(e) return calcdmg(32, 64, 0.5, nil, e) end
	return { mpcost = pastamp(8), damage = pastatune(f), special = true }
end)

add_spell_estimator("Weapon of the Pastalord", function()
	local function f(e) return calcdmg(32, 64, 0.5, nil, e) end
	return { mpcost = pastamp(32), damage = pastahalftune(f) }
end)

add_spell_estimator("Fearful Fettucini", function()
	local dmg = calcdmg(32, 64, 0.5, nil, "Spooky")
	return { mpcost = pastamp(32), damage = { { probability = 1, sources = { dmg } } } }
end)

function summarize_damage(dmgs)
	local summed_min = {}
	local summed_avg = {}
	local summed_max = {}
	for _, x in ipairs(dmgs) do
		for _, s in ipairs(x.sources) do
			summed_min[s.element] = (summed_min[s.element] or 0) + x.probability * s.min
			summed_avg[s.element] = (summed_avg[s.element] or 0) + x.probability * s.avg
			summed_max[s.element] = (summed_max[s.element] or 0) + x.probability * s.max
		end
	end
	return tojson(summed_min) .. " to " .. tojson(summed_max) .. " [avg " .. tojson(summed_avg) .. "]"
end

function debug_show_spell_estimates()
	local output = {}
	for name, f in pairs(spell_estimators) do
		local x = f()
		table.insert(output, string.format("%s (%d MP): %s", name, x.mpcost, summarize_damage(x.damage)))
	end
	return table.concat(output, "<br>\n")
end
