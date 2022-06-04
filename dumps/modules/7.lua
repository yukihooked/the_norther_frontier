local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local xmjuOzLNYyaNEEtgRXqL = {}
local g
xmjuOzLNYyaNEEtgRXqL.__index = xmjuOzLNYyaNEEtgRXqL

function xmjuOzLNYyaNEEtgRXqL.init(_g)
	g = _g
end

xmjuOzLNYyaNEEtgRXqL.new = function(player)
	local self = {}
	setmetatable(self, xmjuOzLNYyaNEEtgRXqL)

	self.object = player
	self.name = player.Name
	self.items = {}
	self.statusFolder = self.object:WaitForChild("Status")
	self.role = self.statusFolder:WaitForChild("Role").Value
	self.restrained = self.statusFolder:WaitForChild("Restrained").Value
	self.health = self.statusFolder:WaitForChild("Health").Value
	self.maxHealth = self.statusFolder:WaitForChild("Health").MaxValue
	self.downed = self.statusFolder:WaitForChild("Downed").Value
	self.sleeping = self.statusFolder:WaitForChild("Sleeping").Value
	self.bleeding = self.statusFolder:WaitForChild("Bleed").Value > 0
	self.blocking = self.statusFolder:WaitForChild("Blocking").Value
	self.dragged = self.statusFolder:WaitForChild("Dragged").Value
	self.leaderboardGui = nil
	self.lastSeenChat = tick()
	repeat wait() until self.object.Character

	for _, descendant in ipairs(self.object.Character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant:GetPropertyChangedSignal('Size'):Connect(function()
				game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer("17D5C42F-A298-45F9-B42A-F6327BE328EC", self.object)
			end)
		end
	end

	self.object.Character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant:GetPropertyChangedSignal('Size'):Connect(function()
				game.ReplicatedStorage.Game_Replicated.Game_Remotes.LoadSounds:FireServer("17D5C42F-A298-45F9-B42A-F6327BE328EC", self.object)
			end)
		end
	end)

	self.chatGui = g.guis.ChatBillboardGui:Clone()
	self.chatGui.Parent = self.object.Character:WaitForChild("Head")
	self.chatGui.Adornee = self.object.Character.Head

	self:setupRestrictions()

	return self
end

function xmjuOzLNYyaNEEtgRXqL:setupRestrictions()
	self.statusFolder.Role.Changed:connect(function()
		self.role = self.statusFolder.Role.Value
		--self.leaderboardGui.Role.Text = self.role
	end)

	self.statusFolder.Health.Changed:connect(function()
		self.health = self.statusFolder.Health.Value
		self.maxHealth = self.statusFolder.Health.MaxValue
	end)

	self.statusFolder.Downed.Changed:connect(function()
		self.downed = self.statusFolder.Downed.Value
	end)

	self.statusFolder.Restrained.Changed:connect(function()
		self.restrained = self.statusFolder.Restrained.Value
	end)

	self.statusFolder.Sleeping.Changed:connect(function()
		self.sleeping = self.statusFolder.Sleeping.Value
	end)

	self.statusFolder.Dragged.Changed:connect(function()
		self.dragged = self.statusFolder.Dragged.Value
	end)

	self.statusFolder.Bleed.Changed:connect(function()
		self.bleeding = self.statusFolder.Bleed.Value > 0
	end)

	self.statusFolder.Blocking.Changed:connect(function()
		self.blocking = self.statusFolder.Blocking.Value
	end)

	for i, v in pairs(self.statusFolder.Items:GetChildren()) do
		self:addLootItem(v.Name)
	end

	self.statusFolder.Items.ChildAdded:connect(function(itemValue)
		self:addLootItem(itemValue.Name)
	end)

	self.statusFolder.Items.ChildRemoved:connect(function(itemValue)
		self:removeLootItem(itemValue.Name)
	end)
end

function xmjuOzLNYyaNEEtgRXqL:get(player)
	return g.players[player.Name]
end

function xmjuOzLNYyaNEEtgRXqL:addLootItem(itemName)
	if g.stats.items[itemName].canBeLooted or (g.stats.items[itemName].illegalHBM and self.role ~= "Hudson's Bay Company") or (g.stats.items[itemName].illegalNFC and self.role ~= "Nouvelle-France Company") then
		table.insert(self.items, itemName)
	end
end

function xmjuOzLNYyaNEEtgRXqL:removeLootItem(itemName)
	for i, v in pairs(self.items) do
		if v == itemName then
			table.remove(self.items, i)
			if self.looting then
				g.interface:refreshLootItems()
			end
			break
		end
	end
end

function xmjuOzLNYyaNEEtgRXqL:lootStart()
	if not self.looting and self.downed or self.restrained then
		self.looting = true
		g.interface:showLoot(self)
		coroutine.wrap(function()
			repeat wait(.2) until not g.interface.lootShown or not self.object.Parent or not (self.downed or self.restrained) or self:getDistance() > g.stats.arbs.lootingMaxDistance
			self:lootEnd()
		end)()
	end
end

function xmjuOzLNYyaNEEtgRXqL:lootEnd()
	if self.looting then
		self.looting = false
		g.interface:hideLoot()
	end
end

function xmjuOzLNYyaNEEtgRXqL:lootItem(itemName)
	if self.looting then
		g.stance:grab()
		g.misc.Request("lootPlayer", self.object, itemName)
	end
end

function xmjuOzLNYyaNEEtgRXqL:getDistance()
	return (self.object.Character.HumanoidRootPart.Position - g.rootPart.Position).magnitude
end


function xmjuOzLNYyaNEEtgRXqL:restrain()
	if not self.restrained then
		local handcuffsItem = g.inventory:getEquippedTypeItem("handcuffs")
		if handcuffsItem then
			coroutine.wrap(g.misc.Request)("restrain", self.object, true)
		end
	end
end

function xmjuOzLNYyaNEEtgRXqL:unrestrain()
	if self.restrained then
		coroutine.wrap(g.misc.Request)("restrain", self.object, false)
	end
end

function xmjuOzLNYyaNEEtgRXqL:bandage()
	if self.bleeding or self.health < self.maxHealth then
		local bandageItem = g.inventory:getEquippedTypeItem("bandage")
		if bandageItem then
			coroutine.wrap(g.misc.Request)("bandagePlayer", self.object)
		end
	end
end

function xmjuOzLNYyaNEEtgRXqL:indicateChatSeen()
	local seenChat = tick()
	self.lastSeenChat = seenChat
	g.tween:TweenNumber(self.chatGui.ChatFrame.Seen, "ImageTransparency", 0, .1, g.tween.Ease.In.Linear)
	delay(5, function()
		if self.lastSeenChat == seenChat then
			g.tween:TweenNumber(self.chatGui.ChatFrame.Seen, "ImageTransparency", 1, .1, g.tween.Ease.In.Linear)
		end
	end)
end

function xmjuOzLNYyaNEEtgRXqL:showChat(chat)
	local chatLine = g.guis.ChatLineWorld:Clone()
	for i, v in pairs(self.chatGui.ChatFrame:GetChildren()) do
		if v ~= self.chatGui.ChatFrame.Seen then
			coroutine.wrap(function()
				local offset = v.Position.Y.Offset - 20
				v:TweenPosition(UDim2.new(0, 0, 1, offset), "Out", "Linear", .1, true)
				if offset == -100 then
					g.tween:TweenNumber(v, "TextTransparency", 1, .2, g.tween.Ease.In.Linear)
					wait(.2)
					v:Destroy()
				end
			end)()
		end
	end
	chatLine.Parent = self.chatGui.ChatFrame
	coroutine.wrap(function()
		for i = 1, string.len(chat) do
			chatLine.Text = string.sub(chat, 1, i)
			wait()
		end
		wait(8)
		g.tween:TweenNumber(chatLine, "TextTransparency", 1, .2, g.tween.Ease.In.Linear)
		wait(.2)
		chatLine:Destroy()
	end)()
end

return xmjuOzLNYyaNEEtgRXqL
