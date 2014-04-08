local familiar_info_f = {}

function track_familiar_info(which, f)
    table.insert(familiar_info_f, { f = f, which = which })
end

function maybe_get_tracked_familiar_info(which)
    local results = {}
    for _, faminfo in ipairs(familiar_info_f) do
       if faminfo.which ~= which then
       else
	   local v = faminfo.f()
	   if v then
	       table.insert(results, v)
	   end
       end
    end
    return results
end

