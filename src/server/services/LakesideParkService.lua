--!strict

-- Photo-led Suwa Lakeside Park environment pass. This service replaces the old
-- coloured greybox trails while leaving fishing, bicycles and lake craft intact.

local Lighting = game:GetService('Lighting')

local tartanColor = Color3.fromRGB(139, 56, 55)
local asphaltColor = Color3.fromRGB(57, 61, 62)
local markingColor = Color3.fromRGB(235, 235, 226)
local timberColor = Color3.fromRGB(101, 72, 48)
local darkMetal = Color3.fromRGB(53, 57, 56)

local LakesideParkService = {}

local function terrainHeight(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -220, 0), parameters)
	return if result then result.Position.Y else fallback
end

local function makePart(
	className: string,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): BasePart
	local object = Instance.new(className) :: BasePart
	object.Name = name
	object.Anchored = true
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = material
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function makeSeat(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance): Seat
	local seat = Instance.new("Seat")
	seat.Name = name
	seat.Anchored = true
	seat.Size = size
	seat.CFrame = cframe
	seat.Color = color
	seat.Material = material
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.Parent = parent
	return seat
end


local function makeBall(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): BasePart
	local object = makePart('Part', name, size, CFrame.new(position), color, material, parent)
	object.Shape = Enum.PartType.Ball
	return object
end

local function makeCylinder(
	name: string,
	height: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): BasePart
	local object = makePart(
		'Part',
		name,
		Vector3.new(height, diameter, diameter),
		cframe * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		parent
	)
	object.Shape = Enum.PartType.Cylinder
	return object
end

local function addJapaneseLabel(sign: BasePart, text: string)
	local gui = Instance.new('SurfaceGui')
	gui.Name = 'JapaneseLabel'
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 42
	gui.Parent = sign

	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(54, 48, 39)
	label.TextScaled = true
	label.Parent = gui
end

local function makePathSegment(
	parent: Instance,
	name: string,
	from: Vector3,
	to: Vector3,
	width: number,
	thickness: number,
	color: Color3,
	material: Enum.Material
): BasePart
	local groundedFrom = Vector3.new(from.X, terrainHeight(from.X, from.Z, from.Y) + thickness / 2 + 0.04, from.Z)
	local groundedTo = Vector3.new(to.X, terrainHeight(to.X, to.Z, to.Y) + thickness / 2 + 0.04, to.Z)
	local delta = groundedTo - groundedFrom
	local midpoint = (groundedFrom + groundedTo) / 2
	local cframe = CFrame.lookAt(midpoint, groundedTo) * CFrame.Angles(0, math.pi / 2, 0)
	return makePart('Part', name, Vector3.new(delta.Magnitude + 1.4, thickness, width), cframe, color, material, parent)
end

local function makePolyline(
	parent: Instance,
	name: string,
	points: { Vector3 },
	width: number,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	withMarkings: boolean
)
	for index = 1, #points - 1 do
		local from = points[index]
		local to = points[index + 1]
		local horizontalDistance = Vector2.new(to.X - from.X, to.Z - from.Z).Magnitude
		-- Long straight parts bridge over every dip between their two raycast
		-- endpoints. Short terrain-sampled sections keep both tracks planted on
		-- rolling ground without losing the broad lakeside curve.
		local subdivisionCount = math.max(1, math.ceil(horizontalDistance / 11))
		for subdivision = 1, subdivisionCount do
			local segmentFrom = from:Lerp(to, (subdivision - 1) / subdivisionCount)
			local segmentTo = from:Lerp(to, subdivision / subdivisionCount)
			local segment = makePathSegment(
				parent,
				`{name}Segment{index}_{subdivision}`,
				segmentFrom,
				segmentTo,
				width,
				thickness,
				color,
				material
			)
			if withMarkings and subdivision % 2 == 1 then
				local dash = makePart(
					'Part',
					`{name}CenterDash{index}_{subdivision}`,
					Vector3.new(math.min(5, segment.Size.X * 0.48), 0.08, 0.42),
					segment.CFrame * CFrame.new(0, thickness / 2 + 0.06, 0),
					markingColor,
					Enum.Material.SmoothPlastic,
					parent
				)
				dash.CanCollide = false
			end
		end
	end
end

local function groundModelAt(model: Model, x: number, z: number, clearance: number)
	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local bottom = boundingCFrame.Y - boundingSize.Y / 2
	local targetBottom = terrainHeight(x, z, 0) + clearance
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position + Vector3.new(0, targetBottom - bottom, 0)) * pivot.Rotation)
	model:SetAttribute('TerrainGrounded', true)
end

local function removeGreybox()
	local central = workspace:FindFirstChild('SuwaCentral')
	if central then
		for _, name in
			{
				'LakesidePromenade',
				'LakesideTrees',
				'LakesideFurniture',
				'PromenadeLights',
				'WestLakesideParkLawn',
				'SekichoInspiredLawn',
				'ParkToDormPath',
			}
		do
			local object = central:FindFirstChild(name)
			if object then
				object:Destroy()
			end
		end
	end

	local activities = workspace:FindFirstChild('LakesideActivities')
	if activities then
		for _, oldName in
			{
				'LakesideTrails',
				'LakesideRestArea',
				'LakesideFoodStall',
				'FootbathArea',
				'BikeRouteSign',
				'FishingAreaSign',
			}
		do
			local oldObject = activities:FindFirstChild(oldName)
			if oldObject then
				oldObject:Destroy()
			end
		end
	end
end

local function buildDualTrack(root: Model)
	local tracks = Instance.new('Model')
	tracks.Name = 'CurvingDualLakesideTrack'
	tracks.Parent = root

	local asphaltPoints = {
		Vector3.new(-640, 0.7, -170),
		Vector3.new(-560, 1.2, -181),
		Vector3.new(-470, 2.6, -171),
		Vector3.new(-380, 3.2, -153),
		Vector3.new(-285, 2.1, -159),
		Vector3.new(-190, 0.8, -176),
		Vector3.new(-90, 1.4, -169),
		Vector3.new(15, 3.1, -149),
		Vector3.new(120, 4.1, -140),
		Vector3.new(220, 3.0, -148),
		Vector3.new(315, 1.3, -164),
		Vector3.new(410, 2.4, -180),
		Vector3.new(510, 1.1, -174),
		Vector3.new(610, 0.7, -190),
		Vector3.new(670, 0.6, -184),
	}
	local tartanPoints = {
		Vector3.new(-640, 0.65, -190),
		Vector3.new(-560, 1.0, -201),
		Vector3.new(-470, 2.0, -192),
		Vector3.new(-380, 2.7, -175),
		Vector3.new(-285, 1.7, -181),
		Vector3.new(-190, 0.65, -198),
		Vector3.new(-90, 1.0, -191),
		Vector3.new(15, 2.6, -171),
		Vector3.new(120, 3.5, -162),
		Vector3.new(220, 2.5, -170),
		Vector3.new(315, 1.0, -186),
		Vector3.new(410, 2.0, -202),
		Vector3.new(510, 0.8, -196),
		Vector3.new(610, 0.6, -212),
		Vector3.new(670, 0.55, -205),
	}

	makePolyline(tracks, 'AsphaltBikeWalk', asphaltPoints, 13, 0.72, asphaltColor, Enum.Material.Asphalt, true)
	makePolyline(tracks, 'RedTartanJogging', tartanPoints, 9, 0.7, tartanColor, Enum.Material.Fabric, false)

	local inlandBranches = Instance.new('Model')
	inlandBranches.Name = 'BranchingParkPaths'
	inlandBranches.Parent = tracks
	makePolyline(inlandBranches, 'WestLocomotiveApproach', {
		Vector3.new(-505, 2.2, -166),
		Vector3.new(-515, 3.0, -138),
		Vector3.new(-500, 3.8, -112),
		Vector3.new(-470, 3.5, -91),
	}, 9, 0.55, Color3.fromRGB(72, 76, 73), Enum.Material.Asphalt, false)
	makePolyline(inlandBranches, 'CentralTerraceRamp', {
		Vector3.new(-90, 1.4, -165),
		Vector3.new(-72, 2.4, -139),
		Vector3.new(-48, 4.0, -116),
		Vector3.new(-20, 5.3, -93),
	}, 10, 0.6, Color3.fromRGB(78, 80, 76), Enum.Material.Asphalt, false)
	makePolyline(inlandBranches, 'EastFacilityApproach', {
		Vector3.new(410, 2.4, -176),
		Vector3.new(430, 2.8, -145),
		Vector3.new(455, 3.2, -116),
		Vector3.new(480, 2.6, -84),
	}, 11, 0.6, Color3.fromRGB(76, 78, 74), Enum.Material.Asphalt, false)

	local loopPoints = {}
	for index = 0, 16 do
		local angle = (index / 16) * math.pi * 2
		table.insert(
			loopPoints,
			Vector3.new(-305 + math.cos(angle) * 62, 2.2 + math.sin(angle * 2) * 0.8, -99 + math.sin(angle) * 42)
		)
	end
	makePolyline(
		inlandBranches,
		'WestGardenLoop',
		loopPoints,
		7,
		0.5,
		Color3.fromRGB(96, 91, 82),
		Enum.Material.Pavement,
		false
	)
end

local function makeBench(parent: Instance, index: number, position: Vector3, yaw: number)
	local template = game:GetService("ServerStorage"):FindFirstChild("CreatorParkBench")
	if template then
		local bench = template:Clone()
		bench.Name = `LakeFacingBench{index}`
		-- Lower it by 1.6 studs so the legs are in the ground
		local groundedPosition = Vector3.new(position.X, terrainHeight(position.X, position.Z, position.Y) - 1.6, position.Z)
		bench:PivotTo(CFrame.new(groundedPosition) * CFrame.Angles(0, yaw, 0))
		bench.Parent = parent
	end
end

local function buildBenches(root: Model)
	local benches = Instance.new('Model')
	benches.Name = 'LakeFacingBenches'
	benches.Parent = root
	for index, spec in
		{
			{ Vector3.new(-595, 0.7, -157), math.rad(-7) },
			{ Vector3.new(-470, 2.5, -145), math.rad(9) },
			{ Vector3.new(-335, 3.0, -131), math.rad(4) },
			{ Vector3.new(-205, 1.1, -151), math.rad(-8) },
			{ Vector3.new(-55, 2.0, -143), math.rad(10) },
			{ Vector3.new(75, 4.2, -119), math.rad(5) },
			{ Vector3.new(205, 3.4, -126), math.rad(-5) },
			{ Vector3.new(330, 1.7, -143), math.rad(-10) },
			{ Vector3.new(465, 2.8, -157), math.rad(8) },
			{ Vector3.new(595, 1.0, -167), math.rad(-8) },
		}
	do
		makeBench(benches, index, spec[1] :: Vector3, spec[2] :: number)
	end
end

local function makeWillow(parent: Instance, index: number, position: Vector3, scale: number)
	local isSakura = (index % 2 == 0)
	local template = game:GetService("ServerStorage"):FindFirstChild(isSakura and "CreatorSakuraTree" or "CreatorPineTree")
	if template then
		local tree = template:Clone()
		tree.Name = `ParkTree{index}`
		local groundedPosition = Vector3.new(position.X, terrainHeight(position.X, position.Z, position.Y), position.Z)
		local s = scale * (0.8 + (math.random() * 0.4))
		if tree:IsA("Model") then tree:ScaleTo(s) end
		tree:PivotTo(CFrame.new(groundedPosition) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0))
		tree.Parent = parent
	end
end

local function buildNaturalShore(root: Model)
	local shore = Instance.new('Model')
	shore.Name = 'NaturalShorelineDetails'
	shore.Parent = root

	for index = 1, 154 do
		local x = -660 + (index - 1) * 8.6
		local z = -226 + math.sin(x / 82) * 9 + math.cos(x / 165) * 5
		local size = 0.8 + ((index * 7) % 13) / 7
		local color = if index % 3 == 0 then Color3.fromRGB(128, 128, 119) else Color3.fromRGB(156, 151, 133)
		local pebbleHeight = terrainHeight(x, z, 0)
		local pebble = makeBall(
			'RoundedShorePebble',
			Vector3.new(size * 1.5, size * 0.65, size),
			Vector3.new(x, pebbleHeight + size * 0.3 - 0.05, z),
			color,
			Enum.Material.Pebble,
			shore
		)
		pebble.CanCollide = size > 1.8
	end

	for index, x in { -610, -495, -365, -235, -105, 35, 175, 305, 450, 590 } do
		local z = -213 + math.sin(x / 82) * 8 + math.cos(x / 165) * 4
		makeWillow(shore, index, Vector3.new(x, 0, z), 1.3 + (index % 3) * 0.1)
	end

	for index = 1, 48 do
		local x = -650 + index * 27
		local shoreZ = -233 + math.sin(x / 82) * 9 + math.cos(x / 165) * 5
		local reedHeight = 2.3 + (index % 3)
		local reedGround = terrainHeight(x, shoreZ + math.sin(index) * 1.8, -0.2)
		local reed = makePart(
			'Part',
			'ShoreGrass',
			Vector3.new(0.3, reedHeight, 0.3),
			CFrame.new(x, reedGround + reedHeight / 2 - 0.08, shoreZ + math.sin(index) * 1.8)
				* CFrame.Angles(0, 0, math.rad((index % 5) - 2)),
			Color3.fromRGB(91, 123, 63),
			Enum.Material.Grass,
			shore
		)
		reed.CanCollide = false
	end
end

local function buildRainPuddleDetails(root: Model)
	local puddles = Instance.new('Model')
	puddles.Name = 'ShallowRainPuddleReflections'
	puddles:SetAttribute('DecorativeOnly', true)
	puddles.Parent = root

	for index, spec in
		{
			{ position = Vector3.new(-650, 0.04, -92), width = 24, depth = 11, yaw = 14 },
			{ position = Vector3.new(360, 0.04, -32), width = 20, depth = 9, yaw = -11 },
			{ position = Vector3.new(650, 0.04, -105), width = 18, depth = 10, yaw = 9 },
		}
	do
		for lobe = 1, 2 do
			local offset = if lobe == 1 then Vector3.zero else Vector3.new(spec.width * 0.28, 0.01, 1.5)
			local surface = makePart(
				'Part',
				`PuddleReflection{index}_{lobe}`,
				Vector3.new(
					0.08,
					spec.width * (if lobe == 1 then 1 else 0.48),
					spec.depth * (if lobe == 1 then 1 else 0.7)
				),
				CFrame.new(spec.position + offset)
					* CFrame.Angles(0, math.rad(spec.yaw - (if lobe == 1 then 0 else 18)), 0)
					* CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(93, 139, 153),
				Enum.Material.Glass,
				puddles
			)
			surface.Shape = Enum.PartType.Cylinder
			surface.Transparency = 0.55
			surface.Reflectance = 0.12
			surface.CanCollide = false
			surface.CanTouch = false
			surface.CastShadow = false
		end
	end
end

local function buildTraditionalShelter(root: Model)
	local shelter = Instance.new('Model')
	shelter.Name = 'TraditionalRestShelter'
	shelter.Parent = root
	local center = Vector3.new(38, terrainHeight(38, -105, 0), -105)

	makePart(
		'Part',
		'StoneFloor',
		Vector3.new(38, 1, 27),
		CFrame.new(center + Vector3.new(0, 0.5, 0)),
		Color3.fromRGB(155, 151, 139),
		Enum.Material.Slate,
		shelter
	)
	for index, offset in
		{ Vector3.new(-15, 0, -10), Vector3.new(15, 0, -10), Vector3.new(-15, 0, 10), Vector3.new(15, 0, 10) }
	do
		makePart(
			'Part',
			`TimberPost{index}`,
			Vector3.new(1.3, 12, 1.3),
			CFrame.new(center + offset + Vector3.new(0, 6.5, 0)),
			timberColor,
			Enum.Material.Wood,
			shelter
		)
	end

	local roofColor = Color3.fromRGB(67, 77, 70)
	makePart(
		'WedgePart',
		'JapaneseRoofLakeSide',
		Vector3.new(21, 5.5, 32),
		CFrame.new(center + Vector3.new(-10.3, 15.1, 0)) * CFrame.Angles(0, 0, math.rad(180)),
		roofColor,
		Enum.Material.RoofShingles,
		shelter
	)
	makePart(
		'WedgePart',
		'JapaneseRoofTownSide',
		Vector3.new(21, 5.5, 32),
		CFrame.new(center + Vector3.new(10.3, 15.1, 0)),
		roofColor,
		Enum.Material.RoofShingles,
		shelter
	)
	makePart(
		'Part',
		'RoofRidge',
		Vector3.new(1.2, 1.2, 34),
		CFrame.new(center + Vector3.new(0, 18, 0)),
		Color3.fromRGB(47, 52, 49),
		Enum.Material.Slate,
		shelter
	)
	makePart(
		'Part',
		'LakeViewSeat',
		Vector3.new(18, 0.8, 3),
		CFrame.new(center + Vector3.new(0, 2.4, -6)),
		timberColor,
		Enum.Material.WoodPlanks,
		shelter
	)
	makePart(
		'Part',
		'LowTable',
		Vector3.new(11, 0.7, 5),
		CFrame.new(center + Vector3.new(0, 3.2, 2)),
		timberColor,
		Enum.Material.WoodPlanks,
		shelter
	)
end

local function buildFootbathCanopy(root: Model)
	local activities = workspace:FindFirstChild('LakesideActivities')
	local legacyFootbath = activities and activities:FindFirstChild('FootbathArea')
	if legacyFootbath then
		legacyFootbath:Destroy()
	end

	local canopy = Instance.new('Model')
	canopy.Name = 'AshiyuCanopy'
	canopy:SetAttribute('UsableFootbath', true)
	canopy:SetAttribute('ContainsRealBlueWater', true)
	canopy:SetAttribute('BasinDepthStuds', 4)
	canopy.Parent = root
	-- Raycast beside the excavation: casting through the centre would find the
	-- recessed basin floor and incorrectly lower the entire canopy.
	local center = Vector3.new(102, terrainHeight(76, -96, 0), -96)
	local deckColor = Color3.fromRGB(151, 151, 142)
	for index, deck in
		{
			{ 'NorthStoneDeck', Vector3.new(50, 0.65, 5.5), Vector3.new(0, 0.32, -10.25) },
			{ 'SouthStoneDeck', Vector3.new(50, 0.65, 5.5), Vector3.new(0, 0.32, 10.25) },
			{ 'WestStoneDeck', Vector3.new(5.5, 0.65, 15), Vector3.new(-22.25, 0.32, 0) },
			{ 'EastStoneDeck', Vector3.new(5.5, 0.65, 15), Vector3.new(22.25, 0.32, 0) },
		}
	do
		makePart(
			'Part',
			deck[1] :: string,
			deck[2] :: Vector3,
			CFrame.new(center + (deck[3] :: Vector3)),
			if index % 2 == 0 then deckColor else Color3.fromRGB(143, 145, 138),
			Enum.Material.Pavement,
			canopy
		)
	end
	makePart(
		'Part',
		'AshiyuBasinFloor',
		Vector3.new(40, 0.5, 14),
		CFrame.new(center + Vector3.new(0, -3.35, 0)),
		Color3.fromRGB(91, 103, 101),
		Enum.Material.Slate,
		canopy
	)
	local warmWater = makePart(
		'Part',
		'UsableWarmWater',
		Vector3.new(36, 0.22, 10),
		CFrame.new(center + Vector3.new(0, 1.02, 0)),
		Color3.fromRGB(71, 171, 201),
		Enum.Material.Glass,
		canopy
	)
	warmWater.Transparency = 0.18
	warmWater.CanCollide = false
	warmWater.CanTouch = true
	warmWater.Reflectance = 0.18
	warmWater:SetAttribute('WaterType', 'Ashiyu')

	for _, wall in
		{
			{ 'NorthBasinWall', Vector3.new(42, 4.6, 1.5), Vector3.new(0, -1.05, -7.25) },
			{ 'SouthBasinWall', Vector3.new(42, 4.6, 1.5), Vector3.new(0, -1.05, 7.25) },
			{ 'WestBasinWallNorth', Vector3.new(1.5, 4.6, 4), Vector3.new(-20.25, -1.05, -4.5) },
			{ 'WestBasinWallSouth', Vector3.new(1.5, 4.6, 4), Vector3.new(-20.25, -1.05, 4.5) },
			{ 'EastBasinWall', Vector3.new(1.5, 4.6, 13), Vector3.new(20.25, -1.05, 0) },
		}
	do
		makePart(
			'Part',
			wall[1] :: string,
			wall[2] :: Vector3,
			CFrame.new(center + (wall[3] :: Vector3)),
			Color3.fromRGB(105, 108, 104),
			Enum.Material.Slate,
			canopy
		)
	end
	for _, seatSpec in
		{
			{ 'AshiyuSeatNorth', Vector3.new(0, 1.25, -10) },
			{ 'AshiyuSeatSouth', Vector3.new(0, 1.25, 10) },
		}
	do
		makePart(
			'Part',
			seatSpec[1] :: string,
			Vector3.new(34, 0.55, 2.2),
			CFrame.new(center + (seatSpec[2] :: Vector3) + Vector3.new(0, -0.6, 0)),
			timberColor,
			Enum.Material.WoodPlanks,
			canopy
		)
		-- Add legs to AshiyuSeat
		for legX = -15, 15, 15 do
			makePart('Part', 'AshiyuSeatLeg', Vector3.new(0.6, 1.5, 1.8),
				CFrame.new(center + (seatSpec[2] :: Vector3) + Vector3.new(legX, -1.5, 0)),
				darkMetal, Enum.Material.Metal, canopy)
		end
	end
	-- Broad submerged steps provide a readable entry and stop the pool from
	-- feeling like a blue decal. They also give avatars a safe gradual descent.
	for stepIndex = 1, 3 do
		makePart(
			'Part',
			`AshiyuEntryStep{stepIndex}`,
			Vector3.new(5.5, 0.55, 8.5),
			CFrame.new(center + Vector3.new(-21.2 + stepIndex * 2, 0.35 - stepIndex * 0.95, 0)),
			Color3.fromRGB(130, 134, 129),
			Enum.Material.Slate,
			canopy
		)
	end
	for x = -15, 15, 10 do
		local steamAttachment = Instance.new('Attachment')
		steamAttachment.Name = 'SteamVent'
		steamAttachment.Position = Vector3.new(x, 0.35, 0)
		steamAttachment.Parent = warmWater
		local steam = Instance.new('ParticleEmitter')
		steam.Name = 'GentleSteam'
		steam.Texture = 'rbxasset://textures/particles/smoke_main.dds'
		steam.Color = ColorSequence.new(Color3.fromRGB(245, 248, 248))
		steam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.72),
			NumberSequenceKeypoint.new(1, 1),
		})
		steam.Lifetime = NumberRange.new(2.5, 4)
		steam.Rate = 1.4
		steam.Speed = NumberRange.new(0.35, 0.8)
		steam.SpreadAngle = Vector2.new(12, 12)
		steam.Parent = steamAttachment
	end
	for index, offset in
		{ Vector3.new(-21, 0, -10), Vector3.new(21, 0, -10), Vector3.new(-21, 0, 10), Vector3.new(21, 0, 10) }
	do
		makePart(
			'Part',
			`CanopyPost{index}`,
			Vector3.new(1.1, 10, 1.1),
			CFrame.new(center + offset + Vector3.new(0, 5, 0)),
			timberColor,
			Enum.Material.Wood,
			canopy
		)
	end
	makePart(
		'Part',
		'AshiyuRoof',
		Vector3.new(49, 1.2, 25),
		CFrame.new(center + Vector3.new(0, 11, 0)),
		Color3.fromRGB(74, 79, 70),
		Enum.Material.Slate,
		canopy
	)
	makePart(
		'Part',
		'RoofFasciaLake',
		Vector3.new(49, 1.8, 0.8),
		CFrame.new(center + Vector3.new(0, 10.5, -12.5)),
		timberColor,
		Enum.Material.Wood,
		canopy
	)
end

local function buildDuckBoatDock(root: Model)
	local dock = Instance.new('Model')
	dock.Name = 'DuckBoatDock'
	dock.Parent = root
	local wood = Color3.fromRGB(112, 84, 57)

	makePart(
		'Part',
		'AccessWalkway',
		Vector3.new(9, 1.2, 78),
		CFrame.new(245, 1.75, -199),
		wood,
		Enum.Material.WoodPlanks,
		dock
	)
	makePart(
		'Part',
		'MooringPlatform',
		Vector3.new(32, 1.2, 12),
		CFrame.new(245, 1.15, -238),
		wood,
		Enum.Material.WoodPlanks,
		dock
	)
	for _, x in { 231, 259 } do
		makeCylinder('MooringPost', 4.5, 1, CFrame.new(x, 2.3, -238), darkMetal, Enum.Material.Metal, dock)
	end

	local sign = makePart(
		'Part',
		'DuckBoatSign',
		Vector3.new(17, 5, 0.7),
		CFrame.new(253, 4, -193),
		Color3.fromRGB(222, 207, 168),
		Enum.Material.WoodPlanks,
		dock
	)
	addJapaneseLabel(sign, 'スワンボート')
end

local function buildTerracedLawn(root: Model)
	local terrace = Instance.new('Model')
	terrace.Name = 'UndulatingEventLawnTerrace'
	terrace.Parent = root

	for step = 1, 8 do
		local stair = makePart(
			'Part',
			`BroadGrassTerraceStep{step}`,
			Vector3.new(34 + step * 2.5, 0.65, 7.2),
			CFrame.new(-42, 0.45 + step * 0.64, -146 + step * 6.6),
			if step % 2 == 0 then Color3.fromRGB(151, 151, 140) else Color3.fromRGB(168, 166, 151),
			Enum.Material.Concrete,
			terrace
		)
		stair:SetAttribute('TerraceRise', true)
	end

	makePart(
		'Part',
		'UpperLawnViewingPad',
		Vector3.new(92, 0.7, 32),
		CFrame.new(-42, 5.9, -78),
		Color3.fromRGB(103, 137, 74),
		Enum.Material.Grass,
		terrace
	)
	for _, x in { -71, -13 } do
		makePart(
			'Part',
			'StepHandrail',
			Vector3.new(0.45, 5.5, 50),
			CFrame.new(x, 4.6, -116) * CFrame.Angles(math.rad(-6), 0, 0),
			darkMetal,
			Enum.Material.Metal,
			terrace
		).CanCollide =
			false
	end
end

local function buildFitnessCorner(root: Model)
	local fitness = Instance.new('Model')
	fitness.Name = 'OutdoorFitnessCorner'
	fitness.Parent = root
	local center = Vector3.new(-220, 0.18, -35)
	local rubberColors = { Color3.fromRGB(73, 83, 77), Color3.fromRGB(117, 68, 65) }
	for xIndex = -1, 1 do
		for zIndex = -1, 1 do
			makePart(
				'Part',
				'RubberSafetyTile',
				Vector3.new(7.5, 0.35, 7.5),
				CFrame.new(center + Vector3.new(xIndex * 7.7, 0, zIndex * 7.7)),
				rubberColors[((xIndex + zIndex + 8) % 2) + 1],
				Enum.Material.Rubber,
				fitness
			)
		end
	end
	for _, x in { -7, 7 } do
		makePart(
			'Part',
			'StretchPost',
			Vector3.new(0.7, 6.4, 0.7),
			CFrame.new(center + Vector3.new(x, 3.35, 0)),
			Color3.fromRGB(126, 70, 43),
			Enum.Material.Metal,
			fitness
		)
	end
	makePart(
		'Part',
		'StretchBar',
		Vector3.new(15, 0.7, 0.7),
		CFrame.new(center + Vector3.new(0, 6.25, 0)),
		Color3.fromRGB(126, 70, 43),
		Enum.Material.Metal,
		fitness
	)
	makePart(
		'Part',
		'BalancePlatform',
		Vector3.new(10, 0.8, 4),
		CFrame.new(center + Vector3.new(0, 1, 8)),
		timberColor,
		Enum.Material.WoodPlanks,
		fitness
	)
end

local function buildCurvedGravelPlaza(root: Model)
	local plaza = Instance.new('Model')
	plaza.Name = 'CurvedGravelFitnessPlaza'
	plaza.Parent = root

	-- Three overlapping horizontal cylinders avoid the hard rectangular outline
	-- of the old lawn greybox and create the loose, rounded plaza seen around the
	-- fitness and sculpture areas in the reference photos.
	for index, spec in
		{
			{ Vector3.new(-220, 0.12, -35), Vector3.new(0.5, 88, 62) },
			{ Vector3.new(-193, 0.12, -30), Vector3.new(0.5, 55, 48) },
			{ Vector3.new(-244, 0.12, -29), Vector3.new(0.5, 50, 46) },
		}
	do
		local patch = makePart(
			'Part',
			`RoundedGravelPatch{index}`,
			spec[2] :: Vector3,
			CFrame.new(spec[1] :: Vector3) * CFrame.Angles(0, 0, math.rad(90)),
			if index == 1 then Color3.fromRGB(174, 164, 143) else Color3.fromRGB(158, 151, 134),
			Enum.Material.Pebble,
			plaza
		)
		patch.Shape = Enum.PartType.Cylinder
	end

	local edgingPoints = {}
	for index = 0, 8 do
		local angle = math.rad(205 + index * 17)
		table.insert(edgingPoints, Vector3.new(-220 + math.cos(angle) * 48, 0.48, -35 + math.sin(angle) * 34))
	end
	makePolyline(
		plaza,
		'CurvedStoneEdging',
		edgingPoints,
		1.4,
		0.5,
		Color3.fromRGB(123, 122, 113),
		Enum.Material.Slate,
		false
	)

	for index, spec in
		{
			{ Vector3.new(-254, 0.3, -12), math.rad(28) },
			{ Vector3.new(-222, 0.3, -1), math.rad(3) },
		}
	do
		makeBench(plaza, 20 + index, spec[1] :: Vector3, spec[2] :: number)
	end
end

local function buildPublicToilet(root: Model)
	local toilet = Instance.new('Model')
	toilet.Name = 'LakesidePublicToilet'
	toilet:SetAttribute('AccessibleFacility', true)
	toilet.Parent = root
	local center = Vector3.new(505, terrainHeight(505, -75, 0) + 0.5, -75)

	makePart(
		'Part',
		'Foundation',
		Vector3.new(36, 1, 24),
		CFrame.new(center),
		Color3.fromRGB(148, 148, 139),
		Enum.Material.Concrete,
		toilet
	)
	makePart(
		'Part',
		'Building',
		Vector3.new(32, 12, 20),
		CFrame.new(center + Vector3.new(0, 6.3, 0)),
		Color3.fromRGB(213, 207, 190),
		Enum.Material.Plaster,
		toilet
	)
	makePart(
		'Part',
		'WoodCladding',
		Vector3.new(32.5, 4, 20.5),
		CFrame.new(center + Vector3.new(0, 3, 0)),
		Color3.fromRGB(113, 83, 59),
		Enum.Material.WoodPlanks,
		toilet
	)
	makePart(
		'Part',
		'LowPitchedRoof',
		Vector3.new(38, 1.1, 25),
		CFrame.new(center + Vector3.new(0, 12.8, 0)) * CFrame.Angles(0, 0, math.rad(-4)),
		Color3.fromRGB(65, 67, 62),
		Enum.Material.RoofShingles,
		toilet
	)

	for index, spec in
		{
			{ -10, Color3.fromRGB(73, 124, 169), '男性' },
			{ 0, Color3.fromRGB(178, 91, 102), '女性' },
			{ 10, Color3.fromRGB(72, 143, 119), '多目的' },
		}
	do
		local door = makePart(
			'Part',
			`ToiletDoor{index}`,
			Vector3.new(5.5, 7.5, 0.55),
			CFrame.new(center + Vector3.new(spec[1] :: number, 4.75, -10.3)),
			spec[2] :: Color3,
			Enum.Material.Metal,
			toilet
		)
		addJapaneseLabel(door, spec[3] :: string)
	end

	local sign = makePart(
		'Part',
		'ToiletSign',
		Vector3.new(14, 3.2, 0.55),
		CFrame.new(center + Vector3.new(0, 11.0, -10.5)),
		Color3.fromRGB(232, 228, 210),
		Enum.Material.WoodPlanks,
		toilet
	)
	addJapaneseLabel(sign, '公衆トイレ')

	local vending = Instance.new('Model')
	vending.Name = 'ToiletSideVendingMachine'
	vending.Parent = toilet
	local vendingPosition = center + Vector3.new(21, 0, -6)
	makePart(
		'Part',
		'Cabinet',
		Vector3.new(4, 6.5, 2.6),
		CFrame.new(vendingPosition + Vector3.new(0, 3.25, 0)),
		Color3.fromRGB(232, 235, 229),
		Enum.Material.Metal,
		vending
	)
	local productWindow = makePart(
		'Part',
		'ProductWindow',
		Vector3.new(3.4, 3.6, 0.25),
		CFrame.new(vendingPosition + Vector3.new(0, 4.2, -1.43)),
		Color3.fromRGB(161, 213, 225),
		Enum.Material.Glass,
		vending
	)
	productWindow.Transparency = 0.1
	for row = 0, 2 do
		for column = -2, 2 do
			makePart(
				'Part',
				'DrinkSelection',
				Vector3.new(0.42, 0.5, 0.16),
				CFrame.new(vendingPosition + Vector3.new(column * 0.58, 5.1 - row * 0.82, -1.58)),
				if (row + column) % 2 == 0 then Color3.fromRGB(196, 71, 62) else Color3.fromRGB(66, 126, 175),
				Enum.Material.Neon,
				vending
			).CanCollide =
				false
		end
	end
end

local function buildBicycleParking(root: Model)
	local parking = Instance.new('Model')
	parking.Name = 'CoveredMamachariParking'
	parking:SetAttribute('Capacity', 12)
	parking.Parent = root
	local center = Vector3.new(430, terrainHeight(430, -70, 0) + 0.3, -70)

	makePart(
		'Part',
		'ParkingSurface',
		Vector3.new(52, 0.6, 25),
		CFrame.new(center),
		Color3.fromRGB(119, 119, 112),
		Enum.Material.Pavement,
		parking
	)
	for index, offset in
		{
			Vector3.new(-23, 0, -10),
			Vector3.new(23, 0, -10),
			Vector3.new(-23, 0, 10),
			Vector3.new(23, 0, 10),
		}
	do
		makePart(
			'Part',
			`CanopyPost{index}`,
			Vector3.new(0.8, 9, 0.8),
			CFrame.new(center + offset + Vector3.new(0, 4.8, 0)),
			Color3.fromRGB(76, 80, 78),
			Enum.Material.Metal,
			parking
		)
	end
	makePart(
		'Part',
		'TransparentCanopy',
		Vector3.new(56, 0.7, 28),
		CFrame.new(center + Vector3.new(0, 9.5, 0)) * CFrame.Angles(0, 0, math.rad(-4)),
		Color3.fromRGB(126, 151, 151),
		Enum.Material.Glass,
		parking
	).Transparency =
		0.28

	for index = 1, 12 do
		local x = center.X - 22 + (index - 1) * 4
		makePart(
			'Part',
			'RackLeft',
			Vector3.new(0.35, 3.5, 0.35),
			CFrame.new(x - 1.2, center.Y + 1.8, center.Z),
			darkMetal,
			Enum.Material.Metal,
			parking
		)
		makePart(
			'Part',
			'RackRight',
			Vector3.new(0.35, 3.5, 0.35),
			CFrame.new(x + 1.2, center.Y + 1.8, center.Z),
			darkMetal,
			Enum.Material.Metal,
			parking
		)
		makePart(
			'Part',
			'RackTop',
			Vector3.new(2.7, 0.35, 0.35),
			CFrame.new(x, center.Y + 3.5, center.Z),
			darkMetal,
			Enum.Material.Metal,
			parking
		)
	end
	local sign = makePart(
		'Part',
		'BicycleParkingSign',
		Vector3.new(12, 3.2, 0.55),
		CFrame.new(center.X, terrainHeight(center.X, center.Z - 13, center.Y) + 5, center.Z - 13),
		Color3.fromRGB(223, 216, 190),
		Enum.Material.WoodPlanks,
		parking
	)
	local signGround = terrainHeight(center.X, center.Z - 13, center.Y)
	for _, xOffset in { -4.3, 4.3 } do
		makePart(
			'Part',
			'BicycleParkingSignPost',
			Vector3.new(0.65, 5.2, 0.65),
			CFrame.new(center.X + xOffset, signGround + 2.6, center.Z - 13),
			timberColor,
			Enum.Material.Wood,
			parking
		)
	end
	addJapaneseLabel(sign, '駐輪場')
end

local function makeLocomotiveWheel(parent: Instance, name: string, position: Vector3, diameter: number)
	local wheel = makePart(
		'Part',
		name,
		Vector3.new(0.85, diameter, diameter),
		CFrame.new(position) * CFrame.Angles(0, math.pi / 2, 0),
		Color3.fromRGB(130, 37, 31),
		Enum.Material.Metal,
		parent
	)
	wheel.Shape = Enum.PartType.Cylinder
	return wheel
end

local function buildD51Locomotive(root: Model)
	local display = Instance.new('Model')
	display.Name = 'PreservedD51_824Display'
	display:SetAttribute('Prototype', 'JNR Class D51 824')
	display:SetAttribute('StaticExhibit', true)
	display.Parent = root
	local center = Vector3.new(-545, terrainHeight(-545, -82, 3.2) + 0.2, -82)
	local black = Color3.fromRGB(37, 39, 38)

	for sleeper = -4, 4 do
		makePart(
			'Part',
			'RailSleeper',
			Vector3.new(4, 0.4, 10),
			CFrame.new(center + Vector3.new(sleeper * 6, 0, 0)),
			Color3.fromRGB(88, 64, 45),
			Enum.Material.WoodPlanks,
			display
		)
	end
	for _, z in { -3.1, 3.1 } do
		makePart(
			'Part',
			'DisplayRail',
			Vector3.new(58, 0.45, 0.45),
			CFrame.new(center + Vector3.new(0, 0.45, z)),
			Color3.fromRGB(65, 67, 65),
			Enum.Material.Metal,
			display
		)
	end

	local boiler = makePart(
		'Part',
		'SteamBoiler',
		Vector3.new(27, 7, 7),
		CFrame.new(center + Vector3.new(-3, 7.2, 0)),
		black,
		Enum.Material.Metal,
		display
	)
	boiler.Shape = Enum.PartType.Cylinder
	makePart(
		'Part',
		'DriverCab',
		Vector3.new(12, 12, 10),
		CFrame.new(center + Vector3.new(15, 7.3, 0)),
		black,
		Enum.Material.Metal,
		display
	)
	makePart(
		'Part',
		'CabRoof',
		Vector3.new(15, 1, 12),
		CFrame.new(center + Vector3.new(15, 13.8, 0)),
		Color3.fromRGB(27, 29, 28),
		Enum.Material.Metal,
		display
	)
	makePart(
		'Part',
		'FrontPlate',
		Vector3.new(1.2, 8.5, 8.5),
		CFrame.new(center + Vector3.new(-17, 7.1, 0)),
		black,
		Enum.Material.Metal,
		display
	)

	for _, x in { -10, -3.5, 3, 9.5 } do
		for _, z in { -4.2, 4.2 } do
			makeLocomotiveWheel(display, 'DrivingWheel', center + Vector3.new(x, 3.4, z), 6)
		end
	end
	for _, z in { -4.2, 4.2 } do
		makeLocomotiveWheel(display, 'LeadingWheel', center + Vector3.new(-17.5, 2.9, z), 4.5)
	end

	makeCylinder(
		'SmokeStack',
		7.5,
		2.8,
		CFrame.new(center + Vector3.new(-11, 13, 0)),
		black,
		Enum.Material.Metal,
		display
	)
	makeCylinder(
		'SteamDome',
		3,
		3.2,
		CFrame.new(center + Vector3.new(-2, 11.5, 0)),
		black,
		Enum.Material.Metal,
		display
	)
	local headlight = makePart(
		'Part',
		'Headlight',
		Vector3.new(2.6, 2.6, 2.6),
		CFrame.new(center + Vector3.new(-18.2, 9.2, 0)),
		Color3.fromRGB(228, 211, 164),
		Enum.Material.Glass,
		display
	)
	headlight.Shape = Enum.PartType.Ball
	local lamp = Instance.new('PointLight')
	lamp.Brightness = 0.7
	lamp.Color = Color3.fromRGB(255, 224, 170)
	lamp.Range = 15
	lamp.Parent = headlight
	for _, z in { -4.8, 4.8 } do
		makePart(
			'Part',
			'ConnectingRod',
			Vector3.new(27, 0.45, 0.45),
			CFrame.new(center + Vector3.new(0, 3.4, z)),
			Color3.fromRGB(185, 183, 168),
			Enum.Material.Metal,
			display
		)
	end

	for index, offset in
		{
			Vector3.new(-29, 0, -8),
			Vector3.new(29, 0, -8),
			Vector3.new(-29, 0, 8),
			Vector3.new(29, 0, 8),
		}
	do
		makePart(
			'Part',
			`ShelterPost{index}`,
			Vector3.new(1, 17, 1),
			CFrame.new(center + offset + Vector3.new(0, 8.5, 0)),
			Color3.fromRGB(77, 81, 78),
			Enum.Material.Metal,
			display
		)
	end
	makePart(
		'Part',
		'LocomotiveShelterRoof',
		Vector3.new(64, 1, 21),
		CFrame.new(center + Vector3.new(0, 17.3, 0)),
		Color3.fromRGB(73, 78, 75),
		Enum.Material.Slate,
		display
	)
	local sign = makePart(
		'Part',
		'D51Sign',
		Vector3.new(10, 3.6, 0.6),
		CFrame.new(center + Vector3.new(0, 4.5, -11)),
		Color3.fromRGB(225, 215, 188),
		Enum.Material.WoodPlanks,
		display
	)
	addJapaneseLabel(sign, 'D51 824 蒸気機関車')
	display:ScaleTo(1.5)
	groundModelAt(display, center.X, center.Z, 0.05)
	display:SetAttribute('ApproximateLengthStuds', 59)
	display:SetAttribute('ScaleBasis', '5.5-stud avatar')
end

local function makeParkLamp(parent: Instance, index: number, position: Vector3)
	local model = Instance.new('Model')
	model.Name = `MinimalParkLamp{index}`
	model.Parent = parent
	local groundedPosition = Vector3.new(position.X, terrainHeight(position.X, position.Z, position.Y), position.Z)
	makePart(
		'Part',
		'Post',
		Vector3.new(0.55, 9, 0.55),
		CFrame.new(groundedPosition + Vector3.new(0, 4.5, 0)),
		darkMetal,
		Enum.Material.Metal,
		model
	)
	local head = makePart(
		'Part',
		'Lantern',
		Vector3.new(1.7, 2, 1.7),
		CFrame.new(groundedPosition + Vector3.new(0, 9.6, 0)),
		Color3.fromRGB(245, 218, 159),
		Enum.Material.Glass,
		model
	)
	head.CanCollide = false
	local light = Instance.new('PointLight')
	light.Brightness = 1.35
	light.Color = Color3.fromRGB(255, 210, 142)
	light.Range = 24
	light.Shadows = true
	light.Parent = head
end

local function buildParkDetails(root: Model)
	local details = Instance.new('Model')
	details.Name = 'ParkLightsAndInformation'
	details.Parent = root
	for index, position in
		{
			Vector3.new(-620, 0.7, -154),
			Vector3.new(-510, 2.8, -142),
			Vector3.new(-395, 3.0, -129),
			Vector3.new(-275, 2.1, -141),
			Vector3.new(-150, 1.2, -153),
			Vector3.new(-25, 3.5, -126),
			Vector3.new(105, 4.4, -116),
			Vector3.new(235, 3.1, -128),
			Vector3.new(365, 1.8, -145),
			Vector3.new(490, 2.0, -154),
			Vector3.new(625, 0.7, -167),
		}
	do
		makeParkLamp(details, index, position)
	end

	for index, spec in
		{
			{ Vector3.new(-585, 5, -142), 'D51・石彫公園' },
			{ Vector3.new(-235, 5, -132), '諏訪湖畔公園' },
			{ Vector3.new(155, 6, -121), '足湯・休憩所' },
			{ Vector3.new(455, 5, -116), 'トイレ・駐輪場' },
		}
	do
		local requestedPosition = spec[1] :: Vector3
		local ground = terrainHeight(requestedPosition.X, requestedPosition.Z, requestedPosition.Y - 5)
		local position = Vector3.new(requestedPosition.X, ground + 5, requestedPosition.Z)
		local sign = makePart(
			'Part',
			`ParkInformation{index}`,
			Vector3.new(13, 4.4, 0.65),
			CFrame.new(position),
			Color3.fromRGB(218, 205, 174),
			Enum.Material.WoodPlanks,
			details
		)
		makePart(
			'Part',
			'SignPost',
			Vector3.new(0.75, 5.5, 0.75),
			CFrame.new(position.X - 4.7, ground + 2.75, position.Z),
			timberColor,
			Enum.Material.Wood,
			details
		)
		makePart(
			'Part',
			'SignPost',
			Vector3.new(0.75, 5.5, 0.75),
			CFrame.new(position.X + 4.7, ground + 2.75, position.Z),
			timberColor,
			Enum.Material.Wood,
			details
		)
		addJapaneseLabel(sign, spec[2] :: string)
	end
end

local function repositionFishingPiers()
	local activities = workspace:FindFirstChild('LakesideActivities')
	if not activities then
		return
	end
	for _, name in { 'WestFishingPier', 'CentralFishingPier', 'EastFishingPier' } do
		local pier = activities:FindFirstChild(name)
		if pier and pier:IsA('Model') and not pier:GetAttribute('ExpandedParkPosition') then
			pier:PivotTo(pier:GetPivot() + Vector3.new(0, 0, -24))
			pier:SetAttribute('ExpandedParkPosition', true)
		end
	end
end

local function repositionLegacyVenues()
	local openMic = workspace:FindFirstChild('LakesideOpenMic')
	if openMic and openMic:IsA('Model') and not openMic:GetAttribute('ExpandedParkPosition') then
		openMic:PivotTo(openMic:GetPivot() + Vector3.new(0, 0, 68))
		local pivot = openMic:GetPivot()
		groundModelAt(openMic, pivot.X, pivot.Z, 0.04)
		openMic:SetAttribute('ExpandedParkPosition', true)
	end
end

local function applyGoldenHour()
	Lighting.ClockTime = 17.55
	Lighting.Brightness = 2.15
	Lighting.Ambient = Color3.fromRGB(118, 124, 138)
	Lighting.OutdoorAmbient = Color3.fromRGB(164, 157, 147)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.ShadowSoftness = 0.5

	local colorCorrection = Lighting:FindFirstChild('SuwaGoldenHour') or Instance.new('ColorCorrectionEffect')
	colorCorrection.Name = 'SuwaGoldenHour'
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast = 0.07
	colorCorrection.Saturation = -0.03
	colorCorrection.TintColor = Color3.fromRGB(255, 225, 194)
	colorCorrection.Parent = Lighting

	local sunRays = Lighting:FindFirstChild('SuwaSunRays') or Instance.new('SunRaysEffect')
	sunRays.Name = 'SuwaSunRays'
	sunRays.Intensity = 0.045
	sunRays.Spread = 0.72
	sunRays.Parent = Lighting

	local bloom = Lighting:FindFirstChild('SuwaWaterBloom') or Instance.new('BloomEffect')
	bloom.Name = 'SuwaWaterBloom'
	bloom.Intensity = 0.18
	bloom.Size = 28
	bloom.Threshold = 1.85
	bloom.Parent = Lighting
end


-- =========================================================================
-- GRAND CREATOR STORE LAKESIDE PLAYGROUND & AMUSEMENT PARK
-- =========================================================================
local function buildLakesideAmusementPlayground(root: Model)
	local oldPg = root:FindFirstChild("SuwaLakesidePlayground")
	if oldPg then oldPg:Destroy() end

	local playground = Instance.new("Model")
	playground.Name = "SuwaLakesidePlayground"
	playground.Parent = root

	local ss = game:GetService("ServerStorage")
	local csa = ss:FindFirstChild("CreatorStoreAssets")
	local darkMetal = Color3.fromRGB(45, 48, 52)
	local brightRed = Color3.fromRGB(225, 65, 55)
	local brightCyan = Color3.fromRGB(40, 180, 220)
	local baseY = 2.0

	-- -------------------------------------------------------------------------
	-- A. COBBLESTONE PATHWAYS
	-- -------------------------------------------------------------------------
	local px = -310
	makePart("Part", "PlaygroundPathwayMain", Vector3.new(140, 0.3, 12),
		CFrame.new(px, baseY + 0.15, -100),
		Color3.fromRGB(175, 172, 162), Enum.Material.Cobblestone, playground)
	makePart("Part", "PlaygroundPathwayCross1", Vector3.new(12, 0.3, 85),
		CFrame.new(px - 40, baseY + 0.15, -105),
		Color3.fromRGB(175, 172, 162), Enum.Material.Cobblestone, playground)
	makePart("Part", "PlaygroundPathwayCross2", Vector3.new(12, 0.3, 85),
		CFrame.new(px + 40, baseY + 0.15, -105),
		Color3.fromRGB(175, 172, 162), Enum.Material.Cobblestone, playground)

	-- -------------------------------------------------------------------------
	-- B. TORII ENTRANCE GATE
	-- -------------------------------------------------------------------------
	local archX = px
	local archZ = -60
	makePart("Part", "ArchPostL", Vector3.new(1.4, 14, 1.4), CFrame.new(archX - 8, baseY + 7, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)
	makePart("Part", "ArchPostR", Vector3.new(1.4, 14, 1.4), CFrame.new(archX + 8, baseY + 7, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)
	makePart("Part", "ArchBeamTop", Vector3.new(20, 1.4, 1.4), CFrame.new(archX, baseY + 14.5, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)
	makePart("Part", "ArchBeamMid", Vector3.new(18, 1.0, 1.0), CFrame.new(archX, baseY + 12.5, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)

	-- -------------------------------------------------------------------------
	-- C. BIANGLALA (FERRIS WHEEL)
	-- -------------------------------------------------------------------------
	local fwTemplate = csa and csa:FindFirstChild("CreatorStoreFerrisWheel")
	if fwTemplate then
		local fw = fwTemplate:Clone()
		fw.Name = "SuwaFerrisWheel"
		fw.Parent = playground
		local fs = fw:FindFirstChild("FerrisScript", true)
		if fs then fs:Destroy() end
		local _, sz = fw:GetBoundingBox()
		fw:PivotTo(CFrame.new(-230, baseY + sz.Y / 2, -90) * CFrame.Angles(0, math.rad(90), 0))
		for _, d in ipairs(fw:GetDescendants()) do
			if d:IsA("BasePart") then
				local isWheel = d:FindFirstAncestor("Wheel") ~= nil
				local isBasket = d:FindFirstAncestor("Baskets") ~= nil
				d.Anchored = not (isWheel or isBasket)
				if d.Name == "Roof" or d.Name == "Rails" or d.Name == "Seats" then d.CanCollide = false end
			end
		end
		local motor = fw:FindFirstChild("FerrisMotor", true) :: HingeConstraint?
		if motor then
			motor.ActuatorType = Enum.ActuatorType.Motor
			motor.MotorMaxTorque = 100000000
			motor.AngularVelocity = 0.35
		end
	end

	-- -------------------------------------------------------------------------
	-- D. PEROSOTAN LURUS BERSIH (CLEAN STRAIGHT SLIDE)
	-- -------------------------------------------------------------------------
	local slideTemplate = csa and (csa:FindFirstChild("CreatorStoreStraightSlide") or csa:FindFirstChild("CreatorStoreBigSlide") or csa:FindFirstChild("CreatorStoreSlideModel"))
	if slideTemplate then
		local slide = slideTemplate:Clone()
		slide.Name = "SuwaPlaygroundSlideSet"
		slide.Parent = playground
		for _, d in ipairs(slide:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = true
			end
		end
		local _, sz = slide:GetBoundingBox()
		local scaleF = 18.0 / math.max(sz.X, sz.Z)
		slide:ScaleTo(math.clamp(scaleF, 0.4, 1.5))
		local _, sz2 = slide:GetBoundingBox()
		slide:PivotTo(CFrame.new(-380, baseY + sz2.Y / 2, -95) * CFrame.Angles(0, 0, 0))
	end

	-- -------------------------------------------------------------------------
	-- E. AYUNAN BIASA (CLASSIC SWING SET)
	-- -------------------------------------------------------------------------
	local swingTemplate = csa and csa:FindFirstChild("CreatorStoreSwingSet")
	if swingTemplate then
		local swing = swingTemplate:Clone()
		swing.Name = "SuwaSwingSet"
		swing.Parent = playground
		for _, d in ipairs(swing:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Frame" then d.Anchored = true end
		end
		local _, sz = swing:GetBoundingBox()
		swing:PivotTo(CFrame.new(-310, baseY + sz.Y / 2, -135))
	end

	-- -------------------------------------------------------------------------
	-- F. AYUNAN ESTETIK TEMPAT PACARAN (ROMANTIC SAKURA COUPLE SWING - PROPER LAKE-FACING)
	-- -------------------------------------------------------------------------
	local coupleSwingPos = Vector3.new(-270, baseY, -135)

	-- Sakura tree placed directly behind the romantic swing facing the lake (Z = -156)
	local treeTemplate = csa and (csa:FindFirstChild("JapaneseSakuraTreeTemplate") or csa:FindFirstChild("CreatorStoreSakuraTree"))
	if treeTemplate then
		local tree = treeTemplate:Clone()
		tree.Name = "RomanticCoupleSakuraTree"
		tree.Parent = playground
		for _, d in ipairs(tree:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = tree:GetBoundingBox()
		tree:PivotTo(CFrame.new(coupleSwingPos.X, baseY + sz.Y / 2, -156))
	end

	makePart("Part", "RomanticDeck", Vector3.new(18, 0.25, 14),
		CFrame.new(coupleSwingPos.X, baseY + 0.12, coupleSwingPos.Z),
		Color3.fromRGB(185, 180, 172), Enum.Material.Cobblestone, playground)

	local coupleSwingTemplate = csa and csa:FindFirstChild("CreatorStoreRomanticSwing")
	if coupleSwingTemplate then
		local cs = coupleSwingTemplate:Clone()
		cs.Name = "SuwaRomanticCoupleSwing"
		cs.Parent = playground
		for _, d in ipairs(cs:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = cs:GetBoundingBox()
		local scaleF = 9.0 / math.max(sz.X, sz.Z)
		cs:ScaleTo(math.clamp(scaleF, 0.8, 1.3))
		local _, sz2 = cs:GetBoundingBox()
		-- Flipped 270 degrees so the wooden bench faces forward (towards -Z / Lake Suwa)
		cs:PivotTo(CFrame.new(coupleSwingPos.X, baseY + sz2.Y / 2, coupleSwingPos.Z) * CFrame.Angles(0, math.rad(90), 0))

		-- Invisible helper seats with CFrame facing towards the camera / Lake Suwa
		local seatL = Instance.new("Seat")
		seatL.Name = "CoupleSeat_L"
		seatL.Size = Vector3.new(1.8, 0.3, 1.6)
		seatL.CFrame = CFrame.new(coupleSwingPos.X - 1.4, baseY + 1.8, coupleSwingPos.Z) * CFrame.Angles(0, 0, 0)
		seatL.Transparency = 1 ; seatL.CanCollide = false ; seatL.Anchored = true ; seatL.Parent = cs

		local seatR = Instance.new("Seat")
		seatR.Name = "CoupleSeat_R"
		seatR.Size = Vector3.new(1.8, 0.3, 1.6)
		seatR.CFrame = CFrame.new(coupleSwingPos.X + 1.4, baseY + 1.8, coupleSwingPos.Z) * CFrame.Angles(0, 0, 0)
		seatR.Transparency = 1 ; seatR.CanCollide = false ; seatR.Anchored = true ; seatR.Parent = cs
	end

	-- -------------------------------------------------------------------------
	-- G. DUA SUPER TRAMPOLIN (TWIN HIGH JUMP TRAMPOLINES ON LAWN)
	-- -------------------------------------------------------------------------
	local tramTemplate = csa and (csa:FindFirstChild("CreatorStoreHighJumpTrampoline") or csa:FindFirstChild("CreatorStoreRoundTrampoline"))
	if tramTemplate then
		local tramPositions = {
			Vector3.new(-265, baseY, -70),
			Vector3.new(-295, baseY, -70),
		}
		for idx, pos in ipairs(tramPositions) do
			local tram = tramTemplate:Clone()
			tram.Name = `SuwaTrampoline_{idx}`
			tram.Parent = playground
			for _, d in ipairs(tram:GetDescendants()) do
				if d:IsA("BasePart") then d.Anchored = true end
			end
			local _, sz = tram:GetBoundingBox()
			local scaleF = 17 / math.max(sz.X, sz.Z)
			tram:ScaleTo(math.clamp(scaleF, 0.5, 1.2))
			local _, sz2 = tram:GetBoundingBox()
			tram:PivotTo(CFrame.new(pos.X, baseY + sz2.Y / 2, pos.Z))

			local pad = Instance.new("Part")
			pad.Name = "TrampolineBouncePad"
			pad.Size = Vector3.new(17.0, 2.5, 17.0)
			pad.CFrame = CFrame.new(pos.X, baseY + sz2.Y + 0.8, pos.Z)
			pad.Transparency = 1 ; pad.CanCollide = false ; pad.CanTouch = true ; pad.Anchored = true ; pad.Parent = tram
		end
	end

	-- -------------------------------------------------------------------------
	-- H. TANGGA MONYET MERAH (MONKEY BARS - SHIFTED TO THE LEFT)
	-- -------------------------------------------------------------------------
	local mbTemplate = csa and csa:FindFirstChild("CreatorStoreMonkeyBars")
	if mbTemplate then
		local mb = mbTemplate:Clone()
		mb.Name = "SuwaMonkeyBars"
		mb.Parent = playground
		for _, d in ipairs(mb:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = mb:GetBoundingBox()
		mb:PivotTo(CFrame.new(-375, baseY + sz.Y / 2, -135))
	end

	-- -------------------------------------------------------------------------
	-- I. SPOT FOTO ESTETIK: 5 KUDA PEGAS DENGAN POHON SAKURA MEKAR DI BELAKANGNYA
	-- -------------------------------------------------------------------------
	local sakuraSpot = Vector3.new(-345, baseY, -135)

	local treeSpot = csa and (csa:FindFirstChild("JapaneseSakuraTreeTemplate") or csa:FindFirstChild("CreatorStoreSakuraTree"))
	if treeSpot then
		local tree = treeSpot:Clone()
		tree.Name = "PhotoSpotSakuraTree"
		tree.Parent = playground
		for _, d in ipairs(tree:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = tree:GetBoundingBox()
		tree:PivotTo(CFrame.new(sakuraSpot.X, baseY + sz.Y / 2, -156))
	end

	makePart("Part", "PhotoSpotPad", Vector3.new(26, 0.25, 12),
		CFrame.new(sakuraSpot.X, baseY + 0.12, sakuraSpot.Z),
		Color3.fromRGB(180, 176, 168), Enum.Material.Cobblestone, playground)

	local springTemplate = csa and csa:FindFirstChild("CreatorStoreSpringRiders")
	if springTemplate then
		local sp = springTemplate:Clone()
		sp.Name = "SuwaSpringRiders"
		sp.Parent = playground
		local _, sz = sp:GetBoundingBox()
		sp:PivotTo(CFrame.new(sakuraSpot + Vector3.new(0, sz.Y / 2, 0)) * CFrame.Angles(0, math.rad(0), 0))

		for _, rider in ipairs(sp:GetDescendants()) do
			if rider:IsA("Model") and (rider.Name:find("Happy") or rider.Name:find("Rider")) then
				local base = rider:FindFirstChild("Base") :: BasePart?
				local seat = (rider:FindFirstChildWhichIsA("VehicleSeat") or rider:FindFirstChildWhichIsA("Seat")) :: BasePart?
				if base and seat then
					base.Anchored = true
					seat.Anchored = true
					for _, d in ipairs(rider:GetDescendants()) do
						if d:IsA("BasePart") and d ~= base and d ~= seat then
							d.Anchored = false
							local w = Instance.new("WeldConstraint")
							w.Part0 = seat
							w.Part1 = d
							w.Parent = seat
						end
					end
				end
			end
		end
	end

	-- -------------------------------------------------------------------------
	-- J. MEJA PANCO (ARM WRESTLING TABLE)
	-- -------------------------------------------------------------------------
	local armCenter = Vector3.new(-310, baseY, -75)
	local armModel = Instance.new("Model")
	armModel.Name = "SuwaArmWrestlingArena"
	armModel.Parent = playground
	makePart("Part", "TableLegCenter", Vector3.new(2, 3.6, 2), CFrame.new(armCenter + Vector3.new(0, 1.8, 0)), darkMetal, Enum.Material.Metal, armModel)
	makePart("Part", "TableTop", Vector3.new(6.4, 0.6, 4.4), CFrame.new(armCenter + Vector3.new(0, 3.8, 0)), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic, armModel)
	makePart("Part", "ElbowPadRed", Vector3.new(1.4, 0.3, 1.4), CFrame.new(armCenter + Vector3.new(-1.6, 4.2, 0)), brightRed, Enum.Material.Fabric, armModel)
	makePart("Part", "ElbowPadBlue", Vector3.new(1.4, 0.3, 1.4), CFrame.new(armCenter + Vector3.new(1.6, 4.2, 0)), brightCyan, Enum.Material.Fabric, armModel)
	makePart("Part", "GripPegL", Vector3.new(0.3, 1.4, 0.3), CFrame.new(armCenter + Vector3.new(-2.6, 4.6, 1.5)), Color3.fromRGB(220, 220, 220), Enum.Material.Metal, armModel)
	makePart("Part", "GripPegR", Vector3.new(0.3, 1.4, 0.3), CFrame.new(armCenter + Vector3.new(2.6, 4.6, -1.5)), Color3.fromRGB(220, 220, 220), Enum.Material.Metal, armModel)
	makeSeat("ArmSeat_Red", Vector3.new(2, 0.4, 2), CFrame.new(armCenter + Vector3.new(-3.4, 2.2, 0)) * CFrame.Angles(0, math.rad(-90), 0), brightRed, Enum.Material.SmoothPlastic, armModel)
	makeSeat("ArmSeat_Blue", Vector3.new(2, 0.4, 2), CFrame.new(armCenter + Vector3.new(3.4, 2.2, 0)) * CFrame.Angles(0, math.rad(90), 0), brightCyan, Enum.Material.SmoothPlastic, armModel)
	makePart("Part", "StoolLegRed", Vector3.new(0.5, 2.2, 0.5), CFrame.new(armCenter + Vector3.new(-3.4, 1.1, 0)), darkMetal, Enum.Material.Metal, armModel)
	makePart("Part", "StoolLegBlue", Vector3.new(0.5, 2.2, 0.5), CFrame.new(armCenter + Vector3.new(3.4, 1.1, 0)), darkMetal, Enum.Material.Metal, armModel)
end

local function buildPark()
	local previous = workspace:FindFirstChild("SuwaLakesidePark")
	if previous then
		previous:Destroy()
	end
	removeGreybox()

	local root = Instance.new("Model")
	root.Name = "SuwaLakesidePark"
	root:SetAttribute("ReferenceBasis", "Suwa Lakeside Park photo set")
	root:SetAttribute("NoSkyscrapers", true)
	root:SetAttribute("ParkWidthStuds", 1340)
	root:SetAttribute("ParkDepthStuds", 260)
	root.Parent = workspace

	buildBenches(root)
	buildNaturalShore(root)
	buildTerracedLawn(root)
	buildCurvedGravelPlaza(root)
	buildFitnessCorner(root)
	buildTraditionalShelter(root)
	buildFootbathCanopy(root)
	buildDuckBoatDock(root)
	buildPublicToilet(root)
	buildBicycleParking(root)
	buildD51Locomotive(root)
	buildParkDetails(root)
	buildLakesideAmusementPlayground(root)
	repositionFishingPiers()
	repositionLegacyVenues()
	applyGoldenHour()
end

function LakesideParkService.init()
	buildPark()
end

return LakesideParkService
