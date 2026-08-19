local player = game.Players.LocalPlayer
local ProximityPromptService = game:GetService("ProximityPromptService")

local function onCharacterAdded(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
        ProximityPromptService.Enabled = (hum.SeatPart == nil)
    end)
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
