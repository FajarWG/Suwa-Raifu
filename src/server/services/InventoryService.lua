--!strict

-- InventoryService: item, clothing, furniture, fish.
-- Operasi di server; client tidak mengubah langsung.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local Types = require(ReplicatedStorage.Shared:WaitForChild('types'))

local InventoryService = {}

-- Tambah item ke inventori (stackable di-merge).
function InventoryService.addItem(playerId: number, itemId: string, count: number): Types.Result<number>
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

-- Ambil item (cek jumlah cukup).
function InventoryService.removeItem(playerId: number, itemId: string, count: number): Types.Result<number>
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

function InventoryService.init()
	-- Skeleton
end

return InventoryService
