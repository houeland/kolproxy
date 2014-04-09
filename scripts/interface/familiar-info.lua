local familiar_info_f = {}

-- TODO: look up by familiarid, use get_familiarid() for input verification

function track_familiar_info(which, f)
	if not familiar_info_f[which] then
		familiar_info_f[which] = {}
	end
	table.insert(familiar_info_f[which], f)
end

function get_tracked_familiar_info(which)
	local results = {}
	for _, f in ipairs(familiar_info_f[which] or {}) do
		local v = f()
		if v then
			table.insert(results, v)
		end
	end
	return results
end
