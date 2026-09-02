--!strict

-- The lakeside amphitheatre: a round stage set into a stepped bowl on the Suwa
-- waterfront, following the reference photos of the real park -- the low stage
-- at the water's edge with the lake as its backdrop, the terraced mound rising
-- behind it, and the twin-lamp gate straddling the ramp down into it.
--
-- Why a separate service rather than an addition to LakesideParkService: that
-- generator opens with `if previous then return previous end`, and the park in
-- this place is authored rather than generated, so its builders never run. A
-- self-contained, idempotent service adds the bowl on every start without
-- regenerating -- or risking -- everything else already standing in the park.
--
-- Siting: the terrain here already steps from Y=2 at the shore to Y=6 at the
-- promenade, so seating that climbs away from the water rides the slope that is
-- there instead of fighting it. Measured before building: z=-160..-190 sits at
-- Y=2, z=-100..-140 at Y=6, and open water begins around z=-195.

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
local SEGMENTS = 34

-- Seating wraps the landward side only. The lake side stays open so the water
-- and the sunset are the backdrop, exactly as the real stage is set.
local ARC_START, ARC_END = -18, 198

-- Radial staircases cut through the rings so people can walk down to the floor
-- instead of hopping the rows.
local AISLE_ANGLES = { 45, 90, 135 }
local AISLE_HALF_WIDTH = 5
local STEPS_PER_TIER = 4

local CONCRETE = Color3.fromRGB(178, 174, 164)
local CONCRETE_DARK = Color3.fromRGB(140, 137, 129)
-- Street View of the real bowl: the floor is pale concrete and the stage is a
-- raised timber deck at the water's edge, not a dark disc in the middle.
local PLAZA = Color3.fromRGB(196, 192, 182)
local TIMBER = Color3.fromRGB(122, 84, 52)
local BENCH = Color3.fromRGB(158, 152, 142)
local STEEL = Color3.fromRGB(46, 48, 52)
local GRASS = Color3.fromRGB(106, 138, 74)

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

local function isAisle(degrees: number): boolean
	for _, angle in ipairs(AISLE_ANGLES) do
		if math.abs(degrees - angle) <= AISLE_HALF_WIDTH then
			return true
		end
	end
	return false
end

-- A ring is drawn as a fan of boxes turned to face the centre. Each one is
-- built down to well below ground rather than sitting at its own height, so the
-- bowl reads as a solid earthwork and never floats over the slope beneath it.
local function buildRing(
	parent: Instance,
	name: string,
	innerRadius: number,
	depth: number,
	topY: number,
	color: Color3,
	material: Enum.Material,
	skipAisles: boolean
)
	local midRadius = innerRadius + depth / 2
	local step = (ARC_END - ARC_START) / SEGMENTS
	for index = 0, SEGMENTS - 1 do
		local degrees = ARC_START + (index + 0.5) * step
		if not (skipAisles and isAisle(degrees)) then
			local radians = math.rad(degrees)
			local height = topY - (GROUND_Y - 6)
			local chord = 2 * midRadius * math.sin(math.rad(step) / 2) + 0.6
			makePart(
				name,
				Vector3.new(depth + 0.4, height, chord),
				CFrame.new(
					CENTER_X + math.cos(radians) * midRadius,
					topY - height / 2,
					CENTER_Z + math.sin(radians) * midRadius
				) * CFrame.Angles(0, -radians, 0),
				color,
				material,
				parent
			)
		end
	end
end

local function buildAisleStairs(parent: Instance)
	for _, angle in ipairs(AISLE_ANGLES) do
		local radians = math.rad(angle)
		for tier = 1, TIER_COUNT do
			local innerRadius = APRON_RADIUS + (tier - 1) * TIER_DEPTH
			local baseY = GROUND_Y + (tier - 1) * TIER_RISE
			for stepIndex = 1, STEPS_PER_TIER do
				local run = TIER_DEPTH / STEPS_PER_TIER
				local radius = innerRadius + (stepIndex - 0.5) * run
				local topY = baseY + stepIndex * (TIER_RISE / STEPS_PER_TIER)
				local height = topY - (GROUND_Y - 6)
				local width = 2 * radius * math.sin(math.rad(AISLE_HALF_WIDTH)) * 2
				makePart(
					'AisleStep',
					Vector3.new(run + 0.3, height, width),
					CFrame.new(
						CENTER_X + math.cos(radians) * radius,
						topY - height / 2,
						CENTER_Z + math.sin(radians) * radius
					) * CFrame.Angles(0, -radians, 0),
					CONCRETE_DARK,
					Enum.Material.Concrete,
					parent
				)
			end
		end
	end
end

local function buildStage(parent: Instance)
	-- Flat apron the performers and the front row share.
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

	-- The timber performance deck, set on the lake side of the plaza so players
	-- on it are framed by the water exactly as the real one is.
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

	-- Banner arch on the lake side, so the audience reads it against the water.
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

	-- Stage lighting masts, the pair that flanks the real stage.
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

-- The dark twin-legged gates with the pale rounded slab between them. Street
-- View shows a pair of these standing at either shoulder of the bowl rather
-- than one over the centre, so they are placed at the ends of the seating arc.
local GATE_ANGLES = { 12, 168 }

local function buildEntranceGate(parent: Instance)
	local gateRadius = APRON_RADIUS + TIER_COUNT * TIER_DEPTH + 6

	for _, angle in ipairs(GATE_ANGLES) do
		local radians = math.rad(angle)
		local gateX = CENTER_X + math.cos(radians) * gateRadius
		local gateZ = CENTER_Z + math.sin(radians) * gateRadius
		local baseY = groundAt(gateX, gateZ, GROUND_Y)
		-- Turned to face the stage, so the pair frames the bowl.
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

		-- The pale rounded slab the two legs carry.
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

-- Continuous curved benches along every row, the way the real bowl is furnished
-- -- concrete arcs set toward the back of each tread, facing the stage. Every
-- fourth segment is an actual Seat so the rows can be used rather than admired.
-- The holder is named for a bench on purpose: the seat-prompt system reads the
-- owning model's name, and "bench" is what makes it offer Sit rather than Ride.
local BENCH_SEGMENTS = 16

local function buildSeating(parent: Instance)
	local benches = Instance.new('Model')
	benches.Name = 'AmphitheaterBenches'
	benches.Parent = parent

	for tier = 1, TIER_COUNT do
		local radius = APRON_RADIUS + (tier - 1) * TIER_DEPTH + TIER_DEPTH * 0.72
		local seatTop = GROUND_Y + tier * TIER_RISE + 1.3
		local step = (ARC_END - ARC_START) / BENCH_SEGMENTS
		for index = 0, BENCH_SEGMENTS - 1 do
			local degrees = ARC_START + (index + 0.5) * step
			if not isAisle(degrees) then
				local radians = math.rad(degrees)
				local chord = 2 * radius * math.sin(math.rad(step) / 2) - 0.5
				local cframe = CFrame.new(
					CENTER_X + math.cos(radians) * radius,
					seatTop - 0.65,
					CENTER_Z + math.sin(radians) * radius
				) * CFrame.Angles(0, -radians, 0)
				local size = Vector3.new(2.6, 1.3, chord)

				if index % 4 == 2 then
					local seat = Instance.new('Seat')
					seat.Name = 'TerraceSeat'
					seat.Size = size
					-- Turned to face the stage, so sitting looks at the performance.
					seat.CFrame = CFrame.lookAt(
						cframe.Position,
						Vector3.new(CENTER_X, cframe.Position.Y, CENTER_Z)
					) * CFrame.Angles(0, math.rad(90), 0)
					seat.Color = BENCH
					seat.Material = Enum.Material.Concrete
					seat.Anchored = true
					seat.TopSurface = Enum.SurfaceType.Smooth
					seat.BottomSurface = Enum.SurfaceType.Smooth
					seat.Parent = benches
				else
					makePart('BenchArc', size, cframe, BENCH, Enum.Material.Concrete, benches)
				end
			end
		end
	end
end

-- The real bowl is dug into the mound, and so is this one. Measured on site
-- first: the landward terrain crests at Y=6 while the lower rows finish at Y=4
-- and Y=6, which buried tiers 1-2 and the bottom of every stairway in grass.
-- Carving a stepped hollow fixes that and is also how the ground actually
-- reads there. Each pass clears everything above one row's finished level, so
-- working outer-to-inner leaves a stepped basin rather than a flat pit.
local function excavateBowl()
	local terrain = Workspace.Terrain
	local carveHeight = 80

	-- Each band is cleared to a stud below the *lowest* thing finished inside it
	-- -- the previous row's level, not its own. Carving to a row's own top left
	-- the grass exactly coplanar with the slab (so it still won any downward ray)
	-- and buried the bottom steps of every stairway, which climb through the band
	-- from the row below.
	local MARGIN = 1

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
end

local function buildAmphitheater(park: Model): Model
	local model = Instance.new('Model')
	model.Name = MODEL_NAME
	model.Parent = park

	excavateBowl()
	buildStage(model)

	for tier = 1, TIER_COUNT do
		buildRing(
			model,
			'SeatingTier' .. tier,
			APRON_RADIUS + (tier - 1) * TIER_DEPTH,
			TIER_DEPTH,
			GROUND_Y + tier * TIER_RISE,
			if tier % 2 == 0 then CONCRETE_DARK else CONCRETE,
			Enum.Material.Concrete,
			true
		)
	end

	-- Two grass rings outside the top row carry the earthwork back down to the
	-- lawn, so the bowl reads as a raised mound rather than a wall.
	local bermInner = APRON_RADIUS + TIER_COUNT * TIER_DEPTH
	buildRing(model, 'BermUpper', bermInner, 5, GROUND_Y + TIER_COUNT * TIER_RISE - 1.2, GRASS, Enum.Material.Grass, false)
	buildRing(model, 'BermLower', bermInner + 5, 5, GROUND_Y + TIER_COUNT * TIER_RISE - 2.8, GRASS, Enum.Material.Grass, false)

	buildAisleStairs(model)
	buildEntranceGate(model)
	buildSeating(model)

	return model
end

--=============================================================================
-- Making room: the bowl lands where a bench row, a lantern and a tree stand
--=============================================================================

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
						-- Push it out along the axis it already leans to, so the
						-- row it belongs to keeps its spacing.
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

function LakesideAmphitheaterService.init()
	-- Deferred so it runs once every service has had its turn: the park is
	-- authored in this place, but on a fresh build LakesideParkService has to
	-- create it first, and the runner's grounding sweep is deferred after this
	-- point so relocated benches get re-seated on the ground they land on.
	task.defer(function()
		local park = Workspace:FindFirstChild('SuwaLakesidePark')
		if not park or not park:IsA('Model') then
			warn('[Amphitheater] SuwaLakesidePark missing; nothing built.')
			return
		end

		local existing = park:FindFirstChild(MODEL_NAME)
		if existing then
			existing:Destroy()
		end

		local shifted = clearBowlFootprint(park)

		-- Open the lawn between the promenade and the bowl: the footbath and the
		-- rest shelter both sat on the axis people now walk down to the stage.
		local ashiyu = park:FindFirstChild('AshiyuCanopy')
		if ashiyu and ashiyu:IsA('Model') then
			moveModel(ashiyu, 230, -95)
		end
		local shelter = park:FindFirstChild('TraditionalRestShelter')
		if shelter and shelter:IsA('Model') then
			moveModel(shelter, -60, -95)
		end

		local model = buildAmphitheater(park)
		local count = 0
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA('BasePart') then
				count += 1
			end
		end
		print(`[Amphitheater] Lakeside stage bowl built ({count} parts, {shifted} park pieces moved clear).`)
	end)
end

return LakesideAmphitheaterService
