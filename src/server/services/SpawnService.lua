--!strict

-- SpawnService (server): menempatkan NPC ke Workspace + ProximityPrompt.
-- Interaksi prompt di-handle oleh client (PromptTriggered -> fire NPCInteract).

local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local NPCs = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('NPCs'))

-- Lokasi NPC di depan sekolah bahasa fiktif.
-- Part NPC tingginya 4 stud, jadi tengah ditaruh di atas permukaan tanah.
local NPC_SPAWNS: { [string]: Vector3 } = {
	teacher_sakura = Vector3.new(-190, 3.5, 72),
}

local SpawnService = {}

local function resolveDisplayName(npcId: string): string
	if npcId == 'teacher_sakura' then
		return 'Teacher Sakura'
	end
	return npcId
end

local function findSpawnLocation(): SpawnLocation?
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA('SpawnLocation') then
			return descendant
		end
	end
	return nil
end

local function groundedPosition(preferred: Vector3?): Vector3
	if preferred then
		local origin = Vector3.new(preferred.X, 300, preferred.Z)
		local result = Workspace:Raycast(origin, Vector3.new(0, -1200, 0))
		if result then
			return Vector3.new(preferred.X, result.Position.Y + 2.6, preferred.Z)
		end
	end

	local spawnLocation = findSpawnLocation()
	if spawnLocation then
		local anchor = spawnLocation.CFrame.Position + spawnLocation.CFrame.LookVector * 8
		local fallbackOrigin = Vector3.new(anchor.X, 300, anchor.Z)
		local fallbackHit = Workspace:Raycast(fallbackOrigin, Vector3.new(0, -1200, 0))
		if fallbackHit then
			return Vector3.new(anchor.X, fallbackHit.Position.Y + 2.6, anchor.Z)
		end
		return anchor + Vector3.new(0, 2.6, 0)
	end

	return Vector3.new(0, 6, 0)
end

local function getNpcFolder(): Folder
	local folder = Workspace:FindFirstChild('NPCs')
	if folder and folder:IsA('Folder') then
		return folder
	end

	folder = Instance.new('Folder')
	folder.Name = 'NPCs'
	folder.Parent = Workspace
	return folder
end

function SpawnService.spawnNPC(npcId: string)
	local npc = NPCs[npcId]
	if not npc then
		warn(`[Spawn] Unknown NPC: {npcId}`)
		return nil
	end
	local position = groundedPosition(NPC_SPAWNS[npcId])
	local folder = getNpcFolder()
	local existing = folder:FindFirstChild(npcId)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new('Model')
	model.Name = npcId

	local part = Instance.new('Part')
	part.Size = Vector3.new(2.5, 5, 2)
	part.Anchored = true
	part.Position = position
	part.Name = 'Body'
	part.Color = Color3.fromRGB(247, 187, 208)
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = model

	local humanoid = Instance.new('Humanoid')
	humanoid.DisplayName = resolveDisplayName(npcId)
	humanoid.Parent = model

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'InteractPrompt'
	prompt.ActionText = 'Talk'
	prompt.ObjectText = npcId
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	local marker = Instance.new('BillboardGui')
	marker.Name = 'NameTag'
	marker.Size = UDim2.fromOffset(180, 36)
	marker.StudsOffset = Vector3.new(0, 3.2, 0)
	marker.AlwaysOnTop = true
	marker.Parent = part

	local nameLabel = Instance.new('TextLabel')
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 245, 190)
	nameLabel.TextStrokeTransparency = 0.45
	nameLabel.Text = resolveDisplayName(npcId)
	nameLabel.Parent = marker

	model.Parent = folder
	return model
end

function SpawnService.init()
	SpawnService.spawnNPC(Config.spawnNpcId)
	-- Terrain/map services may still be finalizing during startup, so respawn once
	-- after a short delay to keep NPC visible on the final ground level.
	task.delay(2, function()
		SpawnService.spawnNPC(Config.spawnNpcId)
	end)
end

return SpawnService
