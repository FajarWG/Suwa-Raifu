--!strict

-- Safe, non-damaging island fireworks. A regular show runs for ten minutes;
-- Suwa's August 15 festival mode automatically extends it to one hour in JST.

local Debris = game:GetService('Debris')
local TweenService = game:GetService('TweenService')

local NORMAL_DURATION = 10 * 60
local AUGUST_15_DURATION = 60 * 60
local LAUNCH_INTERVAL = 1.15

local FireworksFestivalService = {}
local running = false

local palette = {
	Color3.fromRGB(255, 87, 72),
	Color3.fromRGB(255, 208, 74),
	Color3.fromRGB(106, 196, 255),
	Color3.fromRGB(129, 255, 159),
	Color3.fromRGB(225, 125, 255),
}

local function terrainHeight(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 90, z), Vector3.new(0, -200, 0), parameters)
	return if result then result.Position.Y else fallback
end

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local object = Instance.new('Part')
	object.Name = name
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = Enum.Material.Neon
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.CastShadow = false
	object.Parent = parent
	return object
end

local function collectLaunchers(): { BasePart }
	local result: { BasePart } = {}
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('BasePart') and descendant:GetAttribute('FireworksLaunchPoint') then
			table.insert(result, descendant)
		end
	end
	return result
end

local function playPositionalSound(
	parent: BasePart,
	soundId: string,
	volume: number,
	playbackSpeed: number,
	range: number
)
	local sound = Instance.new('Sound')
	sound.Name = 'FireworkSound'
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = playbackSpeed
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 18
	sound.RollOffMaxDistance = range
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 5)
end

local function burst(position: Vector3, color: Color3, isLarge: boolean)
	local effect = Instance.new('Model')
	effect.Name = if isLarge then 'LargeSafeFireworkBurst' else 'SmallSafeFireworkBurst'
	effect.Parent = workspace
	local soundAnchor = makePart(effect, 'SoundAnchor', Vector3.new(0.2, 0.2, 0.2), CFrame.new(position), color)
	soundAnchor.Transparency = 1
	playPositionalSound(
		soundAnchor,
		'rbxasset://sounds/Rocket shot.wav',
		if isLarge then 1.25 else 0.72,
		if isLarge then 0.78 else 1.2,
		if isLarge then 420 else 240
	)
	if isLarge then
		task.delay(0.12, function()
			if soundAnchor.Parent then
				playPositionalSound(soundAnchor, 'rbxasset://sounds/Rocket shot.wav', 0.85, 0.62, 440)
			end
		end)
	end

	local sparkCount = if isLarge then 34 else 14
	local baseDistance = if isLarge then 30 else 14
	for index = 1, sparkCount do
		local angle = (index / sparkCount) * math.pi * 2
		local vertical = ((index % 7) - 3) * (if isLarge then 3.2 else 1.8)
		local distance = baseDistance + (index % 5) * (if isLarge then 3.3 else 1.8)
		local direction = Vector3.new(math.cos(angle) * distance, vertical, math.sin(angle) * distance)
		local spark = makePart(
			effect,
			'Spark',
			if isLarge then Vector3.new(0.55, 0.55, 2.5) else Vector3.new(0.32, 0.32, 1.4),
			CFrame.lookAt(position, position + direction),
			color
		)
		local lifetime = if isLarge then 1.8 else 1.05
		local tween =
			TweenService:Create(spark, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = CFrame.lookAt(
					position + direction - Vector3.new(0, if isLarge then 10 else 4, 0),
					position + direction * 2
				),
				Transparency = 1,
			})
		tween:Play()
	end
	Debris:AddItem(effect, if isLarge then 2.2 else 1.4)
end

local function launchShell(launcher: BasePart)
	local isLarge = math.random() < 0.24
	local color = palette[math.random(1, #palette)]
	local origin = launcher.Position + Vector3.new(0, 2, 0)
	local destination = origin
		+ Vector3.new(
			math.random(-28, 28),
			if isLarge then math.random(105, 135) else math.random(68, 92),
			math.random(-24, 24)
		)
	local shell = makePart(
		workspace,
		if isLarge then 'LargeFireworkShell' else 'SmallFireworkShell',
		if isLarge then Vector3.new(0.72, 2.1, 0.72) else Vector3.new(0.45, 1.35, 0.45),
		CFrame.new(origin),
		color
	)
	playPositionalSound(shell, 'rbxasset://sounds/Rocket whoosh 01.wav', if isLarge then 0.62 else 0.38, 1, 180)
	local trailAttachment0 = Instance.new('Attachment')
	trailAttachment0.Position = Vector3.new(0, -0.7, 0)
	trailAttachment0.Parent = shell
	local trailAttachment1 = Instance.new('Attachment')
	trailAttachment1.Position = Vector3.new(0, 0.5, 0)
	trailAttachment1.Parent = shell
	local trail = Instance.new('Trail')
	trail.Attachment0 = trailAttachment0
	trail.Attachment1 = trailAttachment1
	trail.Color = ColorSequence.new(color)
	trail.Lifetime = 0.35
	trail.LightEmission = 1
	trail.Parent = shell
	local flight = TweenService:Create(
		shell,
		TweenInfo.new(1.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(destination) }
	)
	flight:Play()
	flight.Completed:Once(function()
		if shell.Parent then
			burst(destination, color, isLarge)
			shell:Destroy()
		end
	end)
	Debris:AddItem(shell, 1.3)
end

local function jstDate(): any
	return os.date('!*t', os.time() + 9 * 60 * 60)
end

local function showDuration(): number
	local now = jstDate()
	return if now.month == 8 and now.day == 15 then AUGUST_15_DURATION else NORMAL_DURATION
end

local function formatRemaining(seconds: number): string
	local minutes = math.floor(seconds / 60)
	return string.format('%02d:%02d', minutes, seconds % 60)
end

local function buildConsole()
	local previous = workspace:FindFirstChild('FestivalFireworksControl')
	if previous then
		previous:Destroy()
	end
	local console = Instance.new('Model')
	console.Name = 'FestivalFireworksControl'
	console:SetAttribute('NormalShowSeconds', NORMAL_DURATION)
	console:SetAttribute('August15ShowSeconds', AUGUST_15_DURATION)
	console:SetAttribute('FestivalTimezone', 'Asia/Tokyo')
	console.Parent = workspace

	local consoleGround = terrainHeight(-28, -649, 2.6)
	local consoleClearance = 0.28
	local base = makePart(
		console,
		'FireworksConsole',
		Vector3.new(5.5, 3.2, 4),
		CFrame.new(-28, consoleGround + consoleClearance + 1.6, -649),
		Color3.fromRGB(74, 78, 76)
	)
	base.Material = Enum.Material.Metal
	local screen = makePart(
		console,
		'StatusScreen',
		Vector3.new(4.4, 2.1, 0.25),
		CFrame.new(-28, consoleGround + consoleClearance + 2.1, -646.9),
		Color3.fromRGB(42, 78, 81)
	)

	local billboard = Instance.new('BillboardGui')
	billboard.Name = 'FestivalStatus'
	billboard.Size = UDim2.fromOffset(180, 42)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 65
	billboard.Adornee = screen
	billboard.Parent = screen
	local label = Instance.new('TextLabel')
	label.Name = 'StatusLabel'
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(26, 39, 43)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.fromRGB(246, 232, 188)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = `花火大会 • Ready ({formatRemaining(showDuration())})`
	label.Parent = billboard

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'StartFireworksPrompt'
	prompt.ActionText = 'Start fireworks'
	prompt.ObjectText = 'Island festival console'
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	prompt.Triggered:Connect(function()
		if running then
			return
		end
		local launchers = collectLaunchers()
		if #launchers == 0 then
			label.Text = 'Launchers are not ready'
			return
		end
		running = true
		prompt.Enabled = false
		local duration = showDuration()
		local finishAt = os.clock() + duration
		task.spawn(function()
			while running and os.clock() < finishAt do
				local remaining = math.max(0, math.ceil(finishAt - os.clock()))
				label.Text = `花火大会 • {formatRemaining(remaining)}`
				launchShell(launchers[math.random(1, #launchers)])
				task.wait(LAUNCH_INTERVAL)
			end
			running = false
			prompt.Enabled = true
			label.Text = `花火大会 • Ready ({formatRemaining(showDuration())})`
		end)
	end)
end

function FireworksFestivalService.init()
	buildConsole()
end

return FireworksFestivalService
