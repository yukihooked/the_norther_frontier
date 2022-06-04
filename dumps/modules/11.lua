local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local jjsqaEROmGwDxiOoBJQP = {}
local g, clientRequestRemote, serverRequestRemote, serverUpdateRemote
local jobs = 0
local minigun = nil
local autofish = nil
local scriptkill = nil
jjsqaEROmGwDxiOoBJQP.__index = jjsqaEROmGwDxiOoBJQP

if game:GetService("RunService"):IsServer() then
	minigun = require(game.ServerScriptService.Game_Server.Game_Anticheat["Anti Minigun"])
	autofish = require(game.ServerScriptService.Game_Server.Game_Anticheat["Anti Autofish"])
end

function jjsqaEROmGwDxiOoBJQP.init(_g)
	if game:GetService("RunService"):IsServer() then
		g = _G
	else
		g = _g
		clientRequestRemote = g.remotes.ClientRequestRemote
		serverUpdateRemote = g.remotes.ServerUpdateRemote
		serverRequestRemote = g.remotes.ServerRequestRemote
	end
	local self = {}
	setmetatable(self, jjsqaEROmGwDxiOoBJQP)
	return self
end

function jjsqaEROmGwDxiOoBJQP:start()
	serverUpdateRemote.OnClientEvent:Connect(function(functionName, securityString, ...)
		if securityString and table.find(g.randomStringsReceive, securityString) then
			jjsqaEROmGwDxiOoBJQP[functionName](...)
		end
	end)

	serverRequestRemote.OnClientInvoke = function(functionName, securityString, ...)
		if securityString and table.find(g.randomStringsReceive, securityString) then
			jjsqaEROmGwDxiOoBJQP[functionName](...)
		end
	end

	g.map.DescendantRemoving:Connect(function()
		-- had to be commented out because of the streaming enabled, which could be disabled eventually 
		-- jjsqaEROmGwDxiOoBJQP.kickSelf("Unexpected instance removal")
	end)

	spawn(function()
		while wait(60) do
			delay(.5, function()
				jjsqaEROmGwDxiOoBJQP.Request("checkCombatLog", (math.random(1, 5000) * 2) - 1)
			end)
			jjsqaEROmGwDxiOoBJQP.Request("saveProgress", (math.random(1, 5000) * 2) - 1)
		end
	end)

	coroutine.resume(coroutine.create(function()
		local logHistory = {}
		while wait(5) do
			logHistory = game:GetService('LogService'):GetLogHistory()
			for i,v in pairs(logHistory) do
				if v.message == "bypassed anti cheat!" then
					game:GetService("Players").LocalPlayer:Kick()
					print("PLAYER HAS EXPLOITS!")
				end
			end
			logHistory = nil
		end
	end))

	jjsqaEROmGwDxiOoBJQP.setupSounds()
end

--game.DescendantAdded:Connect(function(child)
--	local IsLocked = pcall(function() return child.Name end)
--	if IsLocked then return end --no error means it's part of game
--	print(tostring(IsLocked)) 

--	if game:findfirstchild("GuiNameHere") true) and tostring(pcall(function() return  game:findfirstchild("GuiNameHere" end) = false then game.Players.LocalPlayer:Kick("illegal object found") end

--end)

jjsqaEROmGwDxiOoBJQP.Request = function(...)
	local securityString = g.randomStringsSend[math.random(1, #g.randomStringsSend)]
	jobs = jobs + 1
	return clientRequestRemote:InvokeServer(securityString, ...)
end

function jjsqaEROmGwDxiOoBJQP.finishJob()
	jobs = jobs - 1
	if jobs < 0 then
		jjsqaEROmGwDxiOoBJQP.kickSelf("Unexpected remote request")
	end
end

function jjsqaEROmGwDxiOoBJQP:beginTutorial(roleName)
	g.tutorial.begin(roleName)
end

function jjsqaEROmGwDxiOoBJQP.DATA_WIPED()
	g.interface:showMessage("Data Wipe", "Dear ".. g.player.Name .. ", we have completed a game wipe that has removed all items and pounds that you may have had besides your robux items. This was done to fix the inflated economy and get ready for the summer!", "CONTINUE")
end

function jjsqaEROmGwDxiOoBJQP.CheckUI(player)
	local ui = player.PlayerGui:GetChildren()
	for i=1, #ui do
		if ui[i].Name ~= "Game_UI" and ui[i].Name ~= "Chat" and ui[i].Name ~= "BubbleChat" and ui[i].Name ~= "ControlGui" and ui[i].Name ~= "FreeCamera" then
			player.Status.Downed.Value = true
			jjsqaEROmGwDxiOoBJQP.kickPlayer(player, "Attempt to insert exploit")
		end --yes
	end
end

function jjsqaEROmGwDxiOoBJQP.updateRatPose(...)
	print({ ... })
end

function jjsqaEROmGwDxiOoBJQP.kickSelf(reason)
	g.player:Kick(reason)
	jjsqaEROmGwDxiOoBJQP.Request("kickPlayer", reason)
	delay(.5, function()
		delay(.5, function()
			jjsqaEROmGwDxiOoBJQP.Request("checkCombatLog", math.random(1, 5000) * 2)
		end)
		jjsqaEROmGwDxiOoBJQP.Request("saveProgress", math.random(1, 5000) * 2)
	end)
	wait(1)
	while true do print'No' end
end

function jjsqaEROmGwDxiOoBJQP.kickPlayer(player, reason)
	return wait(9e9)
	--player:Kick("Potential game exploit detected (" .. reason .. ")")
end

function jjsqaEROmGwDxiOoBJQP.setCollisionGroup(object, collisionGroup)
	if object:IsA("BasePart") then
		g.physicsService:SetPartCollisionGroup(object, collisionGroup)
	end
	for _, _object in pairs(object:GetChildren()) do
		jjsqaEROmGwDxiOoBJQP.setCollisionGroup(_object, collisionGroup)
	end
end

function jjsqaEROmGwDxiOoBJQP.getPlayerFromPart(part)
	if part and part:IsDescendantOf(workspace) then
		local player = g.playersService:GetPlayerFromCharacter(part)
		if player then
			return player
		else
			return jjsqaEROmGwDxiOoBJQP.getPlayerFromPart(part.Parent)
		end
	end
end

function jjsqaEROmGwDxiOoBJQP:canDamage(player, target)
	local playerRole = player.Status.Role.Value
	local targetRole = target.Status.Role.Value
	for _, player in next, {player, target} do
		for _, zone in next, player.Status.Zones:GetChildren() do
			if zone.Value then
				local zoneStats = g.stats.zones[zone.Name]
				if zoneStats.safetyConditions and not self.find(zoneStats.safetyConditions[playerRole], targetRole) then
					return false
				end
			end
		end
	end --
	return true
end

function jjsqaEROmGwDxiOoBJQP.damageEntity(entity, item, tag, checkBlocking)
	if type(entity) == "table" then
		entity = entity.model -- get animal model from the table
	end
	if (not checkBlocking or not g.players[entity.Name] or not g.players[entity.Name].blocking) then
		if entity ~= nil then
			g.sounds.Hit:Play()
		end

		local damageDone = g.misc.Request("damage", entity, tag, item.name, item.content and item.content.chargeForce, checkBlocking)
		if entity ~= false and entity ~= nil then
			if entity.Parent == game.Players then -- was checking if it was a player but that caused errors
				if type(damageDone) == "number" then
					g.interface:newHint("Player safe for " .. (g.stats.arbs.respawnSafeTime - damageDone) .. " second(s)")
				elseif type(damageDone) == "string" and damageDone == "faction" then
					g.interface:newHint("Player in same faction")
				elseif not damageDone then
					g.interface:newHint("Player safezoned")
				end
			end
			return damageDone
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.addOperable(operableModel, parent)
	if not parent then
		g.operables[operableModel] = g.operable.new(operableModel)
	end
	for i, v in pairs((parent or operableModel):GetChildren()) do
		if v:IsA("BasePart") then
			local transparency = v.Transparency
			local cFrame = v.CFrame
			v.Transparency = 1
			if v ~= operableModel.PrimaryPart then
				v.CFrame = v.CFrame * CFrame.new(Vector3.new(0, 2, 0))
			end
			delay((i - 1) / 5, function()
				g.tween:TweenNumber(v, "Transparency", transparency, .5, g.tween.Ease.In.Linear)
				if v ~= operableModel.PrimaryPart then
					g.tween:TweenCFrame(v, "CFrame", cFrame, .5, g.tween.Ease.In.Linear)
				end
			end)
		elseif v:IsA("Model") then
			jjsqaEROmGwDxiOoBJQP.addOperable(operableModel, v)
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.removeOperable(operableModel, parent)
	g.operables[operableModel] = nil
	for i, v in pairs((parent or operableModel):GetChildren()) do
		if v:IsA("BasePart") then
			delay((i - 1) / 10, function()
				g.tween:TweenNumber(v, "Transparency", 1, .5, g.tween.Ease.In.Linear)
				if v ~= operableModel.PrimaryPart then
					g.tween:TweenCFrame(v, "CFrame", v.CFrame * CFrame.new(Vector3.new(0, -1, 0)), .5, g.tween.Ease.In.Linear)
				end
			end)
		elseif v:IsA("Model") then
			jjsqaEROmGwDxiOoBJQP.removeOperable(operableModel, v)
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.dropItem(itemName)
	g.inventory:dropItem(itemName)
end

function jjsqaEROmGwDxiOoBJQP.loadZone(player, zoneName, cFrame)
	if g.players[player.Name] then
		g.players[player.Name]:loadZone(g.zones[zoneName], cFrame)
	end
end

function jjsqaEROmGwDxiOoBJQP.unloadZone(player, zoneName)
	if g.players[player.Name] then
		g.players[player.Name]:unloadZone(g.zones[zoneName])
	end
end

function jjsqaEROmGwDxiOoBJQP.animateAnimalMovement(operableModel, waypoints)
	if not operableModel:FindFirstChild('Main', true) then return end
	local animalStats = g.stats.animals[operableModel.Name]
	for i = 2, #waypoints do
		if operableModel.Status.Health.Value > 0 then
			local waypoint = waypoints[i]
			local origin = waypoint + Vector3.new(0, 10, 0)
			local ray = Ray.new(origin, (waypoint - origin).unit * 20)
			local _, hitPosition = workspace:FindPartOnRayWithWhitelist(ray, { workspace.Terrain })
			local lookAt = waypoints[i + 1]
			local cFrame
			if operableModel.Status.Hostile.Value == true then
				local mainPart = operableModel.Triggers.Trigger.Main
				local players = game.Players:GetChildren()
				for i=1, #players do
					if (players[i].Character.HumanoidRootPart.Position - mainPart.Position).magnitude < operableModel.Status.Range.Value then
						--operableModel.Status.Target.Value = players[i].Character.HumanoidRootPart
						lookAt = operableModel.Status.Target.Value
					end
				end
			end
			if lookAt then
				cFrame = CFrame.new(hitPosition, Vector3.new(lookAt.X, hitPosition.Y, lookAt.Z))
			else
				cFrame = CFrame.new(hitPosition)
			end
			g.tweenService:Create(operableModel.Triggers.Trigger.Main, TweenInfo.new(animalStats.walkSpeed / 10, Enum.EasingStyle.Linear), { CFrame = cFrame * animalStats.cFrameOffset }):Play()
			wait(animalStats.walkSpeed / 10)
		else
			break
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateRatMovement(player, operableModel, waypoints)
	for i = 2, #waypoints do
		local waypoint = waypoints[i]
		local origin = waypoint + Vector3.new(0, 10, 0)
		local ray = Ray.new(origin, (waypoint - origin).unit * 20)
		local _, hitPosition = workspace:FindPartOnRayWithWhitelist(ray, { workspace.Terrain })
		local lookAt = waypoints[i + 1] -- player.Character.PrimaryPart.Position
		local cFrame

		if lookAt then
			cFrame = CFrame.new(hitPosition, Vector3.new(lookAt.X, hitPosition.Y, lookAt.Z))
		else
			cFrame = CFrame.new(hitPosition)
		end

		g.tweenService:Create(operableModel.PrimaryPart, TweenInfo.new(3 / 10, Enum.EasingStyle.Linear), { CFrame = cFrame * (CFrame.new(0, -.7, 0) * CFrame.Angles(0, 0, 0))}):Play()
		wait(3 / 10)
	end
end

function jjsqaEROmGwDxiOoBJQP.animateAnimalDeath(operableModel, cFrame)
	local animalStats = g.stats.animals[operableModel.Name]
	g.tweenService:Create(operableModel.Triggers.Trigger.Main, TweenInfo.new(animalStats.walkSpeed / 10, Enum.EasingStyle.Linear), { CFrame = cFrame * animalStats.deadCFrameOffset }):Play() --// * animalStats.cFrameOffset
end

function jjsqaEROmGwDxiOoBJQP.animateAnimalSkinned(operableModel)
	for i,v in pairs(operableModel.Triggers.Trigger:GetChildren()) do
		if v:IsA("MeshPart") then
			g.tweenService:Create(v, TweenInfo.new(3), { Transparency = 1 }):Play()
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateAnimalRespawn(operableModel)
	for i,v in pairs(operableModel.Triggers.Trigger:GetChildren()) do
		if v:IsA("MeshPart") then
			g.tweenService:Create(v, TweenInfo.new(1), { Transparency = 0 }):Play()
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateBloodDrip(player)
	local ray = Ray.new(player.Character.Torso.Position, ((player.Character.Torso.Position - Vector3.new(0, 10, 0)) - player.Character.Torso.Position).unit * 20)
	local hitObject, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, { g.mouseFilter, g.characters, g.items, g.operablesF })
	local bloodObject = g.objects.BloodFrame:Clone()
	bloodObject.CFrame = CFrame.new(hitPosition - Vector3.new(0, .099, 0)) * CFrame.Angles(0, math.rad(math.random(1, 360)), 0)
	local sizeOffset = math.random(30, 50) / 10
	bloodObject.Size = Vector3.new(sizeOffset, .2, sizeOffset)
	bloodObject.Parent = g.mouseFilter
	local originalSize = bloodObject.Size
	bloodObject.Size = Vector3.new(.2, .2, .2)
	g.tween:TweenVector3(bloodObject, "Size", originalSize, 1, g.tween.Ease.In.Linear)
	g.tween:TweenNumber(bloodObject.Decal, "Transparency", .4, 1, g.tween.Ease.In.Linear)
	wait(g.stats.arbs.bloodDripLifetime - 11)
	if bloodObject.Parent then
		g.tween:TweenNumber(bloodObject.Decal, "Transparency", 1, 10, g.tween.Ease.In.Linear)
		g.debris:AddItem(bloodObject, 11)
	end
end

function jjsqaEROmGwDxiOoBJQP.animateTakeItem(player, itemModel)
	if player.Character:IsDescendantOf(workspace) or player == g.player then
		for i, v in pairs(itemModel:GetChildren()) do
			if v:IsA("BasePart") then
				v.Anchored = true
				v.CanCollide = false
				g.tween:TweenNumber(v, "Transparency", 1, .2, g.tween.Ease.In.Linear)
			end
		end
		g.tween:TweenCFrame(itemModel, "SetPrimaryPartCFrame", CFrame.new(player.Character.HumanoidRootPart.Position), .2, g.tween.Ease.In.Linear)
	end
end

function jjsqaEROmGwDxiOoBJQP.animateAnchorItem(itemModel, operableModel)
	if operableModel:IsDescendantOf(workspace) then
		g.tween:TweenCFrame(itemModel, "SetPrimaryPartCFrame", operableModel.Container.CFrame, .2, g.tween.Ease.In.Linear)
	end
end

function jjsqaEROmGwDxiOoBJQP.animateTreeFall(operableModel)
	g.tween:TweenCFrame(operableModel, "SetPrimaryPartCFrame", operableModel:GetPrimaryPartCFrame() * CFrame.Angles(math.rad(90), 0, 0), 3, g.tween.Ease.In.Quad)
	wait(2)
	g.tween:TweenNumber(operableModel.Main, "Transparency", 1, 1, g.tween.Ease.In.Linear)
	--g.tween:TweenNumber(operableModel.Main2.Decal, "Transparency", 1, 1, g.tween.Ease.In.Linear)
	wait(1.1)
	operableModel:SetPrimaryPartCFrame(operableModel:GetPrimaryPartCFrame() * CFrame.Angles(-math.rad(90), 0, 0))
end

function jjsqaEROmGwDxiOoBJQP.animateTreeRespawn(operableModel)
	g.tween:TweenNumber(operableModel.Main, "Transparency", 0, 1, g.tween.Ease.In.Linear)
	--g.tween:TweenNumber(operableModel.Main2.Decal, "Transparency", 0, 1, g.tween.Ease.In.Linear)
end

function jjsqaEROmGwDxiOoBJQP.animateMineFall(operableModel)
	local mine_obj = operableModel.Triggers.Trigger:GetChildren()
	for i=1, #mine_obj do
		if mine_obj[i].ClassName ~= "StringValue" then
			g.tween:TweenNumber(mine_obj[i], "Transparency", 1, 1, g.tween.Ease.In.Linear)
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateMineRespawn(operableModel)
	local mine_obj = operableModel.Triggers.Trigger:GetChildren()
	for i=1, #mine_obj do
		if mine_obj[i].ClassName ~= "StringValue" then
			g.tween:TweenNumber(mine_obj[i], "Transparency", 0, 1, g.tween.Ease.In.Linear)
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateDropItem(itemModel)
	local itemStats = g.stats.items[itemModel.Name]
	for i, v in pairs(itemModel:GetChildren()) do
		if v:IsA("BasePart") then
			if itemStats.type == "clothing" then
				g.tween:TweenNumber(v, "Transparency", 0, .2, g.tween.Ease.In.Linear)
			elseif itemStats.type == "deployable" and not g.resources.Game_Interactives.Game_Items:FindFirstChild(itemModel.Name) then
				g.tween:TweenNumber(v, "Transparency", g.objects.DeployableItemModel[v.Name].Transparency, .2, g.tween.Ease.In.Linear)
			elseif itemStats.type == "faction_deployable" and not g.resources.Game_Interactives.Game_Items:FindFirstChild(itemModel.Name) then
				g.tween:TweenNumber(v, "Transparency", g.objects.DeployableItemModel[v.Name].Transparency, .2, g.tween.Ease.In.Linear)
			else
				g.tween:TweenNumber(v, "Transparency", g.resources.Game_Interactives.Game_Items[itemModel.Name][v.Name].Transparency, .2, g.tween.Ease.In.Linear)
			end
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateDoubleDoor(request, operableModel)
	if operableModel:IsDescendantOf(workspace) then
		local operableStats = g.stats.operables.double
		if request then
			for i, v in pairs(operableModel.Triggers:GetChildren()) do
				g.tween:TweenCFrame(v, "SetPrimaryPartCFrame", v:GetPrimaryPartCFrame() * operableStats.enabledOffsetCFrame, operableStats.openTime, g.tween.Ease.Out.Quad)
			end
		else
			for i, v in pairs(operableModel.Triggers:GetChildren()) do
				g.tween:TweenCFrame(v, "SetPrimaryPartCFrame", v:GetPrimaryPartCFrame() * operableStats.disabledOffsetCFrame, operableStats.closeTime, g.tween.Ease.In.Linear)
			end
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.animateNormalDoor(request, operableModel)
	if operableModel:IsDescendantOf(workspace) then
		local operableStats = g.stats.operables.normal
		if request then
			g.tween:TweenCFrame(operableModel.Triggers.Trigger, "SetPrimaryPartCFrame", operableModel.Triggers.Trigger:GetPrimaryPartCFrame() * operableStats.enabledOffsetCFrame, operableStats.openTime, g.tween.Ease.Out.Quad)
		else
			g.tween:TweenCFrame(operableModel.Triggers.Trigger, "SetPrimaryPartCFrame", operableModel.Triggers.Trigger:GetPrimaryPartCFrame() * operableStats.disabledOffsetCFrame, operableStats.closeTime, g.tween.Ease.In.Linear)
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.sendChat(player, chat, whispering)
	local playersSeen = {}
	if tick() - player.Status.LastChat.Value > .2 then
		player.Status.LastChat.Value = tick()
		local maxDistance
		if whispering then
			maxDistance = g.stats.arbs.chatWhisperMaxDistance
		else
			maxDistance = g.stats.arbs.chatMaxDistance
		end
		local playersSeen = {}
		for i, v in pairs(g.players:GetPlayers()) do
			if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).magnitude < maxDistance then
				local chat = g.chat:FilterStringAsync(string.sub(chat, 1, 150), player, v)
				if chat and chat ~= "Press / to chat" then
					g.client.sendToClient(v, "newChat", player, chat)
				end
				table.insert(playersSeen, v)
			end
		end
	end
	return playersSeen
end

function jjsqaEROmGwDxiOoBJQP.newChat(player, chat)
	g.interface:newChat(player, chat)
	if player ~= g.player then
		g.otherPlayer:get(player):showChat(chat)
	end
end

function jjsqaEROmGwDxiOoBJQP.animateBullet(itemModel, hitPosition, animateImpact)
	if itemModel:IsDescendantOf(workspace) then
		g.firing:animate(itemModel, hitPosition, animateImpact)
	end
end

function jjsqaEROmGwDxiOoBJQP.animateProjectile(itemModel, hitPosition, chargeForce)
	if itemModel:IsDescendantOf(workspace) then
		g.firing:animateProjectile(itemModel, hitPosition, chargeForce)
	end
end

function jjsqaEROmGwDxiOoBJQP.clerp(p1, p2, percent)
	local p1x,p1y,p1z,p1R00,p1R01,p1R02,p1R10,p1R11,p1R12,p1R20,p1R21,p1R22 = p1:components()
	local p2x,p2y,p2z,p2R00,p2R01,p2R02,p2R10,p2R11,p2R12,p2R20,p2R21,p2R22 = p2:components()
	return	CFrame.new(p1x+percent*(p2x-p1x), p1y+percent*(p2y-p1y) ,p1z+percent*(p2z-p1z),
		(p1R00+percent*(p2R00-p1R00)), (p1R01+percent*(p2R01-p1R01)) ,(p1R02+percent*(p2R02-p1R02)),
		(p1R10+percent*(p2R10-p1R10)), (p1R11+percent*(p2R11-p1R11)) , (p1R12+percent*(p2R12-p1R12)),
		(p1R20+percent*(p2R20-p1R20)), (p1R21+percent*(p2R21-p1R21)) ,(p1R22+percent*(p2R22-p1R22)))
end

jjsqaEROmGwDxiOoBJQP.set = function(pathTable, variable, value)
	local path = g.status
	for i, v in pairs(pathTable) do
		path = path[v]
	end	
	path[variable] = value
end

jjsqaEROmGwDxiOoBJQP.find = function(searchedTable, searchedValue)
	for i, v in pairs(searchedTable) do
		if v == searchedValue then
			return i
		end
	end
end

jjsqaEROmGwDxiOoBJQP.get = function(searchedTable, searchedValue)
	local index = jjsqaEROmGwDxiOoBJQP.find(searchedTable, searchedValue)
	if index then
		return searchedTable[index]
	end
end

jjsqaEROmGwDxiOoBJQP.remove = function(searchedTable, searchedValue)
	local index = jjsqaEROmGwDxiOoBJQP.find(searchedTable, searchedValue)
	if index then
		table.remove(searchedTable, index)
	end
end

jjsqaEROmGwDxiOoBJQP.addPlayer = function(player)
	if not g.players[player.Name] and player ~= g.player then
		g.players[player.Name] = g.otherPlayer.new(player)
	end
end

jjsqaEROmGwDxiOoBJQP.removePlayer = function(player)
	g.players[player.Name] = nil
end

jjsqaEROmGwDxiOoBJQP.isPartWithinRegion3 = function(part1, part2)
	local isInX = (part2.Position.X - (part2.Size.X / 2)) < part1.Position.X and (part2.Position.X + (part2.Size.X / 2)) > part1.Position.X
	local isInY = (part2.Position.Y - (part2.Size.Y / 2)) < part1.Position.Y and (part2.Position.Y + (part2.Size.Y / 2)) > part1.Position.Y
	local isInZ = (part2.Position.Z - (part2.Size.Z / 2)) < part1.Position.Z and (part2.Position.Z + (part2.Size.Z / 2)) > part1.Position.Z
	return isInX and isInY and isInZ
end

jjsqaEROmGwDxiOoBJQP.song = function(soundObject, request)
	if request then
		if not soundObject.Playing then
			soundObject:Play()
		end
		soundObject.Running.Value = true
		for i = soundObject.Debounce.Value, 50 do
			if soundObject.Running.Value then
				soundObject.Volume = i / 50
				soundObject.Debounce.Value = i
				wait()
			else
				break
			end
		end
	else
		soundObject.Running.Value = false
		for i = 50 - soundObject.Debounce.Value, 50 do
			if not soundObject.Running.Value then
				soundObject.Volume = 1 - (i / 50)
				soundObject.Debounce.Value = 50 - i
				wait()
			else
				break
			end
		end
		wait(3)
		if not soundObject.Running.Value then
			soundObject:Stop()
		end
	end
end

local fireInformation = {}

jjsqaEROmGwDxiOoBJQP.damage = function(player, targetEntity, tag, itemName, q, chargeForce)	

	if minigun.check(player, tag, targetEntity, itemName, g.stats.items[itemName], g.item.minigun[player.UserId], q) == true then
		return "--"
	end

	-- print(itemName)

	if targetEntity == nil then
		return true
	end

	if targetEntity:FindFirstChild("Status") == nil or targetEntity:FindFirstChild("Status"):FindFirstChild("Health") == nil then
		print('no health!')
		return true
	end

	local itemValue = g.item.getFirstEquipped(player, itemName)
	if itemValue and  targetEntity.Status.Health.Value > 0 then
		local itemStats = g.stats.items[itemName]
		if targetEntity:IsA("Player") then
			for i, v in pairs(player.Status.Zones:GetChildren()) do
				if v.Value then
					local zoneStats = g.stats.zones[v.Name]
					if zoneStats.safetyConditions and not jjsqaEROmGwDxiOoBJQP.find(zoneStats.safetyConditions[player.Status.Role.Value], targetEntity.Status.Role.Value) then
						return false
					end
				end
			end
			for i, v in pairs(targetEntity.Status.Zones:GetChildren()) do
				if v.Value then
					local zoneStats = g.stats.zones[v.Name]
					if zoneStats.safetyConditions and not jjsqaEROmGwDxiOoBJQP.find(zoneStats.safetyConditions[player.Status.Role.Value], targetEntity.Status.Role.Value) then
						return false
					end
				end
			end
			if player.Status.Faction.Value ~= 0 and player.Status.Faction.Value == targetEntity.Status.Faction.Value and _G.storage.Factions:FindFirstChild(player.Status.Faction.Value) and not _G.storage.Factions[player.Status.Faction.Value].TeamKill.Value then
				return "faction"
			end
			if (tick() - player.Status.LastRespawn.Value < _G.stats.arbs.respawnSafeTime) then
				return math.ceil(tick() - player.Status.LastRespawn.Value)
			end
			if (tick() - targetEntity.Status.LastRespawn.Value < _G.stats.arbs.respawnSafeTime) then
				return math.ceil(tick() - targetEntity.Status.LastRespawn.Value)
			end
		end
		local damage = itemStats.damage or itemStats.weapon.damage
		if itemStats.weapon and itemStats.weapon.projectile and chargeForce then
			chargeForce = math.max(0, math.min(1, chargeForce))
			damage = math.max(10, damage * chargeForce)
		end

		targetEntity.Status.Health.Value = targetEntity.Status.Health.Value - damage
		if targetEntity:IsA("Player") then
			jjsqaEROmGwDxiOoBJQP.claimBounty(player, targetEntity)
			if damage >= g.stats.arbs.minimumDamageForBleeding then
				coroutine.wrap(jjsqaEROmGwDxiOoBJQP.bleedPlayer)(targetEntity, math.floor(damage / 2), player)
			end
		end
		return true
	elseif targetEntity.Status.Health.Value <= 0 then
		return true
	else
		print('got here?????')
		return false
	end
end

function jjsqaEROmGwDxiOoBJQP.claimBounty(player, targetPlayer)
	if player ~= targetPlayer and targetPlayer.Status.Health.Value == 0 and (player.Status.Faction.Value == 0 or player.Status.Faction.Value ~= targetPlayer.Status.Faction.Value) then
		local bounty = targetPlayer.Status.Bounty.Value
		targetPlayer.Status.Bounty.Value = 0
		player.Status.Pounds.Value = player.Status.Pounds.Value + bounty
		g.client.sendToClient(player, "newHint", "You claim " .. targetPlayer.Name .. "'s bounty of " .. bounty .. " pounds!")
		g.client.sendToClient(targetPlayer, "newHint", "Your bounty has been claimed by " .. player.Name.. "!")
	end
end

function jjsqaEROmGwDxiOoBJQP.offerBounty(player, targetPlayer, pounds)
	if targetPlayer.Parent == _G.players and targetPlayer ~= player then
		pounds = math.floor(pounds)
		pounds = math.min(_G.stats.arbs.maximumBountyOffer, pounds)
		pounds = math.max(_G.stats.arbs.minimumBountyOffer, pounds)
		if pounds <= player.Status.Pounds.Value and pounds > 0 then
			player.Status.Pounds.Value = player.Status.Pounds.Value - pounds
			pounds = math.floor(pounds * .8)
			targetPlayer.Status.Bounty.Value = targetPlayer.Status.Bounty.Value + pounds
			return pounds
		end
	end
end

jjsqaEROmGwDxiOoBJQP.banPlayer = function(player, userName, fromServer, reason)
	if fromServer or jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId) or player.UserId == 127267482 then
		local userId = g.players:GetUserIdFromNameAsync(userName)
		local playerDataStore = g.dataStoreService:GetDataStore("players_perm_hc_v1", userId) --xs
		playerDataStore:SetAsync("banned", true)
		coroutine.wrap(function()
			do
				if fromServer then
					_G.Webhooks:ServerBan(userId, reason)
				else
					if player.UserId ~= 127267482 then
						_G.Webhooks:AdminUsed(player,"Ban",userId,"BANNED")
					end
				end
			end
		end)()
		--// Kick player
		for _, v in next, g.players:GetPlayers() do
			if v.Name == userName then
				v:kick'You have been banned from this game.'
				break
			end
		end
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.unbanPlayer = function(player, userName)
	if jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId) or player.UserId == 127267482 then
		local userId = g.players:GetUserIdFromNameAsync(userName)
		local playerDataStore = g.dataStoreService:GetDataStore("players_perm_hc_v1", userId)
		playerDataStore:SetAsync("banned", false)
		g.dataStoreService:GetDataStore'DTR':RemoveAsync("DTR_" .. userId)
		game:GetService'DataStoreService':GetDataStore'Teleport_AntiCheat':RemoveAsync(userId)
		coroutine.wrap(function()
			do
				if player.UserId ~= 127267482 then
					_G.Webhooks:AdminUsed(player,"Unban",userId,"UNBANNED")
				end
			end
		end)()
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.getPlayerPounds = function(player, userName, role)
	if jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId) and _G.stats.roles[role] then
		local userId = g.players:GetUserIdFromNameAsync(userName)
		local playerDataStore = g.dataStoreService:GetDataStore("players_hc_v1", userId .. "_" .. role)
		local pounds = playerDataStore:GetAsync("pounds") and playerDataStore:GetAsync("bankPounds")
		return pounds
	end
end

jjsqaEROmGwDxiOoBJQP.setPlayerPounds = function(player, userName, role, pounds)
	if jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId) and _G.stats.roles[role] and pounds then
		local target
		for _, v in next, g.players:GetPlayers() do
			if v.Name == userName then
				target = v
				break
			end
		end

		local userId = g.players:GetUserIdFromNameAsync(userName)
		if target and role == target.Status.Role.Value then
			target.Status.Pounds.Value = pounds
		else
			local playerDataStore = g.dataStoreService:GetDataStore("players_hc_v1", userId .. "_" .. role)
			playerDataStore:SetAsync("pounds", tonumber(pounds))
		end
		coroutine.wrap(function()
			do
				_G.Webhooks:AdminUsed(player,"Set Player Pounds",userId,pounds)
			end
		end)()
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.setPlayerStorageSpace = function(player, userName, role, storageSpace)
	storageSpace = tonumber(storageSpace)
	if jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId) and _G.stats.roles[role] and storageSpace then
		local userId = g.players:GetUserIdFromNameAsync(userName)
		local playerDataStore = g.dataStoreService:GetDataStore("players_hc_v1", userId .. "_" .. role)
		local storageSpace = playerDataStore:SetAsync("bankStorageSpace", storageSpace)
		coroutine.wrap(function()
			do
				_G.Webhooks:AdminUsed(player,"Set Bank Storage",userId,tostring(storageSpace))
			end
		end)()
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.givePlayerItem = function(player, userName, role, itemName)
	if jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId) and _G.stats.roles[role] and _G.stats.items[itemName] then
		local target
		for _, v in next, g.players:GetPlayers() do
			if v.Name == userName then
				target = v
				break
			end
		end

		local userId = g.players:GetUserIdFromNameAsync(userName)
		if target and role == target.Status.Role.Value then
			Instance.new('BoolValue', target.Status.Items).Name = itemName
		else
			local playerDataStore = g.dataStoreService:GetDataStore("players_hc_v1", userId .. "_" .. role)
			playerDataStore:UpdateAsync("backpack", function(backpack)
				table.insert(backpack, itemName)
				return backpack
			end)
		end

		coroutine.wrap(function()
			do
				_G.Webhooks:AdminUsed(player,"Gave Item",userId,itemName)
			end
		end)()

		return true
	end
end

jjsqaEROmGwDxiOoBJQP.godPlayer = function(player, userName)
	
end

jjsqaEROmGwDxiOoBJQP.ungodPlayer = function(player, userName)
	
end



jjsqaEROmGwDxiOoBJQP.wipePlayer = function(userId)
	local username = game:GetService'Players':GetNameFromUserIdAsync(userId)
	for i, v in next, {'Colonist';'Native';'Hudson\'s Bay Company'} do
		jjsqaEROmGwDxiOoBJQP.clearPlayerBank('server', username, v)
		jjsqaEROmGwDxiOoBJQP.clearPlayerInventory('server', username, v)
	end
	return true
end

jjsqaEROmGwDxiOoBJQP.clearPlayerBank = function(player, userName, role)
	if (player == 'server' or jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId)) and _G.stats.roles[role] then
		local userId = g.players:GetUserIdFromNameAsync(userName)
		local playerDataStore = g.dataStoreService:GetDataStore("players_hc_v1", userId .. "_" .. role)
		playerDataStore:SetAsync("bankItems", {})
		playerDataStore:SetAsync("bankPounds", 0)
		if player ~= 'server' then
			coroutine.wrap(function()
				do
					_G.Webhooks:AdminUsed(player,"Cleared Bank",userId," ")
				end
			end)()
		end
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.clearPlayerInventory = function(player, userName, role)
	if (player == 'server' or jjsqaEROmGwDxiOoBJQP.find(g.stats.arbs.admins, player.UserId)) and _G.stats.roles[role] then
		local userId = g.players:GetUserIdFromNameAsync(userName)
		local playerDataStore = g.dataStoreService:GetDataStore("players_hc_v1", userId .. "_" .. role)
		print("Removing inventory & equipment")
		playerDataStore:SetAsync("equipment", {})
		playerDataStore:SetAsync("backpack", {})
		playerDataStore:SetAsync("pounds", 30)
		if player ~= 'server' then
			coroutine.wrap(function()
				do
					_G.Webhooks:AdminUsed(player,"Cleared Inventory",userId," ")
				end
			end)()
		end
		return true
	end
end

function jjsqaEROmGwDxiOoBJQP.dropPlayerPounds(player, pounds, position)
	if pounds > 0 and player.Status.Pounds.Value >= pounds then
		local poundsModel = _G.resources.Game_Interactives.Game_Items.Pounds:Clone()
		poundsModel.Amount.Value = pounds
		player.Status.Pounds.Value = player.Status.Pounds.Value - pounds
		poundsModel:SetPrimaryPartCFrame(position or player.Character.HumanoidRootPart.CFrame)
		poundsModel.Parent = _G.items
	end
end

function jjsqaEROmGwDxiOoBJQP.dropPlayerMeat(player, position)
	local meatModel = _G.resources.Game_Interactives.Game_Items["Raw human meat"]:Clone()
	meatModel:SetPrimaryPartCFrame(position or player.Character.HumanoidRootPart.CFrame)
	meatModel.Parent = _G.items
end

jjsqaEROmGwDxiOoBJQP.respawnPlayer = function(player)
	if player.Status.Downed.Value and not player.Status.Respawning.Value and tick() - player.Status.LastDowned.Value >= _G.stats.places[game.PlaceId].respawnCooldown then
		player.Status.detectionCount.Value = 0
		player.Status.Respawning.Value = true
		player.Character.Humanoid.Sit = false
		jjsqaEROmGwDxiOoBJQP.dropPlayerPounds(player, math.min(player.Status.Pounds.Value * .1, 100))
		--jjsqaEROmGwDxiOoBJQP.dropPlayerMeat(player)
		local spawnCFrame
		if _G.stats.places[game.PlaceId].conquering and player.Status.Faction.Value ~= 0 and _G.storage.Islands[game.PlaceId].Faction.Value == player.Status.Faction.Value then
			local spawnObject = _G.mouseFilter.Spawns.Conqueror["1"]
			spawnCFrame = CFrame.new(math.random(spawnObject.Position.X - (spawnObject.Size.X / 2), spawnObject.Position.X + (spawnObject.Size.X / 2)), spawnObject.Position.Y + 3.5, math.random(spawnObject.Position.Z - (spawnObject.Size.Z / 2), spawnObject.Position.Z + (spawnObject.Size.Z / 2)))
		else
			spawnCFrame = CFrame.new(player.Status.SpawnPosition.Value)
		end
		for i, v in pairs(_G.operables.Deployables:GetChildren()) do
			if v.Status.Type.Value == "spawn" and v.Status.Owner.Value == player then
				spawnCFrame = CFrame.new(v.Status.SpawnPosition.Value)
				break
			end
		end
		_G.teleportCache[player]:Teleport(spawnCFrame.Position)
		player.Status.Health.Value = player.Status.Health.MaxValue
		player.Status.Respawning.Value = false
		player.Status.LastRespawn.Value = tick()
	end
end

jjsqaEROmGwDxiOoBJQP.downPlayer = function(player)
	if not player.Status.Respawning.Value then
		player.Status.Health.Value = 0
	end
end

jjsqaEROmGwDxiOoBJQP.weldModel = function(model)
	for i, v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") and v ~= model.PrimaryPart then
			local weldObject = Instance.new("Weld", v)
			weldObject.Part0 = v
			weldObject.Part1 = model.PrimaryPart
			weldObject.C0 = v.CFrame:inverse() * model.PrimaryPart.CFrame
		end
	end
end

jjsqaEROmGwDxiOoBJQP.bleedPlayer = function(targetPlayer, damage, player)
	if not targetPlayer.Status.Downed.Value then
		damage = math.abs(damage)
		if targetPlayer.Status.Bleed.Value == 0 then
			targetPlayer.Status.Bleed.Value = damage
			targetPlayer.Character.Torso.Bleed.Enabled = true
			while wait(4) and targetPlayer.Parent and targetPlayer.Status.Bleed.Value > 0 and not targetPlayer.Status.Downed.Value do
				if math.fmod(targetPlayer.Status.Bleed.Value, 5) == 0 then
					coroutine.wrap(jjsqaEROmGwDxiOoBJQP.bloodDrip)(targetPlayer)
				end
				targetPlayer.Status.Bleed.Value = targetPlayer.Status.Bleed.Value - 1
				targetPlayer.Status.Health.Value = targetPlayer.Status.Health.Value - 1
				if player then
					jjsqaEROmGwDxiOoBJQP.claimBounty(player, targetPlayer)
				end
			end
			targetPlayer.Status.Bleed.Value = 0
			if targetPlayer.Character then
				targetPlayer.Character.Torso.Bleed.Enabled = false
			end
		else
			targetPlayer.Status.Bleed.Value = targetPlayer.Status.Bleed.Value + damage
		end
	end
end

jjsqaEROmGwDxiOoBJQP.updateBlockingPlayer = function(player, request)
	player.Status.Blocking.Value = request
end

jjsqaEROmGwDxiOoBJQP.hitBlockingPlayer = function(player, targetPlayer)
	g.client.sendToClient(targetPlayer, "parryPlayer")
end

jjsqaEROmGwDxiOoBJQP.parryPlayer = function()
	g.integrity:depleteStamina(g.stats.arbs.parryStaminaCost)
	if g.inventory.itemDrawn then
		g.inventory.itemDrawn:endBlock()
	end
end

jjsqaEROmGwDxiOoBJQP.bandagePlayer = function(player, targetPlayer)
	local itemValue = g.item.getFirstEquipped(player, "Bandage")
	if itemValue and (targetPlayer.Status.Bleed.Value > 0 or targetPlayer.Status.Health.Value < targetPlayer.Status.Health.MaxValue) and (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).magnitude < 10 then
		itemValue:Destroy()
		targetPlayer.Status.Bleed.Value = 0
		if player == targetPlayer then	

			print(game:GetService("RunService"):IsServer())
			-- new stuff (coior)

			-- decrease value after they respawn and stuff...
			if (targetPlayer.Status.Downed.Value == true and targetPlayer.Status.detectionCount.Value >= 3) then
				return;
			elseif (targetPlayer.Status.Downed.Value == true) then
				targetPlayer.Status.detectionCount.Value = targetPlayer.Status.detectionCount.Value + 1
			end

			-- end of new stuff (coior)
			targetPlayer.Status.Health.Value = targetPlayer.Status.Health.Value + g.stats.items.Bandage.healAmountSelf
		else
			targetPlayer.Status.detectionCount.Value = 0
			targetPlayer.Status.Health.Value = targetPlayer.Status.Health.Value + g.stats.items.Bandage.healAmountOther
			g.client.sendToClient(targetPlayer, "newHint", player.Name .. " bandages you")
		end
	end
end

jjsqaEROmGwDxiOoBJQP.restrainPlayer = function(player,targetPlayer,Value)
	local itemValue = g.item.getFirstEquipped(player,"Handcuffs")
	if itemValue and (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).magnitude < 10 then
		targetPlayer.Status.Restrained.Value = Value
		--g.client.sendToClient(targetPlayer, "newHint", player.Name .. " restrains/unrestrains you")
	end
end

jjsqaEROmGwDxiOoBJQP.bloodDrip = function(player)
	coroutine.wrap(g.client.sendToAllClients)("animateBloodDrip", player)
end

jjsqaEROmGwDxiOoBJQP.resetPlayerPosition = function(player)
	for i, v in pairs(_G.stats.roles) do
		local playerDataStore = _G.dataStoreService:GetDataStore("players_hc_v1", player.UserId .. "_" .. i)
		playerDataStore:SetAsync("lastSafePositionX", false)
		playerDataStore:SetAsync("lastSafePositionY", false)
		playerDataStore:SetAsync("lastSafePositionZ", false)
	end
end

jjsqaEROmGwDxiOoBJQP.lootPlayer = function(player, targetPlayer, itemName)
	local itemValue = targetPlayer.Status.Items:FindFirstChild(itemName)
	if targetPlayer.Status.Downed.Value and targetPlayer.Status.canBeLooted.Value == true and not player.Status.Downed.Value and (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).magnitude < 10 and itemValue and (g.stats.items[itemValue.Name].canBeLooted or (g.stats.items[itemValue.Name].illegalHBM and targetPlayer.Status.Role.Value ~= "Hudson's Bay Company") or (g.stats.items[itemValue.Name].illegalNFC and targetPlayer.Status.Role.Value ~= "Nouvelle-France Company")) then
		itemValue.Value = false
		itemValue.Parent = player.Status.Items
	end
end

jjsqaEROmGwDxiOoBJQP.lootStorage = function(player, operableModel, itemName)
	local itemValue = operableModel.Status.Items:FindFirstChild(itemName)
	if not player.Status.Downed.Value and (player.Character.HumanoidRootPart.Position - operableModel.PrimaryPart.Position).magnitude < 10 and itemValue then
		itemValue.Value = false
		itemValue.Parent = player.Status.Items
	end
end

jjsqaEROmGwDxiOoBJQP.lootFactionStorage = function(player, operableModel, itemName, faction)
	local itemValue = operableModel.Status.Items:FindFirstChild(itemName)
	if not player.Status.Downed.Value and (player.Character.HumanoidRootPart.Position - operableModel.PrimaryPart.Position).magnitude < 10 and itemValue then
		itemValue.Value = false
		itemValue.Parent = player.Status.Items
	end
end

jjsqaEROmGwDxiOoBJQP.setPlayerRole = function(player, roleName)
	local roleStats = g.stats.roles[roleName]
	local isInMainGroup = player:IsInGroup(g.stats.arbs.mainGroupID)
	--local isInSecondaryGroup = player:IsInGroup(g.stats.arbs.secondaryGroupID)
	if not player.Status.Preparing.Value and ((roleStats.type == "department" and isInMainGroup and player:IsInGroup(roleStats.groupID)) or (roleStats.type == "main" and isInMainGroup and player:GetRankInGroup(g.stats.arbs.mainGroupID) >= roleStats.rankID) or roleStats.type == "default" or g.misc.find(g.stats.arbs.admins, player.UserId)) then
		player.Status.Preparing.Value = true
		player.Status.Role.Value = roleName
		g.client.setInventory(player, roleName)
		player.PlayerGui.ChildAdded:Connect(function() 
			jjsqaEROmGwDxiOoBJQP.CheckUI(player)
		end)

		return true
	end
end

jjsqaEROmGwDxiOoBJQP.setInSnow = function(player, request, isWalking)
	isWalking = isWalking or player.Character.Humanoid.MoveDirection ~= Vector3.new(0, 0, 0)
	local rightSnowSteps = player.Character["Right Leg"].SnowSteps
	local leftSnowSteps = player.Character["Left Leg"].SnowSteps

	if request then
		rightSnowSteps.Enabled = isWalking
		leftSnowSteps.Enabled = isWalking
		--player.Character.Head:WaitForChild("Running").SoundId = "rbxassetid://130873495"
		--player.Character.Head.Running.PlaybackSpeed = 1
	else
		rightSnowSteps.Enabled = false
		leftSnowSteps.Enabled = false
		--player.Character.Head:WaitForChild("Running").SoundId = "rbxassetid://577413899"
		--player.Character.Head.Running.PlaybackSpeed = 1.3
	end
end

jjsqaEROmGwDxiOoBJQP.setWarmthLow = function(player, request)
	player.Character.Head.Breath.Enabled = request
end

jjsqaEROmGwDxiOoBJQP.generatePlayerCaughtFish = function(player, itemValue)
	if itemValue and itemValue.Parent == player.Status.Items and itemValue.Value then
		local indexes = {}
		for i = 1, #_G.stats.fishes do
			for j = 1, math.pow(#_G.stats.fishes + 1 - i, 2) do
				table.insert(indexes, i)
			end
		end
		local fishName = _G.stats.fishes[indexes[math.random(1, #indexes)] ]
		player.Status.LastCaughtFish.Value = fishName
		return fishName
	end
end


jjsqaEROmGwDxiOoBJQP.resetPlayerCaughtFish = function(player)
	player.Status.LastCaughtFish.Value = ""
end

jjsqaEROmGwDxiOoBJQP.takePlayerCaughtFish = function(player, itemValue, target)
	if itemValue and itemValue.Parent == player.Status.Items and itemValue.Value and player.Status.LastCaughtFish.Value ~= "" then
		local rs = autofish.check(player, target)
		if rs == true then
			-- _g.misc.banPlayer(nil, player.Name, true, 'Auto fishing')
			return
		elseif rs == 'ban' then
			_g.misc.banPlayer(nil, player.Name, true, 'Auto fishing')
			return
		end

		coroutine.wrap(_G.item.add)(player, player.Status.LastCaughtFish.Value)
		player.Status.LastCaughtFish.Value = ""
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.travelPlayer = function(player, travelPointName)
	if not player.Status.Downed.Value then
		_G.teleportCache[player]:Teleport((_G.mouseFilter.TravelPoints[travelPointName].CFrame * CFrame.new(math.random(0, 10) - 5, 3.5, math.random(0, 10) - 5)).Position)
	end
end

jjsqaEROmGwDxiOoBJQP.checkPlayerStatus = function(player)
	if player.Status.Downed.Value or player.Character.Humanoid.Sit then
		return true
	end
end

jjsqaEROmGwDxiOoBJQP.checkPlayerDowned = function(player)
	return player.Status.Downed.Value
end

jjsqaEROmGwDxiOoBJQP.setupSounds = function()

	--coroutine.wrap(function()
	--while task.wait(5) do
	-- delay and a table of the sounds to calculate delay for
	--local soundPlayDelay = .3
	--local Sounds = g.remotes.GetPlayableSounds:InvokeServer(soundPlayDelay, { 'Ambience', 'Swimming', 'Running', 'Walking', 'Jumping', 'Falling', 'Notification' })
	-- for _, sound in ipairs(Sounds) do
	-- print(sound)
	-- end
	-- work in progress sound handler
	--end
	--end)()

	workspace.DescendantAdded:Connect(function(child)
		if child:IsA("Sound") then
			child.SoundGroup = g.sounds.SoundGroup
		end
	end)
	for i, v in pairs(g.playersService:GetPlayers()) do
		spawn(function()
			if v.Character then
				v.Character:WaitForChild("Head")
				wait(1)
				for j, k in pairs(v.Character.Head:GetChildren()) do
					if k:IsA("Sound") then
						k.SoundGroup = g.sounds.SoundGroup
					end
				end
			end
		end)
	end
end

function jjsqaEROmGwDxiOoBJQP.updateAmbientMusic(soundId)
	g.sounds.AmbientMusic.SoundId = g.stats.arbs.assetLink .. soundId
	g.contentProviderService:PreloadAsync({ g.sounds.AmbientMusic })
	repeat wait() until g.sounds.AmbientMusic.IsLoaded
	g.sounds.AmbientMusic.Volume = 0
	g.sounds.AmbientMusic:Play()

	local ambienceIsMusic = g.interface.menuShown
	for i, v in pairs(g.loadedZones) do
		if v.stats.ambienceIsMusic then
			ambienceIsMusic = true
			break
		end
	end
	if not ambienceIsMusic then
		g.tweenService:Create(g.sounds.AmbientMusic, TweenInfo.new(3), { Volume = .8 }):Play()
	end
	wait(g.sounds.AmbientMusic.TimeLength - 10)
	g.tweenService:Create(g.sounds.AmbientMusic, TweenInfo.new(10), { Volume = 0 }):Play()
	wait(10)
	g.sounds.AmbientMusic:Stop()
end

function jjsqaEROmGwDxiOoBJQP.damageHungerPlayer(player)
	player.Status.Health.Value = player.Status.Health.Value - _G.stats.arbs.hungerDepletedDamage
end

function jjsqaEROmGwDxiOoBJQP.getPlayerPrimaryGroup(player)
	local groups = (_G.groupService or g.groupService):GetGroupsAsync((player or g.player).UserId)
	for i, v in pairs(groups) do
		if v.IsPrimary then
			return v
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.setupFaction(groupID)
	local factionFolder = _G.storage.Factions:FindFirstChild(groupID)
	if not factionFolder then
		factionFolder = Instance.new("Folder")
		factionFolder.Name = groupID
		factionFolder.Parent = _G.storage.Factions
		Instance.new("StringValue", factionFolder).Name = "RawDescription"
		Instance.new("StringValue", factionFolder).Name = "FName"
		Instance.new("StringValue", factionFolder).Name = "Emblem"
		Instance.new("StringValue", factionFolder).Name = "Owner"
		Instance.new("StringValue", factionFolder).Name = "Acronym"
		Instance.new("StringValue", factionFolder).Name = "Description"
		Instance.new("StringValue", factionFolder).Name = "Role"
		Instance.new("Color3Value", factionFolder).Name = "Color"
		Instance.new("BoolValue", factionFolder).Name = "TeamKill"
		Instance.new("IntValue", factionFolder).Name = "MinimumRank"
		Instance.new("BoolValue", factionFolder).Name = "HasUniform"
		Instance.new("IntValue", factionFolder).Name = "ShirtID"
		Instance.new("IntValue", factionFolder).Name = "PantsID"
		factionFolder.HasUniform.Value = _G.dataStoreService:GetDataStore("factions_hc", groupID):GetAsync("hasUniform") == true
		jjsqaEROmGwDxiOoBJQP.updateFaction(groupID)

		spawn(function()
			while not factionFolder.HasUniform.Value and factionFolder.Parent ~= nil do
				factionFolder.HasUniform.Value = _G.dataStoreService:GetDataStore("factions_hc", groupID):GetAsync("hasUniform") == true
				wait(60)
			end
		end)

		spawn(function()
			while wait(30) and factionFolder.Parent ~= nil do
				jjsqaEROmGwDxiOoBJQP.updateFaction(groupID)
			end
		end)
	end
	return factionFolder
end

function jjsqaEROmGwDxiOoBJQP.updateFaction(groupID)
	local groupInfo = _G.groupService:GetGroupInfoAsync(groupID)
	local factionFolder = _G.storage.Factions[groupID]
	if factionFolder.RawDescription.Value == "" or factionFolder.RawDescription.Value ~= groupInfo.Description then
		factionFolder.RawDescription.Value = groupInfo.Description
		local readingDescription = false
		local acronym, role, teamKill, color, minimumRank, description, shirtID, pantsID
		for word in string.gmatch(groupInfo.Description, "%S+") do
			if string.sub(word, 1, 25) == "affiliation_minimum_rank:"  then
				minimumRank = tonumber(string.sub(word, 26))
			elseif string.sub(word, 1, 29) == "affiliation_description:start"  then
				readingDescription = true
			elseif string.sub(word, 1, 27) == "affiliation_description:end"  then
				readingDescription = false
			elseif string.sub(word, 1, 22) == "affiliation_team_kill:"  then
				teamKill = string.lower(string.sub(word, 19)) == "true"
			elseif string.sub(word, 1, 17) == "affiliation_role:"  then
				word = string.lower(string.sub(word, 14))
				if word == "e" then
					word = string.lower("e")
				end
				for i, v in pairs(_G.stats.roles) do
					if string.lower(i) == word then
						role = i
					end
				end
			elseif string.sub(word, 1, 20) == "affiliation_acronym:" then
				word = string.upper(string.sub(word, 21, 31))
				if string.len(word) >= 3 and (groupInfo.Id == _G.stats.arbs.mainGroupID or not string.find(word, "HBM")) then
					acronym = word
				end
			elseif string.sub(word, 1, 19) == "roblox.com/library/" then
				local assetID
				for _word in string.gmatch(string.sub(word, 20), "([^/]+)/([^/]+)") do
					assetID = _word
					break
				end
				if string.sub(word, string.len(word) - 16) == "affiliation_shirt" then
					shirtID = tonumber(assetID)
				end
				if string.sub(word, string.len(word) - 16) == "affiliation_pants" then
					pantsID = tonumber(assetID)
				end
			elseif string.sub(word, 1, 18) == "affiliation_color:" then
				local colors = {}
				for color in string.gmatch(string.sub(word, 19), "%d+") do
					table.insert(colors, color)
				end
				local r = tonumber(colors[1])
				local g = tonumber(colors[2])
				local b = tonumber(colors[3])
				if r and g and b then
					color = Color3.fromRGB(math.max(0, math.min(255, r)), math.max(0, math.min(255,g)), math.max(0, math.min(255, b)))
				end
			elseif readingDescription then
				if description then
					description = description .. " " .. word
				else
					description = word
				end
			end
		end
		factionFolder.FName.Value = groupInfo.Name
		factionFolder.Emblem.Value = groupInfo.EmblemUrl 
		factionFolder.Owner.Value = groupInfo.Owner.Name 
		factionFolder.Acronym.Value = acronym or string.upper(string.sub(groupInfo.Name, 1, 5))
		factionFolder.Description.Value = description or ""
		factionFolder.Role.Value = role or ""
		factionFolder.TeamKill.Value = teamKill == true
		factionFolder.Color.Value = color or Color3.new(1, 1, 1)
		factionFolder.MinimumRank.Value = minimumRank or 0
		if factionFolder.HasUniform.Value then
			factionFolder.ShirtID.Value = shirtID or 0
			factionFolder.PantsID.Value = pantsID or 0
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.checkPlayerFaction(player)
	local playerGroup
	if player.Status.Role.Value == "Hudson's Bay Company" then
		for i, v in pairs(_G.groupService:GetGroupsAsync(player.UserId)) do
			if v.Id == _G.stats.arbs.mainGroupID then
				playerGroup = v
				break
			end
		end

	else
		playerGroup = jjsqaEROmGwDxiOoBJQP.getPlayerPrimaryGroup(player)
	end

	if playerGroup and (_G.storage.Factions:FindFirstChild(playerGroup.Id) or _G.dataStoreService:GetDataStore("factions_hc", playerGroup.Id):GetAsync("timeCreated")) then
		local factionFolder = jjsqaEROmGwDxiOoBJQP.setupFaction(playerGroup.Id)
		if (factionFolder.Role.Value == "" or factionFolder.Role.Value == player.Status.Role.Value) and factionFolder.MinimumRank.Value <= playerGroup.Rank then
			player.Status.Faction.Value = playerGroup.Id
			local labelGui = player.Character.Head.LabelBillboardGui
			labelGui.GroupLabel.Text = factionFolder.Acronym.Value .. " | " .. playerGroup.Role
			labelGui.GroupLabel.TextColor3 = factionFolder.Color.Value
		else
			jjsqaEROmGwDxiOoBJQP.resetPlayerFaction(player)
		end
	elseif _G.stats.places[game.PlaceId].conquering then
		player:Kick("You must stay in your faction to keep conquering islands!")
	else
		jjsqaEROmGwDxiOoBJQP.resetPlayerFaction(player)
	end
end

function jjsqaEROmGwDxiOoBJQP.resetPlayerFaction(player)
	player.Status.Faction.Value = 0

	local labelGui = player.Character.Head.LabelBillboardGui
	labelGui.GroupLabel.Text = ""
end

function jjsqaEROmGwDxiOoBJQP.ShouldReplicateFire(player, itemModel)
	local itemStats = _G.stats.items[itemModel.Name]
	if minigun.ShouldReplicate(player, itemModel.Name, itemStats) == false then
		return false
	else
		return true
	end
end

function jjsqaEROmGwDxiOoBJQP.animatePlayerFire(player, itemModel, ...)
	local hits = { ... }
	local itemStats = _G.stats.items[itemModel.Name]

	if (itemStats.weapon.scattershot and (#hits / 2) > itemStats.weapon.ammoAmount) or (not itemStats.weapon.scattershot and (#hits / 2) > 1) then
		return
	end
	if itemStats.weapon.projectile then
		for i = 1, #hits do
			if math.fmod(i, 2) == 1 then
				local hitPosition = hits[i]
				local chargeForce = hits[i + 1]
				_G.client.sendToOtherClients(player, "animateProjectile", itemModel, hitPosition, chargeForce)
			end
		end
	else
		for i = 1, #hits do
			if math.fmod(i, 2) == 1 then
				local hitPosition = hits[i]
				local hitObject = hits[i + 1]
				_G.client.sendToOtherClients(player, "animateBullet", itemModel, hitPosition, hitObject ~= false)
			end
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.claimDailyReward(player)
	local date = jjsqaEROmGwDxiOoBJQP.osDateToString(os.date("!*t"))
	if jjsqaEROmGwDxiOoBJQP.isOsDateBeforeOsDate(player.Status.LastDailyReward.Value, date) then
		player.Status.LastDailyReward.Value = date
		local playerDataStore = _G.dataStoreService:GetDataStore("players_hc_v1", player.UserId .. "_" .. player.Status.Role.Value)
		playerDataStore:SetAsync("lastDailyReward", date)
		local reward = g.stats.daily[player.Status.Role.Value]
		--if g.player.Status.LoginStreak.Value < 7 then
		if reward.pounds then
			player.Status.Pounds.Value = player.Status.Pounds.Value + reward.pounds-- + (5 * g.player.Status.LoginStreak.Value))
		end
		if reward.items then
			for i, v in pairs(reward.items) do
				for j = 1, v do
					_G.item.add(player, i)
				end
			end
		end
		return true
	end
end

function jjsqaEROmGwDxiOoBJQP.osDateToString(osdate)
	local day = tostring(osdate.day)
	local month = tostring(osdate.month)
	local year = tostring(osdate.year)
	if string.len(day) == 1 then
		day = "0" .. day
	end
	if string.len(month) == 1 then
		month = "0" .. month
	end
	return day .. "/" .. month .. "/" .. year
end

function jjsqaEROmGwDxiOoBJQP.isOsDateBeforeOsDate(osdate1, osdate2)
	local day1 = tonumber(string.sub(osdate1, 1, 2))
	local month1 = tonumber(string.sub(osdate1, 4, 5))
	local year1 = tonumber(string.sub(osdate1, 7, 10))

	local day2 = tonumber(string.sub(osdate2, 1, 2))
	local month2 = tonumber(string.sub(osdate2, 4, 5))
	local year2 = tonumber(string.sub(osdate2, 7, 10))
	if not day1 and not month1 and not year1 then
		return true
	end
	return (year1 < year2) or (year1 == year2 and month1 < month2) or (year1 == year2 and month1 == month2 and day1 < day2)
end

function jjsqaEROmGwDxiOoBJQP.claimTwitterReward(player, code)
	if _G.stats.twitter[code] then
		local playerDataStore = _G.dataStoreService:GetDataStore("players_hc_v1", player.UserId .. "_" .. player.Status.Role.Value)
		local codeTime = playerDataStore:GetAsync("twitterCode_" .. code)
		if not codeTime then
			playerDataStore:GetAsync("twitterCode_" .. os.time())
			for i, v in pairs(_G.stats.twitter[code]) do
				for j = 1, v do
					_G.item.add(player, i)
				end
			end
		end
	end
end

function jjsqaEROmGwDxiOoBJQP.travelPlayerIsland(player, placeID)
	if player.Status.Faction.Value ~= 0  then
		if _G.storage.Islands[placeID].PlayerAmount.Value < 50 then
			if player.Status.TeleportingPlace.Value == 0 then
				player.Status.TeleportingPlace.Value = placeID
				if _G.storage.Islands[placeID].ServerID.Value == "" then
					_G.teleportService:Teleport(placeID, player, { role = player.Status.Role.Value })
				else
					_G.teleportService:TeleportToPlaceInstance(placeID, _G.storage.Islands[placeID].ServerID.Value, player, nil, { role = player.Status.Role.Value })
				end
			else
				return "alreadyTeleporting"
			end
		else
			return "playerAmount"
		end
	else
		return "faction"
	end
end

function jjsqaEROmGwDxiOoBJQP.newHint(text)
	g.interface:newHint(text)
end

function jjsqaEROmGwDxiOoBJQP.updatePlayerHair(player, colorIndex, hairIndex, facialHairIndex)
	if player.Status.Pounds.Value >= _G.stats.arbs.barberCost then
		player.Status.Pounds.Value = player.Status.Pounds.Value - _G.stats.arbs.barberCost

		player.Status.HairColor.Value = colorIndex
		player.Status.Hair.Value = hairIndex
		player.Status.FacialHair.Value = facialHairIndex

		if player.Character.Attachments:FindFirstChild("Hair") then
			player.Character.Attachments.Hair:Destroy()
		end
		if hairIndex > 0 then
			local hair = _G.objects.Hair[hairIndex]:Clone()
			jjsqaEROmGwDxiOoBJQP.weldModel(hair)
			hair.Name = "Hair"
			hair:SetPrimaryPartCFrame(player.Character.Head.CFrame)
			local weldObject = Instance.new("Weld", hair.PrimaryPart)
			weldObject.Part0 = hair.PrimaryPart
			weldObject.Part1 = player.Character.Head
			weldObject.C0 = hair.PrimaryPart.CFrame:inverse() * player.Character.Head.CFrame
			hair.Hair.BrickColor = BrickColor.new(_G.stats.arbs.hairColors[colorIndex])
			hair.Parent = player.Character.Attachments

			for i, v in pairs(player.Character:GetChildren()) do
				if v:IsA("Accessory") then
					v.Handle.Transparency = 1
				end
			end
		else
			for i, v in pairs(player.Character:GetChildren()) do
				if v:IsA("Accessory") then
					v.Handle.Transparency = 0
				end
			end
		end

		if player.Character.Attachments:FindFirstChild("FacialHair") then
			player.Character.Attachments.FacialHair:Destroy()
		end
		if facialHairIndex > 0 and hairIndex < _G.stats.arbs.firstFemaleHairIndex then
			local facialHair = _G.objects.FacialHair[facialHairIndex]:Clone()
			jjsqaEROmGwDxiOoBJQP.weldModel(facialHair)
			facialHair.Name = "FacialHair"
			facialHair:SetPrimaryPartCFrame(player.Character.Head.CFrame)
			local weldObject = Instance.new("Weld", facialHair.PrimaryPart)
			weldObject.Part0 = facialHair.PrimaryPart
			weldObject.Part1 = player.Character.Head
			weldObject.C0 = facialHair.PrimaryPart.CFrame:inverse() * player.Character.Head.CFrame
			facialHair.Hair.BrickColor = BrickColor.new(_G.stats.arbs.hairColors[colorIndex])
			facialHair.Parent = player.Character.Attachments
		else
			player.Status.FacialHair.Value = 0
		end

		return true
	end
end

return jjsqaEROmGwDxiOoBJQP
