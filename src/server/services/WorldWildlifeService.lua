--!strict

-- Realistic Lakeside Wildlife Service for Suwa Lakeside Park:
-- Includes realistic swimming ducks, grey herons on shore, Wakasagi & Lake carp,
-- and roaming Japanese Sika Deer (Shika) around the park lawn and shrine area.

local RunService = game:GetService('RunService')

type Swimmer = {
	model: Model,
	center: Vector3,
	radiusX: number,
	radiusZ: number,
	speed: number,
	phase: number,
	bob: number,
	isFish: boolean?,
}

type Roamer = {
	model: Model,
	center: Vector3,
	radius: number,
	speed: number,
	phase: number,
	groundY: number,
}

local WorldWildlifeService = {}
local swimmers: { Swimmer } = {}
local roamers: { Roamer } = {}

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
		Color3.fromRGB(175, 160, 95),
		Color3.fromRGB(110, 142, 118),
		Color3.fromRGB(195, 198, 185),
		Color3.fromRGB(205, 136, 85),
	}
	local color = colors[((index - 1) % #colors) + 1]
	local length = 1.6 + (index % 4) * 0.25

	local body = part(
		model,
		'FishBody',
		Vector3.new(0.55, 0.48, length),
		CFrame.new(position),
		color,
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball

	local head = part(
		model,
		'FishHead',
		Vector3.new(0.52, 0.44, 0.65),
		CFrame.new(position + Vector3.new(0, 0.015, -length * 0.43)),
		color:Lerp(Color3.new(1, 1, 1), 0.12),
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball

	for _, side in { -1, 1 } do
		local eye = part(
			model,
			'FishEye',
			Vector3.new(0.1, 0.1, 0.1),
			CFrame.new(position + Vector3.new(side * 0.26, 0.1, -length * 0.56)),
			Color3.fromRGB(15, 15, 15),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end

	local tailColor = color:Lerp(Color3.new(0, 0, 0), 0.15)
	wedge(
		model,
		'UpperTailFin',
		Vector3.new(0.12, 0.62, 0.78),
		CFrame.new(position + Vector3.new(0, 0.25, length * 0.65)) * CFrame.Angles(math.rad(-18), 0, 0),
		tailColor,
		Enum.Material.SmoothPlastic
	)
	wedge(
		model,
		'LowerTailFin',
		Vector3.new(0.12, 0.62, 0.78),
		CFrame.new(position + Vector3.new(0, -0.25, length * 0.65)) * CFrame.Angles(math.rad(162), 0, 0),
		tailColor,
		Enum.Material.SmoothPlastic
	)
	model.WorldPivot = CFrame.new(position)
	return model
end

local function makeDuck(parent: Instance, position: Vector3, index: number): Model
	local model = Instance.new('Model')
	model.Name = `SuwakoDuck{index}`
	model:SetAttribute('LakeWildlife', true)
	local isMallard = (index % 2 == 0)
	model:SetAttribute('Species', if isMallard then 'Mallard duck' else 'White duck')
	model.Parent = parent

	local bodyColor = if isMallard then Color3.fromRGB(115, 88, 58) else Color3.fromRGB(240, 238, 225)
	local headColor = if isMallard then Color3.fromRGB(25, 115, 75) else bodyColor
	local beakColor = if isMallard then Color3.fromRGB(240, 175, 35) else Color3.fromRGB(245, 140, 30)

	local body = part(
		model,
		'Body',
		Vector3.new(1.4, 0.9, 2.3),
		CFrame.new(position),
		bodyColor,
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball

	if isMallard then
		part(
			model,
			'NeckRing',
			Vector3.new(0.95, 0.18, 0.95),
			CFrame.new(position + Vector3.new(0, 0.35, -0.7)),
			Color3.fromRGB(250, 250, 250),
			Enum.Material.SmoothPlastic
		).Shape = Enum.PartType.Cylinder
	end

	local head = part(
		model,
		'Head',
		Vector3.new(0.88, 0.88, 0.88),
		CFrame.new(position + Vector3.new(0, 0.62, -0.85)),
		headColor,
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball

	part(
		model,
		'Beak',
		Vector3.new(0.48, 0.2, 0.6),
		CFrame.new(position + Vector3.new(0, 0.52, -1.45)),
		beakColor,
		Enum.Material.SmoothPlastic
	)

	for _, side in { -1, 1 } do
		local wing = part(
			model,
			'Wing',
			Vector3.new(0.35, 0.6, 1.5),
			CFrame.new(position + Vector3.new(side * 0.65, 0.1, 0.15)) * CFrame.Angles(0, 0, math.rad(side * 12)),
			if isMallard then Color3.fromRGB(85, 65, 45) else bodyColor,
			Enum.Material.SmoothPlastic
		)
		wing.Shape = Enum.PartType.Ball

		local eye = part(
			model,
			'DuckEye',
			Vector3.new(0.12, 0.12, 0.12),
			CFrame.new(position + Vector3.new(side * 0.38, 0.7, -1.1)),
			Color3.fromRGB(15, 15, 15),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end

	wedge(
		model,
		'DuckTail',
		Vector3.new(0.7, 0.5, 0.8),
		CFrame.new(position + Vector3.new(0, 0.22, 1.25)) * CFrame.Angles(math.rad(20), math.rad(180), 0),
		bodyColor,
		Enum.Material.SmoothPlastic
	)
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

	for _, xOffset in { -0.25, 0.25 } do
		part(
			model,
			'Leg',
			Vector3.new(0.12, 2.0, 0.12),
			CFrame.new(x + xOffset, ground + 1.0, z),
			Color3.fromRGB(95, 80, 58),
			Enum.Material.SmoothPlastic
		)
	end

	local body = part(
		model,
		'Body',
		Vector3.new(1.3, 1.35, 2.0),
		CFrame.new(x, ground + 2.35, z),
		Color3.fromRGB(195, 200, 198),
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball

	for _, side in { -1, 1 } do
		local wing = part(
			model,
			'Wing',
			Vector3.new(0.35, 1.05, 1.6),
			CFrame.new(x + side * 0.6, ground + 2.4, z + 0.15) * CFrame.Angles(0, 0, math.rad(side * 8)),
			Color3.fromRGB(120, 132, 138),
			Enum.Material.SmoothPlastic
		)
		wing.Shape = Enum.PartType.Ball
	end

	part(
		model,
		'Neck',
		Vector3.new(0.28, 2.0, 0.28),
		CFrame.new(x, ground + 3.45, z - 0.5) * CFrame.Angles(math.rad(-14), 0, 0),
		Color3.fromRGB(215, 218, 212),
		Enum.Material.SmoothPlastic
	)

	local head = part(
		model,
		'Head',
		Vector3.new(0.62, 0.62, 0.62),
		CFrame.new(x, ground + 4.35, z - 0.75),
		Color3.fromRGB(220, 222, 218),
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball

	part(
		model,
		'Crest',
		Vector3.new(0.18, 0.25, 0.85),
		CFrame.new(x, ground + 4.5, z - 0.2) * CFrame.Angles(math.rad(22), 0, 0),
		Color3.fromRGB(35, 38, 42),
		Enum.Material.SmoothPlastic
	)

	for _, side in { -1, 1 } do
		local eye = part(
			model,
			'HeronEye',
			Vector3.new(0.1, 0.1, 0.1),
			CFrame.new(x + side * 0.28, ground + 4.42, z - 0.95),
			Color3.fromRGB(20, 20, 15),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end

	part(
		model,
		'Beak',
		Vector3.new(0.2, 0.18, 1.15),
		CFrame.new(x, ground + 4.28, z - 1.5),
		Color3.fromRGB(230, 170, 55),
		Enum.Material.SmoothPlastic
	)
end

local function makeSikaDeer(parent: Instance, center: Vector3, index: number): Model
	local ground = terrainHeight(center.X, center.Z, center.Y)
	local model = Instance.new('Model')
	model.Name = `SuwaSikaDeer{index}`
	model:SetAttribute('ParkWildlife', true)
	model:SetAttribute('Species', 'Sika Deer (Shika)')
	model.Parent = parent

	local coatColor = Color3.fromRGB(175, 115, 68)
	local bellyColor = Color3.fromRGB(235, 222, 200)

	local body = part(
		model,
		'DeerTorso',
		Vector3.new(1.6, 1.8, 3.2),
		CFrame.new(center.X, ground + 2.4, center.Z),
		coatColor,
		Enum.Material.SmoothPlastic
	)
	body.Shape = Enum.PartType.Ball

	part(
		model,
		'Underbelly',
		Vector3.new(1.3, 0.8, 2.6),
		CFrame.new(center.X, ground + 1.9, center.Z),
		bellyColor,
		Enum.Material.SmoothPlastic
	).Shape = Enum.PartType.Ball

	for _, spec in {
		{ -0.6, 1.35, -1.1 },
		{ 0.6, 1.35, -1.1 },
		{ -0.6, 1.35, 1.1 },
		{ 0.6, 1.35, 1.1 },
	} do
		part(
			model,
			'Leg',
			Vector3.new(0.25, 2.6, 0.25),
			CFrame.new(center.X + spec[1], ground + spec[2], center.Z + spec[3]),
			coatColor,
			Enum.Material.SmoothPlastic
		)
		part(
			model,
			'Hoof',
			Vector3.new(0.28, 0.25, 0.28),
			CFrame.new(center.X + spec[1], ground + 0.12, center.Z + spec[3]),
			Color3.fromRGB(40, 35, 30),
			Enum.Material.SmoothPlastic
		)
	end

	part(
		model,
		'Neck',
		Vector3.new(0.55, 1.8, 0.55),
		CFrame.new(center.X, ground + 3.4, center.Z - 1.3) * CFrame.Angles(math.rad(-25), 0, 0),
		coatColor,
		Enum.Material.SmoothPlastic
	)

	local head = part(
		model,
		'Head',
		Vector3.new(0.75, 0.75, 1.05),
		CFrame.new(center.X, ground + 4.3, center.Z - 1.8),
		coatColor,
		Enum.Material.SmoothPlastic
	)
	head.Shape = Enum.PartType.Ball

	part(
		model,
		'Muzzle',
		Vector3.new(0.48, 0.42, 0.65),
		CFrame.new(center.X, ground + 4.15, center.Z - 2.3),
		bellyColor,
		Enum.Material.SmoothPlastic
	)

	for _, side in { -1, 1 } do
		local ear = part(
			model,
			'Ear',
			Vector3.new(0.18, 0.55, 0.28),
			CFrame.new(center.X + side * 0.45, ground + 4.7, center.Z - 1.7) * CFrame.Angles(0, 0, math.rad(side * 28)),
			coatColor,
			Enum.Material.SmoothPlastic
		)
		ear.Shape = Enum.PartType.Ball

		local eye = part(
			model,
			'Eye',
			Vector3.new(0.12, 0.12, 0.12),
			CFrame.new(center.X + side * 0.35, ground + 4.38, center.Z - 1.95),
			Color3.fromRGB(15, 12, 10),
			Enum.Material.SmoothPlastic
		)
		eye.Shape = Enum.PartType.Ball
	end

	if index % 2 == 1 then
		for _, side in { -1, 1 } do
			part(
				model,
				'AntlerMain',
				Vector3.new(0.12, 1.5, 0.12),
				CFrame.new(center.X + side * 0.28, ground + 5.2, center.Z - 1.75) * CFrame.Angles(math.rad(-15), 0, math.rad(side * 18)),
				Color3.fromRGB(210, 195, 170),
				Enum.Material.Wood
			)
			part(
				model,
				'AntlerTine',
				Vector3.new(0.1, 0.7, 0.1),
				CFrame.new(center.X + side * 0.42, ground + 5.4, center.Z - 1.9) * CFrame.Angles(math.rad(-45), 0, math.rad(side * 30)),
				Color3.fromRGB(210, 195, 170),
				Enum.Material.Wood
			)
		end
	end

	for dot = 1, 6 do
		local side = if dot % 2 == 0 then 1 else -1
		local zOff = -0.8 + (dot * 0.38)
		part(
			model,
			'Spot',
			Vector3.new(0.18, 0.18, 0.18),
			CFrame.new(center.X + side * 0.72, ground + 2.7, center.Z + zOff),
			Color3.fromRGB(250, 245, 235),
			Enum.Material.SmoothPlastic
		).Shape = Enum.PartType.Ball
	end

	part(
		model,
		'Tail',
		Vector3.new(0.35, 0.45, 0.35),
		CFrame.new(center.X, ground + 2.5, center.Z + 1.6) * CFrame.Angles(math.rad(-15), 0, 0),
		bellyColor,
		Enum.Material.SmoothPlastic
	)

	model.WorldPivot = CFrame.new(center.X, ground, center.Z)
	return model
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
			radiusX = 4.5 + (index % 4) * 1.2,
			radiusZ = 3.5 + (index % 3) * 1.1,
			speed = 0.42 + (index % 4) * 0.08,
			phase = phase,
			bob = 0.15,
			isFish = true,
		})
	end
end

local function buildWildlife()
	local previous = workspace:FindFirstChild('SuwakoWildlife')
	if previous then
		previous:Destroy()
	end
	table.clear(swimmers)
	table.clear(roamers)

	local root = Instance.new('Model')
	root.Name = 'SuwakoWildlife'
	root:SetAttribute('VisibleFishCount', 18)
	root:SetAttribute('DuckCount', 6)
	root:SetAttribute('SikaDeerCount', 4)
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
			radiusX = 5 + index * 0.8,
			radiusZ = 3 + index * 0.6,
			speed = 0.12 + index * 0.015,
			phase = index * 0.9,
			bob = 0.1,
			isFish = false,
		})
	end

	makeHeron(root, -65, -610, 1)
	makeHeron(root, 64, -638, 2)

	local deerCenters = {
		Vector3.new(-120, 0, -110),
		Vector3.new(80, 0, -120),
		Vector3.new(-220, 0, -140),
		Vector3.new(210, 0, -135),
	}
	for index, center in deerCenters do
		local deer = makeSikaDeer(root, center, index)
		table.insert(roamers, {
			model = deer,
			center = center,
			radius = 18 + index * 4,
			speed = 0.08 + (index % 2) * 0.03,
			phase = index * 1.5,
			groundY = center.Y,
		})
	end
end

local function updateWildlife()
	local now = os.clock()

	for _, swimmer in swimmers do
		if swimmer.model.Parent then
			local angle = swimmer.phase + now * swimmer.speed
			local bobOffset = math.sin(now * 2.2 + swimmer.phase) * swimmer.bob
			local position = swimmer.center
				+ Vector3.new(
					math.cos(angle) * swimmer.radiusX,
					bobOffset,
					math.sin(angle) * swimmer.radiusZ
				)
			local nextPosition = swimmer.center
				+ Vector3.new(math.cos(angle + 0.05) * swimmer.radiusX, bobOffset, math.sin(angle + 0.05) * swimmer.radiusZ)

			local targetCFrame = CFrame.lookAt(position, nextPosition)

			if swimmer.isFish then
				local wiggle = math.sin(now * 8 + swimmer.phase * 3) * math.rad(12)
				targetCFrame *= CFrame.Angles(0, wiggle, 0)
			else
				local duckBob = math.sin(now * 3 + swimmer.phase) * math.rad(4)
				targetCFrame *= CFrame.Angles(duckBob, 0, 0)
			end

			swimmer.model:PivotTo(targetCFrame)
		end
	end

	for _, roamer in roamers do
		if roamer.model.Parent then
			local angle = roamer.phase + now * roamer.speed
			local moveX = roamer.center.X + math.cos(angle) * roamer.radius
			local moveZ = roamer.center.Z + math.sin(angle * 0.7) * (roamer.radius * 0.6)
			local gY = terrainHeight(moveX, moveZ, roamer.groundY)
			local position = Vector3.new(moveX, gY, moveZ)

			local nextX = roamer.center.X + math.cos(angle + 0.04) * roamer.radius
			local nextZ = roamer.center.Z + math.sin((angle + 0.04) * 0.7) * (roamer.radius * 0.6)
			local nextGY = terrainHeight(nextX, nextZ, gY)
			local nextPosition = Vector3.new(nextX, nextGY, nextZ)

			local look = CFrame.lookAt(position, nextPosition)

			local headDip = math.sin(now * 0.8 + roamer.phase)
			if headDip > 0.6 then
				look *= CFrame.Angles(math.rad(18), 0, 0)
			end

			roamer.model:PivotTo(look)
		end
	end
end

function WorldWildlifeService.init()
	task.defer(buildWildlife)
	RunService.Heartbeat:Connect(updateWildlife)
end

return WorldWildlifeService
