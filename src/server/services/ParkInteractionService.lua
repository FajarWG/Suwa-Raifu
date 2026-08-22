--!strict
-- ParkInteractionService: Interactive Attractions & Playground Mechanics
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ParkInteractionService = {}
local slideBusy: { [Player]: boolean } = {}
local armMatchActive = false
local bounceDebounce: { [Player]: number } = {}
local activeRockers: { [BasePart]: RBXScriptConnection } = {}

-- -----------------------------------------------------------------------------
-- SHARED: Sit Prompt
-- -----------------------------------------------------------------------------
local function addSitPrompt(seat: Seat, objectText: string)
	local existing = seat:FindFirstChild("SitPrompt")
	if existing then existing:Destroy() end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SitPrompt"
	prompt.ActionText = "Duduk"
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = (seat.Occupant == nil)
	end)
	prompt.Triggered:Connect(function(player)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and not seat.Occupant then seat:Sit(hum) end
	end)
end

-- -----------------------------------------------------------------------------
-- 1. DUA SUPER TRAMPOLIN (TWIN HIGH JUMP TRAMPOLINES)
-- -----------------------------------------------------------------------------
local function configureTrampoline(playground: Model)
	local function triggerBounce(player: Player, hrp: BasePart, hum: Humanoid)
		local now = os.clock()
		if now - (bounceDebounce[player] or 0) < 0.55 then return end
		bounceDebounce[player] = now

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(hrp.AssemblyLinearVelocity.X * 0.8, 120, hrp.AssemblyLinearVelocity.Z * 0.8)
		bv.MaxForce = Vector3.new(0, 1000000, 0)
		bv.Parent = hrp
		task.delay(0.16, function() bv:Destroy() end)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/action_jump.mp3"
		sound.Volume = 0.9
		sound.PlaybackSpeed = math.random(115, 135) / 100
		sound.Parent = hrp
		sound:Play()
		task.delay(1.2, function() sound:Destroy() end)
	end

	for _, tramName in ipairs({"SuwaTrampoline_1", "SuwaTrampoline_2", "SuwaTrampoline"}) do
		local tram = playground:FindFirstChild(tramName)
		if tram then
			local bouncePad = tram:FindFirstChild("TrampolineBouncePad") :: BasePart?
			if bouncePad then
				bouncePad.Touched:Connect(function(hit)
					local char = hit:FindFirstAncestorOfClass("Model")
					local player = char and Players:GetPlayerFromCharacter(char)
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if player and hum and hrp and hum.Health > 0 then
						triggerBounce(player, hrp, hum)
					end
				end)

				RunService.Heartbeat:Connect(function()
					if not (bouncePad and bouncePad.Parent) then return end
					local overlap = OverlapParams.new()
					overlap.FilterType = Enum.RaycastFilterType.Include
					local charList = {}
					for _, p in ipairs(Players:GetPlayers()) do
						if p.Character then table.insert(charList, p.Character) end
					end
					if #charList == 0 then return end
					overlap.FilterDescendantsInstances = charList
					local parts = workspace:GetPartsInPart(bouncePad, overlap)
					for _, pt in ipairs(parts) do
						local char = pt:FindFirstAncestorOfClass("Model")
						local p = char and Players:GetPlayerFromCharacter(char)
						local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if p and hrp and hum and hum.Health > 0 then
							triggerBounce(p, hrp, hum)
						end
					end
				end)
			end
		end
	end
end

-- -----------------------------------------------------------------------------
-- 2. SPRING RIDERS (5 KUDA PEGAS)
-- -----------------------------------------------------------------------------
local function configureSpringRiders(playground: Model)
	local sp = playground:FindFirstChild("SuwaSpringRiders")
	if not sp then return end

	for _, d in ipairs(sp:GetDescendants()) do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then
			local seat = d :: BasePart
			local originalCFrame = seat.CFrame

			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local occ = (seat :: any).Occupant
				if occ then
					if not activeRockers[seat] then
						local t0 = os.clock()
						local conn
						conn = RunService.Heartbeat:Connect(function()
							if not ((seat :: any).Occupant and seat.Parent) then
								if conn then conn:Disconnect() end
								activeRockers[seat] = nil
								seat.CFrame = originalCFrame
								return
							end
							local elapsed = os.clock() - t0
							local pitch = math.sin(elapsed * 4.8) * math.rad(16)
							local roll = math.sin(elapsed * 2.6) * math.rad(4)
							seat.CFrame = originalCFrame * CFrame.Angles(pitch, 0, roll)
						end)
						activeRockers[seat] = conn
					end
				else
					if activeRockers[seat] then
						activeRockers[seat]:Disconnect()
						activeRockers[seat] = nil
					end
					seat.CFrame = originalCFrame
				end
			end)
		end
	end
end

-- -----------------------------------------------------------------------------
-- 3. AYUNAN PACARAN ESTETIK (ROMANTIC SAKURA COUPLE SWING)
-- -----------------------------------------------------------------------------
local function configureRomanticCoupleSwing(playground: Model)
	local cs = playground:FindFirstChild("SuwaRomanticCoupleSwing")
	if not cs then return end

	local seatL = cs:FindFirstChild("CoupleSeat_L") :: Seat?
	local seatR = cs:FindFirstChild("CoupleSeat_R") :: Seat?

	if seatL then addSitPrompt(seatL, "Ayunan Pacaran (Kiri) 🌸") end
	if seatR then addSitPrompt(seatR, "Ayunan Pacaran (Kanan) 🌸") end

	for _, d in ipairs(cs:GetDescendants()) do
		if d:IsA("Seat") and d ~= seatL and d ~= seatR then
			addSitPrompt(d, "Ayunan Pasangan 🌸")
		end
	end
end

-- -----------------------------------------------------------------------------
-- 4. PEROSOTAN LAKESIDE (SMOOTH PLAYGROUND SLIDE WITH INSTANT SLIDE ACTION)
-- -----------------------------------------------------------------------------
local function configureSlides(playground: Model)
	local slide = playground:FindFirstChild("SuwaPlaygroundSlideSet")
	if not slide then return end

	local climbPart = Instance.new("Part")
	climbPart.Name = "SlideClimbTrigger"
	climbPart.Size = Vector3.new(6, 4, 6)
	climbPart.CFrame = CFrame.new(-365 + 10.5, 3.5, -100 - 9.5)
	climbPart.Transparency = 1 ; climbPart.CanCollide = false ; climbPart.Anchored = true ; climbPart.Parent = slide

	local climbPrompt = Instance.new("ProximityPrompt")
	climbPrompt.Name = "ClimbSlidePrompt"
	climbPrompt.ActionText = "Naik ke Atas 🪜"
	climbPrompt.ObjectText = "Perosotan Pastel"
	climbPrompt.HoldDuration = 0
	climbPrompt.MaxActivationDistance = 10
	climbPrompt.RequiresLineOfSight = false
	climbPrompt.Parent = climbPart

	climbPrompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = CFrame.new(-365 - 0.5, 14.8, -100 + 4.5) * CFrame.Angles(0, math.rad(180), 0)
		end
	end)

	local slidePart = Instance.new("Part")
	slidePart.Name = "SlideChuteTrigger"
	slidePart.Size = Vector3.new(6, 4, 6)
	slidePart.CFrame = CFrame.new(-365 - 0.5, 14.5, -100 + 3.2)
	slidePart.Transparency = 1 ; slidePart.CanCollide = false ; slidePart.Anchored = true ; slidePart.Parent = slide

	local slidePrompt = Instance.new("ProximityPrompt")
	slidePrompt.Name = "SlideDownPrompt"
	slidePrompt.ActionText = "Meluncur! 🛝"
	slidePrompt.ObjectText = "Corong Perosotan"
	slidePrompt.HoldDuration = 0
	slidePrompt.MaxActivationDistance = 10
	slidePrompt.RequiresLineOfSight = false
	slidePrompt.Parent = slidePart

	slidePrompt.Triggered:Connect(function(player)
		if slideBusy[player] then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not (hum and hrp) then return end

		slideBusy[player] = true
		hum.PlatformStand = true
		hrp.Anchored = true

		local waypoints = {
			CFrame.new(-365 - 0.5, 14.2, -100 + 2.5) * CFrame.Angles(math.rad(-15), math.rad(0), 0),
			CFrame.new(-365 - 2.8, 11.5, -100 + 0.8) * CFrame.Angles(math.rad(-20), math.rad(90), 0),
			CFrame.new(-365 - 1.2, 8.2, -100 - 1.8) * CFrame.Angles(math.rad(-20), math.rad(180), 0),
			CFrame.new(-365 + 1.8, 5.2, -100 - 0.2) * CFrame.Angles(math.rad(-18), math.rad(270), 0),
			CFrame.new(-365 + 0.5, 3.2, -100 + 2.5) * CFrame.Angles(0, math.rad(0), 0),
		}

		task.spawn(function()
			for _, wp in ipairs(waypoints) do
				local tw = TweenService:Create(hrp, TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					CFrame = wp
				})
				tw:Play()
				tw.Completed:Wait()
			end

			if hrp.Parent then
				hrp.Anchored = false
				hum.PlatformStand = false
				hrp.AssemblyLinearVelocity = Vector3.new(0, 4, 16)
			end
			slideBusy[player] = nil
		end)
	end)
end

-- -----------------------------------------------------------------------------
-- 5. AYUNAN BIASA (CLASSIC SWINGS)
-- -----------------------------------------------------------------------------
local function configureSwings(playground: Model)
	local swing = playground:FindFirstChild("SuwaSwingSet")
	if not swing then return end
	for _, d in ipairs(swing:GetDescendants()) do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then
			addSitPrompt(d :: Seat, "Ayunan Taman Suwa 🎪")
		end
	end
end

-- -----------------------------------------------------------------------------
-- 6. MEJA PANCO (ARM WRESTLING)
-- -----------------------------------------------------------------------------
local function configureArmWrestling(playground: Model)
	local arena = playground:FindFirstChild("SuwaArmWrestlingArena")
	if not arena then return end
	local seatRed = arena:FindFirstChild("ArmSeat_Red") :: Seat?
	local seatBlue = arena:FindFirstChild("ArmSeat_Blue") :: Seat?
	if seatRed then addSitPrompt(seatRed, "Meja Panco (Sudut Merah)") end
	if seatBlue then addSitPrompt(seatBlue, "Meja Panco (Sudut Biru)") end
end

-- -----------------------------------------------------------------------------
-- 7. BIANGLALA (FERRIS WHEEL)
-- -----------------------------------------------------------------------------
local function configureFerrisWheel(playground: Model)
	local fw = playground:FindFirstChild("SuwaFerrisWheel")
	if not fw then return end
	for _, d in ipairs(fw:GetDescendants()) do
		if d:IsA("Seat") then addSitPrompt(d, "Gondola Bianglala 🎡") end
	end
end

function ParkInteractionService.init()
	local park = workspace:FindFirstChild("SuwaLakesidePark")
	local pg = park and park:FindFirstChild("SuwaLakesidePlayground")
	if pg then
		configureFerrisWheel(pg)
		configureSwings(pg)
		configureRomanticCoupleSwing(pg)
		configureSlides(pg)
		configureArmWrestling(pg)
		configureTrampoline(pg)
		configureSpringRiders(pg)
	end
end

return ParkInteractionService
