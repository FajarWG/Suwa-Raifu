--!strict

-- HUDController: status Yen.
-- Onboarding banner dan guide beam telah dinonaktifkan total agar UI bersih dan pemain bebas beraktivitas.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))
local RemoteController = require(script.Parent:WaitForChild('RemoteController'))

local HUDController = {}

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

local hudGui: ScreenGui? = nil
local currentProfile: ProfileTypes.Profile? = nil

local function createGui(): ScreenGui
	if hudGui then
		return hudGui
	end
	local gui = Instance.new('ScreenGui')
	gui.Name = 'HUDGui'
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	-- Panel status kiri atas
	local panel = Instance.new('Frame')
	panel.Name = 'StatusPanel'
	panel.Position = UDim2.new(0, 10, 0, 10)
	panel.Size = UDim2.new(0, 200, 0, 30)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local yenLabel = Instance.new('TextLabel')
	yenLabel.Name = 'Yen'
	yenLabel.Position = UDim2.new(0, 5, 0, 5)
	yenLabel.Size = UDim2.new(1, -10, 0, 18)
	yenLabel.BackgroundTransparency = 1
	yenLabel.Font = Enum.Font.GothamBold
	yenLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
	yenLabel.TextXAlignment = Enum.TextXAlignment.Left
	yenLabel.Text = '¥ 0'
	yenLabel.Parent = panel

	hudGui = gui
	return gui
end

local function setStatus(profile: ProfileTypes.Profile)
	if not hudGui then
		return
	end
	currentProfile = profile
	hudGui.StatusPanel.Yen.Text = '¥ ' .. tostring(profile.economy.yen)
end

function HUDController.refresh(profile: ProfileTypes.Profile)
	setStatus(profile)
end

function HUDController.init()
	createGui()

	RemoteController.onEvent('ProfileUpdated', function(profile: ProfileTypes.Profile)
		setStatus(profile)
	end)

	-- Ambil profile dari server
	task.spawn(function()
		local profile = RemoteController.invoke('GetProfile')
		if type(profile) == 'table' then
			setStatus(profile)
		end
	end)
end

return HUDController
