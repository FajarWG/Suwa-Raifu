--!strict
-- ParkInteractionService: Interactive Attractions & Playground Mechanics
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ParkInteractionService = {}
local slideBusy: { [Player]: boolean } = {}
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

	local seats = {}
	for _, d in ipairs(cs:GetDescendants()) do
		if d:IsA("Seat") then
			table.insert(seats, d)
		end
	end
	table.sort(seats, function(a, b) return a.Position.X < b.Position.X end)

	if #seats >= 2 then
		addSitPrompt(seats[1], "Ayunan Pacaran (Kiri) 🌸")
		addSitPrompt(seats[2], "Ayunan Pacaran (Kanan) 🌸")
	elseif #seats == 1 then
		addSitPrompt(seats[1], "Ayunan Pacaran 🌸")
	end
end

-- -----------------------------------------------------------------------------
-- 4. PEROSOTAN LURUS (SMOOTH REAL SLIDING PHYSICS)
-- -----------------------------------------------------------------------------
local function configureSlides(playground: Model)
	local slide = playground:FindFirstChild("SuwaPlaygroundSlideSet")
	if not slide then return end

	-- A. Ladder climb helper at base of ladder
	local climbPromptPart = Instance.new("Part")
	climbPromptPart.Name = "SlideClimbPromptPart"
	climbPromptPart.Size = Vector3.new(3.5, 3.0, 3.5)
	climbPromptPart.CFrame = CFrame.new(-371.0, 4.0, -95.0)
	climbPromptPart.Transparency = 1
	climbPromptPart.Anchored = true
	climbPromptPart.CanCollide = false
	climbPromptPart.Parent = slide

	local climbPrompt = Instance.new("ProximityPrompt")
	climbPrompt.Name = "ClimbPrompt"
	climbPrompt.ActionText = "Naik ke Atas 🪜"
	climbPrompt.ObjectText = "Tangga Perosotan"
	climbPrompt.HoldDuration = 0
	climbPrompt.MaxActivationDistance = 9
	climbPrompt.RequiresLineOfSight = false
	climbPrompt.Parent = climbPromptPart

	climbPrompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = CFrame.new(-373.5, 14.8, -95.0) * CFrame.Angles(0, math.rad(90), 0)
		end
	end)

	-- B. Slide trigger at top platform
	local slideTriggerPart = Instance.new("Part")
	slideTriggerPart.Name = "SlideTriggerPart"
	slideTriggerPart.Size = Vector3.new(3.5, 3.5, 3.5)
	slideTriggerPart.CFrame = CFrame.new(-374.0, 14.5, -95.0)
	slideTriggerPart.Transparency = 1
	slideTriggerPart.Anchored = true
	slideTriggerPart.CanCollide = false
	slideTriggerPart.CanTouch = true
	slideTriggerPart.Parent = slide

	local slidePrompt = Instance.new("ProximityPrompt")
	slidePrompt.Name = "SlidePrompt"
	slidePrompt.ActionText = "Meluncur! 🛝"
	slidePrompt.ObjectText = "Perosotan Danau Suwa"
	slidePrompt.HoldDuration = 0
	slidePrompt.MaxActivationDistance = 9
	slidePrompt.RequiresLineOfSight = false
	slidePrompt.Parent = slideTriggerPart

	local function doSlide(player: Player)
		if slideBusy[player] then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not (hum and hrp and hum.Health > 0) then return end

		slideBusy[player] = true
		hum.Sit = true
		hrp.Anchored = true

		-- Move smoothly down along the slide chute (-X direction)
		local pStart = Vector3.new(-375.0, 14.0, -95.0)
		local pMid = Vector3.new(-382.0, 8.5, -95.0)
		local pEnd = Vector3.new(-389.0, 4.0, -95.0)
		local pGrass = Vector3.new(-392.0, 3.2, -95.0)

		hrp.CFrame = CFrame.new(pStart) * CFrame.Angles(0, math.rad(90), 0)

		local tw1 = TweenService:Create(hrp, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			CFrame = CFrame.new(pMid) * CFrame.Angles(0, math.rad(90), 0)
		})
		tw1:Play()
		tw1.Completed:Wait()

		local tw2 = TweenService:Create(hrp, TweenInfo.new(0.35, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(pEnd) * CFrame.Angles(0, math.rad(90), 0)
		})
		tw2:Play()
		tw2.Completed:Wait()

		local tw3 = TweenService:Create(hrp, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(pGrass) * CFrame.Angles(0, math.rad(90), 0)
		})
		tw3:Play()
		tw3.Completed:Wait()

		if hrp.Parent then
			hrp.Anchored = false
			hum.Sit = false
			hrp.AssemblyLinearVelocity = Vector3.new(-16, 4, 0)
		end
		slideBusy[player] = nil
	end

	slidePrompt.Triggered:Connect(doSlide)
	slideTriggerPart.Touched:Connect(function(hit)
		local char = hit:FindFirstAncestorOfClass("Model")
		local p = char and Players:GetPlayerFromCharacter(char)
		if p then doSlide(p) end
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
