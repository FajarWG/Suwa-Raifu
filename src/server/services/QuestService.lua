--!strict

-- QuestService: state quest aktif/selesai, objective progress.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local Items = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Items'))
local Types = require(ReplicatedStorage.Shared:WaitForChild('types'))

local QuestService = {}

-- Cek apakah quest sudah selesai.
function QuestService.isCompleted(playerId: number, questId: string): boolean
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return false
	end
	for _, id in profile.quests.completed do
		if id == questId then
			return true
		end
	end
	return false
end

-- Mulai quest (validasi requirement).
function QuestService.acceptQuest(playerId: number, questId: string): Types.Result<QuestDef>
	local def = Items.QUESTS[questId]
	if not def then
		return { ok = false, error = 'Quest not found' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	if QuestService.isCompleted(playerId, questId) then
		return { ok = false, error = 'Quest already completed' }
	end
	for _, id in profile.quests.active do
		if id == questId then
			return { ok = false, error = 'Quest already active' }
		end
	end
	-- Requirement: level bahasa minimum
	if def.requirements.japaneseLevel and profile.progress.japaneseLevel < def.requirements.japaneseLevel then
		return { ok = false, error = 'Level too low' }
	end
	table.insert(profile.quests.active, questId)
	return { ok = true, data = def }
end

-- Selesaikan quest & beri reward.
function QuestService.completeQuest(playerId: number, questId: string): Types.Result<QuestDef>
	local def = Items.QUESTS[questId]
	if not def then
		return { ok = false, error = 'Quest not found' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	if QuestService.isCompleted(playerId, questId) then
		return { ok = false, error = 'Quest already completed' }
	end
	-- Hapus dari active
	local active = profile.quests.active
	for i, id in active do
		if id == questId then
			table.remove(active, i)
			break
		end
	end
	table.insert(profile.quests.completed, questId)

	-- Reward
	if def.rewards.xp > 0 then
		profile.progress.japaneseXp += def.rewards.xp
		-- TODO: pakai Math.levelFromXp
	end
	if def.rewards.yen > 0 then
		profile.economy.yen += def.rewards.yen
	end
	for _, itemId in def.rewards.items do
		profile.inventory.items[itemId] = (profile.inventory.items[itemId] or 0) + 1
	end
	return { ok = true, data = def }
end

function QuestService.init()
	-- Skeleton
end

return QuestService
