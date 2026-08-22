--!strict

-- Photo-led Suwa Lakeside Park environment pass. This service replaces the old
-- coloured greybox trails while leaving fishing, bicycles and lake craft intact.

local Lighting = game:GetService("Lighting")

local tartanColor = Color3.fromRGB(139, 56, 55)
local asphaltColor = Color3.fromRGB(57, 61, 62)
local markingColor = Color3.fromRGB(235, 235, 226)
local timberColor = Color3.fromRGB(101, 72, 48)
local darkMetal = Color3.fromRGB(53, 57, 56)

local LakesideParkService = {}

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

local function makeSeat(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance): Seat
	local seat = Instance.new("Seat")
	seat.Name = name
	seat.Anchored = true
	seat.Size = size
	seat.CFrame = cframe
	seat.Color = color
	seat.Material = material
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.Parent = parent
	return seat
end

-- =========================================================================
-- GRAND CREATOR STORE LAKESIDE PLAYGROUND & AMUSEMENT PARK
-- =========================================================================
local function buildLakesideAmusementPlayground(root: Model)
	local oldPg = root:FindFirstChild("SuwaLakesidePlayground")
	if oldPg then oldPg:Destroy() end

	local playground = Instance.new("Model")
	playground.Name = "SuwaLakesidePlayground"
	playground.Parent = root

	local ss = game:GetService("ServerStorage")
	local csa = ss:FindFirstChild("CreatorStoreAssets")
	local darkMetal = Color3.fromRGB(45, 48, 52)
	local brightRed = Color3.fromRGB(225, 65, 55)
	local brightCyan = Color3.fromRGB(40, 180, 220)
	local baseY = 2.0

	-- -------------------------------------------------------------------------
	-- A. COBBLESTONE PATHWAYS
	-- -------------------------------------------------------------------------
	local px = -310
	makePart("Part", "PlaygroundPathwayMain", Vector3.new(140, 0.3, 12),
		CFrame.new(px, baseY + 0.15, -100),
		Color3.fromRGB(175, 172, 162), Enum.Material.Cobblestone, playground)
	makePart("Part", "PlaygroundPathwayCross1", Vector3.new(12, 0.3, 85),
		CFrame.new(px - 40, baseY + 0.15, -105),
		Color3.fromRGB(175, 172, 162), Enum.Material.Cobblestone, playground)
	makePart("Part", "PlaygroundPathwayCross2", Vector3.new(12, 0.3, 85),
		CFrame.new(px + 40, baseY + 0.15, -105),
		Color3.fromRGB(175, 172, 162), Enum.Material.Cobblestone, playground)

	-- -------------------------------------------------------------------------
	-- B. TORII ENTRANCE GATE
	-- -------------------------------------------------------------------------
	local archX = px
	local archZ = -60
	makePart("Part", "ArchPostL", Vector3.new(1.4, 14, 1.4), CFrame.new(archX - 8, baseY + 7, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)
	makePart("Part", "ArchPostR", Vector3.new(1.4, 14, 1.4), CFrame.new(archX + 8, baseY + 7, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)
	makePart("Part", "ArchBeamTop", Vector3.new(20, 1.4, 1.4), CFrame.new(archX, baseY + 14.5, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)
	makePart("Part", "ArchBeamMid", Vector3.new(18, 1.0, 1.0), CFrame.new(archX, baseY + 12.5, archZ), Color3.fromRGB(185, 45, 35), Enum.Material.Wood, playground)

	-- -------------------------------------------------------------------------
	-- C. BIANGLALA (FERRIS WHEEL)
	-- -------------------------------------------------------------------------
	local fwTemplate = csa and csa:FindFirstChild("CreatorStoreFerrisWheel")
	if fwTemplate then
		local fw = fwTemplate:Clone()
		fw.Name = "SuwaFerrisWheel"
		fw.Parent = playground
		local fs = fw:FindFirstChild("FerrisScript", true)
		if fs then fs:Destroy() end
		local _, sz = fw:GetBoundingBox()
		fw:PivotTo(CFrame.new(-230, baseY + sz.Y / 2, -90) * CFrame.Angles(0, math.rad(90), 0))
		for _, d in ipairs(fw:GetDescendants()) do
			if d:IsA("BasePart") then
				local isWheel = d:FindFirstAncestor("Wheel") ~= nil
				local isBasket = d:FindFirstAncestor("Baskets") ~= nil
				d.Anchored = not (isWheel or isBasket)
				if d.Name == "Roof" or d.Name == "Rails" or d.Name == "Seats" then d.CanCollide = false end
			end
		end
		local motor = fw:FindFirstChild("FerrisMotor", true) :: HingeConstraint?
		if motor then
			motor.ActuatorType = Enum.ActuatorType.Motor
			motor.MotorMaxTorque = 100000000
			motor.AngularVelocity = 0.35
		end
	end

	-- -------------------------------------------------------------------------
	-- D. PEROSOTAN LURUS BERSIH (CLEAN STRAIGHT SLIDE)
	-- -------------------------------------------------------------------------
	local slideTemplate = csa and (csa:FindFirstChild("CreatorStoreStraightSlide") or csa:FindFirstChild("CreatorStoreBigSlide") or csa:FindFirstChild("CreatorStoreSlideModel"))
	if slideTemplate then
		local slide = slideTemplate:Clone()
		slide.Name = "SuwaPlaygroundSlideSet"
		slide.Parent = playground
		for _, d in ipairs(slide:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = true
			end
		end
		local _, sz = slide:GetBoundingBox()
		local scaleF = 18.0 / math.max(sz.X, sz.Z)
		slide:ScaleTo(math.clamp(scaleF, 0.4, 1.5))
		local _, sz2 = slide:GetBoundingBox()
		slide:PivotTo(CFrame.new(-380, baseY + sz2.Y / 2, -95) * CFrame.Angles(0, math.rad(180), 0))
	end

	-- -------------------------------------------------------------------------
	-- E. AYUNAN BIASA (CLASSIC SWING SET)
	-- -------------------------------------------------------------------------
	local swingTemplate = csa and csa:FindFirstChild("CreatorStoreSwingSet")
	if swingTemplate then
		local swing = swingTemplate:Clone()
		swing.Name = "SuwaSwingSet"
		swing.Parent = playground
		for _, d in ipairs(swing:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Frame" then d.Anchored = true end
		end
		local _, sz = swing:GetBoundingBox()
		swing:PivotTo(CFrame.new(-310, baseY + sz.Y / 2, -135))
	end

	-- -------------------------------------------------------------------------
	-- F. AYUNAN ESTETIK TEMPAT PACARAN (ROMANTIC SAKURA COUPLE SWING)
	-- -------------------------------------------------------------------------
	local coupleSwingPos = Vector3.new(-270, baseY, -135)

	-- Sakura tree placed directly behind the romantic swing facing the lake (Z = -156)
	local treeTemplate = csa and (csa:FindFirstChild("JapaneseSakuraTreeTemplate") or csa:FindFirstChild("CreatorStoreSakuraTree"))
	if treeTemplate then
		local tree = treeTemplate:Clone()
		tree.Name = "RomanticCoupleSakuraTree"
		tree.Parent = playground
		for _, d in ipairs(tree:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = tree:GetBoundingBox()
		tree:PivotTo(CFrame.new(coupleSwingPos.X, baseY + sz.Y / 2, -156))
	end

	makePart("Part", "RomanticDeck", Vector3.new(18, 0.25, 14),
		CFrame.new(coupleSwingPos.X, baseY + 0.12, coupleSwingPos.Z),
		Color3.fromRGB(185, 180, 172), Enum.Material.Cobblestone, playground)

	local coupleSwingTemplate = csa and csa:FindFirstChild("CreatorStoreRomanticSwing")
	if coupleSwingTemplate then
		local cs = coupleSwingTemplate:Clone()
		cs.Name = "SuwaRomanticCoupleSwing"
		cs.Parent = playground
		for _, d in ipairs(cs:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = cs:GetBoundingBox()
		local scaleF = 9.0 / math.max(sz.X, sz.Z)
		cs:ScaleTo(math.clamp(scaleF, 0.8, 1.3))
		local _, sz2 = cs:GetBoundingBox()
		cs:PivotTo(CFrame.new(coupleSwingPos.X, baseY + sz2.Y / 2, coupleSwingPos.Z) * CFrame.Angles(0, math.rad(90), 0))

		local seatL = Instance.new("Seat")
		seatL.Name = "CoupleSeat_L"
		seatL.Size = Vector3.new(1.8, 0.3, 1.6)
		seatL.CFrame = CFrame.new(coupleSwingPos.X - 1.4, baseY + 1.8, coupleSwingPos.Z)
		seatL.Transparency = 1 ; seatL.CanCollide = false ; seatL.Anchored = true ; seatL.Parent = cs

		local seatR = Instance.new("Seat")
		seatR.Name = "CoupleSeat_R"
		seatR.Size = Vector3.new(1.8, 0.3, 1.6)
		seatR.CFrame = CFrame.new(coupleSwingPos.X + 1.4, baseY + 1.8, coupleSwingPos.Z)
		seatR.Transparency = 1 ; seatR.CanCollide = false ; seatR.Anchored = true ; seatR.Parent = cs
	end

	-- -------------------------------------------------------------------------
	-- G. DUA SUPER TRAMPOLIN (TWIN HIGH JUMP TRAMPOLINES ON LAWN)
	-- -------------------------------------------------------------------------
	local tramTemplate = csa and (csa:FindFirstChild("CreatorStoreHighJumpTrampoline") or csa:FindFirstChild("CreatorStoreRoundTrampoline"))
	if tramTemplate then
		local tramPositions = {
			Vector3.new(-265, baseY, -70),
			Vector3.new(-295, baseY, -70),
		}
		for idx, pos in ipairs(tramPositions) do
			local tram = tramTemplate:Clone()
			tram.Name = `SuwaTrampoline_{idx}`
			tram.Parent = playground
			for _, d in ipairs(tram:GetDescendants()) do
				if d:IsA("BasePart") then d.Anchored = true end
			end
			local _, sz = tram:GetBoundingBox()
			local scaleF = 17 / math.max(sz.X, sz.Z)
			tram:ScaleTo(math.clamp(scaleF, 0.5, 1.2))
			local _, sz2 = tram:GetBoundingBox()
			tram:PivotTo(CFrame.new(pos.X, baseY + sz2.Y / 2, pos.Z))

			local pad = Instance.new("Part")
			pad.Name = "TrampolineBouncePad"
			pad.Size = Vector3.new(17.0, 2.5, 17.0)
			pad.CFrame = CFrame.new(pos.X, baseY + sz2.Y + 0.8, pos.Z)
			pad.Transparency = 1 ; pad.CanCollide = false ; pad.CanTouch = true ; pad.Anchored = true ; pad.Parent = tram
		end
	end

	-- -------------------------------------------------------------------------
	-- H. TANGGA MONYET MERAH (MONKEY BARS - SHIFTED TO THE LEFT)
	-- -------------------------------------------------------------------------
	local mbTemplate = csa and csa:FindFirstChild("CreatorStoreMonkeyBars")
	if mbTemplate then
		local mb = mbTemplate:Clone()
		mb.Name = "SuwaMonkeyBars"
		mb.Parent = playground
		for _, d in ipairs(mb:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = mb:GetBoundingBox()
		mb:PivotTo(CFrame.new(-375, baseY + sz.Y / 2, -135))
	end

	-- -------------------------------------------------------------------------
	-- I. SPOT FOTO ESTETIK: 5 KUDA PEGAS DENGAN POHON SAKURA MEKAR DI BELAKANGNYA
	-- -------------------------------------------------------------------------
	local sakuraSpot = Vector3.new(-345, baseY, -135)

	local treeSpot = csa and (csa:FindFirstChild("JapaneseSakuraTreeTemplate") or csa:FindFirstChild("CreatorStoreSakuraTree"))
	if treeSpot then
		local tree = treeSpot:Clone()
		tree.Name = "PhotoSpotSakuraTree"
		tree.Parent = playground
		for _, d in ipairs(tree:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local _, sz = tree:GetBoundingBox()
		tree:PivotTo(CFrame.new(sakuraSpot.X, baseY + sz.Y / 2, -156))
	end

	makePart("Part", "PhotoSpotPad", Vector3.new(26, 0.25, 12),
		CFrame.new(sakuraSpot.X, baseY + 0.12, sakuraSpot.Z),
		Color3.fromRGB(180, 176, 168), Enum.Material.Cobblestone, playground)

	local springTemplate = csa and csa:FindFirstChild("CreatorStoreSpringRiders")
	if springTemplate then
		local sp = springTemplate:Clone()
		sp.Name = "SuwaSpringRiders"
		sp.Parent = playground
		local _, sz = sp:GetBoundingBox()
		sp:PivotTo(CFrame.new(sakuraSpot + Vector3.new(0, sz.Y / 2, 0)) * CFrame.Angles(0, math.rad(0), 0))

		for _, rider in ipairs(sp:GetDescendants()) do
			if rider:IsA("Model") and (rider.Name:find("Happy") or rider.Name:find("Rider")) then
				local base = rider:FindFirstChild("Base") :: BasePart?
				local seat = (rider:FindFirstChildWhichIsA("VehicleSeat") or rider:FindFirstChildWhichIsA("Seat")) :: BasePart?
				if base and seat then
					base.Anchored = true
					seat.Anchored = true
					for _, d in ipairs(rider:GetDescendants()) do
						if d:IsA("BasePart") and d ~= base and d ~= seat then
							d.Anchored = false
							local w = Instance.new("WeldConstraint")
							w.Part0 = seat
							w.Part1 = d
							w.Parent = seat
						end
					end
				end
			end
		end
	end

	-- -------------------------------------------------------------------------
	-- J. MEJA PANCO (ARM WRESTLING TABLE)
	-- -------------------------------------------------------------------------
	local armCenter = Vector3.new(-310, baseY, -75)
	local armModel = Instance.new("Model")
	armModel.Name = "SuwaArmWrestlingArena"
	armModel.Parent = playground
	makePart("Part", "TableLegCenter", Vector3.new(2, 3.6, 2), CFrame.new(armCenter + Vector3.new(0, 1.8, 0)), darkMetal, Enum.Material.Metal, armModel)
	makePart("Part", "TableTop", Vector3.new(6.4, 0.6, 4.4), CFrame.new(armCenter + Vector3.new(0, 3.8, 0)), Color3.fromRGB(30, 32, 36), Enum.Material.SmoothPlastic, armModel)
	makePart("Part", "ElbowPadRed", Vector3.new(1.4, 0.3, 1.4), CFrame.new(armCenter + Vector3.new(-1.6, 4.2, 0)), brightRed, Enum.Material.Fabric, armModel)
	makePart("Part", "ElbowPadBlue", Vector3.new(1.4, 0.3, 1.4), CFrame.new(armCenter + Vector3.new(1.6, 4.2, 0)), brightCyan, Enum.Material.Fabric, armModel)
	makePart("Part", "GripPegL", Vector3.new(0.3, 1.4, 0.3), CFrame.new(armCenter + Vector3.new(-2.6, 4.6, 1.5)), Color3.fromRGB(220, 220, 220), Enum.Material.Metal, armModel)
	makePart("Part", "GripPegR", Vector3.new(0.3, 1.4, 0.3), CFrame.new(armCenter + Vector3.new(2.6, 4.6, -1.5)), Color3.fromRGB(220, 220, 220), Enum.Material.Metal, armModel)
	makeSeat("ArmSeat_Red", Vector3.new(2, 0.4, 2), CFrame.new(armCenter + Vector3.new(-3.4, 2.2, 0)) * CFrame.Angles(0, math.rad(-90), 0), brightRed, Enum.Material.SmoothPlastic, armModel)
	makeSeat("ArmSeat_Blue", Vector3.new(2, 0.4, 2), CFrame.new(armCenter + Vector3.new(3.4, 2.2, 0)) * CFrame.Angles(0, math.rad(90), 0), brightCyan, Enum.Material.SmoothPlastic, armModel)
	makePart("Part", "StoolLegRed", Vector3.new(0.5, 2.2, 0.5), CFrame.new(armCenter + Vector3.new(-3.4, 1.1, 0)), darkMetal, Enum.Material.Metal, armModel)
	makePart("Part", "StoolLegBlue", Vector3.new(0.5, 2.2, 0.5), CFrame.new(armCenter + Vector3.new(3.4, 1.1, 0)), darkMetal, Enum.Material.Metal, armModel)
end

local function applyGoldenHour()
	Lighting.ClockTime = 17.55
	Lighting.Brightness = 2.15
	Lighting.Ambient = Color3.fromRGB(118, 124, 138)
	Lighting.OutdoorAmbient = Color3.fromRGB(164, 157, 147)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.ShadowSoftness = 0.5

	local colorCorrection = Lighting:FindFirstChild("SuwaGoldenHour") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "SuwaGoldenHour"
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast = 0.07
	colorCorrection.Saturation = -0.03
	colorCorrection.TintColor = Color3.fromRGB(255, 225, 194)
	colorCorrection.Parent = Lighting

	local sunRays = Lighting:FindFirstChild("SuwaSunRays") or Instance.new("SunRaysEffect")
	sunRays.Name = "SuwaSunRays"
	sunRays.Intensity = 0.045
	sunRays.Spread = 0.72
	sunRays.Parent = Lighting

	local bloom = Lighting:FindFirstChild("SuwaWaterBloom") or Instance.new("BloomEffect")
	bloom.Name = "SuwaWaterBloom"
	bloom.Intensity = 0.18
	bloom.Size = 28
	bloom.Threshold = 1.85
	bloom.Parent = Lighting
end

local function buildPark()
	local previous = workspace:FindFirstChild("SuwaLakesidePark")
	if previous then previous:Destroy() end

	local root = Instance.new("Model")
	root.Name = "SuwaLakesidePark"
	root.Parent = workspace

	buildLakesideAmusementPlayground(root)
	applyGoldenHour()
end

function LakesideParkService.init()
	buildPark()
end

return LakesideParkService
