--!strict

-- Hatsushima-inspired islet, lake craft, active water propulsion, world boundary & anti-ghost ride.

local RunService = game:GetService('RunService')

local LakeActivityService = {}
local ISLAND_CENTER = Vector3.new(0, 0, -610)

local function terrainHeight(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -180, 0), parameters)
	return if result then result.Position.Y else fallback
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = Instance.new('Part')
	object.Name = name
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = material
	object.Anchored = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function ball(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = part(parent, name, size, cframe, color, material)
	object.Shape = Enum.PartType.Ball
	return object
end

local function cylinder(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = part(parent, name, size, cframe, color, material)
	object.Shape = Enum.PartType.Cylinder
	return object
end

local function makeTree(parent: Instance, position: Vector3, scale: number)
	local tree = Instance.new('Model')
	tree.Name = 'GroundedBroadleafTree'
	tree:SetAttribute('TerrainGrounded', true)
	tree.Parent = parent
	local groundPosition = Vector3.new(position.X, terrainHeight(position.X, position.Z, position.Y), position.Z)
	local phase = math.rad(math.abs(math.floor(position.X * 3 + position.Z)) % 360)
	cylinder(
		tree,
		'LowerTrunk',
		Vector3.new(7 * scale, 2.4 * scale, 2.4 * scale),
		CFrame.new(groundPosition + Vector3.new(0, 3.35 * scale - 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(83, 57, 39),
		Enum.Material.Wood
	)
	cylinder(
		tree,
		'UpperTrunk',
		Vector3.new(5.5 * scale, 1.75 * scale, 1.75 * scale),
		CFrame.new(groundPosition + Vector3.new(0, 8.2 * scale, 0)) * CFrame.Angles(0, phase, math.rad(86)),
		Color3.fromRGB(91, 64, 42),
		Enum.Material.Wood
	)
	for branchIndex = 1, 4 do
		local angle = phase + (branchIndex / 4) * math.pi * 2
		local startPosition = groundPosition + Vector3.new(0, 8.2 * scale, 0)
		local endPosition = startPosition
			+ Vector3.new(math.cos(angle) * 4.1 * scale, 3.1 * scale, math.sin(angle) * 4.1 * scale)
		local branchVector = endPosition - startPosition
		cylinder(
			tree,
			'Branch',
			Vector3.new(branchVector.Magnitude, 0.75 * scale, 0.75 * scale),
			CFrame.lookAt((startPosition + endPosition) / 2, endPosition) * CFrame.Angles(0, math.pi / 2, 0),
			Color3.fromRGB(91, 64, 42),
			Enum.Material.Wood
		).CanCollide =
			false
	end
	local leafColors = {
		Color3.fromRGB(48, 105, 56),
		Color3.fromRGB(62, 121, 64),
		Color3.fromRGB(76, 133, 69),
	}
	for crownIndex, crownSpec in
		{
			{ Vector3.new(0, 12.2, 0), Vector3.new(10.5, 8.2, 9.8) },
			{ Vector3.new(4.0, 11.6, 0.7), Vector3.new(8.4, 7.1, 8.0) },
			{ Vector3.new(-3.4, 12.0, -1.4), Vector3.new(8.2, 7.4, 8.5) },
			{ Vector3.new(0.8, 14.9, -2.2), Vector3.new(7.8, 6.4, 7.6) },
		}
	do
		local rawOffset = crownSpec[1] :: Vector3
		local rotatedOffset = CFrame.Angles(0, phase, 0):VectorToWorldSpace(rawOffset * scale)
		local foliage = ball(
			tree,
			`LeafCluster{crownIndex}`,
			(crownSpec[2] :: Vector3) * scale,
			CFrame.new(groundPosition + rotatedOffset),
			leafColors[((crownIndex + math.floor(scale * 10)) % #leafColors) + 1],
			Enum.Material.LeafyGrass
		)
		foliage.CanCollide = false
		foliage.CanTouch = false
	end
end

local function buildIslandDetails(root: Model)
	local island = Instance.new('Model')
	island.Name = 'HatsushimaInspiredIsland'
	island:SetAttribute('PreserveAsCentralLakeIsland', true)
	island:SetAttribute('ApproximateDiameterStuds', 180)
	island:SetAttribute('FestivalCapacity', 20)
	island:SetAttribute('Center', ISLAND_CENTER)
	island.Parent = root

	for index = 1, 7 do
		local stoneZ = -573 - index * 3.2
		part(
			island,
			'StoneApproach',
			Vector3.new(4.5, 0.35, 2.5),
			CFrame.new(0, terrainHeight(0, stoneZ, 2.6) + 0.18, stoneZ),
			Color3.fromRGB(139, 139, 130),
			Enum.Material.Slate
		)
	end

	local deckGround = terrainHeight(12, -657, 2.6)
	local deckY = deckGround + 0.65
	local deckTop = deckY + 0.5
	part(
		island,
		'FireworksSafetyDeck',
		Vector3.new(62, 1, 20),
		CFrame.new(12, deckY, -657),
		Color3.fromRGB(115, 88, 61),
		Enum.Material.WoodPlanks
	)
	local launcherIndex = 0
	for row = 0, 2 do
		for column = 0, 3 do
			launcherIndex += 1
			local launcherX = -12 + column * 16
			local launcherZ = -650 - row * 7
			part(
				island,
				`LauncherCradle{launcherIndex}`,
				Vector3.new(3.2, 0.5, 3.2),
				CFrame.new(launcherX, deckTop + 0.25, launcherZ),
				Color3.fromRGB(47, 49, 52),
				Enum.Material.Metal
			)
			local launcher = cylinder(
				island,
				`FireworkLauncher{launcherIndex}`,
				Vector3.new(3.6, 1.25, 1.25),
				CFrame.new(launcherX, deckTop + 0.5 + 1.8, launcherZ) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(70, 72, 78),
				Enum.Material.Metal
			)
			launcher.CanCollide = false
			launcher:SetAttribute('FireworksLaunchPoint', true)
		end
	end
end



local function buildLakeFeatures()
	local previous = workspace:FindFirstChild("LakeActivitySet")
	if previous then
		previous:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "LakeActivitySet"
	root.Parent = workspace
	buildIslandDetails(root)
end

function LakeActivityService.init()
	buildLakeFeatures()
end

return LakeActivityService
