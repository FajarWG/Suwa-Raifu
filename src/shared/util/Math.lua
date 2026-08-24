--!strict

-- Util shared: generic helpers (di-testable tanpa Roblox).

-- Clamp number ke range.
local function clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
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
	makeRateLimiter = makeRateLimiter,
}
