-- Services
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService") 
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Local
local local_player = Players.LocalPlayer

local mouse = local_player:GetMouse()

-- Drawings 
local fov_circle
local fov_target

-- Status
local cheat_client = {
    config = {
        aim = {
            enabled = true,
            fov = 100,
            max_distance = 500,
            ignore_fov = true,
            silent = true,
            non_sticky = true,
            aim_key = Enum.KeyCode.LeftControl
        },
        esp = {
            player = {
                enabled = true,
            },
            entity = {
                ore = true,
                npc = true,
                animal = true,
                dropped = true,
            },
        },
        misc = {
            mod_notification = true,
        },
        exploits = {
            infinite_stamina = true,
            infinite_warmth = true,
            infinite_hunger = true,

            force_respawn = true,
            no_down = false,
            spoof_snowshoes = true,
            hook_walkspeed = false,
            walkspeed = 30,

            instant_interaction = true,

            gun_exploits = {
                enabled = true,
                no_spread = true,
                modify_range = true,
                max_range = 500, -- This is probably your max fire distance, increase at your own risk
            },
        },
    },

    status = {
        current_target = nil,
    },

    hooks = {},
    connections = {},
    drawings = {},
}

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

for i,v in next, getloadedmodules() do
    if v.Name == "Misc" then
        game_client.misc = require(v)
        break
    end
end

-- Functions
do -- Utility
    function cheat_client:handle_drawing(type, properties)
        local drawing = Drawing.new(type)
        for i,v in next, properties do
            drawing[i] = v
        end
        return drawing
    end
    
    function cheat_client:get_character(player)
        return Workspace.World.Characters:FindFirstChild(player)
    end
    
    function cheat_client:get_camera(player)
        return Workspace.CurrentCamera
    end

    function cheat_client:unload()
        
    end

    function cheat_client:handle_object(type, properties)
        local object = Instance.new(type)
        for i,v in next, properties do
            object[i] = v
        end
        return object
    end
end

do -- Aim
    function cheat_client:calculate_target()
        if local_player.Character then
            local max_distance = math.huge
            local target 
            local magnitude
            local current_character
            for _,v in next, Players:GetPlayers() do
                if v ~= local_player then
                    current_character = cheat_client:get_character(v.Name)
                    if current_character then
                        if current_character:FindFirstChild("Torso") then
                            if local_player:DistanceFromCharacter(current_character.Torso.Position) < cheat_client.config.aim.max_distance then
                                local camera = cheat_client:get_camera()
                                local screen_position, on_screen = camera:WorldToViewportPoint(current_character.Torso.Position)
                                if on_screen then
                                    magnitude = (fov_circle.Position - Vector2.new(screen_position.X, screen_position.Y)).magnitude
                                    if (magnitude < fov_circle.Radius) or cheat_client.config.aim.ignore_fov then
                                        if magnitude < max_distance then
                                            max_distance = magnitude
                                            target = current_character
                                        end
                                    end
                                    current_character = nil
                                else
                                    current_character = nil
                                end
                            end
                        end
                    end
                end
            end
            if UserInputService:IsKeyDown("LeftControl") then
                cheat_client.status.current_target = target
            else
                cheat_client.status.current_target = nil
            end
        end
    end
end

do -- ESP
end

do -- Misc
    function cheat_client:detect_mod(player)
        if player:GetRankInGroup(10800343) > 1 then
            local player_icon = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            local player_rank = player:GetRoleInGroup(10800343)

            local notification_bind = self:handle_object("BindableFunction", {
                OnInvoke = function(value)
                    if value == "Log" then
                        local_player:Kick("Moderator detected, client initiated disconnect")
                    end
                end
            })

            StarterGui:SetCore("SendNotification", {
                Title = "Moderator Detected",
                Text = ("Name: %s\nRole: %s"):format(player.Name, player_rank),
                Icon = player_icon,
                Duration = 300, -- 5 minutes
                Button1 = "Log",
                Button2 = "Dismiss",
                Callback = notification_bind
            })

            notification_bind:Destroy()
        end
    end
end

do --Exploits
    function cheat_client:force_respawn()
        if game_client.stance and cheat_client.config.exploits.force_respawn then
            game_client.stance:respawn()
        end
    end
end

-- Hooks
do 
    do -- integrity hooks
        local old_set_warmth = game_client.integrity.setWarmth
        local old_set_stamina = game_client.integrity.setStamina
        local old_set_hunger = game_client.integrity.setHunger

        game_client.integrity.setWarmth = function(self, warmth)
            if cheat_client.config.exploits.infinite_warmth then
                warmth = 6000 -- This get's clamped anyways
                return old_set_warmth(game_client.integrity, warmth)
            else
                return old_set_warmth(game_client.integrity, warmth)
            end
        end

        game_client.integrity.setStamina = function(self, stamina)
            if cheat_client.config.exploits.infinite_stamina then
                stamina = 100 -- This get's clamped anyways
                return old_set_stamina(game_client.integrity, stamina)
            else
                return old_set_stamina(game_client.integrity, stamina)
            end
        end

        game_client.integrity.setHunger = function(self, hunger)
            if cheat_client.config.exploits.infinite_stamina then
                hunger = 200 -- This get's clamped anyways
                return old_set_hunger(game_client.integrity, hunger)
            else
                return old_set_hunger(game_client.integrity, hunger)
            end
        end
    end

    do -- interaction hooks
        local old_start_interaction = game_client.interaction._start

        game_client.interaction._start = function(object)
            if cheat_client.config.exploits.instant_interaction then
                if object.objectTargetting or object.deployValid then
                    object.interacting = true
                    object:request()
                end
            else
                return old_start_interaction(object)
            end
        end
    end

    do -- stance hooks
        local old_update_walkspeed = game_client.stance.updateWalkSpeed

        game_client.stance.updateWalkSpeed = function(self)
            if cheat_client.config.exploits.hook_walkspeed then
                game_client.setup.humanoid.WalkSpeed = cheat_client.config.exploits.walkspeed
                game_client.setup.humanoid.JumpPower = 50
            else
                old_update_walkspeed(self)
            end
        end
        -- For future exploiting

        local old_set_down = game_client.stance.down

        game_client.stance.down = function(self)
            if cheat_client.config.exploits.no_down then
                return
            else
                old_set_down(self)
            end
        end
    end

    do -- inventory hooks
        local old_get_equipped_type_item = game_client.inventory.getEquippedTypeItem

        game_client.inventory.getEquippedTypeItem = function(self, key)
            if cheat_client.config.exploits.spoof_snowshoes and key == "snowshoes" then
                return true    
            else
                return old_get_equipped_type_item(self, key)
            end
        end
        
    end

    do -- weapon hook
        local old_ray = game_client.weapon_fire.ray

        game_client.weapon_fire.ray = function(self, weapon)
            if cheat_client.config.exploits.gun_exploits.enabled then
                local weapon_clone = weapon
                if cheat_client.config.exploits.gun_exploits.no_spread then
                    weapon_clone.stats.weapon.spread = 0
                end
                if cheat_client.config.exploits.gun_exploits.modify_range then
                    weapon_clone.stats.weapon.maxRange = cheat_client.config.exploits.gun_exploits.max_range
                end
                return old_ray(self, weapon_clone)
            else
                return old_ray(self, weapon)
            end
        end

        local index_hook
        index_hook = hookmetamethod(game, "__index", function(self, index)
            if not checkcaller() then
                if self == mouse and index == "Hit" then
                    if cheat_client.status.current_target then
                        return cheat_client.status.current_target.Torso.CFrame
                    end
                end
            end
            return index_hook(self, index)
        end)

        

        -- Insert Instant Reload, it's not that hard
    end
end

-- Init
do
    
    game_client.interface:newHint(("Welcome %s, to Yukihook."):format(local_player.Name))

    if cheat_client.config.misc.mod_notification then
        for _,v in next, Players:GetPlayers() do
            task.spawn(function() -- I need a new thread cause this uses web stuff
               cheat_client:detect_mod(v)
            end)
        end
    end

    fov_circle = cheat_client:handle_drawing("Circle", {
        Radius = cheat_client.config.aim.fov,
        Transparency = 1,
        Filled = false,
        Thickness = 1,
        Visible = true,
        Color = Color3.fromRGB(255,255,255),
    })

    fov_target = cheat_client:handle_drawing("Circle", {
        Radius = 4,
        Transparency = 1,
        Thickness = 1,
        Filled = true,
        Color = Color3.fromRGB(255,0,0),
    })
end

-- Connections
RunService.RenderStepped:Connect(function()
    cheat_client:calculate_target()
    fov_circle.Position = UserInputService:GetMouseLocation()
    fov_circle.Color = cheat_client.status.current_target and Color3.fromRGB(255,0,0) or Color3.fromRGB(255, 255, 255)
    fov_circle.Visible = not cheat_client.config.aim.ignore_fov and true or false
    if cheat_client.status.current_target then
        local camera = cheat_client:get_camera()
        local screen_position, on_screen = camera:WorldToViewportPoint(cheat_client.status.current_target.Torso.Position)
        if on_screen then
            fov_target.Position = Vector2.new(screen_position.X, screen_position.Y)
            fov_target.Visible = true
        end
    else
        fov_target.Visible = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    -- Force Respawn lol
    if input.KeyCode == Enum.KeyCode.F8 then
        cheat_client:force_respawn()
    end
end)

Players.PlayerAdded:Connect(function(player)
    if cheat_client.config.misc.mod_notification then
        task.spawn(function() -- I need a new thread cause this uses web stuff
            cheat_client:detect_mod(player)
        end)
    end
end)
