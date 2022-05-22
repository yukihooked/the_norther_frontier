--[[
    Dear, Riannator1234, Hello, this is YUKINO#7070, I hope to join you on your endeavors to make TNF a great game,
    as such, I would love to work on your developer team and patch any exploits that come your way.

    Firstly, I would like to commend you on being able to ban my users, only for the method to be patched, 30 minutes later.
    Secondly, I would like to commend you for trying to make fun of my users, while your own admins are blatantly cheating in this game.
    Lastly, I would like to commend you for the audacity you showed thinking that you could patch my exploits.


    Sincerely,
        YUKINO#7070
]]
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
            smoothness = 2, -- Divides mouse delta
            max_distance = 500,
            ignore_fov = true,
            silent = true,
            non_sticky = true,
            aim_key = Enum.KeyCode.LeftControl
        },
        esp = {
            global_enabled = true,
            global_distance_limit = 2500,

            player = {
                enabled = true,
                max_distance = 1000,

                box = true,
                name = true, -- This will automatically tostring the distance
                status = true,
                health = true,
            },
            ore = {
                enabled = true,
                max_distance = 500,
            },
            animal = {
                enabled = true,
                max_distance = 500,
            },
            dropped = {
                enabled = true,
                max_distance = 500,
            },
        },
        exploits = {
            print_ban = true,-- Anticheat (Catches and prints ban, disable if u dont like prints)

            infinite_stamina = true, -- Integrity
            infinite_warmth = true,
            infinite_hunger = true,

            force_revive = true, -- Stance
            no_down = false,
            spoof_snowshoes = true,
            hook_walkspeed = false,
            walkspeed = 30,

            instant_interaction = true, -- Interaction (DANGEROUS)

            spoof_maxeight = true, -- Inventory
            max_weight = 1000,
            bypass_inventory_check = true,
            auto_pickup = true, -- (DANGEROUS)
            auto_pickup_distance = 6, -- It's distance limited on server
            auto_picked_list = {}, -- Prevent spam

            auto_bandage = true,
            bandage_debounce = {
                enabled = false,
                debounce = false, -- Do not touch this
                wait_time = 1,
            },

            force_rejoin = true, -- Teleport

            gun_exploits = {
                enabled = true,
                no_spread = true,
                modify_range = true,
                max_range = 500, -- This is probably your max fire distance, increase at your own risk
            },


        },
        misc = {
            mod_notification = true,
            auto_log = false,
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
        aiming = false,
        current_target = nil,
        window_active = true,
    },

    connections = {},
    drawings = {},
}

local game_client = {}

-- Garbage Collector
do
    local garbage_collection = getgc(true)
    for _, v in pairs(garbage_collection) do
        if typeof(v) == "table" then    
            if rawget(v, "randomStringsReceive") then -- Init Chunk
                game_client.setup = v
            elseif rawget(v, "fillHunger") then -- Character Chunk
                game_client.integrity = v
            elseif rawget(v, "animateSnow") then
                game_client.stance = v
            elseif rawget(v, "dragCart") then -- Inventory Chunk
                game_client.operable = v
            elseif rawget(v, "getBackpackNameItem") then
                game_client.inventory = v
            elseif rawget(v, "_request") then
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

        function cheat_client:can_render()
            return cheat_client.config.esp.global_enabled and cheat_client.status.window_active
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
            if character:FindFirstChild("HumanoidRootPart") then
                local character_cframe = character.HumanoidRootPart.CFrame
                local camera = cheat_client:get_camera()
                local size = character.HumanoidRootPart.Size + Vector3.new(1,4,1)
        
                local left, lvis = camera:WorldToViewportPoint(character_cframe.Position + (camera.CFrame.RightVector * -size.Z))
                local right, rvis = camera:WorldToViewportPoint(character_cframe.Position + (camera.CFrame.RightVector * size.z))
                local top, tvis = camera:WorldToViewportPoint(character_cframe.Position + (camera.CFrame.UpVector * size.y) / 2)
                local bottom, bvis = camera:WorldToViewportPoint(character_cframe.Position + (camera.CFrame.UpVector * -size.y) / 2)
        
                if not lvis and not rvis and not tvis and not bvis then 
                    return 
                end
        
                local width = math.floor(math.abs(left.x - right.x))
                local height = math.floor(math.abs(top.y - bottom.y))
        
                local screen_position = camera:WorldToViewportPoint(character_cframe.Position)
                local screen_size = Vector2.new(math.floor(width), math.floor(height))
        
                return Vector2.new(screen_position.X -(screen_size.X/ 2), screen_position.Y -(screen_size.Y / 2)), screen_size
            end
        end

        function cheat_client:add_player_esp(player)
            local esp = {
                player = player,
                drawings = {},
                low_health = Color3.fromRGB(255,0,0),
            }
    
            do -- Create Drawings
                do -- Main
                    esp.drawings.name = cheat_client:handle_drawing("Text", {
                        Text = player.name,
                        Font = 2,
                        Size = 13,
                        Center = true,
                        Outline = true,
                        Color = Color3.fromRGB(255,255,255)
                    })
        
                    esp.drawings.box = cheat_client:handle_drawing("Square", {
                        Thickness = 1,
                        ZIndex = 2,
                    })
        
                    esp.drawings.box_outline = cheat_client:handle_drawing("Square", {   
                        Thickness = 3,
                        ZIndex = 1,     
                        Color = Color3.fromRGB(0,0,0),
                    })
        
                    esp.drawings.health = cheat_client:handle_drawing("Line", {
                        Thickness = 2,           
                        ZIndex = 2,
                        Color = Color3.fromRGB(0, 255, 0),
                    })
        
                    esp.drawings.health_text = cheat_client:handle_drawing("Text", {
                        Text = "100",
                        Font = 2,
                        Size = 13,
                        Outline = true,
                        Color = Color3.fromRGB(255, 255, 255),
                    })
        
                    esp.drawings.health_outline = cheat_client:handle_drawing("Line", {
                        Thickness = 5,           
                        Color = Color3.fromRGB(0, 0, 0),
                    })

                    esp.drawings.status_effects = cheat_client:handle_drawing("Text", {
                        Font = 2,
                        Size = 13,
                        Outline = true,
                        Color = Color3.fromRGB(255, 255, 255),
                    })
    
                end
            end
    
            function esp:get_player_color(player)
                if player:FindFirstChild("Status") then
                if player.Status.Faction.Value == 10991087 then
                    return cheat_client.config.color_map.player.hbm
                    end

                    if player.Status.Role.Value == "Colonist" then
                        return cheat_client.config.color_map.player.colonist
                    end

                    if player.Status.Role.Value == "Native" then
                        return cheat_client.config.color_map.player.native
                    end
                else
                    return Color3.fromRGB(255,255,255)
                end
            end

            function esp:destruct()
                esp.update_connection:diconnect() -- Disconnect before deleting drawings so that the drawings don't cause an index error
                for _,v in next, esp.drawings do
                    table.remove(framework.drawings, table.find(framework.drawings, v))
                    v:Remove()
                end
            end
    
            esp.update_connection = cheat_client:handle_connection(RunService.RenderStepped, function()
                if cheat_client:can_render() then
                    if esp.player ~= nil then
                        if esp.player.Character and esp.player.Character:FindFirstChild("HumanoidRootPart") and esp.player:FindFirstChild("Status") then
                            local distance = (Workspace.CurrentCamera.CFrame.Position - esp.player.Character:FindFirstChild("HumanoidRootPart").CFrame.Position).Magnitude
                            if distance < cheat_client.config.esp.global_distance_limit and distance < cheat_client.config.esp.player.max_distance then
                                local screen_position, screen_size = cheat_client:calculate_player_bounding_box(player.Character)
                                if screen_position and screen_size then
                                    do -- Positioning
                                        do -- Box
                                            if cheat_client.config.esp.player.box then
                                                esp.drawings.box.Position = screen_position
                                                esp.drawings.box.Size = screen_size
                                                esp.drawings.box.Color = esp:get_player_color(esp.player)
                                                
                                                esp.drawings.box_outline.Position = screen_position
                                                esp.drawings.box_outline.Size = screen_size

                                                esp.drawings.box.Visible = true
                                                esp.drawings.box_outline.Visible = true
                                            end

                                        end

                                        do -- Name (and distance)
                                            if cheat_client.config.esp.player.name then
                                                esp.drawings.name.Text = "["..tostring(math.floor(distance)).."m] "..esp.player.Name
                                                esp.drawings.name.Position = esp.drawings.box.Position + Vector2.new(screen_size.X/2, -esp.drawings.name.TextBounds.Y)

                                                esp.drawings.name.Visible = true
                                            end
                                        end
    
                                        do -- Health
                                            if cheat_client.config.esp.player.health then
                                                esp.drawings.health.From = Vector2.new((screen_position.X - 5), screen_position.Y + screen_size.Y)
                                                esp.drawings.health.To = Vector2.new(esp.drawings.health.From.X, esp.drawings.health.From.Y - (esp.player.Status.Health.Value / esp.player.Status.Health.MaxValue) * screen_size.Y)
                                                esp.drawings.health.Color = esp.low_health:Lerp(Color3.fromRGB(0,255,0), esp.player.Status.Health.Value / esp.player.Status.Health.MaxValue)
        
                                                esp.drawings.health_outline.From = esp.drawings.health.From + Vector2.new(0, 1)
                                                esp.drawings.health_outline.To = Vector2.new(esp.drawings.health_outline.From.X, screen_position.Y - 1)
                                
                                                esp.drawings.health_text.Text = tostring(math.floor(esp.player.Status.Health.Value))
                                                esp.drawings.health_text.Position = esp.drawings.health.To - Vector2.new((esp.drawings.health_text.TextBounds.X + 4), 0)

                                                esp.drawings.health.Visible = true
                                                esp.drawings.health_outline.Visible = true
                                                esp.drawings.health_text.Visible = true
                                            end
                                        end

                                        do -- Status
                                            if cheat_client.config.esp.player.status then
                                                local status_string = ""

                                                if esp.player.Status.Bleed.Value > 0 then
                                                    status_string ..= "[bleed]\n"
                                                end
    
                                                if esp.player.Status.Downed.Value  then
                                                    status_string ..= "[down]\n"
                                                end
    
                                                esp.drawings.status_effects.Text = status_string
                                                esp.drawings.status_effects.Position = (screen_position) + Vector2.new(screen_size.X + 2, 0)

                                                esp.drawings.status_effects.Visible = true
                                            end

                                        end
                                    end
                                    
                                else
                                    for _,v in next, esp.drawings do
                                        v.Visible = false
                                    end
                                end
                            else
                                for _,v in next, esp.drawings do
                                    v.Visible = false
                                end
                            end
                        else
                            for _,v in next, esp.drawings do
                                v.Visible = false
                            end
                        end
                    else
                        esp:destruct()
                    end
                else
                    for _,v in next, esp.drawings do
                        v.Visible = false
                    end
                end
            end)
    
            return esp
        end

        function cheat_client:add_ore_esp(ore)
            local esp = {
                object = ore,
                ore_status = ore:WaitForChild("Status"),
                ore_type = ore:WaitForChild("Status"):WaitForChild("OreType").Value,
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

                if (cheat_client.config.esp.global_enabled and cheat_client.config.esp.ore.enabled) and (cheat_client:can_render()) then
                    local world_position = esp.object:GetBoundingBox()
                    local camera = cheat_client:get_camera()
                    local distance = (world_position.Position - camera.CFrame.Position).magnitude
                    if distance <= cheat_client.config.esp.ore.max_distance then
                        local screen_position, visible = camera:WorldToViewportPoint(world_position.Position)
                        if visible then
                            esp.drawings.text.Text = esp.ore_type.."\n".."["..tostring(math.floor(distance)).."m]"
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
                animal_status = animal:WaitForChild("Status"),
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
                
                if (cheat_client.config.esp.global_enabled and cheat_client.config.esp.animal.enabled) and (cheat_client:can_render()) then
                    local world_position = esp.object:GetBoundingBox()
                    local camera = cheat_client:get_camera()
                    local distance = (world_position.Position - camera.CFrame.Position).magnitude
                    if distance <= cheat_client.config.esp.animal.max_distance then
                        local screen_position, visible = camera:WorldToViewportPoint(world_position.Position)
                        if visible then
                            esp.drawings.text.Text = esp.animal_type.."\n".."["..tostring(math.floor(distance)).."m]\n"..(esp.animal_status.Available.Value and "[down]" or "")
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

                if (cheat_client.config.esp.global_enabled and cheat_client.config.esp.dropped.enabled) and (cheat_client:can_render()) then
                    local world_position = esp.object:GetBoundingBox()
                    local camera = cheat_client:get_camera()
                    local distance = (world_position.Position - camera.CFrame.Position).magnitude
                    if distance <= cheat_client.config.esp.dropped.max_distance then
                        local screen_position, visible = camera:WorldToViewportPoint(world_position.Position)
                        if visible then
                            esp.drawings.text.Text = esp.drop_type.."\n".."["..tostring(math.floor(distance)).."m]\n"..(esp.drop_type == "pounds" and ("[£"..tostring(esp.object.Amount.Value).."]") or "")
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
        function cheat_client:force_revive()
            if cheat_client.config.exploits.force_revive then
                game_client.stance:revive()
            end
        end

        function cheat_client:force_rejoin()
            TeleportService:Teleport(game.PlaceId, local_player, game.JobId)
        end
    end
end

-- Hooks
do 
    do -- hook ac remote
        local ac_remote = game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds

        local namecall_hook
        namecall_hook = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local namecall_method = getnamecallmethod()
            if not checkcaller() then
                if namecall_method == "FireServer" and self == ac_remote then
                    if cheat_client.config.exploits.print_ban then
                        rconsoleprint("Caught ban attempt\nBan ID: "..args[1].."\nReason: "..args[2] and tostring(args[2]).."\n")
                    end
                    return
                else
                    return namecall_hook(self, ...)
                end
            else
                return namecall_hook(self, ...)
            end
        end)
    end

    do -- integrity hooks
        setreadonly(game_client.integrity, false)
        local old_set_warmth = game_client.integrity.setWarmth
        local old_set_stamina = game_client.integrity._setStamina
        local old_set_hunger = game_client.integrity._setHunger

        game_client.integrity.setWarmth = function(self, warmth)
            if cheat_client.config.exploits.infinite_warmth then
                warmth = 6000 -- This get's clamped anyways
                return old_set_warmth(game_client.integrity, warmth)
            else
                return old_set_warmth(game_client.integrity, warmth)
            end
        end

        game_client.integrity._setStamina = function(self, stamina)
            if cheat_client.config.exploits.infinite_stamina then
                stamina = 100 -- This get's clamped anyways
                return old_set_stamina(self, stamina)
            else
                return old_set_stamina(self, stamina)
            end
        end

        game_client.integrity._setHunger = function(self, hunger)
            if cheat_client.config.exploits.infinite_stamina then
                hunger = 200 -- This get's clamped anyways
                return old_set_hunger(game_client.integrity, hunger)
            else
                return old_set_hunger(game_client.integrity, hunger)
            end
        end
    end

    do -- interaction hooks
        setreadonly(game_client.interaction, false)
        local old_start_interaction = game_client.interaction._start
        local old_interaction_request = game_client.interaction._request

        game_client.interaction._start = function(self)
            if cheat_client.config.exploits.instant_interaction then
                if self.objectTargetting or self.deployValid then
                    self.interacting = true
                    self.animationTrack = game_client.stance:getAnimationTrack(game_client.setup.stats.interactions[self.interactionType].animationID)
                    if self.animationTrack then
                        self.animationTrack:Play()
                    end
                    self:_request()

                end
            else
                return old_start_interaction(self)
            end
        end

        game_client.interaction._request = function(self)
            if cheat_client.config.exploits.bypass_inventory_check then
                if self.interactionType == "takeItem" then
                    game_client.interface:newHint("You take the " .. self.objectTargetting.name)
                    self.objectTargetting:take()
                else
                    return old_interaction_request(self)
                end
            else
                return old_interaction_request(self)
            end
        end
    end

    do -- stance hooks
        setreadonly(game_client.stance, false)
        local old_update_walkspeed = game_client.stance.updateWalkSpeed
        local old_set_down = game_client.stance.down

        game_client.stance.updateWalkSpeed = function(self)
            if cheat_client.config.exploits.hook_walkspeed then
                game_client.setup.humanoid.WalkSpeed = cheat_client.config.exploits.walkspeed
                game_client.setup.humanoid.JumpPower = 50
            else
                old_update_walkspeed(self)
            end
        end

        game_client.stance.down = function(self)
            if cheat_client.config.exploits.no_down then
                return
            else
                old_set_down(self)
            end
        end
    end

    do -- inventory hooks
        setreadonly(game_client.inventory, false)
        local old_get_equipped_type_item = game_client.inventory.getEquippedTypeItem
        local old_update_weight = game_client.inventory.updateWeight

        game_client.inventory.getEquippedTypeItem = function(self, key)
            if cheat_client.config.exploits.spoof_snowshoes and key == "snowshoes" then
                return true    
            else
                return old_get_equipped_type_item(self, key)
            end
        end

        game_client.inventory.updateWeight = function(self)
            if cheat_client.config.exploits.spoof_maxeight then
                self.maxWeight = cheat_client.config.exploits.max_weight
                old_update_weight(self)
            else
                old_update_weight(self)
            end
        end
    end

    do -- weapon hook
        setreadonly(game_client.weapon_fire, false)
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
                    if cheat_client.status.current_target and cheat_client.config.aim.silent then
                        return cheat_client.status.current_target.Torso.CFrame
                    end
                end
            end
            return index_hook(self, index)
        end)

    end
end

-- Init
do
    do -- Client Load Notification
        game_client.interface:newHint(("Welcome to Yukihook."))
    end

    do -- Hook Initializer
        if cheat_client.config.exploits.spoof_maxeight then
            game_client.inventory.maxWeight = cheat_client.config.exploits.max_weight
        end
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
        for _,v in next, Players:GetPlayers() do
            if v ~= local_player then 
                cheat_client:add_player_esp(v)
            end
        end

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

            fov_circle.Position = UserInputService:GetMouseLocation()
            fov_circle.Color = cheat_client.status.current_target and Color3.fromRGB(255,0,0) or Color3.fromRGB(255, 255, 255) -- Update then Calculate
            fov_circle.Visible = not cheat_client.config.aim.ignore_fov and true or false
            cheat_client:calculate_target()

            if cheat_client.status.current_target and not cheat_client.config.aim.silent then
                local camera = cheat_client:get_camera()
                local screen_position, on_screen = camera:WorldToViewportPoint(cheat_client.status.current_target.Torso.Position)
                if on_screen then
                    fov_target.Position = Vector2.new(screen_position.X, screen_position.Y)
                    fov_target.Visible = true
                    mousemoverel(Vector2.new(screen_position.X / cheat_client.config.aim.smoothness, screen_position.X / cheat_client.config.aim.smoothness))
                end
            else
                fov_target.Visible = false
            end
        end)
    end 
    
    do -- Input
        cheat_client:handle_connection(UserInputService.InputBegan, function(input, processed)
            -- Force Respawn lol
            if input.KeyCode == Enum.KeyCode.F8 then
                cheat_client:force_revive()
            elseif input.KeyCode == Enum.KeyCode.Home then
                cheat_client.config.esp.global_enabled = not cheat_client.config.esp.global_enabled
            elseif input.KeyCode == Enum.KeyCode.End then
                cheat_client:force_rejoin()
            end
        end)
    end

    do -- ESP Connections
        cheat_client:handle_connection(Players.PlayerAdded, function(player)
            if cheat_client.config.misc.mod_notification then
                task.spawn(function() -- I need a new thread cause this uses web stuff
                    cheat_client:detect_mod(player)
                end)
            end

            cheat_client:add_player_esp(player)
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

        cheat_client:handle_connection(UserInputService.WindowFocused, function() 
            cheat_client.status.window_active = true
        end)
    
        cheat_client:handle_connection(UserInputService.WindowFocusReleased, function() 
            cheat_client.status.window_active = false
        end)
    end

    do -- Autopickup Connection
        cheat_client:handle_connection(RunService.RenderStepped, function()
            if cheat_client.config.exploits.auto_pickup then
                for _,v in next, Workspace.World.Items:GetChildren() do
                    if local_player.Character then
                        if cheat_client.config.exploits.auto_picked_list[v] then
                            continue
                        end
                        if local_player:DistanceFromCharacter(v:GetBoundingBox().Position) <= cheat_client.config.exploits.auto_pickup_distance then
                            local object_targetting = game_client.interaction:get(v)
                            game_client.interaction.interactionType = "takeItem"
                            game_client.interaction.objectTargetting = object_targetting
                            game_client.interaction.parameter = nil
                            game_client.interaction.interacting = true
                            game_client.interaction:_request()
                            cheat_client.config.exploits.auto_picked_list[v] = true
                        end
                    end
                end
            end
        end)
    end

    do -- Auto Bandage Connection
        cheat_client:handle_connection(RunService.RenderStepped, function()
            if cheat_client.config.exploits.auto_bandage then
                if game_client.integrity.health < game_client.integrity.maxHealth then
                    if game_client.inventory:getEquippedNameItem("Bandage") then
                        if cheat_client.config.exploits.bandage_debounce.enabled then
                            if cheat_client.config.exploits.bandage_debounce.debounce then
                                task.wait(cheat_client.config.exploits.bandage_debounce.wait_time)
                                cheat_client.config.exploits.bandage_debounce.debounce = false
                            end
                        end
                        game_client.misc.Request("bandagePlayer", local_player)
                        cheat_client.config.exploits.bandage_debounce.debounce = true
                    end
                end
            end
        end)
    end
end
