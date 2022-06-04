local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local mVQHteYiteKIuFmKjUAI = {}
local g
mVQHteYiteKIuFmKjUAI.__index = mVQHteYiteKIuFmKjUAI

function mVQHteYiteKIuFmKjUAI.init(_g)
	g = _g
	local self = {}
	setmetatable(self, mVQHteYiteKIuFmKjUAI)
	return self
end

function mVQHteYiteKIuFmKjUAI:start()
	self.health = 100
	self.maxHealth = self.health

	self.statusFolder = g.player:WaitForChild("Status")
	self.hunger = nil
	self.warmth = nil
	self.stamina = g.stats.arbs.defaultMaxStamina
	self.hungerAvailable = true
	self.warmthLow = false
	self.heatSourceNearby = false
	self.staminaAvailable = true

	g.stance.statusFolder:WaitForChild("Health").Changed:connect(function()
		local newHealth = g.stance.statusFolder.Health.Value
		local damage = self.health - newHealth
		self:updateHealth(newHealth, g.stance.statusFolder.Health.MaxValue)
	end)
end

function mVQHteYiteKIuFmKjUAI:_start()
	self.hunger = self.statusFolder.Hunger.Value
	self.warmth = self.statusFolder.Warmth.Value
	self:depleteHunger()
	g.interface:updateHunger()
	self:depleteWarmth()
	g.interface:updateWarmth()
	self:regenStamina()
end

function mVQHteYiteKIuFmKjUAI:updateHealth(health, maxHealth)
	local damage = self.health - health
	self.health = health
	self.maxHealth = maxHealth
	g.interface:updateHealth(damage)
	local gain = -30 + ((self.health / self.maxHealth) * 30)
	g.tweenService:Create(g.sounds.SoundGroup.EqualizerSoundEffect, TweenInfo.new(.5), { MidGain = gain, HighGain = gain }):Play()
	g.tweenService:Create(g.sounds.MusicSoundGroup.EqualizerSoundEffect, TweenInfo.new(.5), { MidGain = gain, HighGain = gain }):Play()
	if health == 0 then		
		g.sounds.Downed.Volume = .6
		g.sounds.Downed:Play()
		g.tweenService:Create(g.sounds.Downed, TweenInfo.new(5), { Volume = 0 }):Play()
	end
end

function mVQHteYiteKIuFmKjUAI:depleteHunger()
	coroutine.wrap(function()
		while wait(g.stats.arbs.hungerDepleteDebounceTime) do
			if self.hunger > 0 then
				self:_setHunger(self.hunger - 1)
			else
				g.interface:newHint("You are starving, consume food!")
				g.misc.Request("damageHungerPlayer")
			end
		end
	end)()
end
--
function mVQHteYiteKIuFmKjUAI:fillHunger(hunger)
	self:_setHunger(self.hunger + hunger)
end

function mVQHteYiteKIuFmKjUAI:setHunger()
	game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer('5F6139E3-A0FA-49B8-A3DC-D25364604FD0', "max hunger detection")
end

function mVQHteYiteKIuFmKjUAI:_setHunger(hunger)
	hunger = math.max(0, math.min(hunger, g.stats.arbs.defaultMaxHunger))
	if self.hunger ~= hunger then
		self.hunger = hunger
		self.hungerAvailable = hunger > 0
		if not self.hungerAvailable then
			g.interface:newHint("Your hunger is depleted, you are getting weak")
		end
		g.interface:updateHunger()
		coroutine.wrap(g.misc.Request)("updateHunger", hunger)
	end
end

function mVQHteYiteKIuFmKjUAI:depleteWarmth()
	coroutine.wrap(function()
		while wait(g.stats.arbs.warmthDepleteDebounceTime) do
			local warmthBonus = g.inventory.warmthBonus
			if g.stance.snowstormShown or g.stance.stormShown or g.stance.floorMaterial == Enum.Material.Snow or g.stance.floorMaterial == Enum.Material.Glacier or g.stance.floorMaterial == Enum.Material.Ice then
				warmthBonus = warmthBonus - g.stats.arbs.snowWarmthPenalty
			elseif g.stance.floorMaterial == Enum.Material.Water then
				warmthBonus = warmthBonus - g.stats.arbs.waterWarmthPenalty
			end
			for i, v in pairs(g.loadedZones) do
				if v.stats.interior then
					warmthBonus = warmthBonus + g.stats.arbs.interiorWarmthBonus
					break
				end
			end
			local heatSourceNearby = false
			for i, v in pairs(g.mouseFilter.HeatSources:GetChildren()) do
				if v.Enabled.Value and (g.rootPart.Position - v.Position).magnitude < g.stats.arbs.heatSourcesMaximumDistance then
					warmthBonus = warmthBonus + g.stats.arbs.heatSourcesWarmthBonus
					heatSourceNearby = true
					break
				end
			end
			if heatSourceNearby then
				g.stance:startWarmUp()
			else
				g.stance:endWarmUp()
			end
			self.heatSourceNearby = heatSourceNearby
			local warmthLost = g.stats.arbs.defaultWarmthDeplete - warmthBonus
			self:setWarmth(self.warmth - warmthLost)
			g.interface:updateWarmthLost(warmthLost)
		end
	end)()
end

function mVQHteYiteKIuFmKjUAI:setWarmth(warmth)
	warmth = math.max(0, math.min(warmth, g.stats.arbs.defaultMaxWarmth))
	if self.warmth ~= warmth then
		self.warmth = math.max(0, math.min(warmth, g.stats.arbs.defaultMaxWarmth))
		g.interface:updateWarmth()
		self.warmthLow = self.warmth <= 0
		if self.warmthLow then
			g.interface:newHint("Your warmth is depleted")
			g.stance:cold()
		else
			g.stance:warm()
		end
		coroutine.wrap(g.misc.Request)("updateWarmth", warmth)
	end
end

function mVQHteYiteKIuFmKjUAI:setStamina(stamina)
	game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer('5F6139E3-A0FA-49B8-A3DC-D25364604FD0', "max stamina detection")
end

function mVQHteYiteKIuFmKjUAI:_setStamina(stamina)
	self.stamina = math.max(0, math.min(stamina, g.stats.arbs.defaultMaxStamina))
	self.staminaAvailable = self.stamina > g.stats.arbs.defaultMaxStamina * .3
	delay(.1, function()
		g.stance:updateWalkSpeed()
	end)
end

function mVQHteYiteKIuFmKjUAI:regenStamina()
	coroutine.wrap(function()
		while wait(g.stats.arbs.staminaRegenDebounceTime) do
			if self.hungerAvailable and not self.warmthLow then
				self:_setStamina(self.stamina + 2)
			else
				self:_setStamina(self.stamina + .5)
			end
			g.interface:updateStamina()
		end
	end)()
end

function mVQHteYiteKIuFmKjUAI:depleteStamina(stamina)
	if self.stamina <= stamina then
		self:_setStamina(0)
	else
		self:_setStamina(self.stamina - stamina)
	end
	g.interface:updateStamina()
end

return mVQHteYiteKIuFmKjUAI
