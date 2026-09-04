-- ServerScriptService.BebeqAvatarServer
-- Applies Suwa Life costumes to player characters safely and instantly
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local outfitEvent = ReplicatedStorage:FindFirstChild("ApplyOutfitEvent")
if not outfitEvent then
	outfitEvent = Instance.new("RemoteEvent")
	outfitEvent.Name = "ApplyOutfitEvent"
	outfitEvent.Parent = ReplicatedStorage
end

local CostumeConfig = require(ReplicatedStorage:WaitForChild("SuwaCostumeConfig"))

outfitEvent.OnServerEvent:Connect(function(player, action, outfitId)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	if action == "Apply" and outfitId then
		local preset = CostumeConfig.GetById(outfitId)
		if not preset then return end

		local currentDesc = hum:GetAppliedDescription() or Instance.new("HumanoidDescription")
		local currentEmotes = currentDesc:GetEmotes()
		local currentEquipped = currentDesc:GetEquippedEmotes()

		-- Clone current description to preserve body shape, hair, and accessories
		local newDesc = currentDesc:Clone()
		newDesc.Shirt = preset.shirt
		newDesc.Pants = preset.pants

		-- Preserve player equipped emotes
		pcall(function()
			newDesc:SetEmotes(currentEmotes)
			newDesc:SetEquippedEmotes(currentEquipped)
		end)

		local ok, err = pcall(function()
			hum:ApplyDescription(newDesc)
		end)
		if not ok then
			local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
			shirt.ShirtTemplate = "rbxassetid://" .. tostring(preset.shirt)
			local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
			pants.PantsTemplate = "rbxassetid://" .. tostring(preset.pants)
		end

	elseif action == "Reset" then
		local success, defaultDesc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end)

		if success and defaultDesc then
			local currentDesc = hum:GetAppliedDescription()
			if currentDesc then
				pcall(function()
					defaultDesc:SetEmotes(currentDesc:GetEmotes())
					defaultDesc:SetEquippedEmotes(currentDesc:GetEquippedEmotes())
				end)
			end
			pcall(function()
				hum:ApplyDescription(defaultDesc)
			end)
		end
	end
end)
