local script = script getfenv().script = nil script.Parent = Instance.new("Folder", Instance.new("Folder", Instance.new("Folder")))
local iMdHkUCkPDSERgvwgnYh = {}
local g
iMdHkUCkPDSERgvwgnYh.__index = iMdHkUCkPDSERgvwgnYh

function iMdHkUCkPDSERgvwgnYh.init(_g)
	g = _g
	local self = {}
	setmetatable(self, iMdHkUCkPDSERgvwgnYh)
	return self
end

local fireInformation = {}
--local _stats = require(game.ReplicatedStorage.Game_Replicated.Game_Scripts.Stats)


local firingn = { }
function iMdHkUCkPDSERgvwgnYh:fire(item)
	if firingn[item.name] ~= nil then return end
	firingn[item.name] = true
	local ammoLoaded = item.content.ammoLoaded

	if item.content._token == nil then
		item.content._token = ammoLoaded
	end

	local ammoLoadedReal = item.content._token

	local hits = {}
	for i = 1, ammoLoadedReal or 1 do
		local player, hitPosition, hitObject
		if ammoLoadedReal and ammoLoaded then
			item.content.ammoLoaded = math.max(0, item.content.ammoLoaded - 1)
			item.content._token = math.max(0, item.content._token - 1)
		end
		-- if item["content"] ~= nil and item.content["ammoLoaded"] ~= nil and item.content.ammoLoaded >= 0 then
		if item.stats.weapon.projectile then
			table.insert(hits, g.mouse.Hit.p)
			table.insert(hits, item.content.chargeForce)
			player = self:animateProjectile(item.model, g.mouse.Hit.p, item.content.chargeForce)
		else						
			player, hitPosition, hitObject = self:ray(item)
			self:animate(item.model, hitPosition, hitObject ~= nil)
			table.insert(hits, hitPosition)
			table.insert(hits, hitObject or false)
		end
		-- if player then
		g.misc.damageEntity(player, item, "F0222B56-83B3-4588-AD40-A980C2B27804EEB6DBBB-3224-4D1D-B8CC-E4FE5B5A212D8290F2DC-7CB7-4A6B-B6F0-B9258B2FE5FBD5C78B1D-3CD5-4E10-9595-D61C0E67F11535B19110-1418-4A23-968A-F41D834A0EB13756DCAA-EC0B-46F9-BAEC-5CA35276E1A9E9891651-08D3-47BD-B030-317ECD8C8A17DFE0F302-0B4E-49C8-9A24-E2643D9C5F073E1A9209-5A99-41C5-8436-DD80BADA2E563D9DCEF0-3C90-4482-83D0-162905557543EAAE004A-6809-4DB5-A2D9-58498D6A47B4")
		-- end
		if not item.stats.weapon.scattershot then
			break
		end
		-- end
	end
	firingn[item.name] = nil
	g.misc.Request("animatePlayerFire", item.model, unpack(hits))
end

function iMdHkUCkPDSERgvwgnYh:ray(item)
	local origin = g.character.Head.Position
	local target = g.mouse.Hit.p
	local distance = (origin - target).magnitude
	local minSpread = -(item.stats.weapon.spread or 0) * distance 
	local maxSpread =  (item.stats.weapon.spread or 0) * distance
	target = Vector3.new(target.X + (math.random(minSpread, maxSpread) / 100), target.Y + (math.random(minSpread, maxSpread) / 100), target.Z + (math.random(minSpread, maxSpread) / 100))
	local ray = Ray.new(origin, (target - origin).unit * (item.stats.weapon.maxRange or g.stats.arbs.fireMaximumDistance))
	local hitObject, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, { g.mouseFilter, g.character })
	return g.misc.getPlayerFromPart(hitObject) or g.interaction:getOperable(hitObject), hitPosition, hitObject
end

function iMdHkUCkPDSERgvwgnYh:animate(itemModel, hitPosition, animateImpact)
	local bulletObject = g.objects.Bullet:Clone()
	bulletObject.Parent = g.mouseFilter
	bulletObject.Whizz:Play()
	local lastFire = tick()
	local distance = (itemModel.Barrel.Position - hitPosition).magnitude
	local direction = CFrame.new(itemModel.Barrel.Position, hitPosition)
	local barrelPosition = itemModel.Barrel.Position
	direction = direction - direction.p
	spawn(function()
		while g.runService.RenderStepped:wait() and bulletObject ~= nil do
			local i = (tick() - lastFire) / (g.stats.arbs.bulletLifeTime + (distance / 900))
			if i > 1 then
				bulletObject:Destroy()
				if animateImpact then
					local bulletImpactObject = g.objects.BulletImpact:Clone()
					bulletImpactObject.CFrame = CFrame.new(hitPosition)
					bulletImpactObject.Parent = g.mouseFilter
					bulletImpactObject.Impact:Play()
					delay(.2, function()
						bulletImpactObject.Smoke.Enabled = false
						wait(1.5)
						bulletImpactObject:Destroy()
					end)
				end
				break
			end
			local position = barrelPosition:lerp(hitPosition, i)
			local distance1 = (position - barrelPosition).magnitude
			local distance2 = (hitPosition - position).magnitude
			local distance3 = distance1 < g.stats.arbs.bulletLength and distance1 or g.stats.arbs.bulletLength
			local distance4 = distance2 < g.stats.arbs.bulletLength and distance2 or g.stats.arbs.bulletLength
			local bulletLength = (distance3 < distance4 and distance3) or (distance4 < distance3 and distance4) or g.stats.arbs.bulletLength
			bulletObject.Mesh.Scale = Vector3.new(bulletObject.Mesh.Scale.X, bulletObject.Mesh.Scale.Y, bulletLength)
			bulletObject.CFrame = direction + position
		end
	end)
end

function iMdHkUCkPDSERgvwgnYh:animateProjectile(itemModel, hitPosition, chargeForce, fishingPole)
	local itemStats = g.stats.items[itemModel.Name]
	local lastPosition
	local tipPosition = itemModel.Tip.Position
	local direction = CFrame.new(tipPosition, hitPosition).lookVector * 200 * chargeForce
	local startTime = tick()
	local projectileName
	if fishingPole then
		projectileName = "Floater"
		itemModel.Handle.ReelOut:Play()
	else
		projectileName = itemStats.weapon.ammoType
	end
	local projectileObject = g.objects["Game_Projectiles"][projectileName]:Clone()
	projectileObject.Parent = g.mouseFilter

	while true do
		if tick() - startTime >= 5 then
			projectileObject:Destroy()
		end

		local newPosition = tipPosition + self:lerpProjectile(direction, (tick() - startTime) * 2, -15)

		if lastPosition then
			local hitObject, hitPosition = self:rayProjectile(lastPosition, newPosition, { g.mouseFilter, itemModel.Parent.Parent })
			if hitObject then
				projectileObject.CFrame = CFrame.new(hitPosition, projectileObject.Position) * CFrame.Angles(math.rad(180), 0, 0)
				if fishingPole then
					itemModel.Handle.ReelOut:Stop()
					if hitObject.Name == "Water" then
						projectileObject.Impact:Play()
						itemModel.Tip.RopeConstraint.Length = (tipPosition - newPosition).magnitude + 2 -- - 4 -- was 2
						itemModel.Tip.RopeConstraint.Attachment1 = projectileObject.Attachment
						return projectileObject
					else
						projectileObject:Destroy()
						return
					end
				end
				projectileObject.Impact:Play()
				if hitObject.Anchored then
					delay(15, function()
						g.tweenService:Create(projectileObject, TweenInfo.new(5), { Transparency = 1 }):Play()
						wait(5)
						projectileObject:Destroy()
					end)
				else
					projectileObject.Transparency = 1
					delay(1, function()
						projectileObject:Destroy()
					end)
				end
				return g.misc.getPlayerFromPart(hitObject) or g.interaction:getOperable(hitObject)
			end
		end
		lastPosition = newPosition
		projectileObject.CFrame = CFrame.new(newPosition, projectileObject.Position) * CFrame.Angles(math.rad(180), 0, 0)

		g.runService.RenderStepped:wait()
	end
end

function iMdHkUCkPDSERgvwgnYh:lerpProjectile(initialVelocity, time, gravity)
	local displacement = {}
	displacement.x = initialVelocity.x * time
	displacement.y = (initialVelocity.y * time) + (gravity * (time^2))/2
	displacement.z = initialVelocity.z * time
	return Vector3.new(displacement.x, displacement.y, displacement.z)
end

function iMdHkUCkPDSERgvwgnYh:rayProjectile(origin, target, filter)
	local ray = Ray.new(origin, (target - origin).unit * (origin - target).magnitude)
	local hitObject, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, filter)
	return hitObject, hitPosition
end

return iMdHkUCkPDSERgvwgnYh
