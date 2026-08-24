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
-- Launch points: any BasePart tagged FireworksLaunchPoint wins. With none
-- tagged, shells rise from a ring around the torii islet and lean out over the
-- water toward the lakeside park, so the show reads from both banks.
-- Console: any BasePart tagged FireworksConsole; otherwise a placeholder is
-- built on the islet so the show is always reachable.

local Debris = game:GetService('Debris')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')

local SHOW_CLOCK_TIME = 20.2

-- Festival control point: the islet's south shore, where players stand to
-- watch. Ground height is resolved from terrain at runtime, so only X/Z pinned.
local CONSOLE_SPOT_X = 4
local CONSOLE_SPOT_Z = -679

-- Launch battery: a row of tubes moored on the open water *behind* the viewing
-- spot, firing north across the lake — the way real hanabi barges are set up.
-- Shells therefore climb away from the audience rather than out of nowhere.
local BATTERY_Z = -707
local BATTERY_X_MIN = -62
local BATTERY_X_MAX = 70
local BATTERY_COUNT = 7
local BATTERY_Y = 1.6

-- Lakeside park, the far bank opposite (centre ~(0, -122)). Bursts lean this
-- way so they open over open water, framed from the islet and the park alike.
local PARK_VIEWPOINT = Vector3.new(0, 0, -122)
local PARK_LEAN_MIN = 110
local PARK_LEAN_MAX = 250

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
		apexLow = 165,
		apexHigh = 215,
		radius = 27,
		particles = 210,
		volume = 2.0,
		pitch = 0.95,
		range = 460,
		climb = 1.45,
	},
	large = {
		apexLow = 245,
		apexHigh = 315,
		radius = 50,
		particles = 470,
		volume = 3.8,
		pitch = 0.68,
		range = 820,
		climb = 1.8,
	},
	huge = {
		apexLow = 335,
		apexHigh = 425,
		radius = 80,
		particles = 780,
		volume = 5.5,
		pitch = 0.5,
		range = 1250,
		climb = 2.2,
	},
}

-- Kamuro (crown) willows burn gold and settle to amber.
local KAMURO_GOLD = Color3.fromRGB(255, 198, 96)
local KAMURO_EMBER = Color3.fromRGB(255, 128, 38)

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

-- A colour change only reads if the second colour is actually different.
local function pickDistinct(from: Color3): Color3
	for _ = 1, 8 do
		local candidate = palette[math.random(1, #palette)]
		if candidate ~= from then
			return candidate
		end
	end
	return palette[1]
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
	streak: number,
}

local BURST_STYLES: { [string]: BurstStyle } = {
	peony = { speedLow = 62, speedHigh = 84, lifeLow = 1.3, lifeHigh = 1.9, drag = 6, gravity = 8, sizeScale = 1.0, streak = 4.5 },
	chrysanthemum = {
		speedLow = 55,
		speedHigh = 76,
		lifeLow = 2.1,
		lifeHigh = 2.9,
		drag = 5,
		gravity = 20,
		sizeScale = 1.1,
		streak = 5.5,
	},
	-- Kamuro: opens, then the stars rain down and hang instead of snapping out.
	-- Low drag + long life is what keeps the curtain in the air.
	willow = { speedLow = 36, speedHigh = 54, lifeLow = 4.6, lifeHigh = 6.4, drag = 2.2, gravity = 26, sizeScale = 1.2, streak = 7.5 },
	scatter = { speedLow = 75, speedHigh = 125, lifeLow = 0.8, lifeHigh = 1.5, drag = 9, gravity = 12, sizeScale = 0.7, streak = 3.2 },
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
	emitter.Brightness = 14
	-- Real hanabi read as long radial RAYS, not dots. Aligning each star to its
	-- own velocity and squashing it along that axis is what draws the streak.
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	-- Colour change (iro-henka): hold the first colour, then switch late in the
	-- burn so the change is actually seen instead of blending into a smear.
	-- Kamuro willows stay gold and deepen to amber, the way the real ones do.
	local isWillow = styleName == 'willow'
	local first = if isWillow then KAMURO_GOLD else color
	local second = if isWillow then KAMURO_EMBER else pickDistinct(color)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 252, 240)),
		ColorSequenceKeypoint.new(0.12, first),
		ColorSequenceKeypoint.new(0.5, first),
		ColorSequenceKeypoint.new(0.74, second),
		ColorSequenceKeypoint.new(1, second),
	})
	-- Small stars, many of them: large sprites read as clumps of mini-fireworks
	-- rather than one shell opening.
	local starSize = class.radius * 0.07 * style.sizeScale
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
	-- A tight speed band keeps the shell's outer edge crisp instead of smeared.
	local speedScale = class.radius / 36
	emitter.Speed = NumberRange.new(style.speedLow * speedScale, style.speedHigh * speedScale)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = style.drag
	emitter.Acceleration = Vector3.new(0, -style.gravity, 0)
	emitter.Rate = 0
	-- Negative squash stretches along the velocity axis. Positive squashes
	-- across it, which renders the burst as horizontal bars instead of rays.
	emitter.Squash = NumberSequence.new({
		NumberSequenceKeypoint.new(0, -style.streak),
		NumberSequenceKeypoint.new(0.6, -style.streak * 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Enabled = false
	emitter.Parent = host

	emitter:Emit(class.particles)

	-- Senrin: a fine crackling shimmer riding on top of the main stars. The
	-- wide lifetime spread is what makes it twinkle rather than just glow —
	-- individual specks wink out at different moments.
	local glitter = Instance.new('ParticleEmitter')
	glitter.Name = 'Glitter'
	glitter.Texture = SPARK_TEXTURE
	glitter.LightEmission = 1
	glitter.LightInfluence = 0
	glitter.Brightness = 22
	glitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 245)),
		ColorSequenceKeypoint.new(0.6, if isWillow then KAMURO_GOLD else Color3.fromRGB(255, 240, 200)),
		ColorSequenceKeypoint.new(1, second),
	})
	local fleck = starSize * 0.28
	glitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, fleck),
		NumberSequenceKeypoint.new(0.5, fleck * 1.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	glitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.35, 0.55),
		NumberSequenceKeypoint.new(0.55, 0),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	glitter.Lifetime = NumberRange.new(style.lifeLow * 0.35, style.lifeHigh * 1.1)
	glitter.Speed = NumberRange.new(style.speedLow * 0.6 * (class.radius / 36), style.speedHigh * 1.15 * (class.radius / 36))
	glitter.SpreadAngle = Vector2.new(180, 180)
	glitter.Drag = style.drag * 1.6
	glitter.Acceleration = Vector3.new(0, -style.gravity * 0.8, 0)
	glitter.Rate = 0
	glitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	glitter.Squash = NumberSequence.new({
		NumberSequenceKeypoint.new(0, -style.streak * 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	glitter.Enabled = false
	glitter.Parent = host
	glitter:Emit(math.floor(class.particles * 0.8))

	Debris:AddItem(host, style.lifeHigh * 1.1 + 1.5)
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
	local count = math.clamp(math.floor(class.particles / 2), 40, 140)
	local offsets = if shapeName == 'heart'
		then heartOffsets(count, class.radius)
		else ringOffsets(count, class.radius)

	for _, offset in offsets do
		local target = position + offset
		local star = makeNeonPart(parent, 'Star', Vector3.one * (class.radius * 0.022), CFrame.new(position), color)
		star.Shape = Enum.PartType.Ball

		local emitter = Instance.new('ParticleEmitter')
		emitter.Texture = SPARK_TEXTURE
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Brightness = 6
		emitter.Color = ColorSequence.new(color)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, class.radius * 0.03),
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

-- Weighted so the show is mostly the classic drooping shells Suwa is known for.
-- Heart is a rare novelty: seeing it every other shell kills the effect.
local SHAPES = {
	{ name = 'willow', shaped = false, weight = 27 },
	{ name = 'peony', shaped = false, weight = 23 },
	{ name = 'chrysanthemum', shaped = false, weight = 22 },
	{ name = 'scatter', shaped = false, weight = 16 },
	{ name = 'ring', shaped = true, weight = 5 },
	{ name = 'heart', shaped = true, weight = 3 },
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

local function launchShell(launchFrom: Vector3, className: string?)
	local class = SHELL_CLASSES[className or 'small'] or SHELL_CLASSES.small
	local shape = pickShape()
	local color = pick(palette)

	local origin = launchFrom + Vector3.new(0, 2, 0)
	-- Shells lean out over the water toward the park, so the show frames well
	-- both from the islet underneath and from the lakeside promenade opposite.
	local towardPark = (PARK_VIEWPOINT - origin) * Vector3.new(1, 0, 1)
	local lean = if towardPark.Magnitude > 1 then towardPark.Unit else Vector3.zAxis
	local destination = origin
		+ lean * randomRange(PARK_LEAN_MIN, PARK_LEAN_MAX)
		+ Vector3.new(randomRange(-40, 40), randomRange(class.apexLow, class.apexHigh), randomRange(-30, 30))

	-- Muzzle flash and smoke at the tube, so the launch is visibly the source.
	local muzzle = makeNeonPart(
		workspace,
		'MuzzleFlash',
		Vector3.one * 3.2,
		CFrame.new(launchFrom),
		Color3.fromRGB(255, 226, 158)
	)
	muzzle.Shape = Enum.PartType.Ball
	TweenService:Create(muzzle, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * 8,
		Transparency = 1,
	}):Play()
	local smoke = Instance.new('ParticleEmitter')
	smoke.Texture = SPARK_TEXTURE
	smoke.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 9),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.Lifetime = NumberRange.new(0.8, 1.6)
	smoke.Speed = NumberRange.new(4, 12)
	smoke.SpreadAngle = Vector2.new(35, 35)
	smoke.Drag = 4
	smoke.LightEmission = 0.2
	smoke.Rate = 0
	smoke.Parent = muzzle
	smoke:Emit(18)
	Debris:AddItem(muzzle, 2.2)

	local shell = makeNeonPart(workspace, 'FireworkShell', Vector3.new(0.7, 2.2, 0.7), CFrame.new(origin), color)
	playPositionalSound(shell, WHISTLE_SOUND, class.volume * 0.45, randomRange(0.85, 1.15), 340)

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
	-- Keep this very short. At a half-second lifetime the shell outruns it and
	-- the trail draws a solid line clear across the sky instead of a spark tail.
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.15
	trail.LightEmission = 1
	trail.WidthScale = NumberSequence.new(0.45, 0)
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

-- Low fan jets off the barge deck: the wall of angled sprays at water level
-- that sits under the shells in every Japanese festival photo.
local function fireFanJet(origin: Vector3, tilt: number, color: Color3)
	local host = makeNeonPart(workspace, 'FanJet', Vector3.one * 0.3, CFrame.new(origin), color)
	host.Transparency = 1

	local jet = Instance.new('ParticleEmitter')
	jet.Name = 'Fan'
	jet.Texture = SPARK_TEXTURE
	jet.LightEmission = 1
	jet.LightInfluence = 0
	jet.Brightness = 20
	jet.Orientation = Enum.ParticleOrientation.VelocityParallel
	jet.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 245)),
		ColorSequenceKeypoint.new(0.55, color),
		ColorSequenceKeypoint.new(1, color),
	})
	jet.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.4),
		NumberSequenceKeypoint.new(0.7, 1.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	jet.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	jet.Squash = NumberSequence.new({
		NumberSequenceKeypoint.new(0, -6),
		NumberSequenceKeypoint.new(1, 0),
	})
	jet.Lifetime = NumberRange.new(1.6, 2.4)
	jet.Speed = NumberRange.new(70, 105)
	jet.SpreadAngle = Vector2.new(7, 7)
	jet.Drag = 2.5
	jet.Acceleration = Vector3.new(0, -42, 0)
	jet.EmissionDirection = Enum.NormalId.Top
	jet.Rate = 130
	jet.Parent = host

	-- Lean the whole jet outward so a row of them reads as a fan.
	host.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, tilt)

	playPositionalSound(host, CRACKLE_SOUND, 1.1, randomRange(0.9, 1.15), 420)
	task.delay(2.0, function()
		if host.Parent then
			jet.Enabled = false
		end
	end)
	Debris:AddItem(host, 5)
end

-- A wall of fan jets across the whole battery, splayed outward from the middle.
local function fireFanWall(origins: { Vector3 })
	local colors = { Color3.fromRGB(255, 240, 200), Color3.fromRGB(120, 210, 255), Color3.fromRGB(255, 140, 210) }
	for index, origin in origins do
		local t = if #origins == 1 then 0 else (index - 1) / (#origins - 1) * 2 - 1
		task.delay((index - 1) * 0.05, function()
			fireFanJet(origin, -t * math.rad(34), colors[(index - 1) % #colors + 1])
		end)
	end
end

--=============================================================================
-- Rhythm director
--=============================================================================

-- Ground height at an X/Z, terrain only (water ignored).
local function terrainHeight(x: number, z: number): number?
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), parameters)
	return if result then result.Position.Y else nil
end

-- A visible battery of mortar tubes moored on the water. Shells have to come
-- out of something the player can see, otherwise they read as appearing from
-- nowhere. Rebuilt on start; tag your own parts FireworksLaunchPoint to skip.
local function buildLaunchBattery(): { Vector3 }
	local previous = workspace:FindFirstChild('FireworksLaunchBattery')
	if previous then
		previous:Destroy()
	end

	local battery = Instance.new('Model')
	battery.Name = 'FireworksLaunchBattery'
	battery.Parent = workspace

	local span = BATTERY_X_MAX - BATTERY_X_MIN
	local deck = Instance.new('Part')
	deck.Name = 'Barge'
	deck.Size = Vector3.new(span + 16, 1.6, 15)
	deck.CFrame = CFrame.new((BATTERY_X_MIN + BATTERY_X_MAX) / 2, BATTERY_Y, BATTERY_Z)
	deck.Color = Color3.fromRGB(58, 47, 38)
	deck.Material = Enum.Material.WoodPlanks
	deck.Anchored = true
	deck.Parent = battery

	local origins: { Vector3 } = {}
	for index = 1, BATTERY_COUNT do
		local t = if BATTERY_COUNT == 1 then 0.5 else (index - 1) / (BATTERY_COUNT - 1)
		local x = BATTERY_X_MIN + span * t
		local tube = Instance.new('Part')
		tube.Name = `LaunchTube{index}`
		tube.Shape = Enum.PartType.Cylinder
		tube.Size = Vector3.new(9, 3.4, 3.4)
		-- Stood upright, then tilted north so the muzzles point across the lake.
		tube.CFrame = CFrame.new(x, BATTERY_Y + 5, BATTERY_Z)
			* CFrame.Angles(0, 0, math.rad(90))
			* CFrame.Angles(0, math.rad(-14), 0)
		tube.Color = Color3.fromRGB(38, 40, 42)
		tube.Material = Enum.Material.Metal
		tube.Anchored = true
		tube.Parent = battery

		-- Muzzle sits at the top end of the cylinder's long axis.
		origins[index] = tube.Position + Vector3.new(0, 4.5, 0)
	end
	return origins
end

-- Launch origins are plain positions, so the show does not depend on any
-- particular greybox barge existing.
--
-- Priority: parts the builder tagged FireworksLaunchPoint win outright. With
-- none tagged, shells go up from a spread around the festival islet, which is
-- where players actually stand to watch.
local function collectLaunchOrigins(): { Vector3 }
	local tagged: { Vector3 } = {}
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('BasePart') and descendant:GetAttribute('FireworksLaunchPoint') then
			table.insert(tagged, descendant.Position)
		end
	end
	if #tagged > 0 then
		return tagged
	end

	return buildLaunchBattery()
end

-- Left-to-right, so sequenced volleys read as a real row.
local function orderedOrigins(origins: { Vector3 }): { Vector3 }
	local ordered = table.clone(origins)
	table.sort(ordered, function(a, b)
		return a.X < b.X
	end)
	return ordered
end

-- Each pattern fires its shells and returns how long to rest afterwards.
local PATTERNS = {
	-- A lone shell: the breathing space between bigger moments.
	{
		weight = 20,
		run = function(origins: { Vector3 }): number
			launchShell(pick(origins), if math.random() < 0.3 then 'large' else 'small')
			return randomRange(1.2, 2.3)
		end,
	},
	-- A quick cluster from scattered tubes.
	{
		weight = 24,
		run = function(origins: { Vector3 }): number
			for index = 1, math.random(3, 6) do
				task.delay((index - 1) * randomRange(0.08, 0.2), function()
					launchShell(pick(origins), if math.random() < 0.35 then 'large' else 'small')
				end)
			end
			return randomRange(1.9, 3.0)
		end,
	},
	-- Sequenced row down the barge (deretan).
	{
		weight = 18,
		run = function(origins: { Vector3 }): number
			local ordered = orderedOrigins(origins)
			local reverse = math.random() < 0.5
			for index, origin in ordered do
				local slot = if reverse then #ordered - index + 1 else index
				task.delay((slot - 1) * randomRange(0.14, 0.22), function()
					launchShell(origin, 'small')
				end)
			end
			return randomRange(2.1, 3.2)
		end,
	},
	-- One big shell, given room to breathe.
	{
		weight = 16,
		run = function(origins: { Vector3 }): number
			launchShell(pick(origins), 'huge')
			return randomRange(2.8, 4.2)
		end,
	},
	-- Twin large shells opening together.
	{
		weight = 12,
		run = function(origins: { Vector3 }): number
			local ordered = orderedOrigins(origins)
			launchShell(ordered[1], 'large')
			task.delay(0.06, function()
				launchShell(ordered[#ordered], 'large')
			end)
			return randomRange(2.3, 3.4)
		end,
	},
	-- Fan wall at water level with shells opening above it: the signature
	-- Japanese festival frame.
	{
		weight = 14,
		run = function(origins: { Vector3 }): number
			fireFanWall(origins)
			for index = 1, math.random(4, 7) do
				task.delay(0.25 + (index - 1) * randomRange(0.12, 0.26), function()
					launchShell(pick(origins), if math.random() < 0.45 then 'large' else 'small')
				end)
			end
			return randomRange(3.0, 4.2)
		end,
	},
	-- Full sky: many shells at once, spread wide, the way a finale photo looks.
	{
		weight = 12,
		run = function(origins: { Vector3 }): number
			for index = 1, math.random(8, 12) do
				task.delay((index - 1) * randomRange(0.05, 0.14), function()
					local roll = math.random()
					launchShell(pick(origins), if roll < 0.2 then 'huge' elseif roll < 0.6 then 'large' else 'small')
				end)
			end
			return randomRange(3.4, 4.6)
		end,
	},
	-- Starmine: rolling wall of shells, the crowd-pleaser.
	{
		weight = 10,
		run = function(origins: { Vector3 }): number
			local ordered = orderedOrigins(origins)
			for wave = 0, 2 do
				for index, origin in ordered do
					task.delay(wave * 0.55 + (index - 1) * 0.09, function()
						launchShell(origin, if wave == 2 then 'large' else 'small')
					end)
				end
			end
			task.delay(1.8, function()
				fireFanWall(ordered)
			end)
			task.delay(1.95, function()
				launchShell(pick(ordered), 'huge')
			end)
			return randomRange(4.2, 5.6)
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

local function findConsoleSpot(origins: { Vector3 }): Vector3
	-- Preferred: the pinned festival spot on the islet.
	local pinned = terrainHeight(CONSOLE_SPOT_X, CONSOLE_SPOT_Z)
	if pinned then
		return Vector3.new(CONSOLE_SPOT_X, pinned, CONSOLE_SPOT_Z)
	end

	-- Fallback only if that spot has no ground (terrain edited away): nearest
	-- dry land to the launch origins, searched as widening rings.
	local centre = Vector3.zero
	for _, origin in origins do
		centre += origin
	end
	centre /= #origins

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
local function buildFallbackConsole(origins: { Vector3 }): BasePart
	local previous = workspace:FindFirstChild('FestivalFireworksControl')
	if previous then
		previous:Destroy()
	end

	local spot = findConsoleSpot(origins)
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
		local launchers = collectLaunchOrigins()
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
	local launchers = collectLaunchOrigins()
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
