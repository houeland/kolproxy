f = io.open("chat-dump.html", "a+")
f:write(tostring(text).."\n")
f:close()
