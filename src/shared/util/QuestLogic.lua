--!strict

-- QuestLogic (shared): logika quest murni (tanpa dependensi Roblox service).
-- Testable & dipakai QuestService server.

export type ObjectiveDef = {
	id: string,
	type: 'talk' | 'collect',
	target: string,
	requiredCount: number,
}

export type ObjectiveState = {
	id: string,
	type: 'talk' | 'collect',
	target: string,
	requiredCount: number,
	currentCount: number,
	complete: boolean,
}

export type QuestDef = {
	id: string,
	titleKey: string,
	descKey: string,
	giverNpcId: string,
	requirements: { japaneseLevel: number? },
	objectives: { ObjectiveDef },
	rewards: { xp: number, yen: number, items: { string } },
}

-- Buat state objective dari def.
local function createObjectives(defs: { ObjectiveDef }): { ObjectiveState }
	local states: { ObjectiveState } = {}
	for _, def in defs do
		table.insert(states, {
			id = def.id,
			type = def.type,
			target = def.target,
			requiredCount = def.requiredCount,
			currentCount = 0,
			complete = false,
		})
	end
	return states
end

-- Cek semua objective selesai.
local function allComplete(objectives: { ObjectiveState }): boolean
	for _, obj in objectives do
		if not obj.complete then
			return false
		end
	end
	return true
end

-- Progress objective talk (bicara ke NPC).
-- Return questIds yang jadi selesai (agar caller beri reward).
local function progressTalk(objectives: { ObjectiveState }, npcId: string, questId: string): { string }
	local completed: { string } = {}
	for _, obj in objectives do
		if obj.type == 'talk' and obj.target == npcId and not obj.complete then
			obj.currentCount += 1
			if obj.currentCount >= obj.requiredCount then
				obj.complete = true
			end
		end
	end
	if allComplete(objectives) then
		table.insert(completed, questId)
	end
	return completed
end

-- Progress objective collect (punya item).
local function progressCollect(
	objectives: { ObjectiveState },
	itemId: string,
	count: number,
	questId: string
): { string }
	local completed: { string } = {}
	for _, obj in objectives do
		if obj.type == 'collect' and obj.target == itemId and not obj.complete then
			obj.currentCount = count
			if obj.currentCount >= obj.requiredCount then
				obj.complete = true
			end
		end
	end
	if allComplete(objectives) then
		table.insert(completed, questId)
	end
	return completed
end

-- Hitung reward quest (untuk player progress). Murni kalkulasi.
local function calculateReward(def: QuestDef): { xp: number, yen: number, items: { string } }
	return {
		xp = def.rewards.xp,
		yen = def.rewards.yen,
		items = def.rewards.items,
	}
end

-- Cek requirement terpenuhi.
local function meetsRequirements(def: QuestDef, japaneseLevel: number): boolean
	if def.requirements.japaneseLevel and japaneseLevel < def.requirements.japaneseLevel then
		return false
	end
	return true
end

return {
	createObjectives = createObjectives,
	allComplete = allComplete,
	progressTalk = progressTalk,
	progressCollect = progressCollect,
	calculateReward = calculateReward,
	meetsRequirements = meetsRequirements,
}
