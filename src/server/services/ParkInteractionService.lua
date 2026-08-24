--!strict

-- Makes park benches/seats genuinely interactive, whatever their source (Creator Store included).

local ParkInteractionService = {}

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
			and not descendant:FindFirstAncestor("Bicycles")
			and not descendant:FindFirstAncestor("LakeCrafts")
			and not descendant.Parent:FindFirstChild(`Functional_{descendant.Name}`)
		then
			makeFunctionalSeat(descendant, 'Park seat')
		end
	end
end

function ParkInteractionService.init()
	configureBenches()
end

return ParkInteractionService
