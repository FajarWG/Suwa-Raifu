--!strict

-- BicycleService: Creator Store vehicle handling
-- Adds ProximityPrompt to bikes to require pressing 'E' to ride,
-- and disables auto-sit upon walking over the seat.

local BicycleService = {}

function BicycleService.init()
	print('[BicycleService] Setting up ProximityPrompts for Creator Store Bikes...')
	
	local folder = workspace:FindFirstChild('Bicycles')
	if not folder then return end

	for _, bike in ipairs(folder:GetChildren()) do
		if bike:IsA("Model") then
			-- Iterate over all seats (VehicleSeat and regular Seat)
			for _, seat in ipairs(bike:GetDescendants()) do
				if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
					-- Disable auto-sit when touched
					seat.CanTouch = false
					
					-- Remove any existing prompt just in case
					local existingPrompt = seat:FindFirstChild("RidePrompt")
					if existingPrompt then existingPrompt:Destroy() end
					
					-- Create prompt
					local prompt = Instance.new("ProximityPrompt")
					prompt.Name = "RidePrompt"
					if seat:IsA("VehicleSeat") then
						prompt.ActionText = "Mengemudi"
						prompt.ObjectText = "Sepeda"
					else
						prompt.ActionText = "Menumpang"
						prompt.ObjectText = "Kursi Penumpang"
					end
					prompt.KeyboardKeyCode = Enum.KeyCode.E
					prompt.MaxActivationDistance = 8
					prompt.RequiresLineOfSight = false
					prompt.Parent = seat
					
					-- Hide prompt when someone is sitting
					seat:GetPropertyChangedSignal("Occupant"):Connect(function()
						prompt.Enabled = (seat.Occupant == nil)
					end)
					
					prompt.Triggered:Connect(function(player)
						local character = player.Character
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						-- Check if player is NOT already sitting in something else!
						if humanoid and humanoid.SeatPart == nil and not seat.Occupant then
							-- Force the player to sit
							seat:Sit(humanoid)
						end
					end)
				end
			end
		end
	end
end

return BicycleService
