--!strict

-- Makes park furniture and playground equipment genuinely interactive.

local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

type SwingRuntime = {
	seat: Seat,
	pivot: CFrame,
	parts: { BasePart },
	relatives: { [BasePart]: CFrame },
	phase: number,
}

local ParkInteractionService = {}
local swings: { SwingRuntime } = {}
local seesaw: { board: BasePart, baseCFrame: CFrame, left: Seat, right: Seat }? = nil
local slideBusy: { [Player]: boolean } = {}

local function addSitPrompt(seat: Seat, objectText: string)
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'SitPrompt'
	prompt.ActionText = 'Duduk'
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	
	-- Hide prompt when occupied (as a fallback)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		prompt.Enabled = (seat.Occupant == nil)
	end)

	prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if humanoid and humanoid.SeatPart == nil and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end)
end

local function makeFunctionalSeat(visual: BasePart, objectText: string): Seat
	local seat = Instance.new('Seat')
	seat.Name = `Functional_{visual.Name}`
	seat.Size = Vector3.new(math.clamp(visual.Size.X, 1.5, 6), 0.5, math.clamp(visual.Size.Z, 1.4, 2.5))
	seat.CFrame = visual.CFrame * CFrame.new(0, visual.Size.Y / 2 + 0.28, 0)
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanTouch = false
	seat.Parent = visual.Parent
	seat:SetAttribute('VisualSeatPart', visual.Name)
	addSitPrompt(seat, objectText)
	return seat
end

local function configureBenches()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('Seat') then
			-- Existing Seat objects (e.g. from Creator Store benches)
			if not descendant:FindFirstAncestor("Bicycles")
				and not descendant:FindFirstAncestor("LakeCrafts") 
				and not descendant:FindFirstChild("SitPrompt") 
				and not descendant:FindFirstChild("RidePrompt")
			then
				descendant.CanTouch = false
				addSitPrompt(descendant, 'Bangku')
			end
		elseif
			descendant:IsA('BasePart')
			and not descendant:IsA('VehicleSeat')
			and string.find(descendant.Name, 'Seat')
			and not string.find(descendant.Name, 'SwingSeat')
			and not string.find(descendant.Name, 'Seesaw')
			and not descendant:FindFirstAncestor("Bicycles")
			and not descendant:FindFirstAncestor("LakeCrafts")
			and not descendant.Parent:FindFirstChild(`Functional_{descendant.Name}`)
		then
			makeFunctionalSeat(descendant, 'Park seat')
		end
	end
end

local function configureSwings(playground: Instance)
	for index = 1, 2 do
		local visualSeat = playground:FindFirstChild(`SwingSeat0{index}`)
		local ropeA = playground:FindFirstChild(`SwingRope0{index}A`)
		local ropeB = playground:FindFirstChild(`SwingRope0{index}B`)
		if
			visualSeat
			and visualSeat:IsA('BasePart')
			and ropeA
			and ropeA:IsA('BasePart')
			and ropeB
			and ropeB:IsA('BasePart')
		then
			local seat = makeFunctionalSeat(visualSeat, 'Playground swing')
			local upperY = math.max(ropeA.Position.Y + ropeA.Size.Y / 2, ropeB.Position.Y + ropeB.Size.Y / 2)
			local pivot =
				CFrame.new((ropeA.Position.X + ropeB.Position.X) / 2, upperY, (ropeA.Position.Z + ropeB.Position.Z) / 2)
			local parts = { visualSeat, ropeA, ropeB, seat }
			local relatives: { [BasePart]: CFrame } = {}
			for _, part in parts do
				relatives[part] = pivot:ToObjectSpace(part.CFrame)
			end
			table.insert(swings, {
				seat = seat,
				pivot = pivot,
				parts = parts,
				relatives = relatives,
				phase = index * 1.4,
			})
		end
	end
end

local function configureSeesaw(playground: Instance)
	local board = playground:FindFirstChild('SeesawBoard')
	if not board or not board:IsA('BasePart') then
		return
	end
	local function makeEndSeat(name: string, xOffset: number): Seat
		local seat = Instance.new('Seat')
		seat.Name = name
		seat.Size = Vector3.new(3.2, 0.5, 2.4)
		seat.CFrame = board.CFrame * CFrame.new(xOffset, board.Size.Y / 2 + 0.35, 0)
		seat.Transparency = 1
		seat.Anchored = true
		seat.CanCollide = false
		seat.CanTouch = false
		seat.Parent = playground
		addSitPrompt(seat, 'Seesaw')
		return seat
	end
	seesaw = {
		board = board,
		baseCFrame = board.CFrame,
		left = makeEndSeat('SeesawLeftSeat', -8.5),
		right = makeEndSeat('SeesawRightSeat', 8.5),
	}
end

local function configureSlide(playground: Instance)
	local platform = playground:FindFirstChild('SlidePlatform')
	if not platform or not platform:IsA('BasePart') then
		return
	end
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'SlidePrompt'
	prompt.ActionText = 'Slide'
	prompt.ObjectText = 'Playground slide'
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = platform
	prompt.Triggered:Connect(function(player)
		if slideBusy[player] then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		local root = character and character:FindFirstChild('HumanoidRootPart')
		if not humanoid or not root or not root:IsA('BasePart') then
			return
		end
		slideBusy[player] = true
		humanoid.PlatformStand = true
		root.Anchored = true
		root.CFrame = CFrame.new(-340, 11.8, -94) * CFrame.Angles(0, math.rad(180), 0)
		local tween = TweenService:Create(
			root,
			TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ CFrame = CFrame.new(-340, 2.4, -73) * CFrame.Angles(0, math.rad(180), math.rad(-18)) }
		)
		tween:Play()
		tween.Completed:Once(function()
			if root.Parent then
				root.Anchored = false
				humanoid.PlatformStand = false
			end
			slideBusy[player] = nil
		end)
	end)
end

local function updatePlayground()
	local now = os.clock()
	for _, swing in swings do
		local angle = if swing.seat.Occupant then math.sin(now * 1.75 + swing.phase) * math.rad(22) else 0
		local frame = swing.pivot * CFrame.Angles(angle, 0, 0)
		for _, part in swing.parts do
			if part.Parent then
				part.CFrame = frame * swing.relatives[part]
			end
		end
	end
	if seesaw then
		local leftOccupied = seesaw.left.Occupant ~= nil
		local rightOccupied = seesaw.right.Occupant ~= nil
		local angle = 0
		if leftOccupied and rightOccupied then
			angle = math.sin(now * 1.45) * math.rad(11)
		elseif leftOccupied then
			angle = math.rad(-11)
		elseif rightOccupied then
			angle = math.rad(11)
		end
		seesaw.board.CFrame = seesaw.baseCFrame * CFrame.Angles(0, 0, angle)
		seesaw.left.CFrame = seesaw.board.CFrame * CFrame.new(-8.5, seesaw.board.Size.Y / 2 + 0.35, 0)
		seesaw.right.CFrame = seesaw.board.CFrame * CFrame.new(8.5, seesaw.board.Size.Y / 2 + 0.35, 0)
	end
end

function ParkInteractionService.init()
	configureBenches()
	local activities = workspace:FindFirstChild('LakesideActivities')
	local playground = activities and activities:FindFirstChild('LakesidePlayground')
	if playground then
		configureSwings(playground)
		configureSeesaw(playground)
		configureSlide(playground)
	end
	RunService.Heartbeat:Connect(updatePlayground)
end

return ParkInteractionService
