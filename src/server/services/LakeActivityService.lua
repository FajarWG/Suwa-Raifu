--!strict

-- Hatsushima-inspired islet, lake craft and simple fishing interactions.

local RunService = game:GetService('RunService')
local Debris = game:GetService('Debris')

local LakeActivityService = {}
local craftSpeeds: { [Model]: number } = {}
local WATERLINE_CLEARANCE = 0.75

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
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

local function ball(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local object = part(parent, name, size, cframe, color, material)
	object.Shape = Enum.PartType.Ball
	return object
end

local function cylinder(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local object = part(parent, name, size, cframe, color, material)
	object.Shape = Enum.PartType.Cylinder
	return object
end

local function makeTree(parent: Instance, position: Vector3, scale: number)
	cylinder(parent, 'TreeTrunk', Vector3.new(10 * scale, 2.2 * scale, 2.2 * scale), CFrame.new(position + Vector3.new(0, 5 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(83, 57, 39), Enum.Material.Wood)
	ball(parent, 'TreeCrown', Vector3.new(11, 9, 11) * scale, CFrame.new(position + Vector3.new(0, 12 * scale, 0)), Color3.fromRGB(52, 112, 61), Enum.Material.LeafyGrass).CanCollide = false
end

local function buildIslandDetails(root: Model)
	local island = Instance.new('Model')
	island.Name = 'HatsushimaInspiredIsland'
	island.Parent = root

	makeTree(island, Vector3.new(-12, 0, -610), 1.05)
	makeTree(island, Vector3.new(9, 0, -616), 0.9)
	makeTree(island, Vector3.new(12, 0, -598), 0.75)

	local red = Color3.fromRGB(176, 40, 35)
	part(island, 'ToriiLeftPost', Vector3.new(2, 13, 2), CFrame.new(-5, 6.5, -590), red, Enum.Material.Wood)
	part(island, 'ToriiRightPost', Vector3.new(2, 13, 2), CFrame.new(5, 6.5, -590), red, Enum.Material.Wood)
	part(island, 'ToriiTop', Vector3.new(17, 1.8, 2.4), CFrame.new(0, 13, -590), red, Enum.Material.Wood)
	part(island, 'ToriiBeam', Vector3.new(13, 1.2, 1.8), CFrame.new(0, 10.5, -590), red, Enum.Material.Wood)
	part(island, 'SmallJetty', Vector3.new(9, 1, 24), CFrame.new(0, 0.3, -568), Color3.fromRGB(112, 83, 55), Enum.Material.WoodPlanks)

	for index, x in { -8, 0, 8 } do
		local launcher = cylinder(island, `FireworkLauncher{index}`, Vector3.new(4, 1.5, 1.5), CFrame.new(x, 2, -620) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
		launcher.CanCollide = false
		launcher:SetAttribute('FireworksLaunchPoint', true)
	end
end

local function makeSeat(model: Model, cframe: CFrame, objectText: string): VehicleSeat
	local oldSeat = model:FindFirstChild('DriveSeat')
	if oldSeat then
		oldSeat:Destroy()
	end
	local seat = Instance.new('VehicleSeat')
	seat.Name = 'DriveSeat'
	seat.Size = Vector3.new(2, 0.6, 2)
	seat.CFrame = cframe
	seat.Color = Color3.fromRGB(72, 78, 82)
	seat.Material = Enum.Material.Leather
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.Parent = model

	local prompt = Instance.new('ProximityPrompt')
	prompt.ActionText = 'Board'
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
		if humanoid then
			seat:Sit(humanoid)
		end
	end)

	return seat
end

local function configureCraft(model: Model)
	local isDuckBoat = string.find(model.Name, 'DuckPedalBoat') ~= nil
	local targetLength = if isDuckBoat then 6.5 else 6
	local oldSeat = model:FindFirstChild('DriveSeat')
	if oldSeat then
		oldSeat:Destroy()
	end

	local _, initialSize = model:GetBoundingBox()
	if math.abs(initialSize.Z - targetLength) > 0.05 then
		model:ScaleTo(model:GetScale() * targetLength / initialSize.Z)
	end

	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local bottom = boundingCFrame.Y - boundingSize.Y / 2
	local lift = WATERLINE_CLEARANCE - bottom
	local oldPivot = model:GetPivot()
	model:PivotTo(CFrame.new(oldPivot.Position + Vector3.new(0, lift, 0)) * oldPivot.Rotation)
	boundingCFrame, boundingSize = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(boundingCFrame.X, 0.8, boundingCFrame.Z) * oldPivot.Rotation

	local floor = model:FindFirstChild('WaterproofCockpitFloor')
	if not floor or not floor:IsA('Part') then
		floor = part(model, 'WaterproofCockpitFloor', Vector3.new(1, 0.25, 1), CFrame.identity, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	end
	floor.Size = if isDuckBoat then Vector3.new(1.9, 0.25, 2.4) else Vector3.new(1.7, 0.25, 2.8)
	floor.Color = if isDuckBoat then Color3.fromRGB(235, 221, 181) else Color3.fromRGB(222, 234, 239)
	floor.CanCollide = false
	local floorOffset = if isDuckBoat then 0.7 else -0.45
	floor.CFrame = CFrame.new(boundingCFrame.X, WATERLINE_CLEARANCE + 0.65, boundingCFrame.Z + floorOffset) * oldPivot.Rotation

	local seatHeight = if isDuckBoat then 2.15 else 1.9
	local seatOffset = if isDuckBoat then 0.35 else 0
	makeSeat(model, CFrame.new(boundingCFrame.X, seatHeight, boundingCFrame.Z + seatOffset), if isDuckBoat then 'Duck pedal boat' else 'Lake boat')
	craftSpeeds[model] = 0
end

local function showCatch(player: Player, text: string)
	local character = player.Character
	local head = character and character:FindFirstChild('Head')
	if not head or not head:IsA('BasePart') then
		return
	end
	local gui = Instance.new('BillboardGui')
	gui.Name = 'FishingResult'
	gui.Size = UDim2.fromOffset(260, 60)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = head
	gui.Parent = head
	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(24, 45, 58)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	Debris:AddItem(gui, 3.5)
end

local function configureFishing()
	local activities = workspace:FindFirstChild('LakesideActivities')
	if not activities then
		return
	end
	for _, spot in activities:GetDescendants() do
		if spot:IsA('BasePart') and string.find(spot.Name, 'FishingSpot') then
			spot.Transparency = 1
			spot.CanCollide = false
			local prompt = spot:FindFirstChildOfClass('ProximityPrompt') or Instance.new('ProximityPrompt')
			prompt.Name = 'FishingPrompt'
			prompt.ActionText = 'Fish'
			prompt.ObjectText = 'Lake Suwa'
			prompt.HoldDuration = 2
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = spot
			prompt.Triggered:Connect(function(player)
				local catches = { 'Wakasagi caught!', 'Carp caught!', 'The fish got away...' }
				showCatch(player, catches[math.random(1, #catches)])
			end)
		end
	end
end

local function updateCraft(model: Model, deltaTime: number)
	local seat = model:FindFirstChild('DriveSeat')
	if not seat or not seat:IsA('VehicleSeat') then
		return
	end
	local speed = craftSpeeds[model] or 0
	local throttle = if seat.Occupant then seat.ThrottleFloat else 0
	local steer = if seat.Occupant then seat.SteerFloat else 0
	if math.abs(throttle) > 0.05 then
		speed = math.clamp(speed + throttle * 12 * deltaTime, -4, 16)
	else
		speed *= math.max(0, 1 - 2.8 * deltaTime)
	end
	if seat.Occupant then
		local pivot = model:GetPivot() * CFrame.Angles(0, -steer * math.rad(48) * deltaTime, 0)
		local move = pivot.LookVector * speed * deltaTime
		model:PivotTo(CFrame.new(pivot.X + move.X, 0.8, pivot.Z + move.Z) * pivot.Rotation)
	end
	craftSpeeds[model] = speed
end

local function buildLakeFeatures()
	local previous = workspace:FindFirstChild('LakeActivitySet')
	if previous then
		previous:Destroy()
	end
	local root = Instance.new('Model')
	root.Name = 'LakeActivitySet'
	root.Parent = workspace
	buildIslandDetails(root)

	local crafts = workspace:FindFirstChild('LakeCrafts')
	if crafts then
		for _, child in crafts:GetChildren() do
			if child:IsA('Model') then
				configureCraft(child)
			end
		end
	end

	local oldBarge = workspace:FindFirstChild('LakesideActivities') and workspace.LakesideActivities:FindFirstChild('FireworksLaunchBarge')
	if oldBarge then
		oldBarge:Destroy()
	end
end

function LakeActivityService.init()
	buildLakeFeatures()
	configureFishing()
	RunService.Heartbeat:Connect(function(deltaTime)
		for model in craftSpeeds do
			if model.Parent then
				updateCraft(model, deltaTime)
			else
				craftSpeeds[model] = nil
			end
		end
	end)
end

return LakeActivityService
