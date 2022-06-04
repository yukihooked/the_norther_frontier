local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))

local itFNheliaSCKPIklgOEw = {}
local g
itFNheliaSCKPIklgOEw.__index = itFNheliaSCKPIklgOEw

function itFNheliaSCKPIklgOEw.init(_g)
	g = _g
	local self = {}
	setmetatable(self, itFNheliaSCKPIklgOEw)
	return self
end

function itFNheliaSCKPIklgOEw:start()	
	self.interacting = false
	self.deploying = false
	self.interactionStart = nil
	self.animationTrack = nil
	self.debounce = false
	self.objectTargetting = nil
	self.triggerModelTargetting = nil
	self.interactionType = nil
	self.itemDeploying = nil
	self.deployValid = false
	self.parameter = nil
	self.itemDragging = nil
	self.playerDragging = nil
	self.buttonDown = false
	self.highlighted = false

	coroutine.wrap(function()
		for i, v in pairs(g.operablesF:GetChildren()) do
			coroutine.wrap(function()
				v.ChildAdded:Connect(function(k)
					g.operables[k] = g.operable.new(k)
				end)
				for i, k in pairs(v:GetChildren()) do
					g.operables[k] = g.operable.new(k)
					wait()
				end
			end)()
		end
	end)()

	coroutine.wrap(function()
		for i, v in pairs(g.mouseFilter:WaitForChild("Operables"):GetChildren()) do
			coroutine.wrap(function()
				g.operables[v] = g.operable.new(v)
			end)()
			wait()
		end
	end)()

	for i, v in pairs(g.zonesF:GetChildren()) do
		local succ, err = pcall(function()
			g.zones[v.Name] = g.zone.new(v)
			wait()
		end)
		if not succ then
			warn(err)
		end
	end

	spawn(function()
		for i, v in pairs(game.Players:GetPlayers()) do
			if not g.players[v.Name] and v ~= g.player then
				spawn(function()
					g.players[v.Name] = g.otherPlayer.new(v)
				end)
				wait()
			end
		end
	end)

	if g.mouseFilter.Misc:FindFirstChild("FrontierSign") then
		g.operable:animateSign(g.mouseFilter.Misc.FrontierSign)
	end

	self:target()
end

function itFNheliaSCKPIklgOEw:_start()
	if g.stats.interactions.test.debounce ~= 100 then while true do print'Joe Biden' end end
	if self.objectTargetting or self.deployValid then
		self.interacting = true
		self.interactionStart = tick()
		g.stance:updateWalkSpeed()
		local currentInteractionStart = self.interactionStart
		local debounce
		if self.itemDeploying and self.itemDeploying.stats.deployTime then
			debounce = self.itemDeploying.stats.deployTime
		elseif self.interactionType == "takeDown" then
			if (g.stats.items[self.objectTargetting.name].takeDownTime) then
				debounce = (g.stats.items[self.objectTargetting.name].takeDownTime) * (g.inventory.itemDrawn.stats.effectivenessTime or 1)
			else
				debounce = (g.stats.items[self.objectTargetting.name].deployTime or g.stats.interactions.takeDown.debounce) * (g.inventory.itemDrawn.stats.effectivenessTime or 1)
			end
		elseif self.interactionType == "tree" or self.interactionType == "mine" then
			debounce = g.stats.interactions[self.interactionType].debounce * (g.inventory.itemDrawn.stats.effectivenessTime or 1)
		else
			debounce = g.stats.interactions[self.interactionType].debounce
		end
		g.interface:highlightInteraction(debounce)
		self.animationTrack = g.stance:getAnimationTrack(g.stats.interactions[self.interactionType].animationID)
		if self.animationTrack then
			self.animationTrack:Play()
		end
		coroutine.wrap(function()
			if self.interactionType == "tree" or self.interactionType == "takeDown" then
				g.inventory.itemDrawn:animateCutDown()
			end
			if self.interactionType == "mine" then
				g.inventory.itemDrawn:animateMining()
			end
		end)()
		wait(debounce)
		if self.interactionStart and self.interactionStart == currentInteractionStart then
			if self.animationTrack then
				self.animationTrack:Stop()
				self.animationTrack = nil
			end
			self:_____request()
		end
	end
end

function itFNheliaSCKPIklgOEw:stop()
	if self.interacting then
		self.interacting = false
		self.interactionStart = nil
		g.interface:unhighlightInteraction()
		if self.animationTrack then
			self.animationTrack:Stop()
			self.animationTrack = nil
		end
		g.stance:updateWalkSpeed()
	end
end

function itFNheliaSCKPIklgOEw:request()
	game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer('5F6139E3-A0FA-49B8-A3DC-D25364604FD0', "fast interaction detection")
end

function itFNheliaSCKPIklgOEw:_request()
	game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer('5F6139E3-A0FA-49B8-A3DC-D25364604FD0', "fast interaction detection")
end

function itFNheliaSCKPIklgOEw:_____request()
	if self.interacting and (self.objectTargetting or self.deployValid) then
		self.highlighted = false
		if self.interactionType == "deployItem" then
			g.inventory:deployItem(self.itemDeploying, self.itemDeployingPreviewModel:GetPrimaryPartCFrame())
		elseif self.interactionType == "cart" and not self.objectTargetting.dragger then
			if self.triggerModelTargetting.Name == "ChestTrigger" then
				self.objectTargetting:showStorage()
			else
				self.objectTargetting:dragCart()
			end
		elseif self.interactionType == "takeItem" then
			if #g.inventory.backpack > 150 then
				g.interface:newHint("Cannot carry any more items")
			else
				g.interface:newHint("You take the " .. self.objectTargetting.name)
				self.objectTargetting:take()
			end
		elseif self.interactionType == "lootPlayer" then
			self.objectTargetting:lootStart()
		elseif self.interactionType == "restrainPlayer" then
			if self.parameter then
				g.interface:newHint("You restrain " .. self.objectTargetting.name .. ", handcuffs are used")
				self.objectTargetting:restrain()
			else
				g.interface:newHint("You unrestrain " .. self.objectTargetting.name .. " and take the handcuffs")
				self.objectTargetting:unrestrain()
			end
		elseif self.interactionType == "bandagePlayer" then
			g.interface:newHint("You bandage " .. self.objectTargetting.name .. ", 1 bandage is used")
			self.objectTargetting:bandage()
		elseif self.interactionType == "animal" then
			self.objectTargetting:skin()
		elseif self.interactionType == "tree" then
			g.interface:newHint("You cut down the tree")
			self.objectTargetting:cutDown()
		elseif self.interactionType == "takeDown" then
			self.objectTargetting:takeDown()
		elseif self.interactionType == "mine" then
			g.interface:newHint("You mine the vein")
			self.objectTargetting:Mine()
		elseif self.interactionType == "chair" then
			g.interface:newHint("You sit down on the chair")
			self.objectTargetting:sitDown()
		elseif self.interactionType == "fire" or self.interactionType == "candle" then
			if self.parameter then
				self.objectTargetting:light()
			else
				self.objectTargetting:extinguish()
			end
		elseif self.interactionType == "crafting" then
			self.objectTargetting:useCrafting()
		elseif self.interactionType == "storage" then
			self.objectTargetting:showStorage()
		elseif self.interactionType == "spawn" then
			self.objectTargetting:claim()
		elseif self.interactionType == "travelling" then
			self.objectTargetting:showTravelling()
		elseif self.interactionType == "bank" then
			self.objectTargetting:showBank()
		elseif self.interactionType == "tradingPost" then
			self.objectTargetting:showTradingPost()
		elseif self.interactionType == "shop" then
			if self.objectTargetting:canAccessShop() then
				self.objectTargetting:showShop()
			else
				g.interface:newHint("You lack the permission level to browse the supplies")
			end
		elseif self.interactionType == "purchasable" then
			self.objectTargetting:purchase()
		elseif self.interactionType == "noticeBoard" then
			self.objectTargetting:showNoticeBoard()
		elseif self.interactionType == "islandsBoard" then
			self.objectTargetting:showIslands()
		elseif self.interactionType == "bountiesBoard" then
			self.objectTargetting:showBounties()
		elseif self.interactionType == "door" then
			if self.parameter then
				self.objectTargetting:open(self.triggerModelTargetting)
			else
				self.objectTargetting:close(self.triggerModelTargetting)
			end
		elseif self.interactionType == "bell" then
			self.objectTargetting:ring()
		end
		self.debounce = true
		self:reset()
		delay(.5, function()
			self.debounce = false
		end)
	end
end

function itFNheliaSCKPIklgOEw:highlight(model)
	for i, v in pairs(model:GetChildren()) do
		if v:IsA("BasePart") and v.Transparency < 1 then
			v.Transparency = 1
			v.CanCollide = false
			if v:IsA("MeshPart") then
				v.TextureID = ""
			end
			v.Material = Enum.Material.Neon
			g.tween:TweenNumber(v, "Transparency", .5, .2, g.tween.Ease.In.Linear)
		elseif v:IsA("Model") then
			itFNheliaSCKPIklgOEw:highlight(v)
		end
	end
end

function itFNheliaSCKPIklgOEw:target()
	coroutine.wrap(function()
		while wait(g.stats.arbs.checkDebounceTime) do
			coroutine.wrap(function()
				local objectTargetting, objectType, distance, triggerModel = self:get(g.mouse.Target)
				if not self.debounce and ((objectTargetting and (not self.objectTargetting or objectTargetting ~= self.objectTargetting) and objectType and distance < g.stats.arbs.interactionMaximumDistance) or self.itemDeploying) and g.stance:canDoAction() then				
					if self.itemDeploying then
						local deployValid = distance < g.stats.arbs.deployMaximumDistance and g.mouse.Target and g.mouse.Target:IsA("Terrain")
						if deployValid  then
							if not self.deployValid then
								self.interactionType = "deployItem"
								self.parameter = nil
								g.interface:showInteraction("Deploy " .. self.itemDeploying.name)
								self.itemDeployingPreviewModel = game.ReplicatedStorage.Game_Replicated.Game_Interactives.Game_Interactions[self.itemDeploying.name]:Clone()
								self:highlight(self.itemDeployingPreviewModel)
								self.itemDeployingPreviewModel:SetPrimaryPartCFrame(CFrame.new(g.mouse.Hit.p))
								self.itemDeployingPreviewModel.Parent = g.playerMouseFilter
							end
							g.tween:TweenCFrame(self.itemDeployingPreviewModel, "SetPrimaryPartCFrame", CFrame.new(g.mouse.Hit.p, Vector3.new(g.rootPart.Position.X, g.mouse.Hit.p.Y, g.rootPart.Position.Z)), g.stats.arbs.checkDebounceTime, g.tween.Ease.In.Linear)
						elseif self.deployValid then
							g.interface:hideInteraction()
							for i, v in pairs(self.itemDeployingPreviewModel:GetChildren()) do
								if v:IsA("BasePart") then
									g.tween:TweenNumber(v, "Transparency", 1, .2, g.tween.Ease.In.Linear)
								end
							end
							g.debris:AddItem(self.itemDeployingPreviewModel, .2)
							self.itemDeployingPreviewModel = nil
						end
						self.deployValid = deployValid
					elseif objectType == "item" then
						self.interactionType = "takeItem"
						self.objectTargetting = objectTargetting
						self.parameter = nil
						g.interface:showInteraction("Take " .. self.objectTargetting.name)
					elseif objectType == "player" then
						if g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "handcuffsKey" and objectTargetting.restrained then
							self.interactionType = "restrainPlayer"
							self.objectTargetting = objectTargetting
							self.parameter = false
							g.interface:showInteraction("Unrestrain " .. objectTargetting.name)
						elseif g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "handcuffs" and not objectTargetting.restrained then
							self.interactionType = "restrainPlayer"
							self.objectTargetting = objectTargetting
							self.parameter = true
							g.interface:showInteraction("Restrain " .. objectTargetting.name)
						elseif g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "bandage" and (objectTargetting.bleeding or objectTargetting.health < objectTargetting.maxHealth) then
							self.interactionType = "bandagePlayer"
							self.objectTargetting = objectTargetting
							self.parameter = nil
							g.interface:showInteraction("Bandage " .. objectTargetting.name)
						elseif (objectTargetting.downed or objectTargetting.restrained) and not g.interface.lootShown then
							self.interactionType = "lootPlayer"
							self.objectTargetting = objectTargetting
							self.parameter = nil
							g.interface:showInteraction("Loot " .. objectTargetting.name)
						else
							self:reset()
						end
					elseif objectType == "operable" then
						if objectTargetting.available then
							self.objectTargetting = objectTargetting
							self.triggerModelTargetting = triggerModel
							self.interactionType = self.objectTargetting.type
							if self.interactionType == "tree" and g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "axe" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "mine" and g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "pickaxe" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "cart" and not objectTargetting.dragger then
								if triggerModel.Name == "ChestTrigger" then
									g.interface:showInteraction(g.stats.interactions.storage.hint .. " " .. self.objectTargetting.name)
								else
									g.interface:showInteraction(g.stats.interactions[self.interactionType].hint)
								end
							elseif not self.objectTargetting.locked and self.interactionType == "fortification" then
								if g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "sledgehammer" then
									self.interactionType = "takeDown"
									g.interface:showInteraction(g.stats.interactions["takeDown"].hint)
								end
							elseif not self.objectTargetting.locked and g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "axe" then
								self.interactionType = "takeDown"
								g.interface:showInteraction(g.stats.interactions["takeDown"].hint)
							elseif self.interactionType == "door" or self.interactionType == "lock" or self.interactionType == "lights" then
								if self.objectTargetting.enabled then
									g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hintWhenEnabled)
								else
									g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hintWhenDisabled)
								end
								self.parameter = not self.objectTargetting.enabled
							elseif self.interactionType == "animal" and g.inventory.itemDrawn and g.inventory.itemDrawn.stats.type == "knife" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint .. " " .. self.objectTargetting.name)
							elseif self.interactionType == "fire" or self.interactionType == "candle" then
								if self.objectTargetting.enabled then
									g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hintWhenEnabled)
								else
									g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hintWhenDisabled)
								end
								self.parameter = not self.objectTargetting.enabled
							elseif self.interactionType == "crafting" then
								g.interface:showInteraction("Use " .. self.objectTargetting.name)
							elseif self.interactionType == "storage" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint .. " " .. self.objectTargetting.name)
							elseif self.interactionType == "spawn" then
								if self.objectTargetting.owner == g.player then
									g.interface:showInteraction("Unclaim")
								elseif self.objectTargetting.owner then
									g.interface:showInteraction("Claim (Owned by " .. self.objectTargetting.owner.Name .. ")")
								else
									g.interface:showInteraction("Claim")
								end
							elseif self.interactionType == "travelling" then
								g.interface:showInteraction("Show travelling options")
							elseif self.interactionType == "bank" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "tradingPost" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "shop" then
								if self.objectTargetting.enabled then
									g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint .. g.stats.shops[self.objectTargetting.shop].name)
								end
							elseif self.interactionType == "purchasable" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint .. " " .. self.objectTargetting.name .. " (" .. g.stats.items[self.objectTargetting.name].value * g.stats.shops[self.objectTargetting.shop].purchaseCoefficient .. " pounds)")
							elseif self.interactionType == "noticeBoard" then
								if self.objectTargetting.enabled then
									g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
								end
							elseif self.interactionType == "islandsBoard" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "bountiesBoard" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "chair" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							elseif self.interactionType == "bell" then
								g.interface:showInteraction(g.stats.interactions[self.objectTargetting.type].hint)
							else
								self:reset()
							end
						end
					end
				elseif (not objectTargetting or distance >= g.stats.arbs.interactionMaximumDistance) and not self.itemDeploying then
					self:reset()
				end
			end)()
		end
	end)()
end

function itFNheliaSCKPIklgOEw:reset()
	self:stop()
	self:deployItemEnd()
	self.objectTargetting = nil
	self.itemDeploying = nil
	self.triggerModelTargetting = nil
	self.interactionType = nil
	self.parameter = nil
	self.interactionStart = nil
	self.interacting = false
	self.deployValid = false
	g.interface:hideInteraction()
	g.stance:updateWalkSpeed()
end
function itFNheliaSCKPIklgOEw:deployItemStart(item)
	g.stance:endStances()
	self.itemDeploying = item
end

function itFNheliaSCKPIklgOEw:deployItemEnd()
	if self.itemDeploying then
		self.deploying = false
		self.itemDeploying = nil
		if self.itemDeployingPreviewModel then
			for i, v in pairs(self.itemDeployingPreviewModel:GetChildren()) do
				if v:IsA("BasePart") then
					g.tween:TweenNumber(v, "Transparency", 1, .2, g.tween.Ease.In.Linear)
				end
			end
			g.debris:AddItem(self.itemDeployingPreviewModel, .2)
			self.itemDeployingPreviewModel = nil
		end
	end
end

function itFNheliaSCKPIklgOEw:dragItemStart()
	if self.objectTargetting and not self.itemDragging and self.interactionType == "takeItem" and not self.objectTargetting.model.PrimaryPart.Anchored then
		self.itemDragging = self.objectTargetting
		self.itemDragging.Parent = g.mouseFilter
		--g.stance:followMouse()
		coroutine.wrap(function()
			local position = g.itFNheliaSCKPIklgOEw:getDragPosition(g.mouse.Hit.p)
			g.misc.Request("drag", true, self.itemDragging.model, position)
			while self.itemDragging and self.itemDragging.model.Parent and self.itemDragging.model:FindFirstChild("Status") and self.itemDragging.model.Status.Dragger.Value == g.player and not self.itemDragging.model.PrimaryPart.Anchored do
				position = g.itFNheliaSCKPIklgOEw:getDragPosition(g.mouse.Hit.p)
				g.misc.Request("drag", true, self.itemDragging.model, position)
			end
		end)()
	end
end

function itFNheliaSCKPIklgOEw:dragItemEnd()
	if self.itemDragging then
		coroutine.wrap(g.misc.Request)("drag", false, self.itemDragging.model)
		self.itemDragging = nil
		--		g.stance:unfollowMouse()
	end
end

function itFNheliaSCKPIklgOEw:get(targetObject)
	local item = self:getItem(targetObject)
	local player = self:getPlayer(targetObject)
	local operable, triggerModel = self:getOperable(targetObject)
	if item then
		return item, "item", item:getDistance()
	elseif player then
		return player, "player", player:getDistance()
	elseif operable and triggerModel then
		return operable, "operable", (g.rootPart.Position - g.mouse.Hit.p).magnitude, triggerModel
	else
		return nil, nil, (g.rootPart.Position - g.mouse.Hit.p).magnitude
	end
end

function itFNheliaSCKPIklgOEw:getItem(targetObject)
	if targetObject and targetObject:IsDescendantOf(g.items) then
		if targetObject.Parent == g.items then
			return g.item.new(targetObject.name, targetObject)
		else
			return self:getItem(targetObject.Parent)
		end
	end
end

function itFNheliaSCKPIklgOEw:getPlayer(targetObject)
	if targetObject and targetObject:IsDescendantOf(g.characters) and targetObject.Name ~= "HumanoidRootPart" then
		local player = g.playersService:GetPlayerFromCharacter(targetObject)
		if player then
			local otherPlayer = g.players[player.Name]
			if otherPlayer then
				return otherPlayer
			else
				otherPlayer = g.otherPlayer.new(player)
				g.players[player.Name] = otherPlayer
				return otherPlayer
			end
		else
			return self:getPlayer(targetObject.Parent)
		end
	end
end

function itFNheliaSCKPIklgOEw:getOperable(targetObject, triggerModel)
	if targetObject and targetObject:IsDescendantOf(g.operablesF) then
		if triggerModel and triggerModel.Parent.Name == "Triggers" then
			if g.operables[targetObject] then
				return g.operables[targetObject], triggerModel
			else
				targetObject, triggerModel = self:getOperable(targetObject.Parent, triggerModel)
				return targetObject, triggerModel
			end
		else
			if targetObject.Parent.Parent.Name == "Triggers" then
				targetObject, triggerModel = self:getOperable(targetObject, targetObject.Parent)
				return targetObject, triggerModel
			end
		end
	end
end

function itFNheliaSCKPIklgOEw:getDragPosition(position)
	local ray = Ray.new(g.character.Head.Position, (position - g.character.Head.Position).unit * (g.stats.arbs.itemDragMaximumDistance - 3))
	local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, { g.mouseFilter, g.character })
	position = Vector3.new(position.X, g.rootPart.Position.Y + 1, position.Z)
	return position
end

function itFNheliaSCKPIklgOEw:getDropPosition(position1)
	local position2 = self:getDragPosition(position1)
	local ray = Ray.new(position2, ((position2 + Vector3.new(0, -10, 0)) - position2).unit * (g.stats.arbs.itemDragMaximumDistance))
	local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, { g.mouseFilter, g.character })
	return position
end

return itFNheliaSCKPIklgOEw
