-- Stick ths in autoexec, this is the better method because it abuses FIOne Vulnerability
local old_string_sub = string.sub
local counter = 0
hookfunction(string.sub, function(...)
    counter += 1
    local args = {...}
    writefile(tostring(counter)..".lua", args[1])
    return old_string_sub(...)
end)
