local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local YAQshhpgIQUhvnpGgMIw = {}
local g
YAQshhpgIQUhvnpGgMIw.__index = YAQshhpgIQUhvnpGgMIw

function YAQshhpgIQUhvnpGgMIw.init(_g)
	g = _g
	local self = {}
	setmetatable(self, YAQshhpgIQUhvnpGgMIw)
	return self
end

function YAQshhpgIQUhvnpGgMIw:start()
	self.availableRoles = {}
	self.name = nil
	self.isInMainGroup = g.player:IsInGroup(g.stats.arbs.mainGroupID)
	self.NLRPosition = nil
	self.isInNLR = false
	self.lastNLRObject = nil

	self:getAvailableRoles()
end

function YAQshhpgIQUhvnpGgMIw:getAvailableRoles()
	for i, v in pairs(g.stats.roles) do
		if 
			(v.type == "main" and g.player:IsInGroup(g.stats.arbs.mainGroupID) and g.player:GetRankInGroup(g.stats.arbs.mainGroupID) >= 2)
			--or (v.type == "secondary" and g.player:IsInGroup(g.stats.arbs.secondaryGroupID) and g.player:GetRankInGroup(g.stats.arbs.secondaryGroupID) >= 2)
			or v.type == "default"
			--or g.misc.find(g.stats.arbs.admins, g.player.UserId)
		then
			table.insert(self.availableRoles, v)
		end
	end

end

function YAQshhpgIQUhvnpGgMIw:assignRole(roleName)
	local success, errormessage = pcall(function()
		g.misc.Request("setPlayerRole", roleName)
	end)
	if success then
		local roleStats = g.stats.roles[roleName]
		self.name = roleStats.name
		return true
	else
		local hmSuccess = false
		repeat
			local success2, errormessage2 = pcall(function()
				g.misc.Request("setPlayerRole", roleName)
			end)
			if success2 then
				local roleStats = g.stats.roles[roleName]
				self.name = roleStats.name
				hmSuccess = true
				return true
			end
			wait(2)
		until hmSuccess == true
	end
end

function YAQshhpgIQUhvnpGgMIw:setNLRZone(position)
	if (position - self.spawnPosition).magnitude > g.stats.arbs.NLRRadius then
		self:removeNLRZone(self.lastNLRObject)
		self.NLRPosition = position
		local NLRObject = g.objects.NLRZone:Clone()
		self.lastNLRObject = NLRObject
		NLRObject.CFrame = CFrame.new(position)
		NLRObject.Parent = g.mouseFilter
		g.tween:TweenVector3(NLRObject.Mesh, "Scale", Vector3.new(g.stats.arbs.NLRRadius * 5 * 2, g.stats.arbs.NLRRadius * 5 * 2, g.stats.arbs.NLRRadius * 5 * 2), 5, g.tween.Ease.Out.Quad)
		delay(g.stats.arbs.NLRDuration, function()
			self:removeNLRZone(NLRObject)
		end)
		coroutine.wrap(function()
			while wait(.5) and self.lastNLRObject and NLRObject == self.lastNLRObject do
				g.tween:TweenNumber(NLRObject, "Transparency", .6, .5, g.tween.Ease.In.Quad)
				self:checkNLRZone()
				wait(.5)
				if self.lastNLRObject and NLRObject == self.lastNLRObject then
					self:checkNLRZone()
					g.tween:TweenNumber(NLRObject, "Transparency", .8, .5, g.tween.Ease.Out.Quad)
				end
			end
		end)()
	end
end

function YAQshhpgIQUhvnpGgMIw:checkNLRZone()
	if self.NLRPosition then
		self.isInNLR = (self.NLRPosition - g.rootPart.Position).magnitude < g.stats.arbs.NLRRadius
		if self.isInNLR then
			g.interface:showNLRWarning()
		else
			g.interface:hideNLRWarning()
		end
	end
end

function YAQshhpgIQUhvnpGgMIw:removeNLRZone(NLRObject)
	if NLRObject then
		self.NLRPosition = nil
		if NLRObject == self.lastNLRObject then
			self.lastNLRObject = nil
			self.isInNLR = false
			g.interface:hideNLRWarning()
		end
		g.tween:TweenVector3(NLRObject.Mesh, "Scale", Vector3.new(0, 0, 0), 5, g.tween.Ease.In.Quad)
		delay(.5, function()
			g.tween:TweenNumber(NLRObject, "Transparency", 1, 4.5, g.tween.Ease.In.Linear)
			wait(4.5)
			NLRObject:Destroy()
			NLRObject = nil
		end)
	end
end

return YAQshhpgIQUhvnpGgMIw
