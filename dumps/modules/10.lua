local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local XOFirYPlvNWOuBYBXlSW = {}
local g
XOFirYPlvNWOuBYBXlSW.__index = XOFirYPlvNWOuBYBXlSW

function XOFirYPlvNWOuBYBXlSW.init(_g)
	g = _g
	local self = {}
	setmetatable(self, XOFirYPlvNWOuBYBXlSW)
	return self
end

function XOFirYPlvNWOuBYBXlSW:start()
	self.stocks = {}
	self.pounds = g.storage:WaitForChild("Pounds").Value
	self.stocksFolder = g.storage:WaitForChild("Stocks")
	self.lastStockUpdate = nil
	self.transactionInProgress = false

	self:setupStocks()
end

function XOFirYPlvNWOuBYBXlSW:setupStocks()
	delay(1, function()
		self.stocksFolder.ChildAdded:Connect(function(child)
			wait(1)
			self.stocks[child.Name] = child.Value
			self.lastStockUpdate = tick()
			g.interface:refreshShopItems()
			g.interface:refreshStockItems()
		end)

		for i, v in pairs(self.stocksFolder:GetChildren()) do
			self.stocks[v.Name] = v.Value

			v.Changed:Connect(function()
				self.stocks[v.Name] = v.Value
				self.lastStockUpdate = tick()
				delay(.5, function()
					g.interface:refreshShopItems()
				end)
				g.interface:refreshStockItems()
			end)
		end

		g.storage.Pounds.Changed:Connect(function()
			local pounds = g.storage.Pounds.Value
			g.interface:updateStockPounds(pounds, self.pounds)
			self.pounds = pounds
			delay(.5, function()
				g.interface:refreshShopItems()
			end)
		end)

		g.interface:updateStockPounds(self.pounds, self.pounds)
	end)
end

function XOFirYPlvNWOuBYBXlSW:purchaseItem(shop, itemName, itemAmount, displayModel)
	if not self.transactionInProgress then
		if #g.inventory.backpack > 250 then
			g.interface:newHint("Cannot carry any more items")
		else
			self.transactionInProgress = true
			g.interface:disableShopItems()

			itemAmount = g.misc.Request("purchaseItem", shop, itemName, itemAmount, displayModel)
			self.transactionInProgress = false
			if itemAmount then
				if g.stats.items[itemName].value * g.stats.shops[shop].purchaseCoefficient == 0 then
					g.sounds.ShowInventory:Play()
					g.interface:newHint("You take x" .. itemAmount .. " " .. itemName .. "(s)")
				else
					g.sounds.PurchaseItem:Play()
					g.interface:newHint("You purchase x" .. itemAmount .. " " .. itemName .. "(s)")
				end
			else
				g.interface:newHint("Transaction failed, you were not charged")
			end
			g.interface:refreshShopItems()
		end
	end
end

function XOFirYPlvNWOuBYBXlSW:purchaseItemTradingPost(tradingPost, itemName)
	if not self.transactionInProgress then
		if #g.inventory.backpack > 150 then
			g.interface:newHint("Cannot carry any more items")
		else
			self.transactionInProgress = true
			local success = g.misc.Request("purchaseItemTradingPost", tradingPost.model, itemName)
			self.transactionInProgress = false
			if success then
				if tradingPost.costs[itemName] == 0 or tradingPost.owner == g.player then
					g.sounds.ShowInventory:Play()
					g.interface:newHint("You take a " .. itemName .. " from " .. tradingPost.owner.Name)
				else
					g.sounds.PurchaseItem:Play()
					g.interface:newHint("You purchase a " .. itemName .. " from " .. tradingPost.owner.Name)
				end
			end
		end
	end
end

function XOFirYPlvNWOuBYBXlSW:sellItem(shop, item, itemAmount)
	if not self.transactionInProgress then
		self.transactionInProgress = true
		g.interface:disableShopItems()
		itemAmount = g.misc.Request("sellItem", shop, item.name, itemAmount)
		self.transactionInProgress = false
		if itemAmount then
			g.sounds.SellItem:Play()
			g.interface:newHint("You sell x" .. itemAmount .. " " .. item.name .. "(s)")
		else
			g.interface:newHint("Transaction failed, you were not charged")
		end
		g.interface:refreshShopItems()
	end
end

function XOFirYPlvNWOuBYBXlSW:importItem(itemName, itemAmount)
	if not self.transactionInProgress then
		self.transactionInProgress = true
		g.interface:disableStockItems()
		local success = g.misc.Request("importItem", itemName, itemAmount)
		self.transactionInProgress = false
		if success then
			--g.sounds.ShowInventory:Play()
			g.interface:newHint("You import x" .. itemAmount .. " " .. itemName)
		else
			g.interface:newHint("Transaction failed, you were not charged")
			g.interface:refreshStockItems()
		end
	end
end

function XOFirYPlvNWOuBYBXlSW:exportItem(itemName, itemAmount)
	if not self.transactionInProgress then
		self.transactionInProgress = true
		g.interface:disableStockItems()
		itemAmount = g.misc.Request("exportItem", itemName, itemAmount)
		self.transactionInProgress = false
		if itemAmount then
			--g.sounds.ShowInventory:Play()
			g.interface:newHint("You export x" .. itemAmount .. " " .. itemName)
		else
			g.interface:newHint("Transaction failed, you were not charged")
			g.interface:refreshStockItems()
		end
	end
end

return XOFirYPlvNWOuBYBXlSW
