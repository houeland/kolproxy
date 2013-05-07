loadfile("scripts/base/base-lua-functions.lua")()
loadfile("scripts/base/kolproxy-core-functions.lua")()

return function(f_env)
	print(f_env)
	local pt = get_page("/plains.php")
	print("plains!")
	print(pt)
	print("done!")
end
