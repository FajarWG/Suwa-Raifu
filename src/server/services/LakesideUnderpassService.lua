--!strict

-- The underpass on the approach to the twin-spire monument, following the
-- Street View reference: a white painted-concrete footbridge whose deck arcs
-- over in a shallow hump, black iron railing running along the curve, an
-- arched passage cut through the middle, and a blind arch recessed into the
-- face either side of it. Stone stairs with handrails climb to the deck at
-- both ends.
--
-- Earlier passes built this as a rectangular bore through a grassy earth
-- mound. That was wrong: the real structure is a built arch standing on flat
-- lawn, so `flattenSite()` returns the ground to level rather than sculpting
-- a berm.
--
-- Built as its own service for the same reason as the amphitheatre and the
-- monument: this stretch of the park is authored rather than generated.
-- `build()` refuses to run twice, so it can be called from the command bar in
-- Edit mode to commit it once, and again from init() on a fresh build.

local Workspace = game:GetService('Workspace')

local LakesideUnderpassService = {}

local MODEL_NAME = 'LakesideUnderpass'

-- Sits in the open lawn between the town's UnifiedLakesidePromenade (around
-- z=-42) and the monument's own promenade ring (which starts around z=-153),
-- lined up so the spires show through the arch.
local CENTER_X, CENTER_Z = 466, -100
local GROUND_Y = 6

local HALF_WIDTH = 20 -- the bridge spans x 446..486
local HALF_DEPTH = 10 -- and is 20 studs thick, z -110..-90

local PASSAGE_HALF = 5.5
local SPRING_Y = 10 -- where the arch springs from the passage walls
local ARCH_RADIUS = 5.5 -- semicircular, so the crown lands at 15.5

local DECK_CROWN_Y = 19
local DECK_END_Y = 16
local DECK_THICKNESS = 1.2

local STAIR_RUN = 20
local STAIR_STEPS = 9
-- Both flights run in line with the deck. The east one is nudged south so it
-- clears the public toilet's roof, which overhangs to z=-96.
local EAST_STAIR_Z = -103.5
local STAIR_HALF_WIDTH = 4.5

local WHITE = Color3.fromRGB(238, 236, 230)
local WHITE_SHADE = Color3.fromRGB(214, 211, 204)
local IRON = Color3.fromRGB(30, 32, 36)
local STONE = Color3.fromRGB(198, 194, 186)
local PATH = Color3.fromRGB(206, 200, 188)
local METAL = Color3.fromRGB(168, 172, 176)
local FENCE_GREEN = Color3.fromRGB(46, 120, 64)
local FENCE_BASE_GREEN = Color3.fromRGB(30, 84, 44)

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

local function deckTop(x: number): number
	return DECK_CROWN_Y - (DECK_CROWN_Y - DECK_END_Y) * ((x - CENTER_X) / HALF_WIDTH) ^ 2
end

-- The white mass, sliced finely in X so the arched opening can be cut out of
-- it. The slices are hidden behind the archivolt and under the deck.
local function buildArchMass(parent: Instance)
	local STEP = 0.5
	local x = CENTER_X - HALF_WIDTH
	while x < CENTER_X + HALF_WIDTH - 1e-6 do
		local xc = x + STEP / 2
		local top = deckTop(xc) - DECK_THICKNESS
		local bottom = GROUND_Y
		local dx = xc - CENTER_X
		if math.abs(dx) < PASSAGE_HALF then
			bottom = SPRING_Y + math.sqrt(math.max(ARCH_RADIUS ^ 2 - dx ^ 2, 0))
		end
		if top > bottom + 0.05 then
			makePart(
				'ArchSpandrel',
				Vector3.new(STEP + 0.05, top - bottom, HALF_DEPTH * 2),
				CFrame.new(xc, (top + bottom) / 2, CENTER_Z),
				WHITE,
				Enum.Material.Concrete,
				parent
			)
		end
		x += STEP
	end

	for _, side in ipairs({ -1, 1 }) do
		makePart(
			'PassageWall',
			Vector3.new(HALF_WIDTH - PASSAGE_HALF, SPRING_Y - GROUND_Y, HALF_DEPTH * 2),
			CFrame.new(
				CENTER_X + side * (PASSAGE_HALF + (HALF_WIDTH - PASSAGE_HALF) / 2),
				(GROUND_Y + SPRING_Y) / 2,
				CENTER_Z
			),
			WHITE,
			Enum.Material.Concrete,
			parent
		)
	end

	-- Ribbed metal lining inside the arch, held back from both faces so the
	-- opening reads as a clean white edge from outside.
	local RIBS = 16
	for i = 0, RIBS - 1 do
		local stepDeg = 180 / RIBS
		local theta = math.rad(180 - (i + 0.5) * stepDeg)
		local chord = 2 * ARCH_RADIUS * math.sin(math.rad(stepDeg) / 2) + 0.3
		makePart(
			'VaultRib',
			Vector3.new(0.6, chord, HALF_DEPTH * 2 - 2.4),
			CFrame.new(
				CENTER_X + math.cos(theta) * ARCH_RADIUS,
				SPRING_Y + math.sin(theta) * ARCH_RADIUS,
				CENTER_Z
			) * CFrame.Angles(0, 0, theta),
			METAL,
			Enum.Material.DiamondPlate,
			parent
		)
	end

	makePart(
		'TunnelFloor',
		Vector3.new(PASSAGE_HALF * 2, 0.4, HALF_DEPTH * 2),
		CFrame.new(CENTER_X, GROUND_Y + 0.2, CENTER_Z),
		PATH,
		Enum.Material.Concrete,
		parent
	)
end

-- A smooth white band following the true arch curve on each face, covering
-- the stepped edge the sliced mass leaves behind.
local function buildArchivolt(parent: Instance)
	local SEGS = 26
	local BAND = 1.1
	for _, face in ipairs({ -1, 1 }) do
		local faceZ = CENTER_Z + face * HALF_DEPTH - face * 0.35
		local radius = ARCH_RADIUS + BAND / 2
		for i = 0, SEGS - 1 do
			local stepDeg = 180 / SEGS
			local theta = math.rad(180 - (i + 0.5) * stepDeg)
			local chord = 2 * radius * math.sin(math.rad(stepDeg) / 2) + 0.25
			makePart(
				'Archivolt',
				Vector3.new(BAND, chord, 1.0),
				CFrame.new(
					CENTER_X + math.cos(theta) * radius,
					SPRING_Y + math.sin(theta) * radius,
					faceZ
				) * CFrame.Angles(0, 0, theta),
				WHITE,
				Enum.Material.Concrete,
				parent
			)
		end
		for _, side in ipairs({ -1, 1 }) do
			makePart(
				'Archivolt',
				Vector3.new(BAND, SPRING_Y - GROUND_Y, 1.0),
				CFrame.new(CENTER_X + side * radius, (GROUND_Y + SPRING_Y) / 2, faceZ),
				WHITE,
				Enum.Material.Concrete,
				parent
			)
		end
	end
end

-- The blind arches recessed into the face either side of the passage.
local function buildBlindArches(parent: Instance)
	for _, face in ipairs({ -1, 1 }) do
		local panelZ = CENTER_Z + face * HALF_DEPTH - face * 0.2
		for _, side in ipairs({ -1, 1 }) do
			local rx = CENTER_X + side * 13.5
			makePart(
				'BlindArchPanel',
				Vector3.new(8, 4, 0.5),
				CFrame.new(rx, GROUND_Y + 3, panelZ),
				WHITE_SHADE,
				Enum.Material.Concrete,
				parent
			)
			local cap = makePart(
				'BlindArchCap',
				Vector3.new(0.5, 8, 8),
				CFrame.new(rx, GROUND_Y + 5, panelZ) * CFrame.Angles(0, math.rad(90), 0),
				WHITE_SHADE,
				Enum.Material.Concrete,
				parent
			)
			cap.Shape = Enum.PartType.Cylinder
		end
	end
end

-- Deck and railings, both as short tilted slices following the arc.
local function buildDeckAndRailings(parent: Instance)
	local DSTEP = 2
	local slices = (HALF_WIDTH * 2) / DSTEP

	for i = 0, slices - 1 do
		local x0 = CENTER_X - HALF_WIDTH + i * DSTEP
		local x1 = x0 + DSTEP
		local y0, y1 = deckTop(x0), deckTop(x1)
		local angle = math.atan2(y1 - y0, DSTEP)
		local length = math.sqrt(DSTEP ^ 2 + (y1 - y0) ^ 2)
		makePart(
			'BridgeDeck',
			Vector3.new(length + 0.1, DECK_THICKNESS, HALF_DEPTH * 2 + 2),
			CFrame.new((x0 + x1) / 2, (y0 + y1) / 2 - DECK_THICKNESS / 2, CENTER_Z)
				* CFrame.Angles(0, 0, angle),
			PATH,
			Enum.Material.Concrete,
			parent
		)
	end

	for _, side in ipairs({ -1, 1 }) do
		local railZ = CENTER_Z + side * (HALF_DEPTH + 0.6)
		for i = 0, slices - 1 do
			local x0 = CENTER_X - HALF_WIDTH + i * DSTEP
			local x1 = x0 + DSTEP
			local y0, y1 = deckTop(x0), deckTop(x1)
			local angle = math.atan2(y1 - y0, DSTEP)
			local length = math.sqrt(DSTEP ^ 2 + (y1 - y0) ^ 2)
			for _, rail in ipairs({ { 3.2, 0.28 }, { 1.9, 0.18 } }) do
				makePart(
					'BridgeRail',
					Vector3.new(length + 0.1, rail[2], rail[2]),
					CFrame.new((x0 + x1) / 2, (y0 + y1) / 2 + rail[1], railZ)
						* CFrame.Angles(0, 0, angle),
					IRON,
					Enum.Material.Metal,
					parent
				)
			end
		end
		for i = 0, 13 do
			local px = CENTER_X - HALF_WIDTH + i * (HALF_WIDTH * 2 / 13)
			makePart(
				'BridgeRailPost',
				Vector3.new(0.28, 3.4, 0.28),
				CFrame.new(px, deckTop(px) + 1.7, railZ),
				IRON,
				Enum.Material.Metal,
				parent
			)
		end
	end
end

-- Stone stairs at both ends, each running in line with the deck so you walk
-- straight off the top step onto it. An earlier pass ran the east flight
-- south along the structure's face, which put it behind the deck's own side
-- railing -- there was no way up at all from that end.
local function buildStairs(parent: Instance)
	local rise = DECK_END_Y - GROUND_Y
	local pitch = math.atan2(rise, STAIR_RUN)
	local slope = math.sqrt(STAIR_RUN ^ 2 + rise ^ 2)
	local midY = (GROUND_Y + DECK_END_Y) / 2

	for i = 1, STAIR_STEPS do
		local t = i / STAIR_STEPS
		local topY = GROUND_Y + rise * t
		local height = topY - (GROUND_Y - 2)
		local tread = Vector3.new(STAIR_RUN / STAIR_STEPS + 0.2, height, STAIR_HALF_WIDTH * 2)
		makePart(
			'StairStep',
			tread,
			CFrame.new(
				(CENTER_X - HALF_WIDTH) - (1 - t) * STAIR_RUN - 1.1,
				topY - height / 2,
				CENTER_Z
			),
			STONE,
			Enum.Material.Concrete,
			parent
		)
		makePart(
			'StairStep',
			tread,
			CFrame.new(
				(CENTER_X + HALF_WIDTH) + (1 - t) * STAIR_RUN + 1.1,
				topY - height / 2,
				EAST_STAIR_Z
			),
			STONE,
			Enum.Material.Concrete,
			parent
		)
	end

	local flights = {
		{ (CENTER_X - HALF_WIDTH) - STAIR_RUN / 2 - 1.1, CENTER_Z, 1 },
		{ (CENTER_X + HALF_WIDTH) + STAIR_RUN / 2 + 1.1, EAST_STAIR_Z, -1 },
	}
	for _, side in ipairs({ -1, 1 }) do
		for _, flight in ipairs(flights) do
			local midX, midZ, dir = flight[1], flight[2], flight[3]
			local z = midZ + side * (STAIR_HALF_WIDTH - 0.3)
			makePart(
				'StairRail',
				Vector3.new(slope, 0.25, 0.25),
				CFrame.new(midX, midY + 3.1, z) * CFrame.Angles(0, 0, pitch * dir),
				IRON,
				Enum.Material.Metal,
				parent
			)
			for i = 0, 6 do
				local t = i / 6
				makePart(
					'StairRail',
					Vector3.new(0.25, 3, 0.25),
					CFrame.new(midX + dir * (t - 0.5) * STAIR_RUN, GROUND_Y + rise * t + 1.5, z),
					IRON,
					Enum.Material.Metal,
					parent
				)
			end
		end
	end
end

-- The deck's side railings run its length, but its two ends were left wide
-- open over a ten-stud drop. These close them, leaving a gap exactly where
-- each stair flight arrives.
local function buildEndGuards(parent: Instance)
	local function guard(x: number, zA: number, zB: number)
		local length = math.abs(zB - zA)
		local zc = (zA + zB) / 2
		makePart(
			'EndGuard',
			Vector3.new(0.28, 0.28, length),
			CFrame.new(x, DECK_END_Y + 3.2, zc),
			IRON,
			Enum.Material.Metal,
			parent
		)
		makePart(
			'EndGuard',
			Vector3.new(0.18, 0.18, length),
			CFrame.new(x, DECK_END_Y + 1.9, zc),
			IRON,
			Enum.Material.Metal,
			parent
		)
		local posts = math.max(2, math.floor(length / 3))
		for i = 0, posts do
			makePart(
				'EndGuard',
				Vector3.new(0.28, 3.4, 0.28),
				CFrame.new(x, DECK_END_Y + 1.7, zA + (zB - zA) * (i / posts)),
				IRON,
				Enum.Material.Metal,
				parent
			)
		end
	end

	local northEdge = CENTER_Z + HALF_DEPTH + 1
	local southEdge = CENTER_Z - HALF_DEPTH - 1
	local westX = CENTER_X - HALF_WIDTH + 0.4
	guard(westX, southEdge, CENTER_Z - STAIR_HALF_WIDTH)
	guard(westX, CENTER_Z + STAIR_HALF_WIDTH, northEdge)
	local eastX = CENTER_X + HALF_WIDTH - 0.4
	guard(eastX, southEdge, EAST_STAIR_Z - STAIR_HALF_WIDTH)
	guard(eastX, EAST_STAIR_Z + STAIR_HALF_WIDTH, northEdge)
end

-- Where the route actually joins the rest of the park. The aprons used to be
-- 18-stud stubs that stopped in open grass; these run the whole way to the
-- town promenade's north kerb (z=-52) and to the monument's own red
-- promenade (z=-153), and each stair foot gets a link too.
local PROMENADE_KERB_Z = -52
local MONUMENT_PROMENADE_Z = -153

local function buildApproachesAndFence(parent: Instance)
	local function paved(name, size, cframe)
		makePart(name, size, cframe, PATH, Enum.Material.Concrete, parent)
	end

	local northMouth = CENTER_Z + HALF_DEPTH
	local southMouth = CENTER_Z - HALF_DEPTH
	paved(
		'ApproachApron',
		Vector3.new(PASSAGE_HALF * 2, 0.35, math.abs(PROMENADE_KERB_Z - northMouth)),
		CFrame.new(CENTER_X, GROUND_Y + 0.18, (northMouth + PROMENADE_KERB_Z) / 2)
	)
	paved(
		'ApproachApron',
		Vector3.new(PASSAGE_HALF * 2, 0.35, math.abs(MONUMENT_PROMENADE_Z - southMouth)),
		CFrame.new(CENTER_X, GROUND_Y + 0.18, (southMouth + MONUMENT_PROMENADE_Z) / 2)
	)

	-- West stair foot, as an L: one arm west to the bike-parking branch
	-- (x 376..384), one arm north to the promenade kerb. An earlier pass ran
	-- the north arm at x=421, which put it hard against the bike canopy and
	-- still left a 21-stud break before the branch path.
	paved('LinkPath', Vector3.new(50, 0.35, 10), CFrame.new(407, GROUND_Y + 0.18, CENTER_Z))
	paved(
		'LinkPath',
		Vector3.new(STAIR_HALF_WIDTH * 2, 0.35, math.abs(PROMENADE_KERB_Z - (CENTER_Z - 5))),
		CFrame.new(427.5, GROUND_Y + 0.18, ((CENTER_Z - 5) + PROMENADE_KERB_Z) / 2)
	)

	-- East stair foot: joins the existing BranchToilet path at x 506..514.
	local eastFootX = (CENTER_X + HALF_WIDTH) + STAIR_RUN + 1.1
	paved(
		'LinkPath',
		Vector3.new(14, 0.35, STAIR_HALF_WIDTH * 2),
		CFrame.new(eastFootX - 1, GROUND_Y + 0.18, EAST_STAIR_Z)
	)

	-- BranchToilet runs south to z=-121 expecting to meet LakesideTrail_Main,
	-- but that trail stops at x=450 and the branch sits at x=510, so it just
	-- dead-ended in the grass. This carries it west into the south apron.
	paved('LinkPath', Vector3.new(42, 0.35, 8), CFrame.new(489, GROUND_Y + 0.18, -118))

	-- Temporary construction fence: green mesh panels on darker feet, the
	-- clutter the reference photos show beside the north mouth.
	for i = 0, 2 do
		local panelZ = CENTER_Z + HALF_DEPTH + 6 + i * 4.2
		makePart(
			'ConstructionFenceBase',
			Vector3.new(0.6, 0.8, 4),
			CFrame.new(CENTER_X + 14, GROUND_Y + 0.4, panelZ),
			FENCE_BASE_GREEN,
			Enum.Material.SmoothPlastic,
			parent
		)
		local panel = makePart(
			'ConstructionFencePanel',
			Vector3.new(0.1, 3.4, 3.8),
			CFrame.new(CENTER_X + 14, GROUND_Y + 2.5, panelZ),
			FENCE_GREEN,
			Enum.Material.Fabric,
			parent
		)
		panel.Transparency = 0.15
	end
end

local function buildPlaque(parent: Instance)
	-- Turned about Y and read off the Left face; on the Right face the label
	-- comes out mirrored.
	-- Sits low on the flat wall below the springing line. At head height it
	-- ran into the arch soffit, which swallowed all but a sliver of it.
	local plaque = makePart(
		'ParkPlaque',
		Vector3.new(0.25, 2.2, 5),
		CFrame.new(CENTER_X - PASSAGE_HALF + 0.15, GROUND_Y + 2.2, CENTER_Z + 2)
			* CFrame.Angles(0, math.pi, 0),
		Color3.fromRGB(58, 62, 66),
		Enum.Material.Metal,
		parent
	)
	local gui = Instance.new('SurfaceGui')
	gui.Face = Enum.NormalId.Left
	gui.CanvasSize = Vector2.new(240, 540)
	gui.Parent = plaque
	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = '諏訪湖畔公園  1998'
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(230, 228, 220)
	label.Parent = gui
end

-- The arch stands on level lawn, so the site is flattened rather than
-- sculpted. Written voxel by voxel: FillBlock only sets whole voxels, which
-- leaves the surface two studs proud of the surrounding grass. The lawn here
-- is a solid 0..4 band with everything above it empty, and matching that
-- exactly is what makes the seam invisible.
local function flattenSite()
	local terrain = Workspace.Terrain
	local region = Region3.new(
		Vector3.new(416, 0, -152),
		Vector3.new(508, 32, -36)
	):ExpandToGrid(4)
	local dims = region.Size / 4

	local materials, occupancies = {}, {}
	for x = 1, dims.X do
		materials[x], occupancies[x] = {}, {}
		for y = 1, dims.Y do
			materials[x][y], occupancies[x][y] = {}, {}
			local solid = ((y - 1) * 4) < 4
			for z = 1, dims.Z do
				materials[x][y][z] = if solid then Enum.Material.Grass else Enum.Material.Air
				occupancies[x][y][z] = if solid then 1 else 0
			end
		end
	end
	terrain:WriteVoxels(region, 4, materials, occupancies)
end

function LakesideUnderpassService.build(): string
	local park = Workspace:FindFirstChild('SuwaLakesidePark')
	if not park or not park:IsA('Model') then
		return '[Underpass] SuwaLakesidePark missing; nothing built.'
	end
	if park:FindFirstChild(MODEL_NAME) then
		return '[Underpass] Already present; left as authored.'
	end

	local model = Instance.new('Model')
	model.Name = MODEL_NAME
	model.Parent = park

	flattenSite()
	buildArchMass(model)
	buildArchivolt(model)
	buildBlindArches(model)
	buildDeckAndRailings(model)
	buildStairs(model)
	buildEndGuards(model)
	buildApproachesAndFence(model)
	buildPlaque(model)

	local count = 0
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA('BasePart') then
			count += 1
		end
	end
	return `[Underpass] Lakeside arch footbridge built ({count} parts).`
end

function LakesideUnderpassService.init()
	task.defer(function()
		print(LakesideUnderpassService.build())
	end)
end

return LakesideUnderpassService
