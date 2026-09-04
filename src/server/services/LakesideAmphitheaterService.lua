--!strict

-- The lakeside amphitheatre: a round stage set into a stepped bowl on the Suwa
-- waterfront, following the reference photos of the real park -- the low stage
-- at the water's edge with the lake as its backdrop, the terraced mound rising
-- behind it, and the twin-lamp gate straddling the ramp down into it.
--
-- Precision-engineered geometry:
--   1. Continuous, gapless concrete tiers with section-based arc cuts for aisles.
--   2. Solid, flush aisle staircases with side cheek walls (zero holes/cavities).
--   3. 100% functional Seats across all 4 tiers (every bench position is sittable).
--   4. Smooth Roblox Terrain earthwork berm with no artificial plastic grass blocks.
--   5. Gapless cobblestone bypass path that terminates inside the main trail band.

local Workspace = game:GetService('Workspace')

local LakesideAmphitheaterService = {}

local MODEL_NAME = 'LakesideAmphitheater'

local CENTER_X, CENTER_Z = 80, -172
local GROUND_Y = 2

local STAGE_RADIUS = 15
local APRON_RADIUS = 22
local TIER_COUNT = 4
local TIER_DEPTH = 7
local TIER_RISE = 2

-- Seating wraps the landward side only (18 degrees past 0 to 18 degrees past 180).
local ARC_START, ARC_END = -18, 198

-- Radial staircases cut through the rings at fixed angles
local AISLE_ANGLES = { 45, 90, 135 }
local AISLE_HALF_WIDTH = 4.0 -- degrees on each side
local STEPS_PER_TIER = 4

local CONCRETE = Color3.fromRGB(178, 174, 164)
local CONCRETE_DARK = Color3.fromRGB(140, 137, 129)
local PLAZA = Color3.fromRGB(196, 192, 182)
local TIMBER = Color3.fromRGB(122, 84, 52)
local BENCH = Color3.fromRGB(158, 152, 142)
local STEEL = Color3.fromRGB(46, 48, 52)

local function makePart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new('Part')
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function groundAt(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	local list = { Workspace.Terrain }
	local central = Workspace:FindFirstChild('SuwaCentral')
	if central then
		for _, name in ipairs({ 'CityGround', 'WestLakesideParkLawn', 'SekichoInspiredLawn' }) do
			local part = central:FindFirstChild(name)
			if part then
				table.insert(list, part)
			end
		end
	end
	parameters.FilterDescendantsInstances = list
	parameters.IgnoreWater = true
	local result = Workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -260, 0), parameters)
	return if result then result.Position.Y else fallback
end

-- Generates the 4 discrete continuous arc sections between the 3 aisles
local function getSeatingSections(): { { fromDeg: number, toDeg: number } }
	local sections = {}
	local prevAngle = ARC_START
	for _, aisleAngle in ipairs(AISLE_ANGLES) do
		table.insert(sections, {
			fromDeg = prevAngle,
			toDeg = aisleAngle - AISLE_HALF_WIDTH,
		})
		prevAngle = aisleAngle + AISLE_HALF_WIDTH
	end
	table.insert(sections, {
		fromDeg = prevAngle,
		toDeg = ARC_END,
	})
	return sections
end

-- Builds gapless seating tier rings with exact aisle boundaries
local function buildTiers(parent: Instance)
	local sections = getSeatingSections()

	for tier = 1, TIER_COUNT do
		local innerRadius = APRON_RADIUS + (tier - 1) * TIER_DEPTH
		local outerRadius = innerRadius + TIER_DEPTH
		local midRadius = (innerRadius + outerRadius) / 2
		local topY = GROUND_Y + tier * TIER_RISE
		local height = topY - (GROUND_Y - 4)
		local tierColor = if tier % 2 == 0 then CONCRETE_DARK else CONCRETE

		for _, sec in ipairs(sections) do
			local arcSpan = sec.toDeg - sec.fromDeg
			local segCount = math.max(3, math.ceil(arcSpan / 2.5))
			local step = arcSpan / segCount

			for i = 0, segCount - 1 do
				local deg = sec.fromDeg + (i + 0.5) * step
				local rad = math.rad(deg)
				local chord = 2 * (outerRadius + 0.3) * math.sin(math.rad(step) / 2) + 0.35
				makePart(
					'SeatingTier' .. tier,
					Vector3.new(TIER_DEPTH + 0.3, height, chord),
					CFrame.new(
						CENTER_X + math.cos(rad) * midRadius,
						topY - height / 2,
						CENTER_Z + math.sin(rad) * midRadius
					) * CFrame.Angles(0, -rad, 0),
					tierColor,
					Enum.Material.Concrete,
					parent
				)
			end
		end
	end
end

-- Builds radial aisle stairs with side cheek walls to guarantee 0 holes
local function buildAisleStairs(parent: Instance)
	for _, angle in ipairs(AISLE_ANGLES) do
		local rad = math.rad(angle)

		for tier = 1, TIER_COUNT do
			local innerRadius = APRON_RADIUS + (tier - 1) * TIER_DEPTH
			local baseY = GROUND_Y + (tier - 1) * TIER_RISE
			local run = TIER_DEPTH / STEPS_PER_TIER
			local stepRise = TIER_RISE / STEPS_PER_TIER

			for stepIndex = 1, STEPS_PER_TIER do
				local radius = innerRadius + (stepIndex - 0.5) * run
				local topY = baseY + stepIndex * stepRise
				local height = topY - (GROUND_Y - 4)
				-- Chord across the full aisle at this radius; the extra 0.3 deg tucks
				-- the tread edge under the cheek walls instead of into the seating.
				local stepWidth = 2 * (radius + run / 2) * math.sin(math.rad(AISLE_HALF_WIDTH + 0.3)) + 0.15

				makePart(
					'AisleStep',
					Vector3.new(run + 0.25, height, stepWidth),
					CFrame.new(
						CENTER_X + math.cos(rad) * radius,
						topY - height / 2,
						CENTER_Z + math.sin(rad) * radius
					) * CFrame.Angles(0, -rad, 0),
					CONCRETE_DARK,
					Enum.Material.Concrete,
					parent
				)
			end
		end

		-- Solid side cheek walls bordering each aisle staircase
		for _, side in ipairs({ -1, 1 }) do
			local wallAngle = angle + side * AISLE_HALF_WIDTH
			local wallRad = math.rad(wallAngle)
			for tier = 1, TIER_COUNT do
				local rMin = APRON_RADIUS + (tier - 1) * TIER_DEPTH
				local rMax = rMin + TIER_DEPTH
				local rMid = (rMin + rMax) / 2
				local topY = GROUND_Y + tier * TIER_RISE + 0.1
				local height = topY - (GROUND_Y - 4)
				makePart(
					'AisleCheekWall',
					Vector3.new(TIER_DEPTH + 0.2, height, 0.6),
					CFrame.new(
						CENTER_X + math.cos(wallRad) * rMid,
						topY - height / 2,
						CENTER_Z + math.sin(wallRad) * rMid
					) * CFrame.Angles(0, -wallRad, 0),
					CONCRETE_DARK,
					Enum.Material.Concrete,
					parent
				)
			end
		end
	end
end

local function buildStage(parent: Instance)
	local apron = makePart(
		'StageApron',
		Vector3.new(0.6, APRON_RADIUS * 2, APRON_RADIUS * 2),
		CFrame.new(CENTER_X, GROUND_Y + 0.3, CENTER_Z) * CFrame.Angles(0, 0, math.rad(90)),
		CONCRETE,
		Enum.Material.Concrete,
		parent
	)
	apron.Shape = Enum.PartType.Cylinder

	local platform = makePart(
		'StagePlaza',
		Vector3.new(0.9, STAGE_RADIUS * 2, STAGE_RADIUS * 2),
		CFrame.new(CENTER_X, GROUND_Y + 0.75, CENTER_Z) * CFrame.Angles(0, 0, math.rad(90)),
		PLAZA,
		Enum.Material.Concrete,
		parent
	)
	platform.Shape = Enum.PartType.Cylinder

	makePart(
		'StageDeck',
		Vector3.new(17, 1.4, 9),
		CFrame.new(CENTER_X, GROUND_Y + 1.9, CENTER_Z - 7),
		TIMBER,
		Enum.Material.WoodPlanks,
		parent
	)
	for _, side in ipairs({ -1, 1 }) do
		makePart(
			'StageDeckStep',
			Vector3.new(5, 0.7, 2.4),
			CFrame.new(CENTER_X + side * 5, GROUND_Y + 1.55, CENTER_Z - 1.6),
			TIMBER,
			Enum.Material.WoodPlanks,
			parent
		)
	end

	local bannerZ = CENTER_Z - 17
	for _, side in ipairs({ -1, 1 }) do
		makePart(
			'BannerPost',
			Vector3.new(0.8, 11, 0.8),
			CFrame.new(CENTER_X + side * 11, GROUND_Y + 5.5, bannerZ),
			STEEL,
			Enum.Material.Metal,
			parent
		)
	end
	local banner = makePart(
		'BannerPanel',
		Vector3.new(22, 3.4, 0.3),
		CFrame.new(CENTER_X, GROUND_Y + 9.4, bannerZ),
		Color3.fromRGB(28, 96, 158),
		Enum.Material.SmoothPlastic,
		parent
	)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local surface = Instance.new('SurfaceGui')
		surface.Face = face
		surface.CanvasSize = Vector2.new(880, 136)
		surface.Parent = banner
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = '諏訪湖音楽の夕べ'
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(255, 240, 170)
		label.Parent = surface
	end

	for _, side in ipairs({ -1, 1 }) do
		local mastX = CENTER_X + side * 19
		local mastZ = CENTER_Z - 8
		makePart(
			'LightMast',
			Vector3.new(0.7, 15, 0.7),
			CFrame.new(mastX, GROUND_Y + 7.5, mastZ),
			STEEL,
			Enum.Material.Metal,
			parent
		)
		local head = makePart(
			'LightHead',
			Vector3.new(2.2, 1.8, 2.6),
			CFrame.new(mastX, GROUND_Y + 14.4, mastZ),
			STEEL,
			Enum.Material.Metal,
			parent
		)
		local spot = Instance.new('SpotLight')
		spot.Range = 42
		spot.Angle = 70
		spot.Brightness = 1.6
		spot.Color = Color3.fromRGB(255, 246, 214)
		spot.Face = Enum.NormalId.Back
		spot.Parent = head
	end
end

local GATE_ANGLES = { 12, 168 }

local function buildEntranceGate(parent: Instance)
	local gateRadius = APRON_RADIUS + TIER_COUNT * TIER_DEPTH + 6
	local bermTopY = GROUND_Y + TIER_COUNT * TIER_RISE - 2.8 + 0.1

	for _, angle in ipairs(GATE_ANGLES) do
		local radians = math.rad(angle)
		local gateX = CENTER_X + math.cos(radians) * gateRadius
		local gateZ = CENTER_Z + math.sin(radians) * gateRadius
		local baseY = bermTopY
		local facing = CFrame.lookAt(
			Vector3.new(gateX, baseY, gateZ),
			Vector3.new(CENTER_X, baseY, CENTER_Z)
		)

		for _, side in ipairs({ -1, 1 }) do
			makePart(
				'GateLeg',
				Vector3.new(1.6, 13, 1.6),
				facing * CFrame.new(side * 5.2, 6.2, 0) * CFrame.Angles(0, 0, math.rad(side * 11)),
				STEEL,
				Enum.Material.Metal,
				parent
			)
		end

		makePart(
			'GateSlab',
			Vector3.new(4.4, 10, 1.2),
			facing * CFrame.new(0, 16.6, 0),
			Color3.fromRGB(226, 224, 216),
			Enum.Material.SmoothPlastic,
			parent
		)
		makePart(
			'GateCollar',
			Vector3.new(6.6, 1.6, 2.0),
			facing * CFrame.new(0, 11.8, 0),
			STEEL,
			Enum.Material.Metal,
			parent
		)

		for _, side in ipairs({ -1, 1 }) do
			local head = makePart(
				'GateLamp',
				Vector3.new(2.4, 2.4, 2.4),
				facing * CFrame.new(side * 4.0, 19.6, 0),
				STEEL,
				Enum.Material.Metal,
				parent
			)
			local light = Instance.new('SpotLight')
			light.Range = 34
			light.Angle = 80
			light.Brightness = 1.2
			light.Face = Enum.NormalId.Front
			light.Color = Color3.fromRGB(255, 238, 200)
			light.Parent = head
		end
	end
end

-- Builds 100% functional Seats across all tiers
local function buildSeating(parent: Instance)
	local benches = Instance.new('Model')
	benches.Name = 'AmphitheaterBenches'
	benches.Parent = parent

	local sections = getSeatingSections()

	for tier = 1, TIER_COUNT do
		local radius = APRON_RADIUS + (tier - 1) * TIER_DEPTH + TIER_DEPTH * 0.72
		local seatTop = GROUND_Y + tier * TIER_RISE + 1.25

		for _, sec in ipairs(sections) do
			local arcSpan = sec.toDeg - sec.fromDeg
			local seatCount = math.max(2, math.ceil(arcSpan / 3.2))
			local step = arcSpan / seatCount

			for i = 0, seatCount - 1 do
				local deg = sec.fromDeg + (i + 0.5) * step
				local rad = math.rad(deg)
				local chord = 2 * radius * math.sin(math.rad(step) / 2) + 0.05
				local seatPos = Vector3.new(
					CENTER_X + math.cos(rad) * radius,
					seatTop - 0.6,
					CENTER_Z + math.sin(rad) * radius
				)

				local seat = Instance.new('Seat')
				seat.Name = 'TerraceSeat'
				seat.Size = Vector3.new(chord, 1.2, 2.2)
				seat.CFrame = CFrame.lookAt(
					seatPos,
					Vector3.new(CENTER_X, seatPos.Y, CENTER_Z)
				)
				seat.Color = BENCH
				seat.Material = Enum.Material.Concrete
				seat.Anchored = true
				seat.TopSurface = Enum.SurfaceType.Smooth
				seat.BottomSurface = Enum.SurfaceType.Smooth
				seat.Parent = benches
			end
		end
	end
end

-- Builds gapless bypass cobblestone pathway and clean approach stairs
local function buildApproach(parent: Instance, park: Model)
	local network = park:FindFirstChild('SuwaCobblestonePathwayNetwork')
	local trail = network and network:FindFirstChild('LakesideTrail_Main', true)
	if not trail or not trail:IsA('BasePart') then
		return
	end

	local approach = Instance.new('Model')
	approach.Name = 'BowlApproach'
	approach.Parent = parent

	local trailY = trail.Position.Y + 0.02
	-- Match the main trail exactly so the merge has no lip and no wider ledge.
	local width = trail.Size.Z
	local colour, material = trail.Color, trail.Material

	local radius = 64

	-- End the arc where it crosses the main trail, plus a short tuck so the end
	-- caps finish underneath the trail band instead of dangling past it. No
	-- separate join or fillet parts: those overlapped the trail at an identical
	-- Y, which is what produced the z-fighting patches and the square blob.
	local crossing = math.deg(math.asin(math.clamp((trail.Position.Z - CENTER_Z) / radius, -1, 1)))
	local tuck = math.deg((width * 0.35) / radius)
	local fromDeg, toDeg = crossing - tuck, 180 - crossing + tuck

	local segments = math.max(24, math.ceil((toDeg - fromDeg) / 1.8))
	local step = (toDeg - fromDeg) / segments

	-- Gapless curved bypass trail around the outer mound
	for index = 0, segments - 1 do
		local degrees = fromDeg + (index + 0.5) * step
		local radians = math.rad(degrees)
		-- Slight overlap (+0.3) closes the seams without visible corner flare
		local chord = 2 * (radius + width / 2) * math.sin(math.rad(step) / 2) + 0.3
		makePart(
			'BypassPath',
			Vector3.new(width, 0.25, chord),
			CFrame.new(
				CENTER_X + math.cos(radians) * radius,
				trailY,
				CENTER_Z + math.sin(radians) * radius
			) * CFrame.Angles(0, -radians, 0),
			colour,
			material,
			approach
		)
	end

	-- Radial approach steps over the rim into the middle aisle (angle = 90 deg)
	local stepCount = 7
	local rStart, rEnd = 63.5, 49.5
	local yStart, yEnd = 6.07, 10.0
	for i = 1, stepCount do
		local t = (i - 0.5) / stepCount
		local r = rStart + (rEnd - rStart) * t
		local y = yStart + (yEnd - yStart) * t
		local stepDepth = math.abs(rEnd - rStart) / stepCount + 0.6
		makePart(
			'ApproachStep',
			Vector3.new(6.4, 1.8, stepDepth),
			CFrame.new(CENTER_X, y - 0.9, CENTER_Z + r),
			CONCRETE,
			Enum.Material.Concrete,
			approach
		)
		for _, side in ipairs({ -1, 1 }) do
			makePart(
				'ApproachCurb',
				Vector3.new(0.9, 2.4, stepDepth),
				CFrame.new(CENTER_X + side * 3.6, y - 0.6, CENTER_Z + r),
				CONCRETE_DARK,
				Enum.Material.Concrete,
				approach
			)
		end
	end
end

-- Carves the bowl and sculpts the smooth earthen terrain berm
local function sculptAmphitheaterTerrain()
	local terrain = Workspace.Terrain
	local carveHeight = 80
	local MARGIN = 1

	-- Excavate stepped basin
	for tier = TIER_COUNT, 1, -1 do
		local bandFloor = GROUND_Y + (tier - 1) * TIER_RISE - MARGIN
		terrain:FillCylinder(
			CFrame.new(CENTER_X, bandFloor + carveHeight / 2, CENTER_Z),
			carveHeight,
			APRON_RADIUS + tier * TIER_DEPTH,
			Enum.Material.Air
		)
	end

	terrain:FillCylinder(
		CFrame.new(CENTER_X, GROUND_Y - MARGIN + carveHeight / 2, CENTER_Z),
		carveHeight,
		APRON_RADIUS + 1,
		Enum.Material.Air
	)

	-- Sculpt smooth terrain grass berm around the outer rim of the amphitheater
	local bermOuter = APRON_RADIUS + TIER_COUNT * TIER_DEPTH + 14 -- radius 64
	for deg = -20, 200, 4 do
		local rad = math.rad(deg)
		for r = APRON_RADIUS + TIER_COUNT * TIER_DEPTH, bermOuter, 3 do
			local t = (r - (APRON_RADIUS + TIER_COUNT * TIER_DEPTH)) / 14
			local bermY = (1 - t) * (GROUND_Y + TIER_COUNT * TIER_RISE - 0.2) + t * 6.0
			local pt = Vector3.new(CENTER_X + math.cos(rad) * r, bermY - 1.5, CENTER_Z + math.sin(rad) * r)
			terrain:FillBall(pt, 3.8, Enum.Material.Grass)
		end
	end
end

local function buildAmphitheater(park: Model): Model
	local model = Instance.new('Model')
	model.Name = MODEL_NAME
	model.Parent = park

	sculptAmphitheaterTerrain()
	buildStage(model)
	buildTiers(model)
	buildAisleStairs(model)
	buildEntranceGate(model)
	buildSeating(model)
	buildApproach(model, park)

	return model
end

local function moveModel(model: Model, targetX: number, targetZ: number)
	local pivot = model:GetPivot()
	local fromGround = groundAt(pivot.Position.X, pivot.Position.Z, pivot.Position.Y)
	local toGround = groundAt(targetX, targetZ, fromGround)
	model:PivotTo(
		pivot + Vector3.new(targetX - pivot.Position.X, toGround - fromGround, targetZ - pivot.Position.Z)
	)
end

local function clearBowlFootprint(park: Model)
	local clearRadius = APRON_RADIUS + TIER_COUNT * TIER_DEPTH + 12
	local shifted = 0

	local groups = {
		{ park:FindFirstChild('LakeFacingBenches'), 34 },
		{ park:FindFirstChild('SakuraGardenLanterns'), 30 },
		{ park:FindFirstChild('NaturalShorelineDetails'), 46 },
	}

	for _, entry in ipairs(groups) do
		local folder = entry[1] :: Instance?
		local sidestep = entry[2] :: number
		if folder then
			for _, item in ipairs(folder:GetChildren()) do
				if item:IsA('Model') then
					local position = item:GetPivot().Position
					local dx, dz = position.X - CENTER_X, position.Z - CENTER_Z
					if math.sqrt(dx * dx + dz * dz) < clearRadius then
						local direction = if dx >= 0 then 1 else -1
						shifted += 1
						moveModel(item, CENTER_X + direction * (clearRadius + sidestep), position.Z)
					end
				end
			end
		end
	end

	return shifted
end

function LakesideAmphitheaterService.build(): string
	local park = Workspace:FindFirstChild('SuwaLakesidePark')
	if not park or not park:IsA('Model') then
		return '[Amphitheater] SuwaLakesidePark missing; nothing built.'
	end

	if park:FindFirstChild(MODEL_NAME) then
		return '[Amphitheater] Already present; left as authored.'
	end

	local shifted = 0
	if not park:GetAttribute('AmphitheaterSpaceCleared') then
		shifted = clearBowlFootprint(park)

		local ashiyu = park:FindFirstChild('AshiyuCanopy')
		if ashiyu and ashiyu:IsA('Model') then
			local toGround = groundAt(230, -95, 6)
			ashiyu:PivotTo(CFrame.new(230, toGround + 7.525, -95))
		end
		local shelter = park:FindFirstChild('TraditionalRestShelter')
		if shelter and shelter:IsA('Model') then
			moveModel(shelter, -60, -95)
		end

		local network = park:FindFirstChild('SuwaCobblestonePathwayNetwork')
		if network then
			local branchAshiyu = network:FindFirstChild('BranchAshiyu')
			if branchAshiyu and branchAshiyu:IsA('BasePart') then
				local toGround = groundAt(230, -114, 6)
				branchAshiyu.CFrame = CFrame.new(230, toGround + branchAshiyu.Size.Y / 2, -114)
			end

			local branchShelter = network:FindFirstChild('BranchRestShelter')
			if branchShelter and branchShelter:IsA('BasePart') then
				local toGround = groundAt(-60, -114, 6)
				branchShelter.Size = Vector3.new(8, branchShelter.Size.Y, 20)
				branchShelter.CFrame = CFrame.new(-60, toGround + branchShelter.Size.Y / 2, -114)
			end
		end

		local infoFolder = park:FindFirstChild('ParkLightsAndInformation')
		if infoFolder then
			local info3 = infoFolder:FindFirstChild('ParkInformation3')
			if info3 and info3:IsA('BasePart') then
				info3.CFrame = CFrame.new(230, 7.7, -54)
				local gui = info3:FindFirstChildWhichIsA('SurfaceGui')
				local label = gui and gui:FindFirstChildWhichIsA('TextLabel')
				if label then
					label.Text = '諏訪湖畔 足湯'
				end
			end
			local shelterSign = infoFolder:FindFirstChild('ParkInformation_Shelter')
			if shelterSign and shelterSign:IsA('BasePart') then
				shelterSign.CFrame = CFrame.new(-60, 7.7, -54)
			end
		end

		park:SetAttribute('AmphitheaterSpaceCleared', true)
	end

	local model = buildAmphitheater(park)
	local count = 0
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA('BasePart') then
			count += 1
		end
	end
	return `[Amphitheater] Lakeside stage bowl built ({count} parts, {shifted} park pieces moved clear).`
end

function LakesideAmphitheaterService.init()
	task.defer(function()
		print(LakesideAmphitheaterService.build())
	end)
end

return LakesideAmphitheaterService
