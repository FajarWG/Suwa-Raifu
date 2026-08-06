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

-- Cek jumlah item yang dimiliki.
function InventoryService.countItem(playerId: number, itemId: string): number
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return 0
	end
	return profile.inventory.items[itemId] or 0
end

function InventoryService.init()
	-- Remote hookups didaftarkan oleh fitur (lihat runner.server.lua).
end

return InventoryService
