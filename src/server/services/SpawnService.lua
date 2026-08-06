--!strict

-- SpawnService (server): menempatkan NPC ke Workspace + ProximityPrompt.
-- Interaksi prompt di-handle oleh client (PromptTriggered -> fire NPCInteract).

local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local NPCs = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('NPCs'))

-- Lokasi spawn NPC di dalam asrama (dekat pintu masuk).
-- Part NPC tingginya 4 stud, jadi tengah ditaruh di atas permukaan lantai (y=1.5).
local NPC_SPAWNS: { [string]: Vector3 } = {
	teacher_sakura = Vector3.new(4, 3.5, 6),
}

local SpawnService = {}

function SpawnService.spawnNPC(npcId: string)
	local npc = NPCs[npcId]
	if not npc then
		warn(`[Spawn] Unknown NPC: {npcId}`)
		return nil
	end
	local position = NPC_SPAWNS[npcId] or Vector3.new(0, 3, 0)

	local model = Instance.new('Model')
	model.Name = npcId

	local part = Instance.new('Part')
	part.Size = Vector3.new(2, 4, 1)
	part.Anchored = true
	part.Position = position
	part.Name = 'Body'
	part.Parent = model

	local humanoid = Instance.new('Humanoid')
	humanoid.DisplayName = npcId
	humanoid.Parent = model

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'InteractPrompt'
	prompt.ActionText = 'Talk'
	prompt.ObjectText = npcId
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = true
	prompt.Parent = part

	model.Parent = Workspace
	return model
end

function SpawnService.init()
	task.spawn(function()
		SpawnService.spawnNPC(Config.spawnNpcId)
	end)
end

return SpawnService
