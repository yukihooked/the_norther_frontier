-- Garbage Collector
local garbage_collection = getgc(true)

local game_client = {}
for _, v in pairs(garbage_collection) do
    if typeof(v) == "table" then    
        if rawget(v, "randomStringsReceive") then -- Init Chunk (IDK why but game no longer uses this, so it will never appear)
            game_client.setup = v
        elseif rawget(v, "fillHunger") then -- Character Chunk
            game_client.integrity = v
        elseif rawget(v, "animateSnow") then
            game_client.stance = v
        elseif rawget(v, "dragCart") then -- Inventory Chunk
            game_client.operable = v
        elseif rawget(v, "getBackpackNameItem") then
            game_client.inventory = v
        elseif rawget(v, "_start") then
            game_client.interaction = v
        elseif rawget(v, "eat") then
            game_client.item = v
        elseif rawget(v, "setupStocks") then
            game_client.economy = v
        elseif rawget(v, "newHint") then -- UI Chunk
            game_client.interface = v
        elseif rawget(v, "animateProjectile") then -- Weapon Chunk
            game_client.weapon_fire = v
        elseif rawget(v, "addLootItem") then -- Player Chunk
            game_client.other_player = v
        end
    end
end

for i,v in next, getloadedmodules() do -- You can't grab misc directly from functions, so I just did this
    if v.Name == "Misc" then
        game_client.misc = require(v)
        break -- There's 2 Misc modules for no reason
    end
end


-- Newtwork Spy
local blocked_commands = {""}

local old_request = game_client.misc.Request
game_client.misc.Request = function(command, ...)
    local arguments = {...}

    local function print_table(tbl, depth)
        if typeof(tbl) == "table" then
            depth = depth or 0
            local d = ("\t"):rep(depth)
            local str = ""
            for i,v in next, tbl do
                str = str .. d .. tostring(i) .. '\t' .. tostring(v)..'\n'
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
