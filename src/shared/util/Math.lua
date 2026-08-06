--!strict

-- Util shared: generic helpers (di-testable tanpa Roblox).

-- Clamp number ke range.
local function clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
end

-- Cek apakah player memenuhi level bahasa minimum.
local function meetsLevel(level: number, required: number): boolean
	return level >= required
end

-- Hitung level bahasa dari XP (tabel threshold, di-testable).
local LEVEL_THRESHOLDS = { 0, 1000, 2500, 5000, 7500 }

local function levelFromXp(xp: number): number
	local level = 1
	for i, threshold in LEVEL_THRESHOLDS do
		if xp >= threshold then
			level = i
		end
	end
	return level
end

-- Rate limit sederhana (window per detik).
local function makeRateLimiter(maxCallsPerSecond: number)
	local calls: { [string]: number } = {}
	local lastWindow: { [string]: number } = {}

	return function(key: string, now: number): boolean
		if lastWindow[key] ~= now then
			lastWindow[key] = now
			calls[key] = 0
		end
		calls[key] += 1
		return calls[key] <= maxCallsPerSecond
	end
end

return {
	clamp = clamp,
	meetsLevel = meetsLevel,
	levelFromXp = levelFromXp,
	makeRateLimiter = makeRateLimiter,
	LEVEL_THRESHOLDS = LEVEL_THRESHOLDS,
}
