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
-- SHARED: Bike-style tip card (auto-dismiss, only for seated player)
-- -----------------------------------------------------------------------------
local function showTipCard(player: Player, title: string, lines: { { key: string, desc: string } }, accentColor: Color3)
	local pGui = player:FindFirstChild("PlayerGui")
	if not pGui then return end

	local existing = pGui:FindFirstChild("ParkTipCard")
	if existing then existing:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "ParkTipCard"
	sg.ResetOnSpawn = false
	sg.Parent = pGui

	local frameH = 40 + #lines * 26
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -35)
	frame.Size = UDim2.new(0, 370, 0, frameH)
	frame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 1.5
	stroke.Transparency = 1
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.new(0, 14, 0, 7)
	titleLabel.Size = UDim2.new(1, -28, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextColor3 = accentColor
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTransparency = 1
	titleLabel.Parent = frame

	local allLabels = { titleLabel }

	for i, item in ipairs(lines) do
		local yPos = 33 + (i - 1) * 26

		local keyL = Instance.new("TextLabel")
		keyL.Position = UDim2.new(0, 14, 0, yPos)
		keyL.Size = UDim2.new(0, 110, 0, 20)
		keyL.BackgroundColor3 = Color3.fromRGB(38, 42, 52)
		keyL.BackgroundTransparency = 1
		keyL.Font = Enum.Font.GothamBold
		keyL.Text = item.key
		keyL.TextColor3 = Color3.fromRGB(240, 210, 170)
		keyL.TextSize = 12
		keyL.Parent = frame
		table.insert(allLabels, keyL)

		local keyCorner = Instance.new("UICorner")
		keyCorner.CornerRadius = UDim.new(0, 4)
		keyCorner.Parent = keyL

		local descL = Instance.new("TextLabel")
		descL.Position = UDim2.new(0, 134, 0, yPos)
		descL.Size = UDim2.new(1, -148, 0, 20)
		descL.BackgroundTransparency = 1
		descL.Font = Enum.Font.Gotham
		descL.Text = item.desc
		descL.TextColor3 = Color3.fromRGB(220, 228, 240)
		descL.TextSize = 12
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.TextTransparency = 1
		descL.Parent = frame
		table.insert(allLabels, descL)
	end

	local tIn = TweenInfo.new(0.3)
	TweenService:Create(frame, tIn, { BackgroundTransparency = 0.12 }):Play()
	TweenService:Create(stroke, tIn, { Transparency = 0.2 }):Play()
	for _, lbl in ipairs(allLabels) do
		TweenService:Create(lbl, tIn, { TextTransparency = 0, BackgroundTransparency = if lbl.BackgroundTransparency < 0.5 then 0.35 else 1 }):Play()
	end

	local function dismiss()
		local tOut = TweenInfo.new(0.4)
		TweenService:Create(frame, tOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, tOut, { Transparency = 1 }):Play()
		for _, lbl in ipairs(allLabels) do
			TweenService:Create(lbl, tOut, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
		task.delay(0.45, function() if sg.Parent then sg:Destroy() end end)
	end
	task.delay(5.0, dismiss)
end

-- -----------------------------------------------------------------------------
-- 1. SUPER BOUNCY TRAMPOLINE (Calibrated to Ferris Wheel Peak Height)
-- -----------------------------------------------------------------------------
local function configureTrampoline(playground: Model)
	local tram = playground:FindFirstChild("SuwaTrampoline")
	if not tram then return end

	local bouncePad = tram:FindFirstChild("TrampolineBouncePad") :: BasePart?
	if not bouncePad then return end

	local function triggerBounce(player: Player, hrp: BasePart, hum: Humanoid)
		local now = os.clock()
		if now - (bounceDebounce[player] or 0) < 0.65 then return end
		bounceDebounce[player] = now

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(hrp.AssemblyLinearVelocity.X * 0.8, 118, hrp.AssemblyLinearVelocity.Z * 0.8)
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

-- -----------------------------------------------------------------------------
-- 2. SPRING RIDERS (KUDA PEGAS): Realistic Whole-Model Rocking Motion on Sit
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
					local p = Players:GetPlayerFromCharacter(occ.Parent)
					if p then
						showTipCard(p, "🌸 KUDA PEGAS DANAU SUWA", {
							{ key = "🌊 DANAU SUWA", desc = "Menghadap langsung ke pemandangan danau!" },
							{ key = "🎠 GOYANG", desc = "Seluruh badan kuda pegas bergoyang" },
						}, Color3.fromRGB(245, 140, 180))
					end

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
-- 3. KOMIDI PUTAR (MERRY-GO-ROUND / ROUNDABOUT)
-- -----------------------------------------------------------------------------
local function configureMerryGoRound(playground: Model)
	local mgr = playground:FindFirstChild("SuwaMerryGoRound")
	if not mgr then return end

	local seats = {}
	for _, d in ipairs(mgr:GetDescendants()) do
		if d:IsA("Seat") then
			table.insert(seats, d)
			addSitPrompt(d, "Komidi Putar 🎠")
		end
	end

	local center = Vector3.new(-335, 2.0 + 1.8, -100)
	local currentAngle = 0
	local spinSpeed = 0.8

	RunService.Heartbeat:Connect(function(dt)
		if not mgr.Parent then return end
		local occupiedCount = 0
		for _, st in ipairs(seats) do
			if st.Occupant then occupiedCount = occupiedCount + 1 end
		end
		local targetSpeed = 0.6 + occupiedCount * 0.4
		spinSpeed = spinSpeed + (targetSpeed - spinSpeed) * dt * 2
		currentAngle = (currentAngle + spinSpeed * dt) % (2 * math.pi)

		local radius = 2.8
		for i, st in ipairs(seats) do
			local ang = currentAngle + (i - 1) * (math.pi / 2)
			local sx = center.X + math.cos(ang) * radius
			local sz = center.Z + math.sin(ang) * radius
			st.CFrame = CFrame.new(sx, center.Y, sz) * CFrame.Angles(0, -ang + math.rad(90), 0)
		end
	end)
end

-- -----------------------------------------------------------------------------
-- 4. PEROSOTAN (PLAYGROUND SLIDE INTERACTION & CLIMB)
-- -----------------------------------------------------------------------------
local function configureSlides(playground: Model)
	local slide = playground:FindFirstChild("SuwaPlaygroundSlideSet")
	if not slide then return end

	-- 1. Prompt at bottom of stairs to climb up immediately
	local climbPart = Instance.new("Part")
	climbPart.Name = "SlideClimbTrigger"
	climbPart.Size = Vector3.new(6, 4, 6)
	climbPart.CFrame = CFrame.new(-365 + 10.5, 3.5, -100 - 9.5)
	climbPart.Transparency = 1
	climbPart.CanCollide = false
	climbPart.Anchored = true
	climbPart.Parent = slide

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

	-- 2. Prompt at top of slide chute to slide down smoothly
	local slidePart = Instance.new("Part")
	slidePart.Name = "SlideChuteTrigger"
	slidePart.Size = Vector3.new(5, 4, 5)
	slidePart.CFrame = CFrame.new(-365 - 0.5, 14.5, -100 + 3.2)
	slidePart.Transparency = 1
	slidePart.CanCollide = false
	slidePart.Anchored = true
	slidePart.Parent = slide

	local slidePrompt = Instance.new("ProximityPrompt")
	slidePrompt.Name = "SlideDownPrompt"
	slidePrompt.ActionText = "Meluncur! 🛝"
	slidePrompt.ObjectText = "Corong Spiral"
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
-- 5. AYUNAN (SWINGS)
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
local function startArmWrestlingMatch(player1: Player, player2: Player, seat1: Seat, seat2: Seat, tableTop: BasePart)
	if armMatchActive then return end
	armMatchActive = true

	local matchPower = 0.5
	local matchRunning = true

	local function createDuelHUD(p: Player, isRed: boolean)
		local pGui = p:FindFirstChild("PlayerGui")
		if not pGui then return nil, nil, nil end
		local tipCard = pGui:FindFirstChild("ParkTipCard")
		if tipCard then tipCard:Destroy() end

		local cornerColor = if isRed then Color3.fromRGB(235, 65, 55) else Color3.fromRGB(45, 175, 235)
		local cornerName = if isRed then "SUDUT MERAH" else "SUDUT BIRU"

		local sg = Instance.new("ScreenGui")
		sg.Name = "ArmWrestleHUD"
		sg.ResetOnSpawn = false
		sg.Parent = pGui

		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.42, 0)
		frame.Size = UDim2.new(0, 420, 0, 170)
		frame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
		frame.BackgroundTransparency = 0.1
		frame.BorderSizePixel = 0
		frame.Parent = sg
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = cornerColor ; stroke.Thickness = 2.5

		local title = Instance.new("TextLabel", frame)
		title.Position = UDim2.new(0, 0, 0, 8)
		title.Size = UDim2.new(1, 0, 0, 22)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.Text = `🥊 DUEL PANCO: {cornerName} 🥊`
		title.TextColor3 = cornerColor ; title.TextSize = 15

		local status = Instance.new("TextLabel", frame)
		status.Position = UDim2.new(0, 0, 0, 32)
		status.Size = UDim2.new(1, 0, 0, 26)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamBold
		status.Text = "SIAP-SIAP..."
		status.TextColor3 = Color3.fromRGB(245, 215, 80) ; status.TextSize = 20

		local barBg = Instance.new("Frame", frame)
		barBg.AnchorPoint = Vector2.new(0.5, 0)
		barBg.Position = UDim2.new(0.5, 0, 0, 66)
		barBg.Size = UDim2.new(0, 360, 0, 22)
		barBg.BackgroundColor3 = Color3.fromRGB(38, 42, 55)
		barBg.BorderSizePixel = 0
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 8)

		local fill = Instance.new("Frame", barBg)
		fill.Size = UDim2.new(0.5, 0, 1, 0)
		fill.BackgroundColor3 = cornerColor
		fill.BorderSizePixel = 0
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)

		local tapBtn = Instance.new("TextButton", frame)
		tapBtn.AnchorPoint = Vector2.new(0.5, 0)
		tapBtn.Position = UDim2.new(0.5, 0, 0, 98)
		tapBtn.Size = UDim2.new(0, 270, 0, 40)
		tapBtn.BackgroundColor3 = cornerColor
		tapBtn.Font = Enum.Font.GothamBold
		tapBtn.Text = "💥 TEKAN / KLIK CEPAT! 💥"
		tapBtn.TextColor3 = Color3.fromRGB(255, 255, 255) ; tapBtn.TextSize = 14
		Instance.new("UICorner", tapBtn).CornerRadius = UDim.new(0, 10)

		tapBtn.MouseButton1Click:Connect(function()
			if matchRunning then
				matchPower = math.clamp(matchPower + (if isRed then 0.045 else -0.045), 0, 1)
			end
		end)

		local hint = Instance.new("TextLabel", frame)
		hint.Position = UDim2.new(0, 0, 0, 144)
		hint.Size = UDim2.new(1, 0, 0, 20)
		hint.BackgroundTransparency = 1
		hint.Font = Enum.Font.Gotham
		hint.Text = "Bisa tekan [SPACE] atau klik tombol di atas secepat mungkin!"
		hint.TextColor3 = Color3.fromRGB(195, 205, 220) ; hint.TextSize = 11

		return sg, status, fill
	end

	local sg1, status1, bar1 = createDuelHUD(player1, true)
	local sg2, status2, bar2 = createDuelHUD(player2, false)

	task.spawn(function()
		for c = 3, 1, -1 do
			if status1 then status1.Text = tostring(c) .. "..." end
			if status2 then status2.Text = tostring(c) .. "..." end
			task.wait(1.0)
		end
		if status1 then status1.Text = "⚡ TARIK SEKUAT TENAGA! ⚡" end
		if status2 then status2.Text = "⚡ TARIK SEKUAT TENAGA! ⚡" end

		local t0 = os.clock()
		while matchRunning and os.clock() - t0 < 8 do
			task.wait(0.08)
			if not (seat1.Occupant and seat2.Occupant) then break end
			matchPower = math.clamp(matchPower + (matchPower > 0.5 and -0.008 or 0.008), 0, 1)
			if bar1 then bar1.Size = UDim2.new(matchPower, 0, 1, 0) end
			if bar2 then bar2.Size = UDim2.new(1 - matchPower, 0, 1, 0) end
			if matchPower >= 0.95 or matchPower <= 0.05 then matchRunning = false ; break end
		end
		matchRunning = false

		local winName = if matchPower >= 0.5 then player1.DisplayName else player2.DisplayName
		local winText = `🏆 {winName} MENANG PANCO! 🏆`
		if status1 then status1.Text = winText end
		if status2 then status2.Text = winText end

		local arena = seat1:FindFirstAncestorOfClass("Model")
		local tTop = arena and arena:FindFirstChild("TableTop")
		if tTop then
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
			sparkles.Parent = tTop
			task.delay(3.5, function() sparkles:Destroy() end)
		end

		task.wait(3.5)
		if sg1 then sg1:Destroy() end
		if sg2 then sg2:Destroy() end
		armMatchActive = false
	end)
end

local function configureArmWrestling(playground: Model)
	local arena = playground:FindFirstChild("SuwaArmWrestlingArena")
	if not arena then return end
	local seatRed = arena:FindFirstChild("ArmSeat_Red") :: Seat?
	local seatBlue = arena:FindFirstChild("ArmSeat_Blue") :: Seat?
	local tableTop = arena:FindFirstChild("TableTop") :: BasePart?
	if not (seatRed and seatBlue and tableTop) then return end

	addSitPrompt(seatRed, "Meja Panco (Sudut Merah)")
	addSitPrompt(seatBlue, "Meja Panco (Sudut Biru)")

	local tipLines = {
		{ key = "PESERTA 2", desc = "Minta teman duduk di seberang" },
		{ key = "[KLIK]", desc = "Tekan tombol / Space secepat mungkin" },
		{ key = "🥊 MENANG", desc = "Dorong bar ke ujung untuk menang!" },
	}

	seatRed:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seatRed.Occupant then
			local p = Players:GetPlayerFromCharacter(seatRed.Occupant.Parent)
			if p then showTipCard(p, "🥊 MEJA PANCO 2-PEMAIN (Sudut Merah)", tipLines, Color3.fromRGB(235, 65, 55)) end
		end
		local occRed = seatRed.Occupant ; local occBlue = seatBlue.Occupant
		if occRed and occBlue and not armMatchActive then
			local p1 = Players:GetPlayerFromCharacter(occRed.Parent)
			local p2 = Players:GetPlayerFromCharacter(occBlue.Parent)
			if p1 and p2 then startArmWrestlingMatch(p1, p2, seatRed, seatBlue, tableTop) end
		end
	end)

	seatBlue:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seatBlue.Occupant then
			local p = Players:GetPlayerFromCharacter(seatBlue.Occupant.Parent)
			if p then showTipCard(p, "🥊 MEJA PANCO 2-PEMAIN (Sudut Biru)", tipLines, Color3.fromRGB(45, 175, 235)) end
		end
		local occRed = seatRed.Occupant ; local occBlue = seatBlue.Occupant
		if occRed and occBlue and not armMatchActive then
			local p1 = Players:GetPlayerFromCharacter(occRed.Parent)
			local p2 = Players:GetPlayerFromCharacter(occBlue.Parent)
			if p1 and p2 then startArmWrestlingMatch(p1, p2, seatRed, seatBlue, tableTop) end
		end
	end)
end

-- -----------------------------------------------------------------------------
-- 7. KOTAK PASIR (SANDBOX)
-- -----------------------------------------------------------------------------
local function configureSandbox(playground: Model)
	local sand = playground:FindFirstChild("SuwaSandbox")
	if not sand then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Main Pasir 🏖️"
	prompt.ObjectText = "Kotak Pasir Suwa"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.Parent = sand:FindFirstChildWhichIsA("BasePart") or sand
	prompt.Triggered:Connect(function(player)
		local att = Instance.new("Attachment")
		att.Parent = sand:FindFirstChildWhichIsA("BasePart") or sand
		local p2 = Instance.new("ParticleEmitter")
		p2.Texture = "rbxasset://textures/particles/smoke_main.dds"
		p2.Color = ColorSequence.new(Color3.fromRGB(240, 215, 140))
		p2.Transparency = NumberSequence.new(0.4, 1.0)
		p2.Lifetime = NumberRange.new(0.8, 1.4)
		p2.Rate = 22
		p2.Speed = NumberRange.new(2, 4)
		p2.Size = NumberSequence.new(0.5, 1.8)
		p2.Parent = att
		task.delay(1.5, function() att:Destroy() end)
	end)
end

-- -----------------------------------------------------------------------------
-- 8. BIANGLALA (FERRIS WHEEL)
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
		configureSlides(pg)
		configureArmWrestling(pg)
		configureSandbox(pg)
		configureTrampoline(pg)
		configureSpringRiders(pg)
		configureMerryGoRound(pg)
	end
end

return ParkInteractionService
