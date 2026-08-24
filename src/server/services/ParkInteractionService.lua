--!strict

-- Turns bench props that are plain BaseParts (rather than real Seat objects)
-- into something sittable. The prompt itself is added by
-- VehicleInteractionService, which owns every seat in the world and picks these
-- up through its DescendantAdded listener.

local ParkInteractionService = {}

local VEHICLE_FOLDERS = { Bicycles = true, LakeCrafts = true }

local function isInsideVehicle(instance: Instance): boolean
	local node = instance.Parent
	while node and node ~= workspace do
		if node:IsA('Folder') and VEHICLE_FOLDERS[node.Name] then
			return true
		end
		if node:IsA('Model') and node:GetAttribute('SuwaRigged') then
			return true
		end
		node = node.Parent
	end
	return false
end

local function makeFunctionalSeat(visual: BasePart)
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
end

function ParkInteractionService.init()
	local created = 0
	for _, descendant in workspace:GetDescendants() do
		if
			descendant:IsA('BasePart')
			and not descendant:IsA('Seat')
			and not descendant:IsA('VehicleSeat')
			and string.find(descendant.Name, 'Seat')
			and not isInsideVehicle(descendant)
			and descendant.Parent
			and not descendant.Parent:FindFirstChild(`Functional_{descendant.Name}`)
		then
			makeFunctionalSeat(descendant)
			created += 1
		end
	end
	print(`[Park] Created {created} functional bench seats.`)
end

return ParkInteractionService
