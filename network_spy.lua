-- THIS IS DEPERECATED ILL UPDATE WHEN I GET AROUND TO IT

-- Game Client
local game_client = {}

for i,v in next, getloadedmodules() do -- You can't grab misc directly from functions, so I just did this
    if v.Name == "Misc" then
        game_client.misc = require(v)
        break -- There's 2 Misc modules for no reason
    end
end


-- Newtwork Spy
local blocked_commands = {"setZone"}

local old_request = game_client.misc.Request
game_client.misc.Request = function(command, ...)
    local arguments = {...}

    local function print_table(tbl, depth)
        if typeof(tbl) == "table" then
            depth = depth or 0
            local d = ("\t"):rep(depth)
            local str = ""
            for i,v in next, tbl do
                str = str .. d .. tostring(i) .. '\t' .. typeof(v)..": "..tostring(v)..'\n'
            end
            return str
        end
        return ""
    end
    
    
    if not table.find(blocked_commands, command) then
        rconsoleprint(command.."\t"..print_table(arguments))
    end

    return old_request(command, ...)
end
