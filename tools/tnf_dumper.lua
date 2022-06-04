-- Stick this in autoexec, this is arguably the worst method you could use
local j_anticheat = game.ReplicatedStorage:WaitForChild("Game_Replicated", 9999999):WaitForChild("Game_Scripts", 999999):WaitForChild("ClientLoader"):WaitForChild("Loader")

local func = require(j_anticheat)
local old_func
local counter = 0
old_func = hookfunction(func, function(...)
    counter += 1
    local args = {...}
    writefile(tostring(counter)..".lua", args[1])
    return old_func(...)
end)
