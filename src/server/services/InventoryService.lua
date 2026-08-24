--!strict

-- InventoryService: items, clothing, furniture, fish.
-- Server-side only; the client never mutates inventory directly.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local InventoryService = {}

-- Add an item (stackables merge).
function InventoryService.addItem(playerId: number, itemId: string, count: number): ProfileTypes.Result<number>
	if count <= 0 then
		return { ok = false, error = 'Invalid count' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	profile.inventory.items[itemId] = (profile.inventory.items[itemId] or 0) + count
	return { ok = true, data = profile.inventory.items[itemId] }
end

-- Remove an item, checking the player has enough.
function InventoryService.removeItem(playerId: number, itemId: string, count: number): ProfileTypes.Result<number>
	if count <= 0 then
		return { ok = false, error = 'Invalid count' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	local current = profile.inventory.items[itemId] or 0
	if current < count then
		return { ok = false, error = 'Not enough items' }
	end
	profile.inventory.items[itemId] = current - count
	return { ok = true, data = profile.inventory.items[itemId] }
end

function InventoryService.addFish(playerId: number, fishId: string, count: number): ProfileTypes.Result<number>
	if count <= 0 then
		return { ok = false, error = 'Invalid count' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	profile.inventory.fish[fishId] = (profile.inventory.fish[fishId] or 0) + count
	return { ok = true, data = profile.inventory.fish[fishId] }
end

function InventoryService.getSnapshot(playerId: number): any
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return nil
	end
	return {
		items = table.clone(profile.inventory.items),
		fish = table.clone(profile.inventory.fish),
		yen = profile.economy.yen,
		fishingLevel = profile.progress.fishingLevel,
	}
end

-- How many of an item the player holds.
function InventoryService.countItem(playerId: number, itemId: string): number
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return 0
	end
	return profile.inventory.items[itemId] or 0
end

function InventoryService.init()
	-- Remote hookups are registered by feature services.
end

return InventoryService
