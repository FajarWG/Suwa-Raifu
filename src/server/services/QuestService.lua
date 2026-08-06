--!strict

-- QuestService: state quest aktif/selesai, objective progress, reward.
-- Logika murni di shared/util/QuestLogic.lua (testable); service ini
-- menghubungkan ke profile & inventory.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local InventoryService = require(script.Parent:WaitForChild('InventoryService'))
local Items = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Items'))
local Math = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('Math'))
local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local Types = require(ReplicatedStorage.Shared:WaitForChild('types'))
local QuestTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('QuestTypes'))
local QuestDefTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('QuestDefTypes'))
local QuestLogic = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('QuestLogic'))

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

-- Ambil QuestState aktif untuk questId (nil jika tidak aktif).
function QuestService.getActiveQuest(playerId: number, questId: string): QuestTypes.QuestState?
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return nil
	end
	for _, state in profile.quests.active do
		if state.id == questId then
			return state
		end
	end
	return nil
end

-- Cek apakah quest aktif.
function QuestService.isActive(playerId: number, questId: string): boolean
	return QuestService.getActiveQuest(playerId, questId) ~= nil
end

-- Buat QuestState baru dari QuestDef (pakai QuestLogic).
local function newQuestState(def: QuestDefTypes.QuestDef): QuestTypes.QuestState
	return {
		id = def.id,
		objectives = QuestLogic.createObjectives(def.objectives),
		acceptedAt = os.clock(),
	}
end

-- Progress objective 'talk' (bicara ke NPC).
function QuestService.progressTalk(playerId: number, npcId: string)
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return
	end
	local completed: { string } = {}
	for _, state in profile.quests.active do
		local done = QuestLogic.progressTalk(state.objectives, npcId, state.id)
		for _, questId in done do
			table.insert(completed, questId)
		end
	end
	for _, questId in completed do
		QuestService.completeQuest(playerId, questId)
	end
end

-- Progress objective 'collect' (punya item).
function QuestService.progressCollect(playerId: number, itemId: string)
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return
	end
	local count = InventoryService.countItem(playerId, itemId)
	local completed: { string } = {}
	for _, state in profile.quests.active do
		local done = QuestLogic.progressCollect(state.objectives, itemId, count, state.id)
		for _, questId in done do
			table.insert(completed, questId)
		end
	end
	for _, questId in completed do
		QuestService.completeQuest(playerId, questId)
	end
end

-- Mulai quest (validasi requirement). Return Result.
function QuestService.acceptQuest(playerId: number, questId: string): Types.Result<QuestDefTypes.QuestDef>
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
	if QuestService.isActive(playerId, questId) then
		return { ok = false, error = 'Quest already active' }
	end
	if not QuestLogic.meetsRequirements(def, profile.progress.japaneseLevel) then
		return { ok = false, error = 'Level too low' }
	end
	local state = newQuestState(def)
	table.insert(profile.quests.active, state)
	-- Quest intro: giver memberikan buku pelajaran sebagai awal quest.
	-- TODO: generalisasi pemberian item starter per quest.
	if questId == Config.initialQuestId then
		profile.inventory.items[Config.textbookItemId] = (profile.inventory.items[Config.textbookItemId] or 0) + 1
	end
	QuestService.progressCollect(playerId, Config.textbookItemId)
	return { ok = true, data = def }
end

-- Selesaikan quest & beri reward. Return Result.
function QuestService.completeQuest(playerId: number, questId: string): Types.Result<QuestDefTypes.QuestDef>
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
	for i, state in active do
		if state.id == questId then
			table.remove(active, i)
			break
		end
	end
	table.insert(profile.quests.completed, questId)

	-- Reward
	local reward = QuestLogic.calculateReward(def)
	if reward.xp > 0 then
		profile.progress.japaneseXp += reward.xp
		profile.progress.japaneseLevel = Math.levelFromXp(profile.progress.japaneseXp)
	end
	if reward.yen > 0 then
		profile.economy.yen += reward.yen
	end
	for _, itemId in reward.items do
		profile.inventory.items[itemId] = (profile.inventory.items[itemId] or 0) + 1
	end
	return { ok = true, data = def }
end

-- Ambil semua quest aktif (untuk UI).
function QuestService.getActiveQuests(playerId: number): { QuestTypes.QuestState }
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return {}
	end
	return profile.quests.active
end

function QuestService.init()
	-- Remote hookups didaftarkan oleh fitur (lihat runner.server.lua).
end

return QuestService
