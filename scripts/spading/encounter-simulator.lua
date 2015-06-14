register_setting {
	name = "track monster queues",
	description = "Track adventure zone monster queues",
	group = "other",
	default_level = "enthusiast",
	beta_version = true,
	hidden = true,
}

add_processor("/fight.php", function()
	ascension["zone monster queue"] = nil
	if not setting_enabled("track monster queues") then return end
	if true then return end -- Disabled for now because of Unicode encoding issues
	if requestpath == "/adventure.php" and fight.zone then
		local zoneid = get_zoneid(fight.zone)
		local zone = maybe_get_zonename(zoneid)
		if zoneid and zone then
			local queue = ascension["zone monster queue"] or {}
			local ztbl = queue["z" .. zoneid] or {}
			table.insert(ztbl, get_monstername() or "?")
			if #ztbl > 5 then
				table.remove(ztbl, 1)
			end
			--print("DEBUG fight zoneid", fight.zone, get_monstername(), maybe_get_zonename(fight.zone))
			--print("  monster queue:", tojson(ztbl))
			queue["z" .. zoneid] = ztbl
			ascension["zone monster queue"] = queue
		end
	end
end)

local function normalized_probabilities(tbl_p_unscaled)
	local p_sum = 0.0
	for _, p in pairs(tbl_p_unscaled) do
		p_sum = p_sum + p
	end
	local tbl_p_normalized = {}
	for x, p in pairs(tbl_p_unscaled) do
		tbl_p_normalized[x] = p / p_sum
	end
--	print("DEBUG normalized", tostring(tbl_p_normalized))
	return tbl_p_normalized
end

function compute_monster_probabilities(zonedata, state)
	local monster_p = {}
	for _, monster in ipairs(zonedata.monsters) do
		local monster_weight = nil
		local monster_count = 1
		if state:monster_trail_olfacted(monster) then
			monster_count = monster_count + 3
		end
		if state:monster_cream_olfacted(monster) then
			monster_count = monster_count + 2
		end
		if state:monster_banished(monster) then
			monster_count = monster_count - 1
		end

		if state:monster_trail_olfacted(monster) then
			monster_weight = 1
		elseif state:monster_cream_olfacted(monster) then
			monster_weight = 1
		elseif state:monster_in_queue(monster) then
			if state:monster_nosy_nose_whiffed(monster) then
				monster_weight = 0.5
			else
				monster_weight = 0.25
			end
		else
			monster_weight = 1
		end
		if monster_count > 0 then
			local reject_chance = 0.0
			monster_p[monster] = (monster_p[monster] or 0.0) + monster_weight * monster_count * (1.0 - reject_chance)
		end
	end
--	print("DEBUG monster_p", tostring(monster_p))
	return normalized_probabilities(monster_p)
end

function compute_noncombat_probabilities(zonedata, state)
	local noncombat_p = {}
	for noncombat, noncombatdata in pairs(zonedata.noncombats) do
		if state:noncombat_banished(noncombat) then
		elseif state:noncombat_in_queue(monster) then
			noncombat_p[noncombat] = 0.25
		else
			noncombat_p[noncombat] = 1
		end
	end
--	print("DEBUG noncombat_p", tostring(noncombat_p))
	return normalized_probabilities(noncombat_p)
end

function compute_next_state_probabilities(zonedata, state, policy)
	local adventure_chance = zonedata.adventure_chance - state:combat_frequency_modifier()

	local next_state_p = {}

	for monster, p in pairs(compute_monster_probabilities(zonedata, state)) do
		local next_state = table.copy(state)
		next_state:add_queue_monster(monster)
		policy:encountered_monster(next_state, monster)
		next_state:increment_turncount()
		next_state_p[next_state] = { p = p * (1 - adventure_chance), event = { type = "fight", name = monster, source = "monster" } }
	end

	for noncombat, p in pairs(compute_noncombat_probabilities(zonedata, state)) do
		local next_state = table.copy(state)
		next_state:add_queue_noncombat(noncombat)
		policy:encountered_noncombat(next_state, noncombat)
		next_state:increment_turncount()
		next_state_p[next_state] = { p = p * adventure_chance, event = { type = "adventure", name = noncombat, source = "noncombat" } }
	end

--	print("DEBUG next_state_p", tostring(next_state_p))

	local p_sum = 0.0
	for _, x in pairs(next_state_p) do
		p_sum = p_sum + x.p
	end
	for _, x in pairs(next_state_p) do
		x.p = x.p / p_sum
	end

	return next_state_p
end

local make_blank_state
local state_methods = {}
function state_methods:have_buff(buff)
	return (self.buffs[buff] or 0) > 0
end
function state_methods:add_buff(buff, duration)
	self.buffs[buff] = duration
end
function state_methods:increment_turncount()
	for x, d in pairs(self.buffs) do
		if d - 1 <= 0 then
			self.buffs[x] = nil
		else
			self.buffs[x] = d - 1
		end
	end
end
function state_methods:add_queue_monster(monster)
	table.insert(self.monster_queue, monster)
	if #self.monster_queue > 5 then
		table.remove(self.monster_queue, 1)
	end
end
function state_methods:add_queue_noncombat(noncombat)
	table.insert(self.noncombat_queue, noncombat)
	if #self.noncombat_queue > 5 then
		table.remove(self.noncombat_queue, 1)
	end
end
function state_methods:monster_in_queue(monster)
	for _, x in ipairs(self.monster_queue) do
		if x == monster then return true end
	end
	return false
end
function state_methods:noncombat_in_queue(noncombat)
	for _, x in ipairs(self.noncombat_queue) do
		if x == noncombat then return true end
	end
	return false
end
function state_methods:monster_banished(monster)
	return false
end
function state_methods:noncombat_banished(noncombat)
	return false
end
function state_methods:monster_trail_olfacted(monster)
	return self.flags.trailed == monster and self:have_buff("On the Trail")
end
function state_methods:set_monster_trail_olfacted(monster)
	self.flags.trailed = monster
	self:add_buff("On the Trail", 40)
end
function state_methods:monster_cream_olfacted(monster)
	return self.flags.creamed == monster
end
function state_methods:monster_nosy_nose_whiffed(monster)
	return self.flags.whiffed == monster
end
function state_methods:combat_frequency_modifier()
	return 0.0
end

make_blank_state = function()
	local s = {
		monster_queue = {},
		noncombat_queue = {},
		buffs = {},
		flags = {},
	}
	return setmetatable(s, { __index = state_methods })
end

encounter_simulator_make_blank_state = make_blank_state

local function make_policy(settings)
	local policy = {}
	function policy:encountered_monster(state, monster)
		if not state:have_buff("On the Trail") and monster == settings.olfaction_target then
			state:set_monster_trail_olfacted(monster)
		end
	end
	function policy:encountered_noncombat(s, monster)
	end
	return policy
end

function monte_carlo_simulate_adventure_encounters(settings)
	local policy = make_policy(settings)
	local state = make_blank_state()
	local recorder = setmetatable({}, { __index = settings.recorder })
	recorder:initialize(settings)
	for i = 1, settings.turns do
		local c = math.random()
		local accumul_c = 0.0
--		print("DEBUG doing turn", i)
		for next_state, x in pairs(compute_next_state_probabilities(settings.zonedata, state, policy)) do
			accumul_c = accumul_c + x.p
--			print("DEBUG add p", p, "=>", accumul_c, "vs", c)
			if accumul_c > c then
				state = next_state
				recorder:record_event(x.event, state)
				break
			end
		end
	end
	return recorder:output()
end

encounter_simulator_recorders = {}

encounter_simulator_recorders.do_nothing = {
	initialize = function(self, settings)
	end,
	record_event = function(self, event, state)
	end,
	output = function(self)
	end,
}

encounter_simulator_recorders.record_names = {
	initialize = function(self, settings)
		self.events = {}
	end,
	record_event = function(self, event, state)
		table.insert(self.events, event.name)
	end,
	output = function(self)
		return self.events
	end,
}

encounter_simulator_recorders.count_olfacted = {
	initialize = function(self, settings)
		self.trailed = 0
		self.total = 0
		self.target = settings.olfaction_target
	end,
	record_event = function(self, event, state)
		if event.type == "fight" then
			if event.name == self.target then
				self.trailed = self.trailed + 1
			end
			self.total = self.total + 1
		end
	end,
	output = function(self)
		return self.trailed / self.total
	end
}

function test_adventure_encounter_simulation()
	local output = monte_carlo_simulate_adventure_encounters {
		turns = 10,
		zonedata = {
			monsters = { "dairy goat", "drunk goat", "sabre-toothed goat" },
			noncombats = {},
			adventure_chance = 0.0,
		},
		olfaction_target = "dairy goat",
		recorder = encounter_simulator_recorders.record_names,
	}
	return tojson(output)
end

local function exp_statespace_matrix(mtr)
	-- TODO: renormalize!
	local newmtr = {}
	for xrow, xds in pairs(mtr) do
		local newrowp = {}
		for _, xd in ipairs(xds) do
			local trg = xd.target
			for _, zd in ipairs(mtr[trg]) do
				local zdesc = zd.target
				local zweight = xd.p * zd.p
				newrowp[zdesc] = (newrowp[zdesc] or 0) + zweight
			end
		end

		local newrow = {}
		for t, p in pairs(newrowp) do
			table.insert(newrow, { target = t, p = p })
		end
		newmtr[xrow] = newrow
	end
	return newmtr
end

function test_encounter_statespace()
	local settings = {
		turns = 10,
		zonedata = {
			monsters = { "dairy goat", "drunk goat", "sabre-toothed goat" },
			noncombats = {},
			adventure_chance = 0.0,
		},
		olfaction_target = "none",
		recorder = encounter_simulator_recorders.do_nothing,
	}

	local policy = make_policy(settings)
	local recorder = setmetatable({}, { __index = settings.recorder })
	recorder:initialize(settings)
	local reverse_matrix_lookup = {}
	local matrix = {}
	local queue = { make_blank_state() }
	local startdesc = tojson(queue[1])
	matrix[startdesc] = {}
	reverse_matrix_lookup[startdesc] = { state = queue[1], event = { name = "START!" } }
	while #queue > 0 do
		local state = table.remove(queue)
		local qtbl = matrix[tojson(state)]
		for next_state, x in pairs(compute_next_state_probabilities(settings.zonedata, state, policy)) do
			local desc = tojson(next_state)
			table.insert(qtbl, { target = desc, p = x.p })
			if not matrix[desc] then
				table.insert(queue, next_state)
				matrix[desc] = {}
				reverse_matrix_lookup[desc] = { state = next_state, event = x.event }
			end
		end
	end

	local function printmtr_full(mtr, i)
		print("+++", i)
		for x, y in pairs(mtr) do
			print("", tojson(x))
			for _, z in ipairs(y) do
				print("", "", tojson { p = z.p, event = reverse_matrix_lookup[z.target].event.name })
			end
		end
		print("---", i)
	end

	local function printmtr_collapse(mtr, i)
		local chances = {}
		for _, z in ipairs(mtr[startdesc]) do
			local which = reverse_matrix_lookup[z.target].event.name
			chances[which] = (chances[which] or 0) + z.p
		end
		print(i, tojson(chances))
	end

	local printmtr = printmtr_collapse

	for i = 1, 10 do
		printmtr(matrix, i)
		matrix = exp_statespace_matrix(matrix)
	end

	return table.keys(matrix)
end

function test_amc_banish_internal(monsterlist)
	local zonedata = {
		monsters = monsterlist,
		noncombats = {},
		adventure_chance = 0.0,
	}
	local policy = make_policy {}
	local blank = make_blank_state()
	local ptbl = {}
	ptbl[tojson(blank)] = { p = 1.0, state = blank }
	local finish_in_X = {}
	for i = 1, 20 do
		local newptbl = {}
		for _, s in pairs(ptbl) do
			for next_state, x in pairs(compute_next_state_probabilities(zonedata, s.state, policy)) do
				if x.event.name == "quest gremlin" then
					finish_in_X[i] = (finish_in_X[i] or 0) + x.p * s.p
				else
					local desc = tojson(next_state)
					if not newptbl[desc] then
						newptbl[desc] = { p = 0.0, state = next_state }
					end
					newptbl[desc].p = newptbl[desc].p + x.p * s.p
				end
			end
		end
		ptbl = newptbl
	end
	return finish_in_X
end

function test_amc_banish()
	local function get_turns(tbl)
		local sum = 0.0
		local prodsum = 0.0
		for x, y in ipairs(tbl) do
			prodsum = prodsum + x * y
			sum = sum + y
		end
		return prodsum / sum
	end
	local unbanished = test_amc_banish_internal { "AMC", "dummy gremlin", "non-quest gremlin", "quest gremlin" }
	local banished = test_amc_banish_internal { "dummy gremlin", "non-quest gremlin", "quest gremlin" }
	return { unbanished = get_turns(unbanished), banished = get_turns(banished) }
end
