--!strict

-- LakeWildlifeController.lua
-- High-performance procedural aquatic wildlife covering 100% of Lake Suwa (2400 x 1050 studs).
-- Features:
--   - Full lake coverage across X: -1200 to +1200, Z: -1250 to -200
--   - Shallows & shores: Japanese Nishikigoi (Koi)
--   - Mid-depth: Synchronized Wakasagi Smelt schools
--   - Deep lakebed: Crucian Carp (Funa) & Trout
--   - Proximity LOD: 60 FPS smooth tail animations & avoidance for nearby fish

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')

local player = Players.LocalPlayer

type FishInstance = {
	model: Model,
	root: BasePart,
	tail: BasePart?,
	species: string,
	baseScale: Vector3,
	homeCenter: Vector3,
	patrolRadius: number,
	swimSpeed: number,
	swimY: number,
	angle: number,
	turnSpeed: number,
	wiggleFreq: number,
	wiggleAmp: number,
	schoolOffset: Vector3,
	color: Color3,
}

local LakeWildlifeController = {}
local activeFish: { FishInstance } = {}
local wildlifeFolder: Folder? = nil

local KOI_PALETTES = {
	Color3.fromRGB(240, 85, 35), -- Kohaku Vivid Vermillion
	Color3.fromRGB(255, 175, 45), -- Ogon Golden Yellow
	Color3.fromRGB(245, 245, 250), -- Shiroji Pearl White
	Color3.fromRGB(215, 60, 40), -- Beni Deep Red
	Color3.fromRGB(35, 35, 40), -- Sumi Japanese Ink Black
	Color3.fromRGB(240, 140, 40), -- Yamabuki Ogon Warm Gold
}

local CARP_COLORS = {
	Color3.fromRGB(115, 125, 95), -- Crucian Green-Olive
	Color3.fromRGB(85, 75, 65), -- Bronze Black Carp
	Color3.fromRGB(140, 130, 110), -- River Carp
	Color3.fromRGB(160, 145, 120), -- Rainbow Trout / Silver
}

local function createFishModel(species: string, color: Color3, size: Vector3): (Model, BasePart, BasePart?)
	local model = Instance.new('Model')
	model.Name = species

	local body = Instance.new('Part')
	body.Name = 'Body'
	body.Shape = Enum.PartType.Block
	body.Size = size
	body.Color = color
	body.Material = if species == 'Wakasagi' then Enum.Material.Glass else Enum.Material.SmoothPlastic
	body.Reflectance = if species == 'Wakasagi' then 0.35 else 0.15
	body.Anchored = true
	body.CanCollide = false
	body.CastShadow = false
	body.Parent = model

	local mesh = Instance.new('SpecialMesh')
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.8, 1.6)
	mesh.Parent = body

	local tail = Instance.new('Part')
	tail.Name = 'TailFin'
	tail.Size = Vector3.new(size.X * 0.2, size.Y * 0.9, size.Z * 0.7)
	tail.Color = color
	tail.Material = Enum.Material.SmoothPlastic
	tail.Transparency = 0.2
	tail.Anchored = true
	tail.CanCollide = false
	tail.CastShadow = false
	tail.Parent = model

	local tailMesh = Instance.new('SpecialMesh')
	tailMesh.MeshType = Enum.MeshType.Wedge
	tailMesh.Scale = Vector3.new(0.3, 1, 1)
	tailMesh.Parent = tail

	if species ~= 'Wakasagi' then
		local dorsal = Instance.new('Part')
		dorsal.Name = 'DorsalFin'
		dorsal.Size = Vector3.new(size.X * 0.15, size.Y * 0.5, size.Z * 0.6)
		dorsal.Color = color
		dorsal.Material = Enum.Material.SmoothPlastic
		dorsal.Transparency = 0.3
		dorsal.Anchored = true
		dorsal.CanCollide = false
		dorsal.CastShadow = false
		dorsal.Parent = model
	end

	return model, body, tail
end

local function spawnSchool(species: string, center: Vector3, count: number, radius: number, depthY: number)
	for i = 1, count do
		local size: Vector3
		local color: Color3
		local speed: number
		local wiggleFreq: number
		local wiggleAmp: number

		if species == 'Nishikigoi' then
			size = Vector3.new(0.9, 0.7, 2.6) * (0.85 + math.random() * 0.35)
			color = KOI_PALETTES[(i % #KOI_PALETTES) + 1]
			speed = 4.2 + math.random() * 2.0
			wiggleFreq = 5.0 + math.random() * 1.5
			wiggleAmp = 0.22
		elseif species == 'Wakasagi' then
			size = Vector3.new(0.4, 0.3, 1.2) * (0.8 + math.random() * 0.4)
			color = Color3.fromRGB(185, 215, 230)
			speed = 6.5 + math.random() * 2.8
			wiggleFreq = 8.5 + math.random() * 2.0
			wiggleAmp = 0.28
		else -- LakeCarp
			size = Vector3.new(1.1, 0.9, 3.2) * (0.9 + math.random() * 0.3)
			color = CARP_COLORS[(i % #CARP_COLORS) + 1]
			speed = 3.2 + math.random() * 1.5
			wiggleFreq = 4.0 + math.random() * 1.0
			wiggleAmp = 0.18
		end

		local model, body, tail = createFishModel(species, color, size)
		model.Parent = wildlifeFolder

		local angle = (i / count) * math.pi * 2 + math.random() * 0.5
		local spread = if species == 'Wakasagi' then 16 else 12
		local fish: FishInstance = {
			model = model,
			root = body,
			tail = tail,
			species = species,
			baseScale = size,
			homeCenter = center,
			patrolRadius = radius,
			swimSpeed = speed,
			swimY = depthY + (math.random() - 0.5) * 2.5,
			angle = angle,
			turnSpeed = 0.25 + math.random() * 0.15,
			wiggleFreq = wiggleFreq,
			wiggleAmp = wiggleAmp,
			schoolOffset = Vector3.new((math.random() - 0.5) * spread, (math.random() - 0.5) * 2, (math.random() - 0.5) * spread),
			color = color,
		}
		table.insert(activeFish, fish)
	end
end

function LakeWildlifeController.init()
	local existing = Workspace:FindFirstChild('SuwaWildlifeActive')
	if existing then
		existing:Destroy()
	end

	wildlifeFolder = Instance.new('Folder')
	wildlifeFolder.Name = 'SuwaWildlifeActive'
	wildlifeFolder.Parent = Workspace

	-- =========================================================================
	-- FULL LAKE SCAN & PROCEDURAL SPAWN (Across entire 2400 x 1050 expanse)
	-- =========================================================================
	local rng = Random.new(998877)
	local rayParamsWater = RaycastParams.new()
	rayParamsWater.IgnoreWater = false

	local rayParamsLand = RaycastParams.new()
	rayParamsLand.IgnoreWater = true

	-- Grid step of 75 studs across X: -1180 to 1180, Z: -1220 to -220
	for gx = -1180, 1180, 75 do
		for gz = -1220, -220, 75 do
			local waterHit = Workspace:Raycast(Vector3.new(gx, 60, gz), Vector3.new(0, -100, 0), rayParamsWater)
			if waterHit and waterHit.Material == Enum.Material.Water then
				local bedHit = Workspace:Raycast(Vector3.new(gx, waterHit.Position.Y - 0.5, gz), Vector3.new(0, -100, 0), rayParamsLand)
				local bedY = bedHit and bedHit.Position.Y or (waterHit.Position.Y - 37)
				local depth = waterHit.Position.Y - bedY

				if depth >= 3.5 then
					local center = Vector3.new(gx + rng:NextNumber(-15, 15), 0, gz + rng:NextNumber(-15, 15))

					if depth < 10 then
						-- Shallows / Coasts / Islands: Japanese Nishikigoi (Koi)
						spawnSchool('Nishikigoi', center, rng:NextInteger(4, 6), rng:NextNumber(22, 35), -math.min(depth * 0.6, 5))
					elseif depth < 24 then
						-- Mid-depth waters: Wakasagi Smelt Schools
						spawnSchool('Wakasagi', center, rng:NextInteger(10, 16), rng:NextNumber(40, 60), -math.min(depth * 0.55, 16))
					else
						-- Deep Lakebed basin: Crucian Carp & Trout near bottom
						spawnSchool('LakeCarp', center, rng:NextInteger(3, 5), rng:NextNumber(35, 55), bedY + rng:NextNumber(2.5, 5.0))
						-- Also add a school of Wakasagi cruising above
						if rng:NextNumber() > 0.4 then
							spawnSchool('Wakasagi', center, rng:NextInteger(8, 14), rng:NextNumber(45, 65), -14)
						end
					end
				end
			end
		end
	end

	print(`[LakeWildlife] Spawned {#activeFish} fish across entire Lake Suwa (2400x1050 studs).`)

	-- =========================================================================
	-- 60 FPS SMOOTH LOOP WITH PROXIMITY LOD (Smooth animation everywhere nearby)
	-- =========================================================================
	local elapsed = 0
	local MAX_VISIBLE_DIST = 380
	local MAX_VISIBLE_DIST_SQ = MAX_VISIBLE_DIST * MAX_VISIBLE_DIST

	RunService.Heartbeat:Connect(function(delta: number)
		elapsed += delta
		local char = player.Character
		local hrp = char and char:FindFirstChild('HumanoidRootPart') :: BasePart?
		local playerPos = hrp and hrp.Position or Vector3.new(0, 0, 0)

		for _, fish in ipairs(activeFish) do
			-- Advance orbit angle
			fish.angle = (fish.angle + (fish.swimSpeed / fish.patrolRadius) * delta) % (math.pi * 2)

			local orbitX = fish.homeCenter.X + math.cos(fish.angle) * fish.patrolRadius + fish.schoolOffset.X
			local orbitZ = fish.homeCenter.Z + math.sin(fish.angle) * fish.patrolRadius + fish.schoolOffset.Z
			local targetPos = Vector3.new(orbitX, fish.swimY, orbitZ)

			local distSq = (targetPos.X - playerPos.X) * (targetPos.X - playerPos.X)
				+ (targetPos.Z - playerPos.Z) * (targetPos.Z - playerPos.Z)

			-- Only update full visual transformation if within viewing range (LOD optimization)
			if distSq < MAX_VISIBLE_DIST_SQ then
				local distToPlayer = math.sqrt(distSq)
				local avoidFactor = 1.0

				-- Player & Boat avoidance
				if distToPlayer < 24 then
					local awayX = targetPos.X - playerPos.X
					local awayZ = targetPos.Z - playerPos.Z
					local len = math.sqrt(awayX * awayX + awayZ * awayZ)
					if len > 0.1 then
						targetPos = Vector3.new(
							targetPos.X + (awayX / len) * (24 - distToPlayer) * 0.85,
							targetPos.Y,
							targetPos.Z + (awayZ / len) * (24 - distToPlayer) * 0.85
						)
						avoidFactor = 1.65
					end
				end

				local lookDir = Vector3.new(-math.sin(fish.angle), 0, math.cos(fish.angle))
				local yBob = math.sin(elapsed * 1.5 + fish.angle) * 0.45
				local finalPos = Vector3.new(targetPos.X, fish.swimY + yBob, targetPos.Z)

				local tailWag = math.sin(elapsed * fish.wiggleFreq * avoidFactor) * fish.wiggleAmp
				local bodyRot = CFrame.lookAt(finalPos, finalPos + lookDir) * CFrame.Angles(0, tailWag * 0.35, 0)
				fish.root.CFrame = bodyRot

				if fish.tail then
					fish.tail.CFrame = bodyRot * CFrame.new(0, 0, fish.baseScale.Z * 0.55) * CFrame.Angles(0, tailWag, 0)
				end
			end
		end
	end)
end

return LakeWildlifeController
