-- Services
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
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
            global = true,
            player = {
                enabled = true,
                max_distance = 1000,
            },
            ore = {
                enabled = true,
                max_distance = 500,
            },
            animal = {
                enabled = true,
                max_distance = 2500,
            },
            dropped = {
                enabled = true,
                max_distance = 500,
            },
        },
        misc = {
            mod_notification = true,
            auto_log = false,
        },
        exploits = {
            infinite_stamina = true,
            infinite_warmth = true,
            infinite_hunger = true,

            force_respawn = true, -- F8
            force_rejoin = true, -- End
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
        color_map = {
            player = {
                colonist = Color3.fromRGB(255, 255, 255),
                hbm = Color3.fromRGB(249, 62, 62),
                native = Color3.fromRGB(143, 0, 255)
            },
            animal = {
                elk = Color3.fromRGB(108, 88, 75),
                fox = Color3.fromRGB(143, 76, 42),
                rabbit = Color3.fromRGB(223, 223, 222),
            },
            ore = {   
                stone = Color3.fromRGB(139, 139, 139),
                iron = Color3.fromRGB(241, 241, 241),
                sulphur = Color3.fromRGB(245, 205, 48),
                gold = Color3.fromRGB(255, 176, 0),
            },
            dropped = Color3.fromRGB(155, 0, 255)
        },
    },

    status = {
        current_target = nil,
    },

    hooks = {},
    connections = {},
    drawings = {},
}

local game_client = {}

-- Garbage Collector
do
    local garbage_collection = getgc(true)
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
end

-- Functions
do
    do -- Utility
        function cheat_client:handle_drawing(type, properties)
            local drawing = Drawing.new(type)
            for i,v in next, properties do
                drawing[i] = v
            end
            
            self.drawings[#self.drawings+1] = drawing
            return drawing
        end

        function cheat_client:handle_object(type, properties)
            local object = Instance.new(type)
            for i,v in next, properties do
                object[i] = v
            end
            return object
        end

        function cheat_client:handle_connection(connection, callback)
            local proxy = {
                connection = connection:Connect(callback)
            }

            function proxy:disconnect()
                self.connection:Disconnect()
                table.remove(cheat_client.connections, table.find(cheat_client.connections, proxy))
            end

            self.connections[#self.connections + 1] = proxy
            return proxy
        end

        function cheat_client:handle_hook(original_function, hook_function)
            local proxy = {
                stored_original_function = original_function
            }

            function proxy:disconnect()
                original_function = self.stored_original_function
                table.remove(cheat_client.hooks, table.find(cheat_client.hooks, proxy))
            end

            original_function = hook_function

            self.hooks[#self.hooks+1] = proxy
            return proxy
        end

        function cheat_client:get_camera(player)
            return Workspace.CurrentCamera
        end
        
        function cheat_client:get_character(player)
            return Workspace.World.Characters:FindFirstChild(player)
        end
        
        function cheat_client:unload()
            
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
        function cheat_client:calculate_player_bounding_box(character)
            
        end

        function cheat_client:add_player_esp(player)
            
        end 

        function cheat_client:add_ore_esp(ore)
            local esp = {
                object = ore,
                ore_status = ore:FindFirstChild("Status"),
                ore_type = ore:FindFirstChild("Status"):FindFirstChild("OreType").Value,
                drawings = {},
            }

            do -- Drawings
                esp.drawings.text = self:handle_drawing("Text", {
                    Text = esp.ore_type,
                    Font = 2,
                    Size = 13,
                    Center = true,
                    Outline = true,
                    Color = cheat_client.config.color_map.ore[esp.ore_type],
                })
            end

            function esp:destruct()
                esp.update_connection:disconnect()

                table.remove(cheat_client.drawings, table.find(cheat_client.drawings, esp.drawings.text))
                esp.drawings.text:Remove()
            end

            esp.update_connection = cheat_client:handle_connection(RunService.Heartbeat, function()
                if esp.object.Parent ~= Workspace.World.Operables.Resources then
                    esp:destruct()
                    return
                end

                if (cheat_client.config.esp.global and cheat_client.config.esp.ore.enabled) then
                    local world_position = esp.object:GetBoundingBox()
                    local camera = cheat_client:get_camera()
                    local distance = (world_position.Position - camera.CFrame.Position).magnitude
                    if distance <= cheat_client.config.esp.ore.max_distance then
                        local screen_position, visible = camera:WorldToViewportPoint(world_position.Position)
                        if visible then
                            esp.drawings.text.Text = esp.ore_type.."\n".."["..tostring(math.floor(distance)).."]"
                            esp.drawings.text.Position = Vector2.new(screen_position.X, screen_position.Y)
                            esp.drawings.text.Visible = true
                        else
                            esp.drawings.text.Visible = false
                        end
                    else
                        esp.drawings.text.Visible = false
                    end
                    
                else
                    esp.drawings.text.Visible = false
                end
            end)

            return esp
        end

        function cheat_client:add_animal_esp(animal)
            local esp = {
                object = animal,
                animal_status = animal:FindFirstChild("Status"),
                animal_type = string.lower(animal.Name),
                drawings = {},
            }

            do -- Drawings
                esp.drawings.text = self:handle_drawing("Text", {
                    Text = esp.animal_type,
                    Font = 2,
                    Size = 13,
                    Center = true,
                    Outline = true,
                    Color = cheat_client.config.color_map.animal[esp.animal_type],
                })
            end

            function esp:destruct()
                esp.update_connection:disconnect()

                table.remove(cheat_client.drawings, table.find(cheat_client.drawings, esp.drawings.text))
                esp.drawings.text:Remove()
            end

            esp.update_connection = cheat_client:handle_connection(RunService.Heartbeat, function()
                if esp.object.Parent ~= Workspace.World.Operables.Animals then
                    esp:destruct()
                    return
                end
                
                if (cheat_client.config.esp.global and cheat_client.config.esp.animal.enabled) then
                    local world_position = esp.object:GetBoundingBox()
                    local camera = cheat_client:get_camera()
                    local distance = (world_position.Position - camera.CFrame.Position).magnitude
                    if distance <= cheat_client.config.esp.animal.max_distance then
                        local screen_position, visible = camera:WorldToViewportPoint(world_position.Position)
                        if visible then
                            esp.drawings.text.Text = esp.animal_type.."\n".."["..tostring(math.floor(distance)).."]\n"..(esp.animal_status.Available.Value and "[down]" or "")
                            esp.drawings.text.Position = Vector2.new(screen_position.X, screen_position.Y)
                            esp.drawings.text.Visible = true
                        else
                            esp.drawings.text.Visible = false
                        end
                    else
                        esp.drawings.text.Visible = false
                    end
                    
                else
                    esp.drawings.text.Visible = false
                end
            end)

            return esp
        end

        function cheat_client:add_dropped_esp(dropped)
            local esp = {
                object = dropped,
                drop_type = string.lower(dropped.Name),
                drawings = {},
            }

            do -- Drawings
                esp.drawings.text = self:handle_drawing("Text", {
                    Text = esp.drop_type,
                    Font = 2,
                    Size = 13,
                    Center = true,
                    Outline = true,
                    Color = cheat_client.config.color_map.dropped,
                })
            end

            function esp:destruct()
                esp.update_connection:disconnect()

                table.remove(cheat_client.drawings, table.find(cheat_client.drawings, esp.drawings.text))
                esp.drawings.text:Remove()
            end

            esp.update_connection = cheat_client:handle_connection(RunService.Heartbeat, function()
                if esp.object.Parent == nil then
                    esp:destruct()
                    return
                end

                if (cheat_client.config.esp.global and cheat_client.config.esp.dropped.enabled) then
                    local world_position = esp.object:GetBoundingBox()
                    local camera = cheat_client:get_camera()
                    local distance = (world_position.Position - camera.CFrame.Position).magnitude
                    if distance <= cheat_client.config.esp.dropped.max_distance then
                        local screen_position, visible = camera:WorldToViewportPoint(world_position.Position)
                        if visible then
                            esp.drawings.text.Text = esp.drop_type.."\n".."["..tostring(math.floor(distance)).."]\n"..(esp.drop_type == "pounds" and ("[£"..tostring(esp.object.Amount.Value).."]") or "")
                            esp.drawings.text.Position = Vector2.new(screen_position.X, screen_position.Y)
                            esp.drawings.text.Visible = true
                        else
                            esp.drawings.text.Visible = false
                        end
                    else
                        esp.drawings.text.Visible = false
                    end
                    
                else
                    esp.drawings.text.Visible = false
                end
            end)

            return esp
        end
    end

    do -- Misc
        function cheat_client:detect_mod(player)
            if player:GetRankInGroup(10800343) > 1 then
                if cheat_client.config.misc.auto_log then
                    local_player:Kick("Moderator detected, client initiated disconnect [AUTO LOG]")
                    return
                end

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

        function cheat_client:force_rejoin()
            TeleportService:Teleport(game.PlaceId, local_player, game.JobId)
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
    do -- Client Load Notification
        game_client.interface:newHint(("Welcome %s, to Yukihook."):format(local_player.Name))
    end

    do -- Mod Notifier
        if cheat_client.config.misc.mod_notification then
            for _,v in next, Players:GetPlayers() do
                task.spawn(function() -- I need a new thread cause this uses web stuff
                   cheat_client:detect_mod(v)
                end)
            end
        end
    end

    do -- Drawing Initializer
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

    do -- ESP Initializer
        for _,v in next, Workspace.World.Operables.Resources:GetChildren() do
            if string.find(v.Name, "Mine") then
                cheat_client:add_ore_esp(v)
            end
        end

        for _,v in next, Workspace.World.Operables.Animals:GetChildren() do
            cheat_client:add_animal_esp(v)
        end

        for _,v in next, Workspace.World.Items:GetChildren() do
            cheat_client:add_dropped_esp(v)
        end

        for _,v in next, Workspace.World.Operables.Resources:GetChildren() do
            if string.find(v.Name, "Mine") then
                cheat_client:add_ore_esp(v)
            end
        end
    end
end

-- Connections
do
    do -- Aimbot
        cheat_client:handle_connection(RunService.RenderStepped, function()
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
    end

    w

    
    cheat_client:handle_connection(UserInputService.InputBegan, function(input, processed)
        -- Force Respawn lol
        if input.KeyCode == Enum.KeyCode.F8 then
            cheat_client:force_respawn()
        elseif input.KeyCode == Enum.KeyCode.Home then
            cheat_client.esp.global = not cheat_client.esp.global
        elseif input.KeyCode == Enum.KeyCode.End then
            cheat_client:force_rejoin()
        end
    end)

    do -- ESP Connections
        cheat_client:handle_connection(Players.PlayerAdded, function(player)
            if cheat_client.config.misc.mod_notification then
                task.spawn(function() -- I need a new thread cause this uses web stuff
                    cheat_client:detect_mod(player)
                end)
            end
        end)

        cheat_client:handle_connection(Workspace.World.Operables.Animals.ChildAdded, function(child)
            cheat_client:add_animal_esp(child)
        end)

        cheat_client:handle_connection(Workspace.World.Operables.Resources.ChildAdded, function(child)
            if string.find(child.Name, "Mine") then
                cheat_client:add_ore_esp(child)
            end
        end)

        cheat_client:handle_connection(Workspace.World.Items.ChildAdded, function(child)
            cheat_client:add_dropped_esp(child)
        end)
    end

end
