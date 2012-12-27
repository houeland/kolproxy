f = io.open("everything-log.txt", "a+")
f:write("requestpath["..tostring(requestpath).."] query["..tostring(requestquery).."]:" .. tostring(text).."\n")
f:close()
