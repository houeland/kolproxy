--~ 	local resolve_list = {}
--~ 	local entered = {}
--~ 	local function compile_skill(name, extrain)
--~ 		for x, description in pairs(resolve_list[name]) do
--~ 			local passed_filters = true

--~ 			local filters = {}

--~ 			filters["round"] = (function(test)
--~ 				test = string.gsub(test, " ", "")
--~ 				local roundmin, roundmax = string.match(test, "^([0-9]+)%-(([0-9]+))$")
--~ 				if not roundmin then
--~ 					roundmin = string.match(test, "^([0-9]+)%+$")
--~ 					roundmax = "1000"
--~ 				end
--~ 				if not roundmin then
--~ 					roundmin = string.match(test, "^([0-9]+)$")
--~ 					roundmax = roundmin
--~ 				end
--~ 				if combat_round then
--~ 	--~ 				print("testing round", name, combat_round, roundmin, roundmax)
--~ 					if combat_round < tonumber(roundmin) or combat_round > tonumber(roundmax) then
--~ 						return false
--~ 					end
--~ 				else
--~ 					return false
--~ 				end
--~ 			end)

--~ 			filters["zone"] = (function(test)
--~ 				local z = tonumber(string.match(test, "^([0-9]+)$"))
--~ 	-- 			print("testing zone", zone, z)
--~ 				if adventure_zone ~= z then
--~ 					return false
--~ 				end
--~ 			end)

--~ 			filters["monster"] = (function(test)
--~ 				if monster_name == test then
--~ 					return true
--~ 				else
--~ 					return false
--~ 				end
--~ 			end)

--~ 			filters["flag"] = (function(test)
--~ 				local flag, value = string.match(test, "^(.-):(.+)$")
--~ 				if flag and value then
--~ 					if get_fight_state(flag) ~= value then
--~ 						return false
--~ 					end
--~ 				else
--~ 					print("Error parsing flag{}:", test)
--~ 				end
--~ 			end)

--~ 			extra = extrain

--~ 			filters["once"] = (function(test)
--~ 				onceflag = "once." .. test
--~ 				v = get_fight_state(onceflag)
--~ 				if v == "" then
--~ 					if not extra then extra = {} end
--~ 					extra["once flag"] = onceflag
--~ 					return true
--~ 				else
--~ 					return false
--~ 				end
--~ 			end)

--~ 			filters["icon"] = (function(test)
--~ 				if not extra then extra = {} end
--~ 				extra["icon"] = test
--~ 			end)

--~ 			filters["first"] = (function(test)
--~ 				if not extra then extra = {} end
--~ 				extra["first"] = test
--~ 				return true
--~ 			end)
--~ 			filters["second"] = (function(test)
--~ 				if not extra then extra = {} end
--~ 				extra["second"] = test
--~ 				return true
--~ 			end)

--~ 			filters["r"] = filters["round"]
--~ 			filters["z"] = filters["zone"]
--~ 			filters["m"] = filters["monster"]

--~ 			for code, rawtest in string.gmatch(description, "([a-z]+) *(%b{})") do
--~ 	--~ 			print(name, code, rawtest)
--~ 				if filters[code] then
--~ 					local test = string.match(rawtest, "^{ *(.-) *}$") -- TODO-future: redo regex, .- and  *
--~ 	--~ 				print("filtertest", code, test, "=>", filters[code](test))
--~ 					if filters[code](test) == false then
--~ 						passed_filters = false
--~ 					end
--~ 				else
--~ 					print("Error testing filter:", code)
--~ 					passed_filters = false
--~ 				end
--~ 			end

--~ 			if passed_filters then
--~ 				local skillname = string.gsub(description, " *[a-z]+ *%b{} *", "")
--~ 	--~ 			print("skill", name, description, "["..skillname.."]")
--~ 				if resolve_list[skillname] and not entered[skillname] then
--~ 					entered[skillname] = true
--~ 					local s, extra = process_skill(skillname, extra)
--~ 					if s then return s, extra end
--~ 				end
--~ 				if skills[skillname] then
--~ 	--~ 				print(" => ", skillname, printstr(extra))
--~ 					return skillname, extra
--~ 				end
--~ 			end
--~ 		end
--~ 	end
