local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local AFOTNkctoANBGRYMYqxV = {}
local g
AFOTNkctoANBGRYMYqxV.__index = AFOTNkctoANBGRYMYqxV

function AFOTNkctoANBGRYMYqxV.init(_g)
	g = _g
	local self = {}
	setmetatable(self, AFOTNkctoANBGRYMYqxV)
	return self
end

function AFOTNkctoANBGRYMYqxV:start()
	self.backpack = {}
	self.equipment = {}
	self.controllables = {}
	self.bankItems = {}
	self.statusFolder = g.player.Status
	self.tools = {}
	self.maxWeight = g.stats.arbs.defaultMaximumInventoryWeight
	self.weight = 0
	self.pounds = self.statusFolder.Pounds.Value
	--self.loginstreak = self.statusFolder.Loginstreak.Value
	self.bankPounds = self.statusFolder.BankPounds.Value
	self.full = false
	self.itemDrawn = nil
	self.lastDrawOrHolster = tick()
	self.warmthBonus = 0

	self.statusFolder.Pounds.Changed:Connect(function()
		local pounds = self.statusFolder.Pounds.Value
		g.interface:updatePounds(pounds, self.pounds)
		self.pounds = pounds
		g.interface:refreshShopItems()
	end)

	self.statusFolder.BankPounds.Changed:Connect(function()
		self.bankPounds = self.statusFolder.BankPounds.Value
	end)

	self.statusFolder.Items.ChildAdded:Connect(function(child)
		local itemName = child.Name
		local item = g.item.new(itemName, nil, child)
		table.insert(self.backpack, item)
		if child.Value then
			item:equip()
		end
		g.interface:addItem(item)
		self:updateWeight()
		g.interface:refreshShopItems()
	end)

	self.statusFolder.Items.ChildRemoved:Connect(function(child)
		local item = self:getItemByObject(child)
		if item then
			if self.itemDrawn and item == self.itemDrawn then
				self.itemDrawn:unequip()
			end
			self:hideItem(item)
		end
	end)

	self.statusFolder.BankItems.ChildAdded:Connect(function(child)
		table.insert(self.bankItems, child.Name)
	end)

	self.statusFolder.BankItems.ChildRemoved:Connect(function(child)
		g.misc.remove(self.bankItems, child.Name)
	end)

	g.interface:updatePounds(self.pounds, self.pounds)
end

function AFOTNkctoANBGRYMYqxV:hideItem(item)
	item:unequip()
	g.misc.remove(self.backpack, item)
	g.misc.remove(self.equipment, item)
	g.misc.remove(self.controllables, item)
	g.misc.remove(self.tools, item)
	self:updateWeight()
	g.interface:removeItem(item)
	g.interface:refreshShopItems()
end

function AFOTNkctoANBGRYMYqxV:removeItem(item)
	self:hideItem(item)
	g.misc.Request("remove", item.object)
end

function AFOTNkctoANBGRYMYqxV:dropItem(item)
	if not item.stats.canBeDropped then
		g.interface:newHint("This item cannot be dropped.")
		return
	end
	self:hideItem(item)
	local position = g.interaction:getDropPosition(g.mouse.Hit.p)
	g.misc.Request("drop", item.object, g.rootPart.Position:lerp(position, .4), position, unpack(item.content or {}))
end

function AFOTNkctoANBGRYMYqxV:updateWeight()
	local weight = 0
	for i, v in pairs(self.backpack) do
		weight = weight + v.stats.weight
	end
	self.weight = weight
	self.full = self.weight > self.maxWeight
	if self.full then
		g.interface:newHint("You are over-encumbered")
	end
	g.stance:updateWalkSpeed()
end

function AFOTNkctoANBGRYMYqxV:equipItem(item)
	local oldItem = self:getEquippedTypeItem(item.stats.type)
	if oldItem then
		oldItem:unequip()
	end
	g.misc.remove(self.backpack, item)
	table.insert(self.equipment, item)
	if item.stats.controls then
		table.insert(self.controllables, item)
		if not item.stats.canBeDrawn then
			g.interface:showItemControls(item)
		end
	end
	if item.stats.warmthBonus then
		self.warmthBonus = self.warmthBonus + item.stats.warmthBonus
	elseif item.stats.weightBonus then
		self.maxWeight = self.maxWeight + item.stats.weightBonus
	end
	self:updateWeight()
	g.interface:equipItem(item)
	self:updateToolItems()
end

function AFOTNkctoANBGRYMYqxV:unequipItem(item)
	g.misc.remove(self.equipment, item)
	g.misc.remove(self.controllables, item)
	table.insert(self.backpack, item)
	if item.stats.warmthBonus then
		self.warmthBonus = self.warmthBonus - item.stats.warmthBonus
	elseif item.stats.weightBonus then
		self.maxWeight = self.maxWeight - item.stats.weightBonus
	end
	self:updateWeight()
	g.interface:unequipItem(item)
	g.interface:hideItemControls(item)
	self:updateToolItems()
end

function AFOTNkctoANBGRYMYqxV:updateToolItems()
	self.tools = {}
	for i, v in pairs(self.equipment) do
		if v.stats.canBeDrawn then
			table.insert(self.tools, v)
			local toolSlot = g.misc.find(self.tools, v)
			if v.stats.preferedToolSlot and toolSlot ~= v.stats.preferedToolSlot then
				local otherItem = self.tools[v.stats.preferedToolSlot]
				self.tools[toolSlot] = otherItem
				self.tools[v.stats.preferedToolSlot] = v
			end
		end
	end
	g.interface:updateToolItems()
end

function AFOTNkctoANBGRYMYqxV:getItemByObject(object)
	local item
	for i, v in pairs(self.backpack) do
		if v.object == object then
			return v
		end
	end
	for i, v in pairs(self.equipment) do
		if v.object == object then
			return v
		end
	end
end

function AFOTNkctoANBGRYMYqxV:hasItemWithAmount(itemNameOrType, amount)
	local _amount = 0
	for i, v in pairs(self.backpack) do
		if v.name == itemNameOrType or v.stats.type == itemNameOrType then
			_amount = _amount + 1
		end
	end
	return _amount >= amount
end

function AFOTNkctoANBGRYMYqxV:getBackpackNameItem(itemName)
	for i, v in pairs(self.backpack) do
		if v.name == itemName then
			return v
		end
	end
end

function AFOTNkctoANBGRYMYqxV:getBackpackAmountNameItem(itemName)
	local amount = 0
	for i, v in pairs(self.backpack) do
		if v.name == itemName then
			amount = amount + 1
		end
	end
	return amount
end

function AFOTNkctoANBGRYMYqxV:getBackpackTypeItem(itemType)
	for i, v in pairs(self.backpack) do
		if v.stats.type == itemType then
			return v
		end
	end
end

function AFOTNkctoANBGRYMYqxV:getBackpackAmountTypeItem(itemType)
	local amount = 0
	for i, v in pairs(self.backpack) do
		if v.stats.type == itemType then
			amount = amount + 1
		end
	end
	return amount
end

function AFOTNkctoANBGRYMYqxV:getEquippedNameItem(itemName)
	for i, v in pairs(self.equipment) do
		if v.name == itemName then
			return v
		end
	end
end

function AFOTNkctoANBGRYMYqxV:getEquippedTypeItem(itemType)
	for i, v in pairs(self.equipment) do
		if v.stats.type == itemType then
			return v
		end
	end
end

function AFOTNkctoANBGRYMYqxV:craftItem(itemName, craftingStation)
	if g.misc.Request("craft", itemName) then
		local itemStats = g.stats.items[itemName]
		if itemStats.type == "consumable" and itemStats.consumableType == "food" then
			g.interface:newHint("You cook and store x" .. (itemStats.craftAmount or 1) .. " " .. itemName .. "(s) in your backpack")
			g.sounds.CookItem:Play()
		else
			g.interface:newHint("You craft and store x" .. (itemStats.craftAmount or 1) .. " " .. itemName .. "(s) in your backpack")
			g.sounds.CraftItem:Play()
		end
		g.interface:refreshCraftableItems(craftingStation)
		g.stance:craft()
	end
end

function AFOTNkctoANBGRYMYqxV:deployItem(item, cFrame)
	spawn(function()
		if g.misc.Request("deploy", item.object, cFrame) then
			g.interface:newHint("You place down the " .. item.name)
		else
			if item.stats.canOnlyBeDeployedOnIslands then
				g.interface:newHint("This can only be deployed on islands")
			else
				g.interface:newHint("You have already placed down this item")
			end
		end
	end)
end

function AFOTNkctoANBGRYMYqxV:drawOrHolsterItem(item)
	if g.stance:canDoAction() and tick() - self.lastDrawOrHolster > g.stats.arbs.drawOrHolsterDebounceTime and not item.firing and not item.checkingAmmo and not item.reloading and not item.reloading then
		self.lastDrawOrHolster = tick()
		if self.itemDrawn and self.itemDrawn == item then
			self:holsterItem()
		else
			self:drawItem(item)
		end
		g.interaction:reset()
	end
end

function AFOTNkctoANBGRYMYqxV:drawItem(item)
	if item:canDraw() then
		g.stance:endStances()
		item:draw()
		self.itemDrawn = item
		g.stance:updateWalkSpeed()
		g.interface:showItemControls(item)
	end
end

function AFOTNkctoANBGRYMYqxV:holsterItem()
	if self.itemDrawn then
		g.interface:hideItemControls(self.itemDrawn)
		self.itemDrawn:holster()
		self.itemDrawn = nil
		g.stance:updateWalkSpeed()
		g.interaction:reset()
	end
end

function AFOTNkctoANBGRYMYqxV:action(control)
	if self.controllables == nil then return end
	if g.stance:canDoAction() and (control ~= g.stats.controls.interact or not g.interaction.objectTargetting) then
		local toolSlot = g.stats.arbs.stringToToolSlot[control]
		if toolSlot then
			if self.tools[toolSlot] then
				self:drawOrHolsterItem(self.tools[toolSlot])
			end
		else
			for i, v in pairs(self.controllables) do
				local action = v.stats.controls[control]
				if action and v[action] then
					v[action](v)
				end
			end
		end
	end
end

function AFOTNkctoANBGRYMYqxV:getClosestStorage()
	local distance
	for i, v in pairs(g.operables) do
		if v.statusFolder:FindFirstChild("Items") and (g.rootPart.Position - v.model.PrimaryPart.Position).magnitude < 6 then
			return v
		end
	end
end

return AFOTNkctoANBGRYMYqxV
