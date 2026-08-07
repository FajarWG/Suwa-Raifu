--!strict

-- Lightweight lakeside wildlife: visible fish schools around fishing piers and
-- island coves, plus drifting ducks and two shore birds. All movement is visual
-- and server-authoritative so every player sees the same living lake.

local RunService = game:GetService('RunService')

type Swimmer = {
	model: Model,
	center: Vector3,
	radiusX: number,
	radiusZ: number,
	speed: number,
	phase: number,
	bob: number,
}

local WorldWildlifeService = {}
local swimmers: { Swimmer } = {}

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
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.CastShadow = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function wedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): WedgePart
	local object = Instance.new('WedgePart')
	object.Name = name
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = material
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.CastShadow = true
	object.Parent = parent
	return object
end

local function terrainHeight(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 70, z), Vector3.new(0, -150, 0), parameters)
	return if result then result.Position.Y else fallback
end

local function makeFish(parent: Instance, position: Vector3, index: number): Model
	local model = Instance.new('Model')
	model.Name = `VisibleLakeFish{index}`
	model:SetAttribute('FishingAreaWildlife', true)
	model:SetAttribute('Species', if index % 3 == 0 then 'Wakasagi' else 'Lake carp')
	model.Parent = parent
	local colors = {
		Color3.fromRGB(166, 150, 91),
		Color3.fromRGB(105, 135, 111),
		Color3.fromRGB(184, 188, 174),
		Color3.fromRGB(190, 126, 76),
	}
	local color = colors[((index - 1) % #colors) + 1]
	local length = 1.5 + (index % 4) * 0.22
	local body = part(
		model,
		'FishBody',
		Vector3.new(0.58, 0.46, length),
		CFrame.new(position),
		color,
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball
	local head = part(
		model,
		'FishHead',
		Vector3.new(0.54, 0.43, 0.62),
		CFrame.new(position + Vector3.new(0, 0.015, -length * 0.43)),
		color:Lerp(Color3.new(1, 1, 1), 0.06),
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball
	for _, side in { -1, 1 } do
		local eye = part(
			model,
			'FishEye',
			Vector3.new(0.09, 0.09, 0.09),
			CFrame.new(position + Vector3.new(side * 0.285, 0.1, -length * 0.56)),
			Color3.fromRGB(18, 20, 18),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end
	local tailColor = color:Lerp(Color3.new(0, 0, 0), 0.12)
	wedge(
		model,
		'UpperTailFin',
		Vector3.new(0.14, 0.58, 0.72),
		CFrame.new(position + Vector3.new(0, 0.24, length * 0.66)) * CFrame.Angles(math.rad(-18), 0, 0),
		tailColor,
		Enum.Material.SmoothPlastic
	)
	wedge(
		model,
		'LowerTailFin',
		Vector3.new(0.14, 0.58, 0.72),
		CFrame.new(position + Vector3.new(0, -0.24, length * 0.66)) * CFrame.Angles(math.rad(162), 0, 0),
		tailColor,
		Enum.Material.SmoothPlastic
	)
	for _, side in { -1, 1 } do
		wedge(
			model,
			'PectoralFin',
			Vector3.new(0.12, 0.42, 0.5),
			CFrame.new(position + Vector3.new(side * 0.34, -0.08, -0.08)) * CFrame.Angles(0, 0, math.rad(side * 62)),
			tailColor,
			Enum.Material.SmoothPlastic
		)
	end
	model.WorldPivot = CFrame.new(position)
	return model
end

local function makeDuck(parent: Instance, position: Vector3, index: number): Model
	local model = Instance.new('Model')
	model.Name = `SuwakoDuck{index}`
	model:SetAttribute('LakeWildlife', true)
	model:SetAttribute('Species', if index % 2 == 0 then 'Mallard' else 'Domestic duck')
	model.Parent = parent
	local bodyColor = if index % 2 == 0 then Color3.fromRGB(104, 83, 59) else Color3.fromRGB(218, 213, 188)
	local body =
		part(model, 'Body', Vector3.new(1.45, 0.85, 2.2), CFrame.new(position), bodyColor, Enum.Material.SmoothPlastic)
	body.Shape = Enum.PartType.Ball
	local head = part(
		model,
		'Head',
		Vector3.new(0.92, 0.92, 0.92),
		CFrame.new(position + Vector3.new(0, 0.55, -0.82)),
		if index % 2 == 0 then Color3.fromRGB(54, 101, 74) else bodyColor,
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball
	part(
		model,
		'Beak',
		Vector3.new(0.52, 0.22, 0.55),
		CFrame.new(position + Vector3.new(0, 0.48, -1.42)),
		Color3.fromRGB(230, 151, 49),
		Enum.Material.SmoothPlastic
	)
	for _, side in { -1, 1 } do
		local wing = part(
			model,
			'LayeredWing',
			Vector3.new(0.38, 0.58, 1.45),
			CFrame.new(position + Vector3.new(side * 0.67, 0.08, 0.2)) * CFrame.Angles(0, 0, math.rad(side * 11)),
			bodyColor:Lerp(Color3.new(0, 0, 0), 0.18),
			Enum.Material.SmoothPlastic
		)
		wing.Shape = Enum.PartType.Ball
		local eye = part(
			model,
			'DuckEye',
			Vector3.new(0.12, 0.12, 0.12),
			CFrame.new(position + Vector3.new(side * 0.39, 0.67, -1.1)),
			Color3.fromRGB(18, 18, 16),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end
	local tail = wedge(
		model,
		'DuckTail',
		Vector3.new(0.75, 0.55, 0.8),
		CFrame.new(position + Vector3.new(0, 0.2, 1.25)) * CFrame.Angles(math.rad(18), math.rad(180), 0),
		bodyColor,
		Enum.Material.SmoothPlastic
	)
	tail.CanQuery = false
	model.WorldPivot = CFrame.new(position)
	return model
end

local function makeHeron(parent: Instance, x: number, z: number, index: number)
	local ground = terrainHeight(x, z, 1)
	local model = Instance.new('Model')
	model.Name = `IslandHeron{index}`
	model:SetAttribute('IslandWildlife', true)
	model:SetAttribute('Species', 'Grey heron')
	model.Parent = parent
	for _, xOffset in { -0.22, 0.22 } do
		part(
			model,
			'Leg',
			Vector3.new(0.12, 1.8, 0.12),
			CFrame.new(x + xOffset, ground + 0.9, z),
			Color3.fromRGB(92, 78, 60),
			Enum.Material.SmoothPlastic
		)
	end
	local body = part(
		model,
		'Body',
		Vector3.new(1.25, 1.3, 1.9),
		CFrame.new(x, ground + 2.2, z),
		Color3.fromRGB(197, 203, 199),
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball
	for _, side in { -1, 1 } do
		local wing = part(
			model,
			'FoldedWing',
			Vector3.new(0.32, 1.0, 1.5),
			CFrame.new(x + side * 0.58, ground + 2.25, z + 0.15) * CFrame.Angles(0, 0, math.rad(side * 8)),
			Color3.fromRGB(126, 139, 143),
			Enum.Material.SmoothPlastic
		)
		wing.Shape = Enum.PartType.Ball
	end
	part(
		model,
		'Neck',
		Vector3.new(0.28, 1.8, 0.28),
		CFrame.new(x, ground + 3.3, z - 0.45) * CFrame.Angles(math.rad(-12), 0, 0),
		Color3.fromRGB(211, 215, 208),
		Enum.Material.SmoothPlastic
	)
	local head = part(
		model,
		'Head',
		Vector3.new(0.6, 0.6, 0.6),
		CFrame.new(x, ground + 4.2, z - 0.7),
		Color3.fromRGB(211, 215, 208),
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball
	for _, side in { -1, 1 } do
		local eye = part(
			model,
			'HeronEye',
			Vector3.new(0.09, 0.09, 0.09),
			CFrame.new(x + side * 0.26, ground + 4.28, z - 0.92),
			Color3.fromRGB(20, 20, 16),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end
	part(
		model,
		'Beak',
		Vector3.new(0.2, 0.18, 1.05),
		CFrame.new(x, ground + 4.15, z - 1.45),
		Color3.fromRGB(222, 165, 62),
		Enum.Material.SmoothPlastic
	)
	for _, footSpec in
		{
			Vector3.new(-0.22, 0.05, -0.38),
			Vector3.new(-0.22, 0.05, 0.38),
			Vector3.new(0.22, 0.05, -0.38),
			Vector3.new(0.22, 0.05, 0.38),
		}
	do
		part(
			model,
			'FootToe',
			Vector3.new(0.08, 0.08, 0.65),
			CFrame.new(x + footSpec.X, ground + footSpec.Y, z + footSpec.Z),
			Color3.fromRGB(92, 78, 60),
			Enum.Material.SmoothPlastic
		)
	end
end

local function addFishSchool(root: Model, center: Vector3, count: number, schoolIndex: number)
	for index = 1, count do
		local phase = (index / count) * math.pi * 2
		local position = center
			+ Vector3.new(math.cos(phase) * (4 + index % 3), (index % 3) * 0.18, math.sin(phase) * (3 + index % 4))
		local fish = makeFish(root, position, schoolIndex * 20 + index)
		table.insert(swimmers, {
			model = fish,
			center = center,
			radiusX = 4 + (index % 4) * 1.2,
			radiusZ = 3 + (index % 3) * 1.1,
			speed = 0.38 + (index % 4) * 0.07,
			phase = phase,
			bob = 0.12,
		})
	end
end

local function buildWildlife()
	local previous = workspace:FindFirstChild('SuwakoWildlife')
	if previous then
		previous:Destroy()
	end
	table.clear(swimmers)
	local root = Instance.new('Model')
	root.Name = 'SuwakoWildlife'
	root:SetAttribute('VisibleFishCount', 18)
	root:SetAttribute('DuckCount', 6)
	root.Parent = workspace

	local activities = workspace:FindFirstChild('LakesideActivities')
	local schoolIndex = 0
	if activities then
		for _, pierName in { 'WestFishingPier', 'CentralFishingPier', 'EastFishingPier' } do
			local pier = activities:FindFirstChild(pierName)
			local spot = pier and pier:FindFirstChild('FishingSpot02', true)
			if spot and spot:IsA('BasePart') then
				schoolIndex += 1
				addFishSchool(root, Vector3.new(spot.Position.X, -1.8, spot.Position.Z - 11), 4, schoolIndex)
			end
		end
	end
	addFishSchool(root, Vector3.new(-104, -1.6, -610), 3, 4)
	addFishSchool(root, Vector3.new(104, -1.7, -625), 3, 5)

	local duckCenters = {
		Vector3.new(-101, 0.5, -600),
		Vector3.new(103, 0.5, -623),
		Vector3.new(-22, 0.5, -704),
		Vector3.new(35, 0.5, -516),
		Vector3.new(-280, 0.5, -230),
		Vector3.new(325, 0.5, -232),
	}
	for index, center in duckCenters do
		local duck = makeDuck(root, center, index)
		table.insert(swimmers, {
			model = duck,
			center = center,
			radiusX = 4 + index,
			radiusZ = 2.5 + index * 0.5,
			speed = 0.1 + index * 0.015,
			phase = index * 0.9,
			bob = 0.08,
		})
	end
	makeHeron(root, -65, -610, 1)
	makeHeron(root, 64, -638, 2)
end

local function updateWildlife()
	local now = os.clock()
	for _, swimmer in swimmers do
		if swimmer.model.Parent then
			local angle = swimmer.phase + now * swimmer.speed
			local position = swimmer.center
				+ Vector3.new(
					math.cos(angle) * swimmer.radiusX,
					math.sin(now * 1.7 + swimmer.phase) * swimmer.bob,
					math.sin(angle) * swimmer.radiusZ
				)
			local nextPosition = swimmer.center
				+ Vector3.new(math.cos(angle + 0.05) * swimmer.radiusX, 0, math.sin(angle + 0.05) * swimmer.radiusZ)
			swimmer.model:PivotTo(CFrame.lookAt(position, nextPosition))
		end
	end
end

function WorldWildlifeService.init()
	task.defer(buildWildlife)
	RunService.Heartbeat:Connect(updateWildlife)
end

return WorldWildlifeService
