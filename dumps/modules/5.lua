local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local ThEaqULJPgrYnQhgwVZj = {}
local g
local lastAim = os.clock()
local lastItemSwap = os.clock()
local swapCooldown = 0.2
local lastItemAim = tick()
local aimCooldown = 0.2
ThEaqULJPgrYnQhgwVZj.__index = ThEaqULJPgrYnQhgwVZj

function ThEaqULJPgrYnQhgwVZj.init(_g)
	g = _g
end

function ThEaqULJPgrYnQhgwVZj.new(name, model, object)
	local self = {}
	setmetatable(self, ThEaqULJPgrYnQhgwVZj)

	self.name = name
	self.model = model
	self.animationTracks = {}
	self.stats = g.stats.items[name]
	self.object = object
	self.content = self.stats.content
	self.equipped = false
	self.drawn = false
	self.atEase = false
	self.zoom = 20
	self.charging = false
	self.blocking = false
	self.lastDrawOrHolster = tick()
	self.lastCutDownStart = tick()
	self.lastMiningStart = tick()
	self.firing = false
	self.lastAim = tick()
	self.lastFire = tick()
	self.reloading = false
	self.lastReload = tick()
	self.mag = nil
	self.aiming = false
	self.lightEnabled = false
	self.lazerEnabled = false
	self.hitConnection = nil
	self.lastSwing = tick()
	self.checkingAmmo = false
	self.lastAmmoCheck = tick()
	self.lastToggle = tick()
	self.lastUse = tick()
	self.gui = nil
	self.enabled = false
	self.ratFree = false

	if self.object then
		for i, v in pairs(self.object:GetChildren()) do
			self.content[v.Name] = v.Value
		end
	end

	if self.stats.animations then
		for i, v in pairs(self.stats.animations) do
			self.animationTracks[i] = g.stance:getAnimationTrack(v)
		end
	end

	return self
end

function ThEaqULJPgrYnQhgwVZj:consume()
	if self.stats.type == "consumable" then
		if self.stats.consumableType == "food" then
			self:eat()
		elseif self.stats.consumableType == "drink" then
			self:drink()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:eat()
	if g.integrity.hunger < g.stats.arbs.defaultMaxHunger then
		g.integrity:fillHunger(self.stats.hungerFilled)
		g.inventory:removeItem(self)
		g.stance:consumeFood(self.name)
		g.interface:newHint("You consume the " .. self.name)
	end
end

function ThEaqULJPgrYnQhgwVZj:drink()
	if g.integrity.thirst < g.stats.arbs.defaultMaxThirst then
		g.integrity:fillThirst(self.stats.thirstFilled)
		g.inventory:removeItem(self)
	end
end

function ThEaqULJPgrYnQhgwVZj:getDistance()
	if self.model then
		return (g.rootPart.Position - self.model.PrimaryPart.Position).magnitude
	end
end

function ThEaqULJPgrYnQhgwVZj:equip()
	if self:canBeEquipped() then
		self.equipped = true
		if self.animationTracks.equipped then
			self.animationTracks.equipped:Play()
		end
		g.inventory:equipItem(self)
		coroutine.wrap(function()
			self.model = g.misc.Request("equip", self.object)	
		end)()
		if self.stats.onEquip then
			self[self.stats.onEquip](self)
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:unequip()
	if self.equipped then
		if self.animationTracks.equipped then
			self.animationTracks.equipped:Stop()
		end
		if self.stats.onUnequip then
			self[self.stats.onUnequip](self)
		end
		self:holster()
		g.inventory:unequipItem(self)
		self.equipped = false
		self.model = nil
		coroutine.wrap(g.misc.Request)("unequip", self.object)
		if self.stats.componentItems then
			for i, v in pairs(self.stats.componentItems) do
				local equippedItem = g.inventory:getEquippedNameItem(v)
				if equippedItem then
					equippedItem:unequip()
				end
			end
		end
		if g.inventory.itemDrawn and g.inventory.itemDrawn == self then
			g.inventory:holsterItem()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:take()
	g.stance:grab()
	coroutine.wrap(g.misc.Request)("take", self.model)
end

function ThEaqULJPgrYnQhgwVZj:drop()
	if not g.stance.downed and not g.stance.restrained then
		g.stance:getAnimationTrack(g.stats.arbs.dropItemAnimationID):Play()
	end
	g.inventory:dropItem(self)
	if self.stats.componentItems then
		for i, v in pairs(self.stats.componentItems) do
			local equippedItem = g.inventory:getEquippedNameItem(v)
			if equippedItem then
				equippedItem:unequip()
			end
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:canBeEquipped()

	local canBeEquipped = self.stats.canBeEquipped and not self.equipped
	if canBeEquipped then
		if self.stats.requiredItems then
			for i, v in pairs(self.stats.requiredItems) do
				if not g.inventory:getEquippedNameItem(v) then
					canBeEquipped = false
					break
				end
			end
		end
	end
	return canBeEquipped
end

function ThEaqULJPgrYnQhgwVZj:canDraw()
	return g.stats.items[self.name].weaponType == nil or lastItemSwap + swapCooldown <= os.clock()
end

function ThEaqULJPgrYnQhgwVZj:draw()
	if not self.drawn then

		if (self.model) == nil then return end

		g.inventory:holsterItem()
		self.lastDrawOrHolster = tick()
		if self.model and self.model.Handle and self.model.Handle:FindFirstChild("Draw") then
			self.model.Handle.Draw:Play()
		end
		self.animationTracks.draw:Play()
		self.drawn = true
		if g.stats.items[self.name].weaponType then
			lastItemSwap = os.clock()
		end
		if self.stats.onDraw then
			self[self.stats.onDraw](self)
		end
		coroutine.wrap(g.misc.Request)("draw", self.model)
		g.interface:highlightToolItem(self)
		wait(self.animationTracks.draw.Length)
		self.animationTracks.drawn:Play()
	end
end

function ThEaqULJPgrYnQhgwVZj:holster()
	if self.drawn then

		if (self.model) == nil then return end

		self.lastDrawOrHolster = tick()
		if self.hitConnection then
			self.hitConnection:disconnect()
		end
		if self.stats.weapon then
			self:unaim()
			self:unease()
		end
		self.animationTracks.drawn:Stop()
		self.animationTracks.holster:Play()
		if self.model.Handle:FindFirstChild("Holster") then
			self.model.Handle.Holster:Play()
		end
		self.drawn = false
		self.atEase = false
		self.lastReload = 0
		if self.stats.onHolster then
			self[self.stats.onHolster](self)
		end
		--		g.stance:unfollowMouse()
		coroutine.wrap(g.misc.Request)("holster", self.model)
		g.interface:unhighlightToolItem(self)
	end
end

function ThEaqULJPgrYnQhgwVZj:toggleAtEase()
	if self.atEase then
		self:unease()
	else
		self:ease()
	end
end

function ThEaqULJPgrYnQhgwVZj:makeRatFollow()
	if (self.ratFree) then
		print('noooo the rat going back on shoulder')
		coroutine.wrap(g.misc.Request)("updateRatPose", "Shoulder", self.model)
		self.ratFree = false
	else
		print('yay im free!')
		coroutine.wrap(g.misc.Request)("updateRatPose", "Chase", self.model)
		self.ratFree = true
	end
end

function ThEaqULJPgrYnQhgwVZj:ease()
	if self.drawn and not self.atEase and not self.reloading and tick() - self.lastDrawOrHolster > .2 then
		self.atEase = true
		self.lastReload = 0
		self:unaim()
		self.animationTracks.drawn:Stop()
		self.animationTracks.atEase:Play()
		if self.stats.weaponType == "musket" then
			g.misc.Request("updateMusketPose", "atEase", self.model)
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:unease()
	if self.drawn and self.atEase then
		self.atEase = false
		self.animationTracks.atEase:Stop()
		self.animationTracks.drawn:Play()
		if self.stats.weaponType == "musket" then
			g.misc.Request("updateMusketPose", "", self.model)
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:fire()
	if self.drawn and self.aiming and not self.reloading then
		self.model.Handle.Trigger:Play()
		if (self.content.ammoLoaded > 0 and self.content._token > 0) and ((tick() - self.lastFire > .3) or (self.name == 'MG-42')) then
			self.lastFire = tick()
			self.animationTracks.fire:Play()
			self.model.Barrel.Fire:Play()
			coroutine.wrap(g.misc.Request)("fireMusket", self.model)
			self.model.Barrel.FireP.Enabled = true
			self.model.Barrel.Smoke.Enabled = true
			g.firing:fire(self)
			wait(.1)
			self.model.Barrel.FireP.Enabled = false
			wait(.1)
			self.model.Barrel.Smoke.Enabled = false
			if self.content.ammoLoaded == 0 then
				wait(.2)
				self:unaim()
			end
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:startCharge()
	if self.drawn and (self.stats.type == "fishingPole" or (self.aiming and g.inventory:getBackpackNameItem(self.stats.weapon.ammoType) and tick() - self.lastFire > .5)) and not self.charging then
		self.charging = true
		g.interface:changeCursor("aiming")
		local lastCharge = tick()
		self.lastCharge = lastCharge
		if self.model.Handle:FindFirstChild("Charge") then
			self.model.Handle.Charge:Play()
		end
		local chargeTime = 1
		if self.stats.weaponType == "bow" then
			local arrowObject = g.objects["Game_Projectiles"].Arrow:Clone()
			arrowObject.Name = "FakeArrow"
			local weldObject = Instance.new("Weld", arrowObject)
			arrowObject.Anchored = false
			arrowObject.Transparency = 1
			weldObject.Part0 = arrowObject
			weldObject.Part1 = g.character["Right Arm"]
			arrowObject.CFrame = g.character["Right Arm"].CFrame * CFrame.new(-.2, -3, -.4) * CFrame.Angles(math.rad(-90), 0, 0)
			weldObject.C0 = arrowObject.CFrame:inverse() * g.character["Right Arm"].CFrame
			arrowObject.Parent = g.playerMouseFilter
			g.tweenService:Create(arrowObject, TweenInfo.new(.4), { Transparency = 0 }):Play()
			chargeTime = self.stats.weapon.chargeTime
		end
		self.animationTracks.charge:Play(nil, nil, .5 / chargeTime)
		wait((chargeTime * 2) - .1)
		if self.charging and self.lastCharge == lastCharge then
			self.animationTracks.chargeHold:Play()
			if self.model.Handle:FindFirstChild("Charge") then
				self.model.Handle.Charge:Stop()
			end
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:endCharge()
	--g.interface:changeCursor("normal")
	if self.stats.type == "fishingPole" then
		g.interface:changeCursor("normal")
		if self.content.floater then
			self.content.floater:Destroy()
		end
		coroutine.wrap(g.misc.Request)("resetPlayerCaughtFish")
	end
	if self.charging then
		self.charging = false
		self.lastFire = tick()
		self.animationTracks.charge:Stop()
		self.animationTracks.chargeHold:Stop()
		if self.model.Handle:FindFirstChild("Charge") then
			self.model.Handle.Charge:Stop()
		end
		local ammo
		if self.stats.weaponType == "bow" or self.stats.weaponType == "crossbow" then
			g.interface:changeCursor("normal")
			local arrowObject = g.playerMouseFilter:FindFirstChild("FakeArrow")
			if arrowObject then
				arrowObject:Destroy()
			end
			ammo = g.inventory:getBackpackNameItem(self.stats.weapon.ammoType)
		end
		if self.drawn and (self.stats.type == "fishingPole" or ammo) then
			if ammo then
				spawn(function()
					g.inventory:removeItem(ammo)
				end)
			end
			local chargeForce
			if self.stats.weaponType == "bow" or self.stats.weaponType == "crossbow" then
				chargeForce =( math.min(self.stats.weapon.chargeTime, tick() - self.lastCharge) / self.stats.weapon.chargeTime) * self.stats.weapon.projectile.force
			else
				chargeForce = (math.min(2, tick() - self.lastCharge) / 12) * (self.stats.effectivenessThrow or 1)
			end
			self.content.chargeForce = chargeForce
			if self.animationTracks.fire then
				self.animationTracks.fire:Play()
			end
			self.model.Handle.Shoot:Play()
			if self.stats.weaponType == "bow" or self.stats.weaponType == "crossbow" then
				g.firing:fire(self)
			elseif self.stats.type == "fishingPole" then
				g.interface:newHint("Repeatedly tap R to reel in")
				self.content.floater = g.firing:animateProjectile(self.model, g.mouse.Hit.p, chargeForce, true)
				if self.content.floater then
					self.content.floater.Touched:Connect(function(hitObject)
						if hitObject.Name == "Water" then
							self.content.floater.CanCollide = true
							if self.content.floater:FindFirstChild("Fish") then
								self.content.floater.Fish.Body.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
							end
						end
					end)
					self.content.floater.TouchEnded:Connect(function()
						for i, v in pairs(self.content.floater:GetTouchingParts()) do
							if v.Name == "Water" then
								return
							end
						end
						self.content.floater.CanCollide = false
						if self.content.floater:FindFirstChild("Fish") then
							self.content.floater.Fish.Body.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 0, 0)
						end
					end)
					local lastThrow = tick()
					self.content.lastThrow = lastThrow
					delay(math.random(15 * (self.stats.effectivenessTime or 1), 60 * (self.stats.effectivenessTime or 1)), function()
						if self.content.lastThrow == lastThrow then
							local isInWater = false
							for i, v in pairs(self.content.floater:GetTouchingParts()) do
								if v.Name == "Water" then
									isInWater = true
								end
							end
							if not isInWater then
								self.content.floater:Destroy()
								return
							end
							local caughtFishName = g.misc.Request("generatePlayerCaughtFish", self.object)
							if caughtFishName then
								local caughtFishModel = g.resources.Game_Interactives.Game_Items[caughtFishName]:Clone()
								caughtFishModel.Name = "Fish"
								caughtFishModel.Body.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
								caughtFishModel.Body.CFrame = self.content.floater.CFrame * CFrame.new(caughtFishModel.Body.Attachment.Position)
								self.content.floater.BallSocketConstraint.Attachment1 = caughtFishModel.Body.Attachment
								caughtFishModel.Body.CanCollide = false

								for _ = 1, 6 do
									wait(1)
									caughtFishModel.Parent = self.content.floater
									isInWater = false
									for i, v in pairs(self.content.floater:GetTouchingParts()) do
										if v.Name == "Water" then
											isInWater = true
										end
									end
									if isInWater then
										self.content.floater.Impact:Play()
										self.content.floater.ParticleEmitter.Enabled = true
										delay(.2, function()
											self.content.floater.ParticleEmitter.Enabled = false
										end)
									end
								end
								isInWater = false
								for i, v in pairs(self.content.floater:GetTouchingParts()) do
									if v.Name == "Water" then
										isInWater = true
									end
								end
								if isInWater then
									coroutine.wrap(g.misc.Request)("resetPlayerCaughtFish", self.object)
									self.content.floater:Destroy()
								end
							else
								self.content.floater:Destroy()
							end
						end
					end)
				end
			end
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:reelFishingPole()
	if self.content.floater then
		g.tweenService:Create(self.model.Tip.RopeConstraint, TweenInfo.new(.3), { Length = math.max(1, self.model.Tip.RopeConstraint.Length - (5 * (self.stats.effectivenessReel or 1))) }):Play()
		if self.model.Tip.RopeConstraint.Length <= 5 and self.content.floater then
			if g.misc.Request("takePlayerCaughtFish", self.object, "F0222B56-83B3-4588-AD40-A980C2B27804EEB6DBBB-3224-4D1D-B8CC-E4FE5B5A212D8290F2DC-7CB7-4A6B-B6F0-B9258B2FE5FBD5C78B1D-3CD5-4E10-9595-D61C0E67F11535B19110-1418-4A23-968A-F41D834A0EB13756DCAA-EC0B-46F9-BAEC-5CA35276E1A9E9891651-08D3-47BD-B030-317ECD8C8A17DFE0F302-0B4E-49C8-9A24-E2643D9C5F073E1A9209-5A99-41C5-8436-DD80BADA2E563D9DCEF0-3C90-4482-83D0-162905557543EAAE004A-6809-4DB5-A2D9-58498D6A47B4") then
				if self.content.floater:FindFirstChild("Fish") then
					self.model.Handle.TakeFish:Play()
					g.stance:grab()
					g.interface:newHint("You take the fish")
					self.content.floater.Fish:Destroy()
				end
			end
		else
			self.model.Handle.ReelIn:Play()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:toggleAim()
	if os.clock() - lastAim > .3 then
		if self.aiming then
			self:unaim()
		else
			self:aim()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:aim()
	if self.drawn and not self.aiming and not self.reloading and tick() - self.lastDrawOrHolster > .2 and (tick() - lastItemAim > aimCooldown) then
		self.lastAim = tick()
		lastAim = os.clock()
		lastItemAim = tick()
		self:unease()
		self.aiming = true
		self.animationTracks.aiming:AdjustWeight(1, .3)
		self.animationTracks.aiming:Play()
		g.tweenService:Create(g.camera, TweenInfo.new(.4), { FieldOfView = g.stats.arbs.zoomedInFieldOfView }):Play()
		g.tweenService:Create(g.humanoid, TweenInfo.new(.4), { CameraOffset = Vector3.new(1 ,0, -2) }):Play()
		if self.stats.weaponType == "musket" then
			g.interface:changeCursor("aiming")
			g.misc.Request("updateMusketPose", "aim", self.model)
		elseif self.stats.weaponType == "pistol" then
			g.interface:changeCursor("aiming")
			g.misc.Request("updatePistolPose", "", self.model)
		elseif self.stats.weaponType == "crossbow" then
			g.interface:changeCursor("aiming")
			g.misc.Request("updateCrossbowPose", "", self.model)

			local arrowObject = g.objects["Game_Projectiles"].Arrow:Clone()
			arrowObject.Name = "FakeArrow"
			local weldObject = Instance.new("Weld", arrowObject)
			arrowObject.Anchored = false
			arrowObject.Transparency = 1
			weldObject.Part0 = arrowObject
			weldObject.Part1 = g.character["Right Arm"]
			arrowObject.CFrame = g.character["Right Arm"].CFrame * CFrame.new(-.6, -4, -1) * CFrame.Angles(math.rad(-88), math.rad(5), 0)
			weldObject.C0 = arrowObject.CFrame:inverse() * g.character["Right Arm"].CFrame
			arrowObject.Parent = g.playerMouseFilter
			g.tweenService:Create(arrowObject, TweenInfo.new(.4), { Transparency = 0 }):Play()
		end
		g.stance:updateWalkSpeed()
	end
end

function ThEaqULJPgrYnQhgwVZj:unaim()
	if self.aiming then
		g.interface:changeCursor("normal")
		self.aiming = false
		self:endCharge()
		self.animationTracks.aiming:Stop()
		g.tweenService:Create(g.camera, TweenInfo.new(.4), { FieldOfView = g.stats.arbs.defaultFieldOfView }):Play()
		g.tweenService:Create(g.humanoid, TweenInfo.new(.4), { CameraOffset = g.stats.arbs.cameraOffset }):Play()
		if self.stats.weaponType == "musket" then
			coroutine.wrap(g.misc.Request)("updateMusketPose", "", self.model)
		elseif self.stats.weaponType == "pistol" then
			coroutine.wrap(g.misc.Request)("updatePistolPose", "", self.model)
		elseif self.stats.weaponType == "crossbow" then
			coroutine.wrap(g.misc.Request)("updateCrossbowPose", "", self.model)
		end
		g.stance:updateWalkSpeed()
	end
end

function ThEaqULJPgrYnQhgwVZj:reloadStart()	
	if self.drawn and (self.content.ammoLoaded == 0) and not self.reloading then
		if g.inventory:getBackpackNameItem(self.stats.weapon.ammoType) then
			local lastReload = tick()
			self.lastReload = lastReload
			self.reloading = true
			self:unaim()
			self:unease()
			if self.stats.weaponType == "musket" then
				g.misc.Request("updateMusketPose", "reload", self.model)
			elseif self.stats.weaponType == "pistol" then
				g.misc.Request("updatePistolPose", "reload", self.model)
			elseif self.stats.weaponType == "crossbow" then
				g.misc.Request("updateCrossbowPose", "reload", self.model)
			end
			self.animationTracks.reload:Play()
			wait(self.stats.weapon.reloadTime)
			self:reloadEnd(lastReload)
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:reloadEnd(lastReload)
	if self.reloading then
		if lastReload and self.lastReload == lastReload then
			self.reloading = false
			local ammoAmount = math.min(self.stats.weapon.ammoAmount or 1, g.inventory:getBackpackAmountNameItem(self.stats.weapon.ammoType))
			if ammoAmount > 0 then
				for i = 1, ammoAmount do
					g.inventory:removeItem(g.inventory:getBackpackNameItem(self.stats.weapon.ammoType))
				end
			end
			self.content.ammoLoaded = ammoAmount
			self.content._token = ammoAmount

			if self.stats.weaponType == "musket" then
				g.misc.Request("updateMusketPose", "", self.model)
			elseif self.stats.weaponType == "pistol" then
				g.misc.Request("updatePistolPose", "", self.model)
			elseif self.stats.weaponType == "crossbow" then
				g.misc.Request("updateCrossbowPose", "", self.model)
			end
		elseif not self.drawn then
			self.reloading = false
			self.animationTracks.reload:Stop()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:swing()
	game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer('5F6139E3-A0FA-49B8-A3DC-D25364604FD0', "kill aurora detection")
end

function ThEaqULJPgrYnQhgwVZj:_swing()
	if self.drawn and not self.reloading and tick() - self.lastSwing > self.stats.swingDebounceTime and g.integrity.staminaAvailable then
		self:unaim()
		self:endBlock()
		self:unease()
		self.lastSwing = tick()
		local animationTrack = self.animationTracks["swing" .. math.random(1, 3)]
		if self.animationTracks.swing then
			self.animationTracks.swing:Play()
		else
			animationTrack:Play()
		end
		delay(.1, function()
			self.model.Blade.Swing.PlaybackSpeed = math.random(90, 110) / 100
			self.model.Blade.Swing:Play()
			g.integrity:depleteStamina(self.stats.swingStaminaCost)
		end)
		if self.hitConnection then
			self.hitConnection:disconnect()
		end
		self.hitConnection = self.model.Blade.Touched:connect(function(hitObject)
			local player = g.misc.getPlayerFromPart(hitObject) or g.interaction:getOperable(hitObject)

			if player then
				self.hitConnection:disconnect()
				if g.misc.damageEntity(player, self, "F0222B56-83B3-4588-AD40-A980C2B27804EEB6DBBB-3224-4D1D-B8CC-E4FE5B5A212D8290F2DC-7CB7-4A6B-B6F0-B9258B2FE5FBD5C78B1D-3CD5-4E10-9595-D61C0E67F11535B19110-1418-4A23-968A-F41D834A0EB13756DCAA-EC0B-46F9-BAEC-5CA35276E1A9E9891651-08D3-47BD-B030-317ECD8C8A17DFE0F302-0B4E-49C8-9A24-E2643D9C5F073E1A9209-5A99-41C5-8436-DD80BADA2E563D9DCEF0-3C90-4482-83D0-162905557543EAAE004A-6809-4DB5-A2D9-58498D6A47B4", true) then
					self.model.Blade.Hit:Play()
				else
					coroutine.wrap(g.misc.Request)("hitBlockingPlayer", player)
					self.lastSwing = tick() + 1
					self.model.Blade.HitBlock:Play()
					g.integrity:depleteStamina(g.stats.arbs.hitBlockStaminaCost)
					wait(.1)
					self.animationTracks.hitBlock:Play()
				end
			end
		end)
		delay(self.stats.effectTime, function()
			if self.hitConnection then
				self.hitConnection:disconnect()
			end
		end)
	end
end

function ThEaqULJPgrYnQhgwVZj:useBandage()
	game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer('5F6139E3-A0FA-49B8-A3DC-D25364604FD0', "auto heal detection")
end


function ThEaqULJPgrYnQhgwVZj:_useBandage()
	if self.drawn then
		if g.stance.bleeding or g.integrity.health < g.integrity.maxHealth then
			coroutine.wrap(g.misc.Request)("bandagePlayer", g.player)
			self.animationTracks.use:Play()
			self.animationTracks.drawn:Stop()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:toggleBlock()
	if self.blocking then
		self:endBlock()
	else
		self:startBlock()
	end
end

function ThEaqULJPgrYnQhgwVZj:startBlock()
	if self.drawn and not self.blocking and g.integrity.staminaAvailable then
		self.blocking = true
		coroutine.wrap(g.misc.Request)("updateBlockingPlayer", true)
		self.animationTracks.block:Play()
		while wait(.2) and self.blocking do
			g.integrity:depleteStamina(5)
			if g.integrity.stamina == 0 then
				self:endBlock()
				break
			end
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:endBlock()
	if self.blocking then
		self.blocking = false
		coroutine.wrap(g.misc.Request)("updateBlockingPlayer", false)
		self.animationTracks.block:Stop()
	end
end

function ThEaqULJPgrYnQhgwVZj:animateCutDown()
	local lastCutDownStart = tick()
	self.lastCutDownStart = lastCutDownStart
	wait(.13)
	while g.interaction.interacting and lastCutDownStart == self.lastCutDownStart do
		self.model.AxeHead.Hit.PlaybackSpeed = math.random(8, 13) / 10
		self.model.AxeHead.Hit:Play()
		wait(0.8)
	end
end

function ThEaqULJPgrYnQhgwVZj:animateMining()
	local lastMiningStart = tick()
	self.lastMiningStart = lastMiningStart
	wait(.13)
	while g.interaction.interacting and lastMiningStart == self.lastMiningStart do
		self.model.PickaxeHead.Hit.PlaybackSpeed = math.random(8, 13) / 10
		self.model.PickaxeHead.Hit:Play()
		wait(0.8)
	end
end

function ThEaqULJPgrYnQhgwVZj:enableTorch()
	if not self.enabled then
		self.enabled = true
		coroutine.wrap(g.misc.Request)("updateTorch", true, self.model)
		g.tween:TweenNumber(self.model.Effects.PointLight, "Range", 20, .2, g.tween.Ease.In.Quad)
		g.inventory.warmthBonus = g.inventory.warmthBonus + self.stats.warmthBonusLit
	end
end

function ThEaqULJPgrYnQhgwVZj:disableTorch()
	if self.enabled then
		self.enabled = false
		coroutine.wrap(g.misc.Request)("updateTorch", false, self.model)
		g.tween:TweenNumber(self.model.Effects.PointLight, "Range", 0, .1, g.tween.Ease.In.Linear)
		g.inventory.warmthBonus = g.inventory.warmthBonus - self.stats.warmthBonusLit
	end
end

function ThEaqULJPgrYnQhgwVZj:toggleTorch()
	if tick() - self.lastToggle > self.stats.toggleDebounceTime and (self.stats.type == "lantern" or self.drawn) then
		self.lastToggle = tick()
		self.animationTracks.toggle:Play()
		if self.enabled then
			self:disableTorch()
		else
			self:enableTorch()
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:enableCompass()
	if not self.enabled then
		self.enabled = true
		local compassSpeed = 5
		local camera = workspace.CurrentCamera
		local lastRotation = 0
		local directions = {
			N = math.pi / 4 * 0;
			NW = math.pi / 4 * 1;
			W = math.pi / 4 * 2;
			SW = math.pi / 4 * 3;
			S = math.pi / 4 * 4;
			SE = math.pi / 4 * 5;
			E = math.pi / 4 * 6;
			NE = math.pi / 4 * 7;
		}

		g.interface.gui.Compass:TweenSizeAndPosition(UDim2.new(0, 250, 0, 250), UDim2.new(.5, -125, .5, -125), "Out", "Linear", .5, true)

		spawn(function()
			while self.enabled do
				-- Camera declaration
				local cameraLook = camera.CoordinateFrame.lookVector
				local cameraLook = Vector3.new(cameraLook.x, 0, cameraLook.z).unit

				-- Get rotation
				local rotation = math.atan2(cameraLook.x, cameraLook.z) + math.pi
				local rotationDifference = rotation - lastRotation

				if rotationDifference >  math.pi then rotationDifference = rotationDifference - math.pi * 2 end
				if rotationDifference < -math.pi then rotationDifference = rotationDifference + math.pi * 2 end

				rotation = lastRotation + rotationDifference * wait() * compassSpeed

				if rotation < math.pi*0 then
					rotation = rotation + math.pi * 2
				end
				if rotation > math.pi*2 then
					rotation = rotation - math.pi * 2
				end

				lastRotation = rotation

				-- Display directions
				for direction, position in pairs(directions) do
					local gui = g.interface.gui.Compass[direction]
					position = rotation - position - math.pi / 2
					local cosPos = math.cos(position)
					local sinPos = math.sin(position)
					local trans = (sinPos + 1)*2 * (cosPos > 0 and 2 or 1)
					gui.TextTransparency = trans
					gui.TextStrokeTransparency = trans
					gui.Position = UDim2.new(0.5 + cosPos / 1.7, 0, 0.5 + sinPos / 1.7, 0)
				end
			end
		end)
	end
end

function ThEaqULJPgrYnQhgwVZj:disableCompass()
	if self.enabled then
		self.enabled = false

		g.interface.gui.Compass:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(.5, 0, .5, 0), "Out", "Linear", .5, true)

		delay(.1, function()
			for i, v in pairs(g.interface.gui.Compass:GetChildren()) do
				g.tweenService:Create(v, TweenInfo.new(.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end
end

function ThEaqULJPgrYnQhgwVZj:enableSpyglass()
	if not self.enabled then
		self.enabled = true
		self.zoom = 20
		g.tweenService:Create(workspace.CurrentCamera, TweenInfo.new(.5), { FieldOfView = self.zoom }):Play()
		g.player.CameraMode = Enum.CameraMode.LockFirstPerson
		g.interface.spyglassBlur.Size = 7
		if not g.storage.Snowstorm.Value and not g.storage.Storm.Value then
			g.lighting.FogEnd = 1500
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:disableSpyglass()
	if self.enabled then
		self.enabled = false
		g.tweenService:Create(workspace.CurrentCamera, TweenInfo.new(.5), { FieldOfView = g.stats.arbs.defaultFieldOfView }):Play()
		g.player.CameraMode = Enum.CameraMode.Classic
		g.interface.spyglassBlur.Size = 0
		if g.storage.Snowstorm.Value then
			g.lighting.FogEnd = 100
		elseif g.storage.Storm.Value then
			g.lighting.FogEnd = 200
		else
			g.lighting.FogEnd = 500
		end
	end
end

function ThEaqULJPgrYnQhgwVZj:zoomIn()
	if self.enabled then
		self.zoom = math.max(1, self.zoom - 10)
		g.tweenService:Create(workspace.CurrentCamera, TweenInfo.new(.5), { FieldOfView = self.zoom }):Play()
	end
end

function ThEaqULJPgrYnQhgwVZj:zoomOut()
	if self.enabled then
		self.zoom = math.min(60, self.zoom + 10)
		g.tweenService:Create(workspace.CurrentCamera, TweenInfo.new(.5), { FieldOfView = self.zoom }):Play()
	end
end

function ThEaqULJPgrYnQhgwVZj:enableWatch()
	g.interface:showTime()
end

function ThEaqULJPgrYnQhgwVZj:disableWatch()
	g.interface:hideTime()
end

function ThEaqULJPgrYnQhgwVZj:play()
	if self.enabled then	

	end
end


return ThEaqULJPgrYnQhgwVZj
