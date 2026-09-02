--!strict

-- The twin-spire monument that stands at the water's edge in Suwa Lakeside
-- Park: two tall mirror-polished stainless steeples on a circular paved plaza,
-- ringed by a banded dial of pale flagstones, with the red lakefront promenade
-- curving past it.
--
-- Built as its own service for the same reason as the amphitheatre: the park in
-- this place is authored rather than generated, and LakesideParkService returns
-- early whenever it already exists. `build()` is synchronous and refuses to run
-- twice, so it can be called straight from the command bar in Edit mode to
-- commit the monument to the place file, and again from init() on a fresh build
-- where nothing is there yet.
--
-- Sited at x=470 on the lower shore terrace: probed first, and the strip from
-- x=460 to x=500 between z=-160 and z=-190 is empty flat grass at Y=2, right by
-- the covered bicycle parking at x=420 and hard against the waterline near
-- z=-195, which is where the real one stands.

local Workspace = game:GetService('Workspace')

local LakesideMonumentService = {}

local MODEL_NAME = 'TwinSpireMonument'

local CENTER_X, CENTER_Z = 470, -176
local GROUND_Y = 2

local PLAZA_RADIUS = 18
local DIAL_INNER = 11
local DIAL_OUTER = 15
local TICK_COUNT = 24

local SPIRE_HEIGHT = 56
local SPIRE_SEGMENTS = 14
local SPIRE_BASE_RADIUS = 2.3
local SPIRE_GAP = 2.7
local SPIRE_TILT = 2

local PALE = Color3.fromRGB(226, 223, 214)
local MID_GREY = Color3.fromRGB(150, 148, 143)
local DARK_GREY = Color3.fromRGB(86, 86, 88)
local STEEL = Color3.fromRGB(232, 234, 238)
local PROMENADE_RED = Color3.fromRGB(150, 78, 62)
local STONE = Color3.fromRGB(178, 174, 166)

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
	parameters.FilterDescendantsInstances = { Workspace.Terrain }
	parameters.IgnoreWater = true
	local result = Workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -260, 0), parameters)
	return if result then result.Position.Y else fallback
end

local function makeDisc(
	name: string,
	radius: number,
	thickness: number,
	topY: number,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local disc = makePart(
		name,
		Vector3.new(thickness, radius * 2, radius * 2),
		CFrame.new(CENTER_X, topY - thickness / 2, CENTER_Z) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		parent
	)
	disc.Shape = Enum.PartType.Cylinder
	return disc
end

-- Roblox has no cone primitive, so each steeple is a stack of cylinders whose
-- radius runs out to almost nothing. Fourteen segments is enough that the taper
-- reads as a smooth needle at the distance you ever see it from.
local function buildSpire(parent: Instance, offsetX: number, tiltDegrees: number)
	local base = CFrame.new(CENTER_X + offsetX, GROUND_Y + 0.6, CENTER_Z)
		* CFrame.Angles(0, 0, math.rad(tiltDegrees))
	local segmentHeight = SPIRE_HEIGHT / SPIRE_SEGMENTS

	for index = 0, SPIRE_SEGMENTS - 1 do
		local lower = index / SPIRE_SEGMENTS
		local upper = (index + 1) / SPIRE_SEGMENTS
		local midRadius = SPIRE_BASE_RADIUS * (1 - (lower + upper) / 2)
		local diameter = math.max(midRadius * 2, 0.22)

		local segment = makePart(
			'SpireSegment',
			Vector3.new(segmentHeight + 0.06, diameter, diameter),
			base * CFrame.new(0, segmentHeight * (index + 0.5), 0) * CFrame.Angles(0, 0, math.rad(90)),
			STEEL,
			Enum.Material.Metal,
			parent
		)
		segment.Shape = Enum.PartType.Cylinder
		-- Mirror finish: the real pair reflects the lake and the sky.
		segment.Reflectance = 0.55
	end
end

local function buildPlaza(parent: Instance)
	makeDisc('PlazaOuter', PLAZA_RADIUS, 0.5, GROUND_Y + 0.25, PALE, Enum.Material.Concrete, parent)

	-- The banded dial: a darker ring inset into the pale apron, with flagstone
	-- ticks around it like the markings on the real plaza.
	makeDisc('PlazaDial', DIAL_OUTER, 0.5, GROUND_Y + 0.32, DARK_GREY, Enum.Material.Slate, parent)
	makeDisc('PlazaInner', DIAL_INNER, 0.5, GROUND_Y + 0.4, MID_GREY, Enum.Material.Concrete, parent)

	for index = 0, TICK_COUNT - 1 do
		local radians = (index / TICK_COUNT) * math.pi * 2
		local radius = (DIAL_INNER + DIAL_OUTER) / 2
		makePart(
			'DialTick',
			Vector3.new(3.2, 0.24, 0.9),
			CFrame.new(
				CENTER_X + math.cos(radians) * radius,
				GROUND_Y + 0.44,
				CENTER_Z + math.sin(radians) * radius
			) * CFrame.Angles(0, -radians, 0),
			PALE,
			Enum.Material.Concrete,
			parent
		)
	end

	-- Low plinth the two steeples rise out of.
	makeDisc('SpirePlinth', 5.5, 1.2, GROUND_Y + 0.9, DARK_GREY, Enum.Material.Slate, parent)
end

-- The lakefront path in Street View is red-brown asphalt with a pale kerb, and
-- it sweeps around the plaza rather than running straight past it. Laid as short
-- chords so the curve stays smooth without needing a mesh.
--
-- It is laid dead level at the plaza's own height and the bank behind it is cut
-- away, which is how the real one runs. Following the ground instead turned the
-- landward arc into a flight of steps, because the bank climbs from Y=2 to Y=4
-- right where the path crosses it.
local PATH_TOP = GROUND_Y + 0.45

local function buildPromenade(parent: Instance)
	local SEGMENTS = 26
	local radius = PLAZA_RADIUS + 5.5

	for index = 0, SEGMENTS - 1 do
		-- Only the landward side: the lake takes the rest.
		local degrees = 20 + (index / (SEGMENTS - 1)) * 140
		local radians = math.rad(degrees)
		local chord = 2 * radius * math.sin(math.rad(140 / (SEGMENTS - 1)) / 2) + 0.6
		local x = CENTER_X + math.cos(radians) * radius
		local z = CENTER_Z + math.sin(radians) * radius
		local cframe = CFrame.new(x, PATH_TOP - 0.15, z) * CFrame.Angles(0, -radians, 0)

		-- Cut the bank back over the corridor so the level path is never swallowed.
		Workspace.Terrain:FillCylinder(
			CFrame.new(x, PATH_TOP - 0.1 + 40, z),
			80,
			7.5,
			Enum.Material.Air
		)

		makePart('PromenadeRed', Vector3.new(9, 0.3, chord), cframe, PROMENADE_RED, Enum.Material.Asphalt, parent)
		makePart(
			'PromenadeKerb',
			Vector3.new(1.2, 0.4, chord),
			CFrame.new(x, PATH_TOP + 0.05, z)
				* CFrame.Angles(0, -radians, 0)
				* CFrame.new(5.1, 0, 0),
			PALE,
			Enum.Material.Concrete,
			parent
		)
	end
end

-- Rounded stone bollards line the water's edge in every photo of this stretch.
local function buildBollards(parent: Instance)
	for index = -4, 4 do
		local x = CENTER_X + index * 6.5
		local z = CENTER_Z - PLAZA_RADIUS - 1.5
		makePart(
			'ShoreBollard',
			Vector3.new(1.5, 3.2, 1.5),
			CFrame.new(x, GROUND_Y + 1.6, z),
			STONE,
			Enum.Material.Concrete,
			parent
		)
		local cap = makePart(
			'BollardCap',
			Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(x, GROUND_Y + 3.2, z),
			STONE,
			Enum.Material.Concrete,
			parent
		)
		cap.Shape = Enum.PartType.Ball
	end
end

function LakesideMonumentService.build(): string
	local park = Workspace:FindFirstChild('SuwaLakesidePark')
	if not park or not park:IsA('Model') then
		return '[Monument] SuwaLakesidePark missing; nothing built.'
	end
	if park:FindFirstChild(MODEL_NAME) then
		return '[Monument] Already present; left as authored.'
	end

	local model = Instance.new('Model')
	model.Name = MODEL_NAME
	model.Parent = park

	-- One cherry tree stands squarely in the view corridor from the park to the
	-- spires. Nudged aside rather than removed, onto the clear grass west of the
	-- plaza, and only ever once.
	if not park:GetAttribute('MonumentSightlineCleared') then
		local shoreline = park:FindFirstChild('NaturalShorelineDetails')
		local tree = shoreline and shoreline:FindFirstChild('ParkTree9')
		if tree and tree:IsA('Model') then
			local pivot = tree:GetPivot()
			local fromY = groundAt(pivot.Position.X, pivot.Position.Z, pivot.Position.Y)
			local toY = groundAt(390, -168, fromY)
			tree:PivotTo(
				pivot + Vector3.new(390 - pivot.Position.X, toY - fromY, -168 - pivot.Position.Z)
			)
		end
		park:SetAttribute('MonumentSightlineCleared', true)
	end

	buildPromenade(model)
	buildPlaza(model)
	buildSpire(model, -SPIRE_GAP, -SPIRE_TILT)
	buildSpire(model, SPIRE_GAP, SPIRE_TILT)
	buildBollards(model)

	local count = 0
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA('BasePart') then
			count += 1
		end
	end
	return `[Monument] Twin-spire monument built ({count} parts).`
end

function LakesideMonumentService.init()
	task.defer(function()
		print(LakesideMonumentService.build())
	end)
end

return LakesideMonumentService
