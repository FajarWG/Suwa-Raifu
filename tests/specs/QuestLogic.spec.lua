--!strict

return function()
	describe('QuestLogic', function()
		it('createObjectives membuat state objective dari def', function()
			local QuestLogic = require(ReplicatedStorage.Shared.util.QuestLogic)
			local objectives = QuestLogic.createObjectives({
				{ id = 'a', type = 'talk', target = 'teacher_sakura', requiredCount = 1 },
				{ id = 'b', type = 'collect', target = 'textbook', requiredCount = 1 },
			})
			expect(#objectives).to.equal(2)
			expect(objectives[1].currentCount).to.equal(0)
			expect(objectives[1].complete).to.equal(false)
			expect(objectives[1].target).to.equal('teacher_sakura')
		end)

		it('progressTalk menambah count dan menandai selesai', function()
			local QuestLogic = require(ReplicatedStorage.Shared.util.QuestLogic)
			local objectives = QuestLogic.createObjectives({
				{ id = 'a', type = 'talk', target = 'teacher_sakura', requiredCount = 1 },
			})
			local completed = QuestLogic.progressTalk(objectives, 'teacher_sakura', 'quest_intro')
			expect(objectives[1].currentCount).to.equal(1)
			expect(objectives[1].complete).to.equal(true)
			expect(completed).to.equal({ 'quest_intro' })
		end)

		it('progressTalk tidak menandai jika target berbeda', function()
			local QuestLogic = require(ReplicatedStorage.Shared.util.QuestLogic)
			local objectives = QuestLogic.createObjectives({
				{ id = 'a', type = 'talk', target = 'teacher_sakura', requiredCount = 1 },
			})
			local completed = QuestLogic.progressTalk(objectives, 'other_npc', 'quest_intro')
			expect(objectives[1].complete).to.equal(false)
			expect(completed).to.equal({})
		end)

		it('progressCollect menyinkronkan count dengan inventori', function()
			local QuestLogic = require(ReplicatedStorage.Shared.util.QuestLogic)
			local objectives = QuestLogic.createObjectives({
				{ id = 'b', type = 'collect', target = 'textbook', requiredCount = 1 },
			})
			local completed = QuestLogic.progressCollect(objectives, 'textbook', 2, 'quest_intro')
			expect(objectives[1].currentCount).to.equal(2)
			expect(objectives[1].complete).to.equal(true)
			expect(completed).to.equal({ 'quest_intro' })
		end)

		it('meetsRequirements mengecek level bahasa', function()
			local QuestLogic = require(ReplicatedStorage.Shared.util.QuestLogic)
			local def = {
				id = 'q',
				titleKey = '',
				descKey = '',
				giverNpcId = '',
				requirements = { japaneseLevel = 2 },
				objectives = {},
				rewards = { xp = 0, yen = 0, items = {} },
			}
			expect(QuestLogic.meetsRequirements(def, 1)).to.equal(false)
			expect(QuestLogic.meetsRequirements(def, 2)).to.equal(true)
			expect(QuestLogic.meetsRequirements(def, 5)).to.equal(true)
		end)

		it('calculateReward mengembalikan reward quest', function()
			local QuestLogic = require(ReplicatedStorage.Shared.util.QuestLogic)
			local def = {
				id = 'q',
				titleKey = '',
				descKey = '',
				giverNpcId = '',
				requirements = {},
				objectives = {},
				rewards = { xp = 100, yen = 500, items = { 'onigiri' } },
			}
			local reward = QuestLogic.calculateReward(def)
			expect(reward.xp).to.equal(100)
			expect(reward.yen).to.equal(500)
			expect(reward.items).to.equal({ 'onigiri' })
		end)
	end)
end
