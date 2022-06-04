local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local dmreWQQPGlBbTGbaaYuu = {}
local g
dmreWQQPGlBbTGbaaYuu.__index = dmreWQQPGlBbTGbaaYuu

function dmreWQQPGlBbTGbaaYuu.init(_g)
	g = _g
end

function dmreWQQPGlBbTGbaaYuu.new(model)
	local self = {}
	setmetatable(self, dmreWQQPGlBbTGbaaYuu)

	self.model = model
	self.name = model.Name
	self.statusFolder = model:WaitForChild("Status", 9999999999)
	self.type = self.statusFolder:WaitForChild("Type").Value
	self.enabled = self.statusFolder:WaitForChild("Enabled").Value
	self.locked = self.statusFolder:WaitForChild("Locked").Value
	self.available = self.statusFolder:WaitForChild("Available").Value
	self.stats = g.stats.operables[self.type]
	self.target = nil
	self.shop = nil
	self.owner = nil
	self.dragger = nil

	if self.type == "door" then
		self.doorType = self.statusFolder.DoorType.Value
		self.stats = g.stats.operables[self.doorType]
	elseif self.type == "cart" then
		self.dragger = self.statusFolder.Dragger.Value
		self.statusFolder.Dragger.Changed:Connect(function()
			self.dragger = self.statusFolder.Dragger.Value
		end)
	elseif self.type == "shop" or self.type == "purchasable" then
		self.shop = self.statusFolder.Shop.Value
	elseif self.type == "chair" then
		if self.statusFolder:FindFirstChild("ChairType") then
			self.chairType = self.statusFolder.ChairType.Value
		end
	elseif self.type == "tradingPost" then
		self.items = {}
		self.costs = {}

		for i, v in pairs(self.statusFolder.Items:GetChildren()) do
			self:addTradeItem(v.Name)
		end

		self.statusFolder.Items.ChildAdded:connect(function(itemValue)
			self:addTradeItem(itemValue.Name)
		end)

		self.statusFolder.Items.ChildRemoved:connect(function(itemValue)
			self:removeTradeItem(itemValue.Name)
		end)

		for i, v in pairs(self.statusFolder.Costs:GetChildren()) do
			self.costs[v.Name] = v.Value
			v.Changed:Connect(function()
				if v.Parent == self.statusFolder.Costs then
					self.costs[v.Name] = v.Value
				end
			end)
		end

		self.statusFolder.Costs.ChildAdded:connect(function(itemValue)
			self.costs[itemValue.Name] = itemValue.Value
			itemValue.Changed:Connect(function()
				if itemValue.Parent == self.statusFolder.Costs then
					itemValue.Value = math.ceil(itemValue.Value)
					self.costs[itemValue.Name] = itemValue.Value
					if self.trading then
						g.interface:refreshTradingPostItems(self)
					end
				end
			end)
		end)

		self.statusFolder.Costs.ChildRemoved:connect(function(itemValue)
			self.costs[itemValue.Name] = nil
		end)
	end

	if self.type == "storage" or (g.stats.items[self.name] and g.stats.items[self.name].cartType == "storage") then
		self.items = {}
		self.looting = false

		for i, v in pairs(self.statusFolder.Items:GetChildren()) do
			self:addStorageItem(v.Name)
		end

		self.statusFolder.Items.ChildAdded:connect(function(itemValue)
			self:addStorageItem(itemValue.Name)
		end)

		self.statusFolder.Items.ChildRemoved:connect(function(itemValue)
			self:removeStorageItem(itemValue.Name)
		end)
	end

	if self.statusFolder:FindFirstChild("Owner") then
		self.owner = self.statusFolder.Owner.Value

		self.statusFolder.Owner.Changed:Connect(function()
			self.owner = self.statusFolder.Owner.Value
		end)
	end

	self.statusFolder.Enabled.Changed:connect(function()
		self.enabled = self.statusFolder.Enabled.Value
	end)

	self.statusFolder.Locked.Changed:connect(function()
		self.locked = self.statusFolder.Locked.Value
	end)

	self.statusFolder.Available.Changed:connect(function()
		self.available = self.statusFolder.Available.Value
	end)

	return self
end

function dmreWQQPGlBbTGbaaYuu:showTravelling()
	g.interface:showTravelling()
end

function dmreWQQPGlBbTGbaaYuu:claim()
	g.misc.Request("claim", self.model)
end

function dmreWQQPGlBbTGbaaYuu:useCrafting()
	g.interface:showCrafting(self.statusFolder.CraftingType.Value)
end

function dmreWQQPGlBbTGbaaYuu:addLootableItem(itemName)
	table.insert(self.items, itemName)
	if self.looting then
		g.interface:addLootItem(itemName)
	end
end

function dmreWQQPGlBbTGbaaYuu:removeLootableItem(itemName)
	for i, v in pairs(self.items) do
		if v == itemName then
			table.remove(self.items, i)
			if self.looting then
				g.interface:removeLootItem(itemName)
			end
			break
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:lootStart()
	if not self.looting then
		self.looting = true
		g.inventory:holsterItem()
		g.interface:showLoot(self.items, self)
		spawn(function()
			repeat wait(.2) until not g.interface.lootShown or not self.model or not self.model.Parent or (g.rootPart.Position - self.model.PrimaryPart.Position).magnitude > 10 
			self:lootEnd()
		end)
	end
end

function dmreWQQPGlBbTGbaaYuu:lootEnd()
	if self.looting then
		self.looting = false
		g.interface:hideLoot()
	end
end

function dmreWQQPGlBbTGbaaYuu:lootItem(itemName)
	if self.looting then
		g.stance:grab()
		g.misc.Request("lootStorage", self.model, itemName)
	end
end

function dmreWQQPGlBbTGbaaYuu:animateSign(signModel)
	signModel:SetPrimaryPartCFrame(signModel:GetPrimaryPartCFrame() * CFrame.Angles(0, math.rad(5), 0))
	spawn(function()
		while wait(1) do
			g.tween:TweenCFrame(signModel, "SetPrimaryPartCFrame", signModel:GetPrimaryPartCFrame() * CFrame.Angles(0, math.rad(-10), 0), 1, g.tween.Ease.InOut.Quad)
			wait(1)
			g.tween:TweenCFrame(signModel, "SetPrimaryPartCFrame", signModel:GetPrimaryPartCFrame() * CFrame.Angles(0, math.rad(10), 0), 1, g.tween.Ease.InOut.Quad)
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:purchase()
	if (g.economy.stocks[self.name] or 1000) > 0 then
		if g.inventory.pounds >= g.stats.items[self.name].value * g.stats.shops[self.shop].purchaseCoefficient then
			g.economy:purchaseItem(self.shop, self.name, 1, self.model)
		else
			g.interface:newHint("Not enough pounds")
		end
	else
		g.interface:newHint("Out of stock")
	end
end

function dmreWQQPGlBbTGbaaYuu:canAccessShop()
	local shopStats = g.stats.shops[self.shop]
	if shopStats.requiredRole and g.role.name ~= shopStats.requiredRole then
		return false
	end
	if shopStats.requiredGroupID then
		if g.player:IsInGroup(shopStats.requiredGroupID) then
			if shopStats.requiredRankID then
				return g.player:GetRankInGroup(shopStats.requiredGroupID) >= shopStats.requiredRankID
			else
				return true
			end
		else
			return false
		end
	else
		return true
	end
end

function dmreWQQPGlBbTGbaaYuu:showNoticeBoard()
	g.interface:showNoticeBoard()
	while wait(.2) and g.interface.noticeBoardShown do
		if (g.rootPart.Position - self.model.Triggers.Trigger.PrimaryPart.Position).magnitude > 8 then
			g.interface:hideNoticeBoard()
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:showIslands()
	g.interface:showIslands()
	while wait(.2) and g.interface.islandsShown do
		if (g.rootPart.Position - self.model.Triggers.Trigger.PrimaryPart.Position).magnitude > 8 then
			g.interface:hideIslands()
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:showBounties()
	g.interface:showBounties()
	while wait(.2) and g.interface.bountiesShown do
		if (g.rootPart.Position - self.model.Triggers.Trigger.PrimaryPart.Position).magnitude > 8 then
			g.interface:hideBounties()
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:skin()
	if self.type == "animal" then
		g.misc.Request("interact", true, "skin", self.model)
	end

end

function dmreWQQPGlBbTGbaaYuu:open(triggerModel)
	spawn(function()
		if self.available then
			g.misc.Request("interact", true, self.doorType, self.model)
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:close(triggerModel)
	spawn(function()
		if self.available then
			g.misc.Request("interact", false, self.doorType, self.model)
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:light()
	spawn(function()
		g.misc.Request("interact", true, self.type, self.model)
		g.interface:newHint("You light the fire")
	end)
end

function dmreWQQPGlBbTGbaaYuu:extinguish()
	spawn(function()
		g.misc.Request("interact", false, self.type, self.model)
		g.interface:newHint("You extinguish the fire")
	end)
end

function dmreWQQPGlBbTGbaaYuu:showBank()
	g.interface:showBank()
	while wait(.2) and g.interface.bankShown do
		if (g.rootPart.Position - self.model.Triggers.Trigger.Part.Position).magnitude > 8 then
			g.interface:hideBank()
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:showStorage()
	g.interface:showStorage(self)
	self.looting = true
	while wait(.2) and g.interface.storageShown do
		if not self.model.Parent or (g.rootPart.Position - self.model.PrimaryPart.Position).magnitude > 10 then
			g.interface:hideStorage()
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:addStorageItem(itemName)
	table.insert(self.items, itemName)
	if self.looting then
		g.interface:refreshStorageItems()
	end
end

function dmreWQQPGlBbTGbaaYuu:removeStorageItem(itemName)
	for i, v in pairs(self.items) do
		if v == itemName then
			table.remove(self.items, i)
			if self.looting then
				g.interface:refreshStorageItems()
			end
			break
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:showTradingPost()
	g.interface:showTradingPost(self)
	self.trading = true
	while wait(.2) and g.interface.tradingPostShown do
		if not self.model.Parent or (g.rootPart.Position - self.model.PrimaryPart.Position).magnitude > 8 then
			g.interface:hideTradingPost()
			self.trading = false
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:addTradeItem(itemName)
	table.insert(self.items, itemName)
	if self.trading then
		repeat wait() until self.costs[itemName]
		g.interface:refreshTradingPostItems(self)
	end
end

function dmreWQQPGlBbTGbaaYuu:removeTradeItem(itemName)
	for i, v in pairs(self.items) do
		if v == itemName then
			table.remove(self.items, i)
			if self.trading then
				g.interface:refreshTradingPostItems(self)
			end
			break
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:showShop()
	g.interface:showShop(self.shop)
	while wait(.2) and g.interface.shopShown do
		if (g.rootPart.Position - self.model.Triggers.Trigger.Part.Position).magnitude > 8 then
			g.interface:hideShop()
		end
	end
end

function dmreWQQPGlBbTGbaaYuu:cutDown()
	spawn(function()
		if self.available then
			g.misc.Request("interact", true, self.type, self.model)
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:takeDown()
	spawn(function()
		if self.available then
			if g.misc.Request("interact", true, "takeDown", self.model) then
				g.interface:newHint("You take down the " .. self.name)
			else
				g.interface:newHint(self.name .. " must be empty")
			end
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:Mine()
	spawn(function()
		if self.available then
			g.misc.Request("interact", true, self.type, self.model)
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:sitDown()
	spawn(function()
		if self.available then
			table.insert(g.stance.allowedPositions, self.model.Seat.Position)
			if g.misc.Request("interact", true, self.type, self.model) then
				if self.chairType == "barber" then
					g.interface:showBarber()
				else
					g.player.CameraMode = Enum.CameraMode.LockFirstPerson
					g.humanoid.CameraOffset = Vector3.new(0, 0, -.5)
				end
			end
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:dragCart()
	spawn(function()
		if g.misc.Request("interact", true, self.type, self.model) then
			g.stance:dragCart(self)
		end
	end)
end

function dmreWQQPGlBbTGbaaYuu:dropCart()
	g.misc.Request("interact", false, self.type, self.model)
end

function dmreWQQPGlBbTGbaaYuu:ring()
	self.model.Triggers.Trigger.Bell.Ring:Play()
end

return dmreWQQPGlBbTGbaaYuu
