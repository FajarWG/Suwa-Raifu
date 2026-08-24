--!strict

-- Suwa-style lake fireworks. Safe (non-damaging), and driven by a rhythm
-- director so the show mixes single shells, salvos, sequenced rows and finales
-- instead of firing one identical shell on a fixed beat.
--
-- Launch points: any BasePart with the attribute FireworksLaunchPoint, or any
-- part whose name starts with "Launcher". Creator Store barges therefore work
-- as-is, without tagging anything by hand.

local Debris = game:GetService('Debris')
local TweenService = game:GetService('TweenService')

local NORMAL_DURATION = 10 * 60
local AUGUST_15_DURATION = 60 * 60

local BOOM_SOUND = 'rbxasset://sounds/Rocket shot.wav'
local WHOOSH_SOUND = 'rbxasset://sounds/Rocket whoosh 01.wav'

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

-- How high a shell climbs, how wide it opens, and how hard it lands.
type ShellClass = {
	apexLow: number,
	apexHigh: number,
	radius: number,
	sparks: number,
	sparkSize: number,
	life: number,
	volume: number,
	pitch: number,
	range: number,
	climb: number,
}

local SHELL_CLASSES: { [string]: ShellClass } = {
	small = {
		apexLow = 72,
		apexHigh = 96,
		radius = 18,
		sparks = 26,
		sparkSize = 0.34,
		life = 1.3,
		volume = 1.0,
		pitch = 1.05,
		range = 340,
		climb = 0.95,
	},
	large = {
		apexLow = 112,
		apexHigh = 148,
		radius = 34,
		sparks = 54,
		sparkSize = 0.55,
		life = 2.0,
		volume = 2.2,
		pitch = 0.62,
		range = 640,
		climb = 1.2,
	},
	huge = {
		apexLow = 158,
		apexHigh = 198,
		radius = 52,
		sparks = 76,
		sparkSize = 0.78,
		life = 2.7,
		volume = 3.3,
		pitch = 0.42,
		range = 920,
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
-- Burst shapes: each returns offsets from the burst centre.
--=============================================================================

-- Even spread in every direction (fibonacci sphere) — the classic peony.
local function sphereOffsets(count: number, radius: number): { Vector3 }
	local offsets = table.create(count)
	local golden = math.pi * (3 - math.sqrt(5))
	for index = 0, count - 1 do
		local y = 1 - (index / math.max(1, count - 1)) * 2
		local ring = math.sqrt(math.max(0, 1 - y * y))
		local theta = golden * index
		local jitter = randomRange(0.86, 1.14)
		offsets[index + 1] = Vector3.new(math.cos(theta) * ring, y, math.sin(theta) * ring) * radius * jitter
	end
	return offsets
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
	local tilt = randomRange(0.25, 0.6)
	local rotation = CFrame.Angles(tilt, randomRange(0, math.pi), tilt * 0.5)
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		local flat = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		offsets[index] = rotation:VectorToWorldSpace(flat)
	end
	return offsets
end

-- Wide, slightly flattened dome — the base for drooping willow shells.
local function willowOffsets(count: number, radius: number): { Vector3 }
	local offsets = table.create(count)
	for index = 1, count do
		local angle = (index / count) * math.pi * 2 + randomRange(-0.2, 0.2)
		local lift = randomRange(0.15, 1.0)
		local reach = radius * randomRange(0.75, 1.25)
		offsets[index] = Vector3.new(math.cos(angle) * reach, lift * radius * 0.55, math.sin(angle) * reach)
	end
	return offsets
end

-- Dense scatter of short-lived flecks — the crackle/scatter shell.
local function scatterOffsets(count: number, radius: number): { Vector3 }
	local offsets = table.create(count)
	for index = 1, count do
		local direction = Vector3.new(randomRange(-1, 1), randomRange(-0.7, 1), randomRange(-1, 1))
		if direction.Magnitude < 0.05 then
			direction = Vector3.yAxis
		end
		offsets[index] = direction.Unit * radius * randomRange(0.35, 1.1)
	end
	return offsets
end

-- shape -> how the sparks travel after they open.
-- droop: how far they sag while flying. fall: extra slow drop afterwards.
local SHAPES = {
	{ name = 'peony', build = sphereOffsets, droop = 0.30, fall = 0.0, weight = 26 },
	{ name = 'chrysanthemum', build = sphereOffsets, droop = 0.55, fall = 0.9, weight = 18 },
	{ name = 'willow', build = willowOffsets, droop = 0.35, fall = 2.4, weight = 18 },
	{ name = 'ring', build = ringOffsets, droop = 0.18, fall = 0.0, weight = 12 },
	{ name = 'scatter', build = scatterOffsets, droop = 0.45, fall = 0.5, weight = 16 },
	{ name = 'heart', build = heartOffsets, droop = 0.12, fall = 0.0, weight = 10 },
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

--=============================================================================
-- Rendering
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
	sound.RollOffMinDistance = 25
	sound.RollOffMaxDistance = range
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 6)
end

-- Layered report: a sharp crack over a deep, slightly delayed rumble.
local function playBoom(anchor: BasePart, class: ShellClass)
	playPositionalSound(anchor, BOOM_SOUND, class.volume, class.pitch, class.range)
	if class.volume >= 2 then
		task.delay(0.09, function()
			if anchor.Parent then
				playPositionalSound(anchor, BOOM_SOUND, class.volume * 0.8, class.pitch * 0.62, class.range * 1.15)
			end
		end)
		task.delay(0.26, function()
			if anchor.Parent then
				playPositionalSound(anchor, BOOM_SOUND, class.volume * 0.45, class.pitch * 0.5, class.range * 1.3)
			end
		end)
	end
end

local function burst(position: Vector3, color: Color3, class: ShellClass, shape: any)
	local effect = Instance.new('Model')
	effect.Name = `SafeFireworkBurst_{shape.name}`
	effect.Parent = workspace

	local anchor = makeNeonPart(effect, 'SoundAnchor', Vector3.new(0.2, 0.2, 0.2), CFrame.new(position), color)
	anchor.Transparency = 1
	playBoom(anchor, class)

	-- Opening flash.
	local flash = makeNeonPart(
		effect,
		'Flash',
		Vector3.one * (class.radius * 0.32),
		CFrame.new(position),
		Color3.fromRGB(255, 252, 236)
	)
	flash.Shape = Enum.PartType.Ball
	TweenService:Create(flash, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * (class.radius * 1.05),
		Transparency = 1,
	}):Play()

	-- A second colour on big shells reads as a layered Japanese shell.
	local innerColor = if class.volume >= 2 and math.random() < 0.55 then pick(palette) else color

	local offsets = shape.build(class.sparks, class.radius)
	local totalLife = class.life + shape.fall

	for index, offset in offsets do
		local sparkColor = if index % 3 == 0 then innerColor else color
		local target = position + offset
		local length = class.sparkSize * (if shape.name == 'willow' then 7 else 4.5)

		local spark = makeNeonPart(
			effect,
			'Spark',
			Vector3.new(class.sparkSize, class.sparkSize, length),
			CFrame.lookAt(position, target),
			sparkColor
		)

		-- Stage 1: fly out to the shape.
		local outward = TweenService:Create(
			spark,
			TweenInfo.new(class.life * 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ CFrame = CFrame.lookAt(target, target + offset), Transparency = 0.15 }
		)
		outward:Play()

		-- Stage 2: sag, then (for willow/chrysanthemum) drift down and burn out.
		outward.Completed:Once(function()
			if not spark.Parent then
				return
			end
			local drop = class.radius * (shape.droop + shape.fall * 0.75)
			local settled = target - Vector3.new(0, drop, 0)
			TweenService:Create(
				spark,
				TweenInfo.new(totalLife * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ CFrame = CFrame.lookAt(settled, settled - Vector3.yAxis), Transparency = 1 }
			):Play()
		end)
	end

	Debris:AddItem(effect, totalLife + 1.2)
end

local function launchShell(launcher: BasePart, className: string?)
	local class = SHELL_CLASSES[className or 'small'] or SHELL_CLASSES.small
	local shape = pickShape()
	local color = pick(palette)

	local origin = launcher.Position + Vector3.new(0, 2, 0)
	local destination = origin
		+ Vector3.new(
			randomRange(-30, 30),
			randomRange(class.apexLow, class.apexHigh),
			randomRange(-26, 26)
		)

	local shell = makeNeonPart(
		workspace,
		'FireworkShell',
		Vector3.new(class.sparkSize * 1.2, class.sparkSize * 3.4, class.sparkSize * 1.2),
		CFrame.new(origin),
		color
	)
	playPositionalSound(shell, WHOOSH_SOUND, class.volume * 0.32, 1, 220)

	local attachment0 = Instance.new('Attachment')
	attachment0.Position = Vector3.new(0, -0.8, 0)
	attachment0.Parent = shell
	local attachment1 = Instance.new('Attachment')
	attachment1.Position = Vector3.new(0, 0.6, 0)
	attachment1.Parent = shell

	local trail = Instance.new('Trail')
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.45
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

	Debris:AddItem(shell, class.climb + 0.4)
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
	-- A lone shell, the breathing space between bigger moments.
	{
		weight = 22,
		run = function(launchers: { BasePart }): number
			launchShell(pick(launchers), if math.random() < 0.3 then 'large' else 'small')
			return randomRange(1.1, 2.2)
		end,
	},
	-- A quick cluster from scattered tubes.
	{
		weight = 24,
		run = function(launchers: { BasePart }): number
			local count = math.random(3, 6)
			for index = 1, count do
				task.delay((index - 1) * randomRange(0.08, 0.2), function()
					launchShell(pick(launchers), if math.random() < 0.35 then 'large' else 'small')
				end)
			end
			return randomRange(1.8, 3.0)
		end,
	},
	-- Sequenced row down the barge (senkou / deretan).
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
			return randomRange(2.0, 3.2)
		end,
	},
	-- One big shell, given room to breathe.
	{
		weight = 16,
		run = function(launchers: { BasePart }): number
			launchShell(pick(launchers), 'huge')
			return randomRange(2.6, 4.0)
		end,
	},
	-- Twin large shells opening together.
	{
		weight = 12,
		run = function(launchers: { BasePart }): number
			local ordered = orderedLaunchers(launchers)
			local left = ordered[1]
			local right = ordered[#ordered]
			launchShell(left, 'large')
			task.delay(0.06, function()
				launchShell(right, 'large')
			end)
			return randomRange(2.2, 3.4)
		end,
	},
	-- Starmine: rolling wall of shells, the crowd-pleaser.
	{
		weight = 8,
		run = function(launchers: { BasePart }): number
			local ordered = orderedLaunchers(launchers)
			for wave = 0, 2 do
				for index, launcher in ordered do
					task.delay(wave * 0.55 + (index - 1) * 0.09, function()
						launchShell(launcher, if wave == 2 then 'large' else 'small')
					end)
				end
			end
			task.delay(1.9, function()
				launchShell(pick(ordered), 'huge')
			end)
			return randomRange(3.6, 5.0)
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

-- Any part tagged FireworksConsole, otherwise the old greybox console base if
-- it is still lying around, so the show stays reachable either way.
local function findConsoleAnchor(): BasePart?
	local fallback: BasePart? = nil
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('BasePart') then
			if descendant:GetAttribute('FireworksConsole') then
				return descendant
			end
			if not fallback and descendant.Name == 'FireworksConsole' then
				fallback = descendant
			end
		end
	end
	return fallback
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
		local finishAt = os.clock() + showDuration()
		task.spawn(function()
			while running and os.clock() < finishAt do
				local remaining = math.max(0, math.ceil(finishAt - os.clock()))
				label.Text = `花火大会 • {formatRemaining(remaining)}`
				local rest = pickPattern().run(launchers)
				task.wait(rest)
			end
			running = false
			prompt.Enabled = true
			label.Text = `花火大会 • Ready ({formatRemaining(showDuration())})`
		end)
	end)
end

function FireworksFestivalService.init()
	local anchor = findConsoleAnchor()
	if anchor then
		attachConsole(anchor)
	else
		warn(
			'[Fireworks] No console found. Tag any part with the attribute '
				.. 'FireworksConsole (boolean) to place the festival control.'
		)
	end
end

return FireworksFestivalService
