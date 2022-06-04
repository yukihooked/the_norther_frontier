local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local XNmgQWTdvnueNPCFiiDD = {}
local g
XNmgQWTdvnueNPCFiiDD.__index = XNmgQWTdvnueNPCFiiDD

function XNmgQWTdvnueNPCFiiDD.init(_g)
	g = _g
	local self = {}
	setmetatable(self, XNmgQWTdvnueNPCFiiDD)
	return self
end

function XNmgQWTdvnueNPCFiiDD:start()
	self.animationTracks = {}
	self.statusFolder = g.player.Status
	self.animationTrackGrab = self:getAnimationTrack(g.stats.arbs.grabItemAnimationID)
	self.animationTrackCraft = self:getAnimationTrack(g.stats.arbs.craftItemAnimationID)
	self.animationTrackRestrained = self:getAnimationTrack(g.stats.arbs.restrainedAnimationID)
	self.zoomedIn = false
	self.downed = false
	self.snowWalking = false
	self.covered = false
	self.walking = false
	self.walkSpeed = 16
	self.jumpPower = 50
	self.respawning = false
	self.jumping = false
	self.climbing = false
	self.swimming = false
	self.standing = false
	self.lastSafePosition = self.statusFolder.LastSafePosition.Value
	self.lastDown = tick()
	self.snowstormShown = false
	self.stormShown = false
	self.lastZoomIn = tick()
	self.animationTrackDowned = nil
	self.animationTracksDowned = {}
	self.animationTracksRestrainedDowned = {}
	self.restrained = false
	self.allowedPositions = {}
	self.cartDragged = nil
	self.crouched = false
	self.dragged = false
	self.bleeding = false
	self.isCold = false
	self.warmingUp = false
	self.floorMaterial = nil
	self.lastCrouch = tick()
	self.animationTrackCrouched = self:getAnimationTrack(g.stats.arbs.crouchedAnimationID)
	self.usingRadio = false
	self.animationTrackConsumeFood = self:getAnimationTrack(g.stats.arbs.consumeFoodAnimationID)
	self.followingMouse = false
	self.animationTrackUseRadio = self:getAnimationTrack(g.stats.arbs.useRadioAnimationID)
	self.animationTrackUseOperable = self:getAnimationTrack(g.stats.arbs.useOperableAnimationID)
	self.animationTrackWarmthLow = self:getAnimationTrack(g.stats.arbs.warmthLowAnimationID)
	self.animationTrackHeatSourceNearby = self:getAnimationTrack(g.stats.arbs.heatSourceNearbyAnimationID)
	self.animationTrackSnowstormCover = self:getAnimationTrack(g.stats.arbs.snowstormCoverAnimationID)
	self.animationTrackDragCart = self:getAnimationTrack(g.stats.arbs.dragCartAnimationID)
	self.humanoidState = g.humanoid:GetState()

	g.character.Parent = g.playerMouseFilter

	self:setupHumanoidState()
	self:setupRestrictions()
	self:setupDownedAnimations()
	self:animateSnow()
	self:followMouse()
end

function XNmgQWTdvnueNPCFiiDD:setupRestrictions()
	self.statusFolder.Downed.Changed:connect(function()
		if self.statusFolder.Downed.Value then
			self:down()
		else
			if self.statusFolder.Health.Value > 0 then
				coroutine.wrap(g.misc.Request)("checkPlayerDowned")
				self:revive()
			end
		end
	end)

	self.statusFolder.LastSafePosition.Changed:Connect(function()
		self.lastSafePosition = self.statusFolder.LastSafePosition.Value
	end)

	self.statusFolder.Restrained.Changed:connect(function()
		if self.statusFolder.Restrained.Value then
			self:restrain()
		else
			self:unrestrain()
		end
	end)

	self.statusFolder.Dragged.Changed:connect(function()
		if self.statusFolder.Dragged.Value then
			self:dragStart()
		else
			self:dragEnd()
		end
	end)

	self.statusFolder.Bleed.Changed:connect(function()
		if self.statusFolder.Bleed.Value > 0 then
			self.bleeding = true
			g.interface:showBleeding()
			g.interface:showCombatLogIndicator()
		else
			self.bleeding = false
			g.interface:hideBleeding()
			g.interface:hideCombatLogIndicator()
		end
	end)

	g.rootPart.ChildAdded:Connect(function(object)
		self:checkNewObject(object)
	end)

	g.character.Torso.ChildAdded:Connect(function(object)
		self:checkNewObject(object)
	end)

	for i, v in pairs(g.rootPart:GetChildren()) do
		self:checkNewObject(v)
	end

	for i, v in pairs(g.character.Torso:GetChildren()) do
		self:checkNewObject(v)
	end

	g.humanoid.Changed:Connect(function()
		if g.humanoid.WalkSpeed > 16 or g.humanoid.JumpPower > 50 then
			--g.misc.kickSelf("Unexpected humanoid change I")
		end
	end)

	spawn(function()
		while wait(.5) do
			local playingAnimationTracks = g.humanoid:GetPlayingAnimationTracks()
			for i, v in pairs(playingAnimationTracks) do
				local rbxAnimationIds = { 180435571, 180435792, 180426354, 125750702, 180436148, 180436334, 178130996 }

				if not g.misc.find(self.animationTracks, v) and not g.misc.find(rbxAnimationIds, tonumber(string.sub(v.Animation.AnimationId, 33))) then
					--g.misc.kickSelf("Unexpected humanoid change II")
				end
			end
		end
	end)
	self:test()
end

function XNmgQWTdvnueNPCFiiDD:checkNewObject(object)
	if not g.misc.find({ "Motor6D", "Attachment", "ParticleEmitter", "Decal" }, object.ClassName) then
		--g.misc.kickSelf("Unexpected object added")
	end
end

function XNmgQWTdvnueNPCFiiDD:grab()
	self.animationTrackGrab:Play()
end

function XNmgQWTdvnueNPCFiiDD:consumeFood(itemName)
	self.animationTrackConsumeFood:Play()
	g.sounds.ConsumeFood:Play()
	coroutine.wrap(g.misc.Request)("consume", itemName)
end

function XNmgQWTdvnueNPCFiiDD:craft()
	self.animationTrackCraft:Play()
end

function XNmgQWTdvnueNPCFiiDD:setupMapLimits()
	for i, v in pairs(g.mouseFilter.MapLimits:GetChildren()) do
		v.Touched:Connect(function(part)
			if part == g.rootPart then
				g.rootPart.CFrame = CFrame.new(self.lastSafePosition)
			end
		end)
	end

	local lastPositionTime = tick()
	local lastRemove
	local lastPosition
	local spawnPosition = g.player.Status.SpawnPosition.Value
	spawnPosition = Vector3.new(spawnPosition.X, 0, spawnPosition.Z)

	g.runService:BindToRenderStep("ATPCHK" .. tick(), Enum.RenderPriority.Last.Value, function()
		local _lastPosition = g.rootPart.Position
		if tick() - lastPositionTime < .2 and lastPosition and (lastPosition - _lastPosition).magnitude > 15 and (not lastRemove or tick() - lastRemove > .5) then
			for i, v in pairs(self.allowedPositions) do
				if (g.rootPart.Position - v).magnitude < 15 then
					lastRemove = tick()
					table.remove(self.allowedPositions, i)
					return
				end
			end
			if not g.stats.places[game.PlaceId].conquering or (_lastPosition - g.mouseFilter.Spawns.Conqueror["1"].Position).magnitude > 200 then
				--g.misc.kickSelf("Unexpected position change I")
			end
		end
		lastPosition = _lastPosition
		lastPositionTime = tick()
	end)

	local lastNoFloorTime
	spawn(function()
		local lastPosition
		local wasSeated = false
		while wait(2) do
			local ray = Ray.new(g.rootPart.Position + Vector3.new(0, 2, 0), ((g.rootPart.Position + Vector3.new(0, -10, 0)) - g.rootPart.Position).unit * 100)
			local hitObject = workspace:FindPartOnRayWithWhitelist(ray, { workspace.Terrain })
			if not hitObject and not self.swimming then
				--	g.misc.kickSelf("Unexpected position change III")
			end
		end
	end)

	spawn(function()
		local lastPosition
		local wasSeated = false
		while wait(.5) do
			if not g.character.Head.CanCollide or not g.character.Torso.CanCollide then
				--g.misc.kickSelf("Unexpected humanoid change III")
			end
			if self.seated and wasSeated and lastPosition and (g.rootPart.Position - lastPosition).magnitude > 10 then
				--	g.misc.kickSelf("Unexpected position change IV")
			end
			lastPosition = g.rootPart.Position
			wasSeated = self.seated
		end
	end)
end

function XNmgQWTdvnueNPCFiiDD:setupHumanoidState()
	g.humanoid.AutoJumpEnabled = false
	g.humanoid.StateChanged:connect(function(oldHumanoidState, newHumanoidState)
		self.humanoidState = newHumanoidState
		self.walking = self.humanoidState == Enum.HumanoidStateType.Running
		self.falling = self.humanoidState == Enum.HumanoidStateType.Freefall
		self.climbing = self.humanoidState == Enum.HumanoidStateType.Climbing
		self.jumping = self.humanoidState == Enum.HumanoidStateType.Jumping
		self.swimming = self.humanoidState == Enum.HumanoidStateType.Swimming
		if self.humanoidState == Enum.HumanoidStateType.Jumping then
			self:jump()
		elseif self.humanoidState == Enum.HumanoidStateType.Seated then
			self.seated = true
			g.interface:addControl(g.stats.controlNames.stand, g.stats.controls.stand)
			self:endStances()
			delay(5, function()
				if self.seated then
					g.interface:newHint("Press " .. string.upper(g.stats.controls.stand) .. " to stand")
				end
			end)
		else
			if self.seated then
				self.seated = false
				g.interface:removeControl(g.stats.controlNames.stand)
				g.player.CameraMode = Enum.CameraMode.Classic
				g.humanoid.CameraOffset = g.stats.arbs.cameraOffset
				self:zoomOut()
				g.interface:hideBarber()
			end
		end
	end)
	self:updateSnowWalking()
	g.humanoid.Changed:Connect(function()
		self:updateSnowWalking()
	end)
end

function XNmgQWTdvnueNPCFiiDD:updateSnowWalking()
	self.walking = g.humanoid.MoveDirection ~= Vector3.new(0, 0, 0)
	local snowWalking = (g.humanoid.FloorMaterial == Enum.Material.Snow or g.humanoid.FloorMaterial == Enum.Material.Salt) and self.walking
	if snowWalking ~= self.snowWalking then
		self.snowWalking = snowWalking
		coroutine.wrap(g.misc.Request)("setInSnow", g.humanoid.FloorMaterial == Enum.Material.Snow and not self.respawning, self.walking and not self.respawning)
		self.floorMaterial = g.humanoid.FloorMaterial
		self:updateWalkSpeed()
	end
	if self.cartDragged then
		if self.walking and not self.cartDragged.model.PrimaryPart.Roll.IsPlaying then
			self.cartDragged.model.PrimaryPart.Roll:Play()
		elseif not self.walking then
			self.cartDragged.model.PrimaryPart.Roll:Stop()
		end
	end
end

function XNmgQWTdvnueNPCFiiDD:setupDownedAnimations()
	for i, v in pairs(g.stats.arbs.downedAnimationIDs) do
		self.animationTracksDowned[i] = self:getAnimationTrack(v)
	end

	for i, v in pairs(g.stats.arbs.restrainedDownedAnimationIDs) do
		self.animationTracksRestrainedDowned[i] = self:getAnimationTrack(v)
	end
end

function XNmgQWTdvnueNPCFiiDD:down()
	if not self.downed then			
		self.downed = true
		self.lastDown = tick()
		if self.restrained then
			self.animationTrackDowned = self.animationTracksRestrainedDowned[math.random(1, #self.animationTracksRestrainedDowned)]
		else
			self.animationTrackDowned = self.animationTracksDowned[math.random(1, #self.animationTracksDowned)]
		end
		self.animationTrackDowned:Play()
		self:updateWalkSpeed()
		self:standH()
		g.interface:hideToolbar()
		g.interface:hideIntegrity()
		g.interface:showCombatLogIndicator()
		self:endStances()
		g.interface:showRespawn()
	end
end

function XNmgQWTdvnueNPCFiiDD:revive()
	if self.downed then
		self.downed = false
		self.animationTrackDowned:Stop()
		self:updateWalkSpeed()
		g.interface:hideCombatLogIndicator()
		g.interface:showToolbar()
		g.interface:showIntegrity()
		g.interface:hideRespawn()
	end
end

function XNmgQWTdvnueNPCFiiDD:requestRespawn(force)
	if (self.downed or force) and tick() - self.lastDown > g.stats.places[game.PlaceId].respawnCooldown then
		if self.restrained then
			g.interface:newHint("You cannot respawn while restrained")
		else
			self:respawn()
		end
	end
end

function XNmgQWTdvnueNPCFiiDD:restrain()
	if not self.restrained then
		self.restrained = true
		self:endStances()
		self:updateWalkSpeed()
		if self.downed then
			self.animationTracksRestrainedDowned[math.random(1, #self.animationTracksRestrainedDowned)]:Play()
		else
			self.animationTrackRestrained:Play()
		end
		g.interface:hideToolbar()
		g.interface:newHint("You are restrained | Leaving the game will result in combat log")
		g.interface:showCombatLogIndicator()
	end
end

function XNmgQWTdvnueNPCFiiDD:unrestrain()
	if self.restrained then
		self.restrained = false
		self:updateWalkSpeed()
		if self.animationTrackRestrained then
			self.animationTrackRestrained:Stop()
		end
		for i, v in pairs(self.animationTracksRestrainedDowned) do
			v:Stop()
		end
		g.interface:showToolbar()
		g.interface:newHint("You are unrestrained")
		g.interface:hideCombatLogIndicator()
	end
end

function XNmgQWTdvnueNPCFiiDD:getAnimationTrack(animationID)
	if animationID then
		for i, v in pairs(g.humanoid:GetPlayingAnimationTracks()) do
			if v.Animation.AnimationId == animationID then
				return v
			end
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = g.stats.arbs.assetLink .. tostring(animationID)
		local animationTrack = g.humanoid:LoadAnimation(animation)
		table.insert(self.animationTracks, animationTrack)
		return animationTrack
	end
end

function XNmgQWTdvnueNPCFiiDD:cold()
	if not self.isCold then
		self.isCold = true
		self.animationTrackWarmthLow:Play()
		coroutine.wrap(g.misc.Request)("setWarmthLow", true)
		self:updateWalkSpeed()
	end
end

function XNmgQWTdvnueNPCFiiDD:warm()
	if self.isCold then
		self.isCold = false
		self.animationTrackWarmthLow:Stop()
		coroutine.wrap(g.misc.Request)("setWarmthLow", false)
		self:updateWalkSpeed()
	end
end

function XNmgQWTdvnueNPCFiiDD:startWarmUp()
	if not self.warmingUp then
		self.warmingUp = true
		self.animationTrackHeatSourceNearby:Play()
	end
end

function XNmgQWTdvnueNPCFiiDD:endWarmUp()
	if self.warmingUp then
		self.warmingUp = false
		self.animationTrackHeatSourceNearby:Stop()
	end
end

function XNmgQWTdvnueNPCFiiDD:followMouse()
	if not self.followingMouse then
		self.followingMouse = true
		g.humanoid.AutoRotate = false
		coroutine.wrap(function()
			while g.runService.RenderStepped:wait() and self.followingMouse do
				g.rootPart.CFrame = g.rootPart.CFrame:lerp(CFrame.new(g.rootPart.Position, Vector3.new(g.mouse.Hit.p.X, g.rootPart.Position.Y, g.mouse.Hit.p.Z)), .1)
			end
		end)()
	end
end

function XNmgQWTdvnueNPCFiiDD:animateSnow()
	local snowPart = g.objects.SnowPart:Clone()
	snowPart.Parent = g.playerMouseFilter
	coroutine.wrap(function()
		while g.runService.RenderStepped:wait() do
			snowPart.CFrame = CFrame.new(g.camera.CFrame.p.X, g.camera.CFrame.p.Y + 40, g.camera.CFrame.p.Z)
		end
	end)()
	coroutine.wrap(function()
		while wait(.5) do
			local ray = Ray.new(g.rootPart.Position, Vector3.new(0, 1, 0).unit * (100))
			local hitObject = workspace:FindPartOnRayWithIgnoreList(ray, { g.mouseFilter, g.characters })
			self.covered = hitObject ~= nil
			if hitObject then
				snowPart.ParticleEmitter.Transparency = NumberSequence.new(1)
				self:updateSnowstorm(false)
			else
				snowPart.ParticleEmitter.Transparency = NumberSequence.new(0)
				self:updateSnowstorm(g.storage.Snowstorm.Value)
			end
		end
	end)()

	g.storage.Snowstorm.Changed:Connect(function()
		self:updateSnowstorm(g.storage.Snowstorm.Value, true)
	end)

	self:updateSnowstorm(g.storage.Snowstorm.Value)
end

function XNmgQWTdvnueNPCFiiDD:updateSnowstorm(request, transition)
	if request ~= self.snowstormShown or (not request and transition) then
		local transitionTime
		if transition then
			transitionTime = 30
		else
			transitionTime = 1
		end
		if request then
			self.snowstormShown = true
			g.tweenService:Create(g.lighting.SunRays, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Intensity = 0 }):Play()
			g.tweenService:Create(g.playerMouseFilter.SnowPart, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Transparency = 0, Size = Vector3.new(40, 1, 40) }):Play()
			g.tweenService:Create(g.playerMouseFilter.SnowPart.ParticleEmitter, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Acceleration = Vector3.new(1, 0, 0) }):Play()
			g.tweenService:Create(g.lighting, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { FogEnd = 100 }):Play()
			g.tweenService:Create(g.interface.snowstormBlur, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Size = 7 }):Play()
			g.tweenService:Create(g.sounds.Snowstorm, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .5 }):Play()
			if not g.sounds.Snowstorm.IsPlaying then
				g.sounds.Snowstorm:Play()
			end
			if self.covered then
				g.tweenService:Create(g.sounds.Snowstorm, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .2 }):Play()
			else
				g.tweenService:Create(g.sounds.Snowstorm, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .5 }):Play()
			end
			delay(transitionTime, function()
				if g.storage.Snowstorm.Value then
					g.playerMouseFilter.SnowPart.ParticleEmitter.LockedToPart = true
					g.playerMouseFilter.SnowPart.ParticleEmitter.Speed = NumberRange.new(15, 20)
					if not self.covered then
						g.playerMouseFilter.SnowPart.Snowstorm.Enabled = true
						self.animationTrackSnowstormCover:Play()
					end
				end
			end)
		else
			self.snowstormShown = false
			if g.storage.Snowstorm.Value then
				g.tweenService:Create(g.sounds.Snowstorm, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .1 }):Play()
			else
				g.tweenService:Create(g.lighting.SunRays, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Intensity = .25 }):Play()
				g.tweenService:Create(g.sounds.Snowstorm, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = 0 }):Play()
				g.tweenService:Create(g.playerMouseFilter.SnowPart, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Transparency = 1, Size = Vector3.new(200, 1, 200) }):Play()
				g.tweenService:Create(g.lighting, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { FogEnd = 500 }):Play()
				g.playerMouseFilter.SnowPart.ParticleEmitter.Speed = NumberRange.new(7, 10)
			end
			g.tweenService:Create(g.interface.snowstormBlur, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Size = 0 }):Play()
			g.playerMouseFilter.SnowPart.Snowstorm.Enabled = false
			self.animationTrackSnowstormCover:Stop()
			delay(transitionTime, function()
				if not g.storage.Snowstorm.Value then
					g.playerMouseFilter.SnowPart.ParticleEmitter.LockedToPart = false
					g.sounds.Snowstorm:Stop()
				end
			end)
		end
	end
end

function XNmgQWTdvnueNPCFiiDD:animateRain()
	local rainPart = g.objects.RainPart:Clone()
	rainPart.Parent = g.playerMouseFilter
	coroutine.wrap(function()
		while g.runService.RenderStepped:wait() do
			rainPart.CFrame = CFrame.new(g.camera.CFrame.p.X, g.camera.CFrame.p.Y + 40, g.camera.CFrame.p.Z)
		end
	end)()
	coroutine.wrap(function()
		while wait(.5) do
			local ray = Ray.new(g.rootPart.Position, Vector3.new(0, 1, 0).unit * (100))
			local hitObject = workspace:FindPartOnRayWithIgnoreList(ray, { g.mouseFilter, g.characters })
			self.covered = hitObject ~= nil
			if hitObject then
				rainPart.ParticleEmitter.Transparency = NumberSequence.new(1)
				self:updateStorm(false)
			else
				rainPart.ParticleEmitter.Transparency = NumberSequence.new(0)
				self:updateStorm(g.storage.Storm.Value)
			end
		end
	end)()

	g.storage.Storm.Changed:Connect(function()
		self:updateStorm(g.storage.Storm.Value, true)
	end)

	self:updateStorm(g.storage.Storm.Value)
end

function XNmgQWTdvnueNPCFiiDD:updateStorm(request, transition)
	if request ~= self.snowstormShown or (not request and transition) then
		local transitionTime
		if transition then
			transitionTime = 30
		else
			transitionTime = 1
		end
		if request then
			self.stormShown = true
			g.tweenService:Create(g.lighting.SunRays, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Intensity = 0.2 }):Play()
			g.tweenService:Create(g.playerMouseFilter.RainPart, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Transparency = 0.3, Size = Vector3.new(20, 1, 20) }):Play()
			g.tweenService:Create(g.playerMouseFilter.RainPart.ParticleEmitter, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Acceleration = Vector3.new(1, 0, 0) }):Play()
			g.tweenService:Create(g.lighting, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { FogEnd = 200 }):Play()
			g.tweenService:Create(g.sounds.Rain, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .5 }):Play()
			g.playerMouseFilter.RainPart.ParticleEmitter.Enabled = true
			if not g.sounds.Rain.IsPlaying then
				g.sounds.Rain:Play()
			end
			if self.covered then
				g.tweenService:Create(g.sounds.Rain, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .2 }):Play()
			else
				g.tweenService:Create(g.sounds.Rain, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = .5 }):Play()
			end
		else
			self.stormShown = false
			if g.storage.Storm.Value then
				g.tweenService:Create(g.sounds.Rain, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = 0.1 }):Play()
			else
				g.tweenService:Create(g.lighting.SunRays, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Intensity = .25 }):Play()
				g.tweenService:Create(g.sounds.Rain, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Volume = 0 }):Play()
				g.tweenService:Create(g.playerMouseFilter.RainPart, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { Transparency = 1, Size = Vector3.new(200, 1, 200) }):Play()
				g.tweenService:Create(g.lighting, TweenInfo.new(transitionTime, Enum.EasingStyle.Linear), { FogEnd = 500 }):Play()
				g.playerMouseFilter.RainPart.ParticleEmitter.Enabled = false
			end
			delay(transitionTime, function()
				if not g.storage.Storm.Value then
					g.playerMouseFilter.RainPart.ParticleEmitter.LockedToPart = false
					g.sounds.Rain:Stop()
				end
			end)
		end
	end
end

function XNmgQWTdvnueNPCFiiDD:unfollowMouse()
	if self.followingMouse then
		self.followingMouse = false
		--g.humanoid.AutoRotate = true
	end
end

function XNmgQWTdvnueNPCFiiDD:standH()
	local safePosition
	for i, v in pairs(g.operables) do
		if v.model:FindFirstChild("Seat") and v.model.Seat.Occupant == g.humanoid then
			safePosition = v.statusFolder.SafePosition.Value
		end
	end
	g.humanoid.Sit = false
	if safePosition then
		table.insert(self.allowedPositions, safePosition)
		g.rootPart.CFrame = CFrame.new(safePosition)
	end
end

function XNmgQWTdvnueNPCFiiDD:dragStart()
	if not self.dragged then
		self.dragged = true
		self:updateWalkSpeed()
	end
end

function XNmgQWTdvnueNPCFiiDD:dragEnd()
	if self.dragged then
		self.dragged = false
		self:updateWalkSpeed()
	end
end

function XNmgQWTdvnueNPCFiiDD:jump()
	if g.humanoid.JumpPower > 0 then
		g.integrity:depleteStamina(g.stats.arbs.jumpStaminaCost)
		if g.inventory.itemDrawn and g.inventory.itemDrawn.stats.weapon then
			g.inventory.itemDrawn:unaim()
		end
		wait(.2)
		self.jumpPower = 0
		g.humanoid.JumpPower = self.jumpPower
		wait(g.stats.arbs.jumpDebounceTime - .2)
		self:updateWalkSpeed()
	end
end

function XNmgQWTdvnueNPCFiiDD:canDoAction()
	return not g.interface.menuShown and not self.downed and not self.cartDragged and not self.sprinting and not self.seated and not g.interface.inventoryShown and not g.interface.craftingShown and not g.interface.travellingShown and not g.interface.shopShown and not g.interface.stocksShown and not g.interface.bankShown and not g.interface.tradingPostShown and not g.interface.islandsShown and not g.interface.bountiesShown and not g.interface.factionsShown and not g.interface.storeShown and not g.interface.noticeBoardShown and not g.interaction.interacting
end

function XNmgQWTdvnueNPCFiiDD:updateWalkSpeed()
	--if self.dragged then
	--self:unfollowMouse()
	--self.walkSpeed = 20
	--self.jumpPower = 0
	if self.cartDragged then
		self:unfollowMouse()
		g.humanoid.AutoRotate = true
		if self.snowWalking then
			self.walkSpeed = 9
		else
			self.walkSpeed = 11
		end
		self.jumpPower = 0
	elseif not self:canDoAction() and not g.interface.bankShown and not g.interface.tradingPostShown and not g.interface.shopShown and not g.interface.noticeBoardShown then
		self:unfollowMouse()
		self.walkSpeed = 0
		self.jumpPower = 0
	elseif g.interface.shopShown or g.interface.bankShown or g.interface.tradingPostShown then
		self:unfollowMouse()
		self.walkSpeed = 10
		self.jumpPower = 0
	elseif g.inventory.itemDrawn and g.inventory.itemDrawn.aiming then
		self:followMouse()
		self.walkSpeed = 2
		self.jumpPower = 0
	elseif self.restrained then
		self:unfollowMouse()
		self.walkSpeed = 5
		self.jumpPower = 0
	else
		self:followMouse()
		local interior = false
		for i, v in pairs(g.loadedZones) do
			if v.stats.interior then
				self.walkSpeed = 12
				self.jumpPower = 0
				interior = true
				break
			end
		end
		if not interior then
			self.walkSpeed = 14
			self.jumpPower = 50
			if g.inventory.itemDrawn and g.inventory.itemDrawn.stats.walkSpeedPenalty then
				self.walkSpeed = self.walkSpeed - g.inventory.itemDrawn.stats.walkSpeedPenalty
			end
		end
		if g.inventory.full then
			self.walkSpeed = math.min(6, self.walkSpeed)
			self.jumpPower = 0
		elseif not g.integrity.staminaAvailable then
			self.walkSpeed = math.min(12, self.walkSpeed)
			self.jumpPower = 0
		elseif g.inventory.itemDrawn and g.inventory.itemDrawn.reloading then
			self:followMouse()
			self.walkSpeed =  math.min(10, self.walkSpeed)
			self.jumpPower = 0
		elseif self.floorMaterial == Enum.Material.Snow then
			self:followMouse()
			if g.inventory:getEquippedTypeItem("snowshoes") then
				self.walkSpeed = math.min(13, self.walkSpeed)
				self.jumpPower = math.min(50, self.jumpPower)
			else
				self.walkSpeed = math.min(11, self.walkSpeed)
				self.jumpPower = math.min(40, self.jumpPower)
			end
		elseif g.integrity.warmthLow  then
			self.walkSpeed = math.min(11, self.walkSpeed)
			self.jumpPower = math.min(40, self.jumpPower)
		end
	end
	g.humanoid.WalkSpeed = math.max(0, self.walkSpeed)
	g.humanoid.JumpPower = math.max(0, self.jumpPower)
end

function XNmgQWTdvnueNPCFiiDD:endStances()
	g.inventory:holsterItem()
	g.interface:hideInventory()
	g.interface:hideCrafting()
	g.interface:hideShop()
	g.interface:hideTravelling()
	g.interface:hideLoot()
	g.interface:hideBank()
	g.interface:hideTradingPost()
	g.interface:hideStorage()
	g.interface:hideIslands()
	g.interface:hideBounties()
	g.interface:hideFactions()
	g.interface:hideStore()
	--g.interaction:dragPlayerEnd()
	g.interaction:deployItemEnd()
	g.interaction:dragItemEnd()
	g.interaction:reset()
	self:dropCart(true)
end

function XNmgQWTdvnueNPCFiiDD:respawn(firstRespawn)
	if not self.respawning then
		self.respawning = true
		if firstRespawn then
			g.integrity:_start()
			g.character.Parent = g.playerMouseFilter
			g.camera.CameraSubject = g.humanoid
			g.camera.CameraType = Enum.CameraType.Custom
			self:setupMapLimits()
		else
			local spawnPosition = g.player.Status.SpawnPosition.Value
			for i, v in pairs(g.operables) do
				if v.type == "spawn" and v.statusFolder.Owner.Value == g.player then
					spawnPosition = v.statusFolder.SpawnPosition.Value
					break
				end
			end
			table.insert(self.allowedPositions, spawnPosition)
			g.interface:showTransition()
			g.misc.Request("respawnPlayer")
			self:revive()
			g.integrity:_setHunger(g.stats.arbs.defaultMaxHunger)
			g.integrity:setWarmth(g.stats.arbs.defaultMaxWarmth)
			g.interface:hideTransition()
		end
		self:updateSnowWalking()
		self.respawning = false
	end
end

function XNmgQWTdvnueNPCFiiDD:useOperable()
	self.animationTrackUseOperable:Play()
end

function XNmgQWTdvnueNPCFiiDD:zoomIn()
	if not self.zoomedIn and self.seated and not g.interface.stocksShown then
		self.lastZoomIn = tick()
		self.zoomedIn = true
		g.tweenService:Create(g.camera, TweenInfo.new(.4), { FieldOfView = g.stats.arbs.zoomedInFieldOfView }):Play()
	end
end

function XNmgQWTdvnueNPCFiiDD:zoomOut()
	if self.zoomedIn then
		self.zoomedIn = false
		g.tweenService:Create(g.camera, TweenInfo.new(.4), { FieldOfView = g.stats.arbs.defaultFieldOfView }):Play()
	end
end

function XNmgQWTdvnueNPCFiiDD:dragCart(operable)
	self:endStances()
	self.cartDragged = operable
	self.animationTrackDragCart:Play()
	self:updateWalkSpeed()
	g.interface:addControl(g.stats.controlNames.dropCart, g.stats.controls.dropCart)
end

function XNmgQWTdvnueNPCFiiDD:dropCart(forced)
	if self.cartDragged and (forced or not self.falling) then
		self.cartDragged:dropCart()
		self.cartDragged = nil
		self.animationTrackDragCart:Stop()
		self:updateWalkSpeed()
		g.interface:removeControl(g.stats.controlNames.dropCart)
	end
end

function XNmgQWTdvnueNPCFiiDD:test()

end

return XNmgQWTdvnueNPCFiiDD
