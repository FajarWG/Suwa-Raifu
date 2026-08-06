--!strict

-- Compact Kami-Suwa-inspired street grid. NICC and ryou corridors are intentionally
-- outside this phase; this service only fills the current lakeside map rectangle.

local asphalt = Color3.fromRGB(54, 58, 62)
local concrete = Color3.fromRGB(181, 181, 174)
local lineColor = Color3.fromRGB(244, 225, 151)

local houseColors = {
	Color3.fromRGB(232, 221, 199),
	Color3.fromRGB(217, 226, 228),
	Color3.fromRGB(224, 207, 190),
	Color3.fromRGB(210, 222, 204),
	Color3.fromRGB(235, 229, 214),
}

local roofColors = {
	Color3.fromRGB(54, 72, 88),
	Color3.fromRGB(82, 67, 59),
	Color3.fromRGB(61, 83, 77),
	Color3.fromRGB(92, 56, 54),
}

local verticalRoads = {
	{ name = 'WestNeighborhoodStreet', x = -330, z = 112, length = 250, width = 15 },
	{ name = 'WestTownStreet', x = -112, z = 188, length = 164, width = 16 },
	{ name = 'CentralTownStreet', x = -20, z = 195, length = 150, width = 15 },
	{ name = 'EastTownStreet', x = 132, z = 205, length = 130, width = 16 },
	{ name = 'EastBoundaryStreet', x = 335, z = 150, length = 240, width = 15 },
}

local horizontalRoads = {
	{ name = 'CanalSideStreet', x = -50, z = 148, length = 360, width = 15 },
	{ name = 'SouthTownStreet', x = 25, z = 225, length = 590, width = 17 },
	{ name = 'EastResidentialStreet', x = 235, z = 168, length = 190, width = 14 },
}

local houses = {
	{ 'HouseA', Vector3.new(-286, 0, 174), 34, 28, 13, 1, 1 },
	{ 'HouseB', Vector3.new(-280, 0, 244), 38, 30, 15, 2, 2 },
	{ 'HouseC', Vector3.new(-202, 0, 174), 32, 26, 13, 3, 4 },
	{ 'HouseD', Vector3.new(-173, 0, 245), 40, 30, 15, 4, 1 },
	{ 'HouseE', Vector3.new(-69, 0, 184), 32, 28, 13, 5, 3 },
	{ 'HouseF', Vector3.new(-67, 0, 252), 36, 28, 15, 2, 1 },
	{ 'HouseG', Vector3.new(35, 0, 184), 34, 28, 14, 1, 2 },
	{ 'HouseH', Vector3.new(32, 0, 253), 38, 30, 15, 3, 3 },
	{ 'HouseI', Vector3.new(108, 0, 184), 30, 27, 13, 4, 4 },
	{ 'HouseJ', Vector3.new(178, 0, 205), 40, 30, 15, 5, 1 },
	{ 'HouseK', Vector3.new(270, 0, 205), 36, 28, 14, 2, 3 },
	{ 'HouseL', Vector3.new(295, 0, 252), 38, 30, 15, 1, 2 },
}

local lampPositions = {
	Vector3.new(-345, 0, 55),
	Vector3.new(-345, 0, 170),
	Vector3.new(-345, 0, 250),
	Vector3.new(-128, 0, 155),
	Vector3.new(-36, 0, 155),
	Vector3.new(120, 0, 155),
	Vector3.new(-220, 0, 238),
	Vector3.new(-80, 0, 238),
	Vector3.new(70, 0, 238),
	Vector3.new(210, 0, 238),
	Vector3.new(320, 0, 238),
	Vector3.new(350, 0, 110),
}

local TownRoadService = {}

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

local function verticalRoad(parent: Instance, spec)
	makePart('Part', spec.name, Vector3.new(spec.width, 0.8, spec.length), CFrame.new(spec.x, 0.15, spec.z), asphalt, Enum.Material.Asphalt, parent)
	makePart('Part', spec.name .. 'SidewalkW', Vector3.new(4, 1, spec.length), CFrame.new(spec.x - spec.width / 2 - 2.5, 0.32, spec.z), concrete, Enum.Material.Concrete, parent)
	makePart('Part', spec.name .. 'SidewalkE', Vector3.new(4, 1, spec.length), CFrame.new(spec.x + spec.width / 2 + 2.5, 0.32, spec.z), concrete, Enum.Material.Concrete, parent)
	for offset = -spec.length / 2 + 12, spec.length / 2 - 12, 28 do
		local dash = makePart('Part', spec.name .. 'Dash', Vector3.new(0.45, 0.08, 12), CFrame.new(spec.x, 0.6, spec.z + offset), lineColor, Enum.Material.SmoothPlastic, parent)
		dash.CanCollide = false
	end
end

local function horizontalRoad(parent: Instance, spec)
	makePart('Part', spec.name, Vector3.new(spec.length, 0.8, spec.width), CFrame.new(spec.x, 0.15, spec.z), asphalt, Enum.Material.Asphalt, parent)
	makePart('Part', spec.name .. 'SidewalkN', Vector3.new(spec.length, 1, 4), CFrame.new(spec.x, 0.32, spec.z - spec.width / 2 - 2.5), concrete, Enum.Material.Concrete, parent)
	makePart('Part', spec.name .. 'SidewalkS', Vector3.new(spec.length, 1, 4), CFrame.new(spec.x, 0.32, spec.z + spec.width / 2 + 2.5), concrete, Enum.Material.Concrete, parent)
	for offset = -spec.length / 2 + 12, spec.length / 2 - 12, 28 do
		local dash = makePart('Part', spec.name .. 'Dash', Vector3.new(12, 0.08, 0.45), CFrame.new(spec.x + offset, 0.6, spec.z), lineColor, Enum.Material.SmoothPlastic, parent)
		dash.CanCollide = false
	end
end

local function makeHouse(parent: Instance, spec)
	local model = Instance.new('Model')
	model.Name = spec[1]
	model.Parent = parent
	local position = spec[2] :: Vector3
	local width = spec[3] :: number
	local depth = spec[4] :: number
	local height = spec[5] :: number
	local bodyColor = houseColors[spec[6] :: number]
	local roofColor = roofColors[spec[7] :: number]
	makePart('Part', 'Body', Vector3.new(width, height, depth), CFrame.new(position + Vector3.new(0, height / 2, 0)), bodyColor, Enum.Material.Plaster, model)
	makePart('WedgePart', 'RoofLeft', Vector3.new(width / 2 + 1, 5, depth + 4), CFrame.new(position + Vector3.new(-width / 4, height + 2.5, 0)) * CFrame.Angles(0, 0, math.rad(180)), roofColor, Enum.Material.RoofShingles, model)
	makePart('WedgePart', 'RoofRight', Vector3.new(width / 2 + 1, 5, depth + 4), CFrame.new(position + Vector3.new(width / 4, height + 2.5, 0)), roofColor, Enum.Material.RoofShingles, model)
	makePart('Part', 'Door', Vector3.new(4.5, 7, 0.5), CFrame.new(position + Vector3.new(-width * 0.22, 3.5, -depth / 2 - 0.26)), Color3.fromRGB(75, 91, 101), Enum.Material.Wood, model)
	for side = -1, 1, 2 do
		local window = makePart('Part', 'Window', Vector3.new(6, 4.5, 0.4), CFrame.new(position + Vector3.new(side * width * 0.22, height * 0.58, -depth / 2 - 0.3)), Color3.fromRGB(119, 176, 201), Enum.Material.Glass, model)
		window.Transparency = 0.15
		window.CanCollide = false
	end
	makePart('Part', 'Foundation', Vector3.new(width + 3, 0.8, depth + 3), CFrame.new(position + Vector3.new(0, 0.4, 0)), Color3.fromRGB(145, 145, 139), Enum.Material.Concrete, model)
end

local function makeShop(parent: Instance, name: string, position: Vector3, width: number, color: Color3, text: string)
	local model = Instance.new('Model')
	model.Name = name
	model.Parent = parent
	makePart('Part', 'Building', Vector3.new(width, 13, 26), CFrame.new(position + Vector3.new(0, 6.5, 0)), color, Enum.Material.Brick, model)
	makePart('Part', 'Roof', Vector3.new(width + 3, 1.5, 29), CFrame.new(position + Vector3.new(0, 13.8, 0)), Color3.fromRGB(64, 75, 82), Enum.Material.Metal, model)
	local glass = makePart('Part', 'ShopWindow', Vector3.new(width * 0.52, 6, 0.45), CFrame.new(position + Vector3.new(4, 5, -13.25)), Color3.fromRGB(112, 180, 205), Enum.Material.Glass, model)
	glass.Transparency = 0.18
	glass.CanCollide = false
	makePart('Part', 'Awning', Vector3.new(width * 0.75, 0.8, 5), CFrame.new(position + Vector3.new(2, 10, -15)) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(181, 67, 61), Enum.Material.Fabric, model)
	local sign = makePart('Part', 'Sign', Vector3.new(width * 0.55, 4, 0.5), CFrame.new(position + Vector3.new(0, 10, -13.4)), Color3.fromRGB(245, 240, 222), Enum.Material.Wood, model)
	local gui = Instance.new('SurfaceGui')
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 36
	gui.Parent = sign
	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(45, 55, 60)
	label.TextScaled = true
	label.Parent = gui
end

local function makeLamp(parent: Instance, name: string, position: Vector3)
	makePart('Part', name .. 'Post', Vector3.new(0.7, 10, 0.7), CFrame.new(position + Vector3.new(0, 5, 0)), Color3.fromRGB(45, 50, 54), Enum.Material.Metal, parent)
	local lamp = makePart('Part', name .. 'Lamp', Vector3.new(2.2, 1.2, 2.2), CFrame.new(position + Vector3.new(0, 10.4, 0)), Color3.fromRGB(255, 230, 167), Enum.Material.Neon, parent)
	lamp.Shape = Enum.PartType.Ball
	lamp.CanCollide = false
end

local function makeCrosswalk(parent: Instance, name: string, center: Vector3, horizontal: boolean)
	local model = Instance.new('Model')
	model.Name = name
	model.Parent = parent
	for index = -3, 3 do
		local size = if horizontal then Vector3.new(2.5, 0.1, 15) else Vector3.new(15, 0.1, 2.5)
		local offset = if horizontal then Vector3.new(index * 5, 0, 0) else Vector3.new(0, 0, index * 5)
		local stripe = makePart('Part', 'Stripe', size, CFrame.new(center + offset + Vector3.new(0, 0.62, 0)), Color3.fromRGB(238, 238, 232), Enum.Material.SmoothPlastic, model)
		stripe.CanCollide = false
	end
end

local function buildTown()
	local previous = workspace:FindFirstChild('TownRoadNetwork')
	if previous then
		previous:Destroy()
	end
	local central = workspace:FindFirstChild('SuwaCentral')
	local oldResidential = central and central:FindFirstChild('ResidentialBlocks')
	if oldResidential then
		oldResidential:Destroy()
	end

	local root = Instance.new('Model')
	root.Name = 'TownRoadNetwork'
	root.Parent = workspace
	local roads = Instance.new('Model')
	roads.Name = 'LocalRoads'
	roads.Parent = root
	local buildings = Instance.new('Model')
	buildings.Name = 'TownBlocks'
	buildings.Parent = root
	local details = Instance.new('Model')
	details.Name = 'StreetDetails'
	details.Parent = root

	for _, spec in verticalRoads do
		verticalRoad(roads, spec)
	end
	for _, spec in horizontalRoads do
		horizontalRoad(roads, spec)
	end

	makePart('Part', 'CanalBridgeWest', Vector3.new(19, 1.8, 24), CFrame.new(-112, 1, 118), asphalt, Enum.Material.Asphalt, roads)
	makePart('Part', 'CanalBridgeCentral', Vector3.new(18, 1.8, 24), CFrame.new(-20, 1, 118), asphalt, Enum.Material.Asphalt, roads)
	makePart('Part', 'RiverBridgeNorth', Vector3.new(54, 1.8, 18), CFrame.new(72, 1, 148), asphalt, Enum.Material.Asphalt, roads)
	makePart('Part', 'RiverBridgeSouth', Vector3.new(54, 1.8, 20), CFrame.new(72, 1, 225), asphalt, Enum.Material.Asphalt, roads)

	for _, spec in houses do
		makeHouse(buildings, spec)
	end
	makeShop(buildings, 'LocalCafe', Vector3.new(-82, 0, 20), 38, Color3.fromRGB(211, 177, 138), '喫茶')
	makeShop(buildings, 'MiniMarket', Vector3.new(-15, 0, 20), 42, Color3.fromRGB(202, 220, 213), '商店')
	makeShop(buildings, 'CycleShop', Vector3.new(132, 0, 20), 38, Color3.fromRGB(196, 210, 226), '自転車')

	for index, position in lampPositions do
		makeLamp(details, 'TownLamp' .. index, position)
	end
	makeCrosswalk(details, 'CrosswalkWest', Vector3.new(-112, 0, 148), false)
	makeCrosswalk(details, 'CrosswalkCentral', Vector3.new(-20, 0, 225), true)
	makeCrosswalk(details, 'CrosswalkEast', Vector3.new(132, 0, 225), true)
	makeCrosswalk(details, 'CrosswalkBoundary', Vector3.new(335, 0, 168), false)
end

function TownRoadService.init()
	buildTown()
end

return TownRoadService
