--!strict

-- EconomyService: transaksi yen (server-authoritative).
-- Semua perubahan yen lewat sini (anti-exploit).

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local Math = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('Math'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local EconomyService = {}

-- Tambah yen ke profil. Return Result.
function EconomyService.addYen(playerId: number, amount: number): ProfileTypes.Result<number>
	if amount <= 0 then
		return { ok = false, error = 'Invalid amount' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	profile.economy.yen += amount
	return { ok = true, data = profile.economy.yen }
end

-- Kurangi yen (validasi saldo cukup).
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
	return { ok = true, data = profile.economy.yen }
end

-- Beri Japanese XP; auto naik level sesuai threshold.
function EconomyService.addJapaneseXp(playerId: number, xp: number): ProfileTypes.Result<number>
	if xp <= 0 then
		return { ok = false, error = 'Invalid XP' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	profile.progress.japaneseXp += xp
	profile.progress.japaneseLevel = Math.levelFromXp(profile.progress.japaneseXp)
	return { ok = true, data = profile.progress.japaneseLevel }
end

function EconomyService.init()
	-- Remote hookups didaftarkan oleh fitur (lihat runner.server.lua).
end

return EconomyService
