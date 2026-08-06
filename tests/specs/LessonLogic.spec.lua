--!strict

return function()
	describe('LessonLogic', function()
		it('gradeAnswer benar saat jawaban cocok', function()
			local LessonLogic = require(ReplicatedStorage.Shared.util.LessonLogic)
			local q = { promptKey = 'p', choices = { 'a', 'b', 'c' }, answer = 1 }
			expect(LessonLogic.gradeAnswer(q, 1)).to.equal(true)
			expect(LessonLogic.gradeAnswer(q, 0)).to.equal(false)
			expect(LessonLogic.gradeAnswer(q, -1)).to.equal(false)
		end)

		it('countCorrect menghitung jawaban benar', function()
			local LessonLogic = require(ReplicatedStorage.Shared.util.LessonLogic)
			local questions = {
				{ promptKey = 'p1', choices = { 'a', 'b' }, answer = 0 },
				{ promptKey = 'p2', choices = { 'a', 'b' }, answer = 1 },
				{ promptKey = 'p3', choices = { 'a', 'b' }, answer = 0 },
			}
			local answers = { [0] = 0, [1] = 1, [2] = 0 }
			expect(LessonLogic.countCorrect(questions, answers)).to.equal(3)
			answers[2] = 1
			expect(LessonLogic.countCorrect(questions, answers)).to.equal(2)
		end)

		it('isPassed memakai ambang 60%', function()
			local LessonLogic = require(ReplicatedStorage.Shared.util.LessonLogic)
			expect(LessonLogic.isPassed(1, 1)).to.equal(true)
			expect(LessonLogic.isPassed(2, 3)).to.equal(true)
			expect(LessonLogic.isPassed(1, 3)).to.equal(false)
			expect(LessonLogic.isPassed(0, 0)).to.equal(false)
		end)

		it('calculateXp memberi XP proporsional saat lulus', function()
			local LessonLogic = require(ReplicatedStorage.Shared.util.LessonLogic)
			-- 2/2 benar, base 50 -> 50
			expect(LessonLogic.calculateXp(2, 2, 50)).to.equal(50)
			-- 1/2 benar -> lulus (50%)? 0.5 < 0.6 -> gagal, xp kecil
			expect(LessonLogic.calculateXp(1, 2, 50)).to.equal(10)
			-- 2/3 benar -> lulus, floor(50 * 2/3) = 33
			expect(LessonLogic.calculateXp(2, 3, 50)).to.equal(33)
		end)
	end)
end
