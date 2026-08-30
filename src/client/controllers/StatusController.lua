--!strict

-- Sleek Status button + popup in the unified Top-Right Dock.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIDock = require(script.Parent:WaitForChild('UIDock'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))
local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))

local player = Players.LocalPlayer

local StatusController = {}

local MAX_LENGTH = Config.statusMaxLength

local function buildGui()
	local playerGui = player:WaitForChild('PlayerGui')
	local existing = playerGui:FindFirstChild('SuwaStatusGui')
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaStatusGui'
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- 1. Top-Right Dock Button
	local button = UIDock.pillButton('Status', 2)
	button.Name = 'StatusButton'
	button.ZIndex = 2
	button.Parent = UIDock.getTopRightRow()

	-- 2. Popup Panel
	local panel = Instance.new('Frame')
	panel.Name = 'Panel'
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 58)
	panel.Size = UDim2.new(0, 270, 0, 108)
	panel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.ZIndex = 15
	panel.Parent = gui

	local panelCorner = Instance.new('UICorner')
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new('UIStroke')
	panelStroke.Color = Color3.fromRGB(150, 180, 220)
	panelStroke.Thickness = 1.2
	panelStroke.Transparency = 0.4
	panelStroke.Parent = panel

	UIScaling.fit(panel)

	local padding = Instance.new('UIPadding')
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	local textBox = Instance.new('TextBox')
	textBox.Name = 'Input'
	textBox.Size = UDim2.new(1, 0, 0, 34)
	textBox.BackgroundColor3 = Color3.fromRGB(38, 44, 58)
	textBox.TextColor3 = Color3.new(1, 1, 1)
	textBox.PlaceholderText = 'Enter your status message...'
	textBox.PlaceholderColor3 = Color3.fromRGB(160, 170, 185)
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 13
	textBox.ClearTextOnFocus = false
	textBox.Text = ''
	textBox.ZIndex = 16
	textBox.Parent = panel

	local inputCorner = Instance.new('UICorner')
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = textBox

	local counter = Instance.new('TextLabel')
	counter.Name = 'Counter'
	counter.Size = UDim2.new(1, 0, 0, 16)
	counter.Position = UDim2.new(0, 0, 0, 38)
	counter.BackgroundTransparency = 1
	counter.Font = Enum.Font.Gotham
	counter.TextSize = 11
	counter.TextColor3 = Color3.fromRGB(160, 175, 195)
	counter.TextXAlignment = Enum.TextXAlignment.Right
	counter.Text = `0 / {MAX_LENGTH}`
	counter.ZIndex = 16
	counter.Parent = panel

	local buttonRow = Instance.new('Frame')
	buttonRow.Name = 'Buttons'
	buttonRow.Size = UDim2.new(1, 0, 0, 30)
	buttonRow.Position = UDim2.new(0, 0, 0, 56)
	buttonRow.BackgroundTransparency = 1
	buttonRow.ZIndex = 16
	buttonRow.Parent = panel

	local setBtn = Instance.new('TextButton')
	setBtn.Name = 'Set'
	setBtn.Size = UDim2.new(0.48, 0, 1, 0)
	setBtn.BackgroundColor3 = Color3.fromRGB(56, 128, 92)
	setBtn.TextColor3 = Color3.new(1, 1, 1)
	setBtn.Font = Enum.Font.GothamBold
	setBtn.TextSize = 12
	setBtn.Text = 'Set Status'
	setBtn.ZIndex = 16
	setBtn.Parent = buttonRow
	local setCorner = Instance.new('UICorner')
	setCorner.CornerRadius = UDim.new(0, 6)
	setCorner.Parent = setBtn

	local clearBtn = Instance.new('TextButton')
	clearBtn.Name = 'Clear'
	clearBtn.Size = UDim2.new(0.48, 0, 1, 0)
	clearBtn.Position = UDim2.new(0.52, 0, 0, 0)
	clearBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
	clearBtn.TextColor3 = Color3.new(1, 1, 1)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 12
	clearBtn.Text = 'Clear'
	clearBtn.ZIndex = 16
	clearBtn.Parent = buttonRow
	local clearCorner = Instance.new('UICorner')
	clearCorner.CornerRadius = UDim.new(0, 6)
	clearCorner.Parent = clearBtn

	button.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			textBox:CaptureFocus()
		end
	end)

	textBox:GetPropertyChangedSignal('Text'):Connect(function()
		local text = textBox.Text
		if #text > MAX_LENGTH then
			textBox.Text = string.sub(text, 1, MAX_LENGTH)
			text = textBox.Text
		end
		counter.Text = `{#text} / {MAX_LENGTH}`
		counter.TextColor3 = if #text >= MAX_LENGTH
			then Color3.fromRGB(240, 110, 110)
			else Color3.fromRGB(160, 175, 195)
	end)

	setBtn.MouseButton1Click:Connect(function()
		local text = textBox.Text
		if #text > 0 then
			RemoteController.fire('SetStatus', text)
		end
		panel.Visible = false
	end)

	clearBtn.MouseButton1Click:Connect(function()
		RemoteController.fire('ClearStatus')
		textBox.Text = ''
		panel.Visible = false
	end)
end

function StatusController.init()
	buildGui()
end

return StatusController
