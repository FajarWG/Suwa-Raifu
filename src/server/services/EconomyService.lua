--!strict

-- EconomyService: yen transactions, server-authoritative.
-- Every yen change goes through here so the client cannot forge one.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local InventoryService = require(script.Parent:WaitForChild('InventoryService'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local EconomyService = {}

local function syncEconomy(playerId: number, profile: any)
	local player = Players:GetPlayerByUserId(playerId)
	if player then
		RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
		local snap = InventoryService.getSnapshot(playerId)
		if snap then
			RemoteRegistry.fireClient(player, 'InventoryUpdated', snap)
		end
	end
end

-- Add yen. Returns a Result.
function EconomyService.addYen(playerId: number, amount: number): ProfileTypes.Result<number>
	if amount <= 0 then
		return { ok = false, error = 'Invalid amount' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	profile.economy.yen += amount
	syncEconomy(playerId, profile)
	return { ok = true, data = profile.economy.yen }
end

-- Spend yen, validating the balance first.
function EconomyService.spendYen(playerId: number, amount: number): ProfileTypes.Result<number>
	if amount <= 0 then
		return { ok = false, error = 'Invalid amount' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	if profile.economy.yen < amount then
		return { ok = false, error = 'Insufficient funds' }
	end
	profile.economy.yen -= amount
	syncEconomy(playerId, profile)
	return { ok = true, data = profile.economy.yen }
end

function EconomyService.init()
	-- Remote hookups are registered by feature services.
end

return EconomyService
