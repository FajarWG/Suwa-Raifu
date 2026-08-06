--!strict

return function()
	describe('Math util', function()
		it('clamp membatasi nilai ke range', function()
			local Math = require(ReplicatedStorage.Shared.util.Math)
			expect(Math.clamp(150, 0, 100)).to.equal(100)
			expect(Math.clamp(-5, 0, 100)).to.equal(0)
			expect(Math.clamp(50, 0, 100)).to.equal(50)
		end)

		it('levelFromXp menghitung level dengan benar', function()
			local Math = require(ReplicatedStorage.Shared.util.Math)
			expect(Math.levelFromXp(0)).to.equal(1)
			expect(Math.levelFromXp(999)).to.equal(1)
			expect(Math.levelFromXp(1000)).to.equal(2)
			expect(Math.levelFromXp(2500)).to.equal(3)
			expect(Math.levelFromXp(10000)).to.equal(5)
		end)

		it('makeRateLimiter membatasi jumlah call per detik', function()
			local Math = require(ReplicatedStorage.Shared.util.Math)
			local limiter = Math.makeRateLimiter(2)
			-- 3 call pada detik yang sama
			expect(limiter('p1', 100)).to.equal(true)
			expect(limiter('p1', 100)).to.equal(true)
			expect(limiter('p1', 100)).to.equal(false)
			-- detik baru: reset
			expect(limiter('p1', 101)).to.equal(true)
		end)
	end)
end
