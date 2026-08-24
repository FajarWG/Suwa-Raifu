--!strict

-- Suwa-style lake fireworks. Safe (non-damaging), driven by a rhythm director
-- so the show mixes single shells, salvos, sequenced rows and finales instead
-- of firing one identical shell on a fixed beat.
--
-- Visuals/audio are Creator Store assets, choreographed by this script:
--   spark texture  14365285883  (particle model 16396991939, no scripts)
--   report sounds  160248xxx    (Stickmasterluke firework pack, audited clean)
--   deep mortar    9114361763   (Pro Sound Effects)
--
-- Launch points: any BasePart with the attribute FireworksLaunchPoint, or any
-- part whose name starts with "Launcher". Creator Store barges work as-is.
-- Console: any BasePart with the attribute FireworksConsole; if none exists a
-- placeholder is built on the shore so the show is always reachable.

local Debris = game:GetService('Debris')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')

local SHOW_CLOCK_TIME = 20.2

local NORMAL_DURATION = 10 * 60
local AUGUST_15_DURATION = 60 * 60

local SPARK_TEXTURE = 'rbxassetid://14365285883'
local MORTAR_SOUND = 'rbxassetid://9114361763'
local WHISTLE_SOUND = 'rbxassetid://160247625'
local CRACKLE_SOUND = 'rbxassetid://100559751053348'
local BANG_SOUNDS = {
	'rbxassetid://160248459',
	'rbxassetid://160248479',
	'rbxassetid://160248493',
	'rbxassetid://160248505',
}

local FireworksFestivalService = {}
local running = false

local palette = {
	Color3.fromRGB(255, 87, 72),
	Color3.fromRGB(255, 208, 74),
	Color3.fromRGB(106, 196, 255),
	Color3.fromRGB(129, 255, 159),
	Color3.fromRGB(225, 125, 255),
	Color3.fromRGB(255, 245, 220),
	Color3.fromRGB(255, 150, 60),
}

type ShellClass = {
	apexLow: number,
	apexHigh: number,
	radius: number,
	particles: number,
	volume: number,
	pitch: number,
	range: number,
	climb: number,
}

local SHELL_CLASSES: { [string]: ShellClass } = {
	small = {
		apexLow = 78,
		apexHigh = 104,
		radius = 20,
		particles = 150,
		volume = 1.6,
		pitch = 1.0,
		range = 380,
		climb = 0.95,
	},
	large = {
		apexLow = 118,
		apexHigh = 152,
		radius = 36,
		particles = 320,
		volume = 3.2,
		pitch = 0.72,
		range = 700,
		climb = 1.2,
	},
	huge = {
		apexLow = 162,
		apexHigh = 205,
		radius = 55,
		particles = 520,
		volume = 5.0,
		pitch = 0.55,
		range = 1000,
		climb = 1.45,
	},
}

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

local function randomRange(low: number, high: number): number
	return low + math.random() * (high - low)
end

--=============================================================================
-- Audio
--=============================================================================

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
	sound.RollOffMinDistance = 30
	sound.RollOffMaxDistance = range
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 8)
end

-- Layered report: a sharp crack over a deep, slightly delayed mortar rumble,
-- which is what makes a big shell read as big rather than just loud.
local function playBoom(anchor: BasePart, class: ShellClass)
	playPositionalSound(anchor, pick(BANG_SOUNDS), class.volume, class.pitch, class.range)
	if class.volume >= 3 then
		task.delay(0.05, function()
			if anchor.Parent then
				playPositionalSound(anchor, MORTAR_SOUND, class.volume * 0.85, class.pitch * 0.8, class.range * 1.2)
			end
		end)
	end
	if class.volume >= 5 then
		task.delay(0.35, function()
			if anchor.Parent then
				playPositionalSound(anchor, MORTAR_SOUND, class.volume * 0.5, 0.35, class.range * 1.4)
			end
		end)
	end
	-- Crackling tail as the stars burn out.
	task.delay(0.5, function()
		if anchor.Parent then
			playPositionalSound(anchor, CRACKLE_SOUND, class.volume * 0.35, randomRange(0.9, 1.2), class.range * 0.7)
		end
	end)
end

--=============================================================================
-- Burst rendering
--=============================================================================

local function makeNeonPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
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

-- Per-style particle behaviour. Drag + downward acceleration is what separates
-- a crisp peony from a slow, drooping willow.
type BurstStyle = {
	speedLow: number,
	speedHigh: number,
	lifeLow: number,
	lifeHigh: number,
	drag: number,
	gravity: number,
	sizeScale: number,
}

local BURST_STYLES: { [string]: BurstStyle } = {
	peony = { speedLow = 55, speedHigh = 85, lifeLow = 1.3, lifeHigh = 1.9, drag = 6, gravity = 8, sizeScale = 1.0 },
	chrysanthemum = {
		speedLow = 48,
		speedHigh = 78,
		lifeLow = 2.1,
		lifeHigh = 2.9,
		drag = 5,
		gravity = 20,
		sizeScale = 1.1,
	},
	willow = { speedLow = 34, speedHigh = 56, lifeLow = 3.2, lifeHigh = 4.6, drag = 3, gravity = 34, sizeScale = 1.25 },
	scatter = { speedLow = 75, speedHigh = 125, lifeLow = 0.8, lifeHigh = 1.5, drag = 9, gravity = 12, sizeScale = 0.7 },
}

local function emitParticleBurst(parent: Instance, position: Vector3, color: Color3, class: ShellClass, styleName: string)
	local style = BURST_STYLES[styleName] or BURST_STYLES.peony
	local host = makeNeonPart(parent, 'BurstOrigin', Vector3.one * 0.2, CFrame.new(position), color)
	host.Transparency = 1

	local emitter = Instance.new('ParticleEmitter')
	emitter.Name = 'Stars'
	emitter.Texture = SPARK_TEXTURE
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Brightness = 8
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	-- Two-tone stars: big Japanese shells change colour as they burn.
	local second = if math.random() < 0.55 then pick(palette) else color
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 252, 240)),
		ColorSequenceKeypoint.new(0.25, color),
		ColorSequenceKeypoint.new(1, second),
	})
	-- Small stars, many of them: large sprites read as clumps of mini-fireworks
	-- rather than one shell opening.
	local starSize = class.radius * 0.018 * style.sizeScale
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, starSize * 1.4),
		NumberSequenceKeypoint.new(0.7, starSize),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.65, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(style.lifeLow, style.lifeHigh)
	emitter.Speed = NumberRange.new(style.speedLow * (class.radius / 36), style.speedHigh * (class.radius / 36))
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = style.drag
	emitter.Acceleration = Vector3.new(0, -style.gravity, 0)
	emitter.Rate = 0
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-40, 40)
	emitter.Enabled = false
	emitter.Parent = host

	emitter:Emit(class.particles)
	Debris:AddItem(host, style.lifeHigh + 1.5)
end

-- Parametric heart, drawn in a vertical plane so it reads from the shore.
local function heartOffsets(count: number, radius: number): { Vector3 }
	local offsets = table.create(count)
	local scale = radius / 15
	for index = 1, count do
		local t = (index / count) * math.pi * 2
		local sin = math.sin(t)
		local x = 16 * sin * sin * sin
		local y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
		offsets[index] = Vector3.new(x * scale, y * scale, randomRange(-1.5, 1.5))
	end
	return offsets
end

-- Flat ring, tilted so it never reads as a straight line.
local function ringOffsets(count: number, radius: number): { Vector3 }
	local offsets = table.create(count)
	local rotation = CFrame.Angles(randomRange(0.25, 0.6), randomRange(0, math.pi), randomRange(0.1, 0.35))
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		local flat = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		offsets[index] = rotation:VectorToWorldSpace(flat)
	end
	return offsets
end

-- Shaped shells need stars at exact points, so these are placed individually
-- and each carries a small spark emitter for the glow.
local function emitShapedBurst(parent: Instance, position: Vector3, color: Color3, class: ShellClass, shapeName: string)
	local count = math.clamp(math.floor(class.particles / 3), 20, 64)
	local offsets = if shapeName == 'heart'
		then heartOffsets(count, class.radius)
		else ringOffsets(count, class.radius)

	for _, offset in offsets do
		local target = position + offset
		local star = makeNeonPart(parent, 'Star', Vector3.one * (class.radius * 0.05), CFrame.new(position), color)
		star.Shape = Enum.PartType.Ball

		local emitter = Instance.new('ParticleEmitter')
		emitter.Texture = SPARK_TEXTURE
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Brightness = 6
		emitter.Color = ColorSequence.new(color)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, class.radius * 0.05),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Lifetime = NumberRange.new(0.4, 0.8)
		emitter.Speed = NumberRange.new(0, 2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Rate = 30
		emitter.Parent = star

		-- Snap out to the shape, hold it, then fade.
		TweenService:Create(star, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(target),
		}):Play()
		task.delay(1.5, function()
			if star.Parent then
				emitter.Enabled = false
				TweenService:Create(star, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = CFrame.new(target - Vector3.new(0, class.radius * 0.3, 0)),
					Transparency = 1,
				}):Play()
			end
		end)
	end
end

local SHAPES = {
	{ name = 'peony', shaped = false, weight = 26 },
	{ name = 'chrysanthemum', shaped = false, weight = 18 },
	{ name = 'willow', shaped = false, weight = 18 },
	{ name = 'scatter', shaped = false, weight = 16 },
	{ name = 'ring', shaped = true, weight = 12 },
	{ name = 'heart', shaped = true, weight = 10 },
}

local SHAPE_WEIGHT_TOTAL = 0
for _, shape in SHAPES do
	SHAPE_WEIGHT_TOTAL += shape.weight
end

local function pickShape()
	local roll = math.random() * SHAPE_WEIGHT_TOTAL
	for _, shape in SHAPES do
		roll -= shape.weight
		if roll <= 0 then
			return shape
		end
	end
	return SHAPES[1]
end

local function burst(position: Vector3, color: Color3, class: ShellClass, shape: any)
	local effect = Instance.new('Model')
	effect.Name = `SafeFireworkBurst_{shape.name}`
	effect.Parent = workspace

	local anchor = makeNeonPart(effect, 'SoundAnchor', Vector3.one * 0.2, CFrame.new(position), color)
	anchor.Transparency = 1
	playBoom(anchor, class)

	-- Opening flash.
	local flash = makeNeonPart(
		effect,
		'Flash',
		Vector3.one * (class.radius * 0.3),
		CFrame.new(position),
		Color3.fromRGB(255, 252, 236)
	)
	flash.Shape = Enum.PartType.Ball
	TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * (class.radius * 1.1),
		Transparency = 1,
	}):Play()

	if shape.shaped then
		emitShapedBurst(effect, position, color, class, shape.name)
		Debris:AddItem(effect, 5)
	else
		emitParticleBurst(effect, position, color, class, shape.name)
		Debris:AddItem(effect, 7)
	end
end

local function launchShell(launcher: BasePart, className: string?)
	local class = SHELL_CLASSES[className or 'small'] or SHELL_CLASSES.small
	local shape = pickShape()
	local color = pick(palette)

	local origin = launcher.Position + Vector3.new(0, 2, 0)
	local destination = origin
		+ Vector3.new(randomRange(-32, 32), randomRange(class.apexLow, class.apexHigh), randomRange(-28, 28))

	local shell = makeNeonPart(workspace, 'FireworkShell', Vector3.new(0.7, 2.2, 0.7), CFrame.new(origin), color)
	playPositionalSound(shell, WHISTLE_SOUND, class.volume * 0.3, randomRange(0.85, 1.15), 280)

	local attachment0 = Instance.new('Attachment')
	attachment0.Position = Vector3.new(0, -0.9, 0)
	attachment0.Parent = shell
	local attachment1 = Instance.new('Attachment')
	attachment1.Position = Vector3.new(0, 0.7, 0)
	attachment1.Parent = shell

	local trail = Instance.new('Trail')
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.5
	trail.LightEmission = 1
	trail.WidthScale = NumberSequence.new(1, 0.1)
	trail.Parent = shell

	local flight = TweenService:Create(
		shell,
		TweenInfo.new(class.climb, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(destination) }
	)
	flight:Play()
	flight.Completed:Once(function()
		if shell.Parent then
			burst(destination, color, class, shape)
			shell:Destroy()
		end
	end)

	Debris:AddItem(shell, class.climb + 0.5)
end

--=============================================================================
-- Rhythm director
--=============================================================================

local function collectLaunchers(): { BasePart }
	local result: { BasePart } = {}
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('BasePart') then
			if descendant:GetAttribute('FireworksLaunchPoint') or descendant.Name:match('^Launcher') then
				table.insert(result, descendant)
			end
		end
	end
	return result
end

-- Left-to-right along the barge, so sequenced volleys read as a real row.
local function orderedLaunchers(launchers: { BasePart }): { BasePart }
	local ordered = table.clone(launchers)
	table.sort(ordered, function(a, b)
		return a.Position.X < b.Position.X
	end)
	return ordered
end

-- Each pattern fires its shells and returns how long to rest afterwards.
local PATTERNS = {
	-- A lone shell: the breathing space between bigger moments.
	{
		weight = 20,
		run = function(launchers: { BasePart }): number
			launchShell(pick(launchers), if math.random() < 0.3 then 'large' else 'small')
			return randomRange(1.2, 2.3)
		end,
	},
	-- A quick cluster from scattered tubes.
	{
		weight = 24,
		run = function(launchers: { BasePart }): number
			for index = 1, math.random(3, 6) do
				task.delay((index - 1) * randomRange(0.08, 0.2), function()
					launchShell(pick(launchers), if math.random() < 0.35 then 'large' else 'small')
				end)
			end
			return randomRange(1.9, 3.0)
		end,
	},
	-- Sequenced row down the barge (deretan).
	{
		weight = 18,
		run = function(launchers: { BasePart }): number
			local ordered = orderedLaunchers(launchers)
			local reverse = math.random() < 0.5
			for index, launcher in ordered do
				local slot = if reverse then #ordered - index + 1 else index
				task.delay((slot - 1) * randomRange(0.14, 0.22), function()
					launchShell(launcher, 'small')
				end)
			end
			return randomRange(2.1, 3.2)
		end,
	},
	-- One big shell, given room to breathe.
	{
		weight = 16,
		run = function(launchers: { BasePart }): number
			launchShell(pick(launchers), 'huge')
			return randomRange(2.8, 4.2)
		end,
	},
	-- Twin large shells opening together.
	{
		weight = 12,
		run = function(launchers: { BasePart }): number
			local ordered = orderedLaunchers(launchers)
			launchShell(ordered[1], 'large')
			task.delay(0.06, function()
				launchShell(ordered[#ordered], 'large')
			end)
			return randomRange(2.3, 3.4)
		end,
	},
	-- Starmine: rolling wall of shells, the crowd-pleaser.
	{
		weight = 10,
		run = function(launchers: { BasePart }): number
			local ordered = orderedLaunchers(launchers)
			for wave = 0, 2 do
				for index, launcher in ordered do
					task.delay(wave * 0.55 + (index - 1) * 0.09, function()
						launchShell(launcher, if wave == 2 then 'large' else 'small')
					end)
				end
			end
			task.delay(1.95, function()
				launchShell(pick(ordered), 'huge')
			end)
			return randomRange(3.8, 5.2)
		end,
	},
}

local PATTERN_WEIGHT_TOTAL = 0
for _, pattern in PATTERNS do
	PATTERN_WEIGHT_TOTAL += pattern.weight
end

local function pickPattern()
	local roll = math.random() * PATTERN_WEIGHT_TOTAL
	for _, pattern in PATTERNS do
		roll -= pattern.weight
		if roll <= 0 then
			return pattern
		end
	end
	return PATTERNS[1]
end

--=============================================================================
-- Console
--=============================================================================

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

-- A real hanabi taikai runs after dark, and the stars simply do not read
-- against a bright sky. Dusk is eased in for the show and restored after.
local function fadeSkyToNight(): number
	local before = Lighting.ClockTime
	TweenService:Create(Lighting, TweenInfo.new(6, Enum.EasingStyle.Sine), { ClockTime = SHOW_CLOCK_TIME }):Play()
	return before
end

local function restoreSky(before: number)
	TweenService:Create(Lighting, TweenInfo.new(10, Enum.EasingStyle.Sine), { ClockTime = before }):Play()
end

local function findTaggedConsole(): BasePart?
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('BasePart') and descendant:GetAttribute('FireworksConsole') then
			return descendant
		end
	end
	return nil
end

local function terrainHeight(x: number, z: number): number?
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), parameters)
	return if result then result.Position.Y else nil
end

-- Nearest dry land to the launchers, searched as widening rings so the console
-- lands on the shore rather than out on the lake.
local function findConsoleSpot(launchers: { BasePart }): Vector3
	local centre = Vector3.zero
	for _, launcher in launchers do
		centre += launcher.Position
	end
	centre /= #launchers

	for _, distance in { 26, 42, 60, 85, 115, 150 } do
		for step = 0, 11 do
			local angle = (step / 12) * math.pi * 2
			local x = centre.X + math.cos(angle) * distance
			local z = centre.Z + math.sin(angle) * distance
			local y = terrainHeight(x, z)
			if y and y > 1.5 then
				return Vector3.new(x, y, z)
			end
		end
	end
	return centre + Vector3.new(0, 3, 30)
end

-- Placeholder console so the show is always reachable before a Creator Store
-- model is dropped in. Tag your own part with FireworksConsole to replace it.
local function buildFallbackConsole(launchers: { BasePart }): BasePart
	local previous = workspace:FindFirstChild('FestivalFireworksControl')
	if previous then
		previous:Destroy()
	end

	local spot = findConsoleSpot(launchers)
	local console = Instance.new('Model')
	console.Name = 'FestivalFireworksControl'
	console.Parent = workspace

	local base = makeNeonPart(
		console,
		'FireworksConsole',
		Vector3.new(5.5, 3.2, 4),
		CFrame.new(spot + Vector3.new(0, 1.9, 0)),
		Color3.fromRGB(74, 78, 76)
	)
	base.Material = Enum.Material.Metal
	base.CanCollide = true
	base.CanQuery = true
	return base
end

local function attachConsole(base: BasePart)
	local oldPrompt = base:FindFirstChild('StartFireworksPrompt')
	if oldPrompt then
		oldPrompt:Destroy()
	end
	local oldBillboard = base:FindFirstChild('FestivalStatus')
	if oldBillboard then
		oldBillboard:Destroy()
	end

	local gui = Instance.new('BillboardGui')
	gui.Name = 'FestivalStatus'
	gui.Size = UDim2.fromOffset(190, 44)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 70
	gui.Adornee = base
	gui.Parent = base

	local label = Instance.new('TextLabel')
	label.Name = 'StatusLabel'
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(26, 39, 43)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.fromRGB(246, 232, 188)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = `花火大会 • Ready ({formatRemaining(showDuration())})`
	label.Parent = gui

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
		local skyBefore = fadeSkyToNight()
		local finishAt = os.clock() + showDuration()
		task.spawn(function()
			while running and os.clock() < finishAt do
				local remaining = math.max(0, math.ceil(finishAt - os.clock()))
				label.Text = `花火大会 • {formatRemaining(remaining)}`
				task.wait(pickPattern().run(launchers))
			end
			running = false
			restoreSky(skyBefore)
			prompt.Enabled = true
			label.Text = `花火大会 • Ready ({formatRemaining(showDuration())})`
		end)
	end)
end

function FireworksFestivalService.init()
	local launchers = collectLaunchers()
	if #launchers == 0 then
		warn(
			'[Fireworks] No launch points found. Tag a part with the attribute '
				.. 'FireworksLaunchPoint, or name it "Launcher...".'
		)
		return
	end
	attachConsole(findTaggedConsole() or buildFallbackConsole(launchers))
end

return FireworksFestivalService
