const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('--- Starting UI Cleanup & Modernization ---');

  // 1. Read existing clean_EmoteSystemClient.lua
  let clientSource = fs.readFileSync('scripts/clean_EmoteSystemClient.lua', 'utf8');

  // Replace updateEmoteButtonVisibility to keep emoteButton.Visible = false and handle dockButton
  const oldVisibility = `local function updateEmoteButtonVisibility()
	if not chara or not chara.Parent then
		emoteButton.Visible = false
		if mainFrame.Visible then mainFrame.Visible = false end
		stopCurrentEmote()
		return
	end

	local humanoid = chara:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		emoteButton.Visible = false
		if mainFrame.Visible then mainFrame.Visible = false end
		stopCurrentEmote()
		return
	end

	local isSeated = humanoid.Sit or (humanoid.SeatPart ~= nil) or (chara:FindFirstChild("SeatWeld") ~= nil)
	local state = humanoid:GetState()
	local isSwimming = (state == Enum.HumanoidStateType.Swimming) or (humanoid.FloorMaterial == Enum.Material.Water)
	local isClimbing = (state == Enum.HumanoidStateType.Climbing)
	local isSleeping = (chara:GetAttribute("Sleeping") == true) or humanoid.PlatformStand

	local isBusy = isSeated or isSwimming or isClimbing or isSleeping

	if isBusy then
		emoteButton.Visible = false
		if mainFrame.Visible then
			mainFrame.Visible = false
		end
		stopCurrentEmote()
	else
		emoteButton.Visible = true
	end
end`;

  const newVisibility = `local dockButton = nil

local function updateEmoteButtonVisibility()
	emoteButton.Visible = false -- Always keep old blue square button hidden!

	if not chara or not chara.Parent then
		if dockButton then dockButton.Visible = false end
		if mainFrame.Visible then mainFrame.Visible = false end
		stopCurrentEmote()
		return
	end

	local humanoid = chara:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		if dockButton then dockButton.Visible = false end
		if mainFrame.Visible then mainFrame.Visible = false end
		stopCurrentEmote()
		return
	end

	local isSeated = humanoid.Sit or (humanoid.SeatPart ~= nil) or (chara:FindFirstChild("SeatWeld") ~= nil)
	local state = humanoid:GetState()
	local isSwimming = (state == Enum.HumanoidStateType.Swimming) or (humanoid.FloorMaterial == Enum.Material.Water)
	local isClimbing = (state == Enum.HumanoidStateType.Climbing)
	local isSleeping = (chara:GetAttribute("Sleeping") == true) or humanoid.PlatformStand

	local isBusy = isSeated or isSwimming or isClimbing or isSleeping

	if isBusy then
		if dockButton then dockButton.Visible = false end
		if mainFrame.Visible then
			mainFrame.Visible = false
		end
		stopCurrentEmote()
	else
		if dockButton then dockButton.Visible = true end
	end
end`;

  if (clientSource.includes('local function updateEmoteButtonVisibility()')) {
    clientSource = clientSource.replace(oldVisibility, newVisibility);
  }

  // Update toggleFrame to position mainFrame anchored to the right
  const oldToggle = `local function toggleFrame()
	if not canPlayEmote() and not mainFrame.Visible then
		-- Don't open panel if busy
		return
	end

	mainFrame.Visible = not mainFrame.Visible

	if mainFrame.Visible then
		if CONFIG.EnableSearch then
			searchBar.Text = ""
		end

		if showingFavorites then
			updateEmoteList(favoriteEmotes)
		else
			updateEmoteList(emoteAnimations)
		end

		TweenService:Create(mainFrame, TweenInfo.new(CONFIG.MenuOpenTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = lastFramePosition
		}):Play()
	end
end`;

  const newToggle = `local function toggleFrame()
	if not canPlayEmote() and not mainFrame.Visible then
		-- Don't open panel if busy
		return
	end

	mainFrame.Visible = not mainFrame.Visible

	if mainFrame.Visible then
		mainFrame.AnchorPoint = Vector2.new(1, 0)
		mainFrame.Position = UDim2.new(1, -16, 0, 58)
		lastFramePosition = mainFrame.Position

		if CONFIG.EnableSearch then
			searchBar.Text = ""
		end

		if showingFavorites then
			updateEmoteList(favoriteEmotes)
		else
			updateEmoteList(emoteAnimations)
		end

		TweenService:Create(mainFrame, TweenInfo.new(CONFIG.MenuOpenTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = lastFramePosition
		}):Play()
	end
end`;

  clientSource = clientSource.replace(oldToggle, newToggle);

  // Add Special Action Lay Down inside updateEmoteList
  const targetEmoteListStart = `updateEmoteList = function(emotes)
	-- Synchronously clean up existing buttons to prevent task.spawn race condition
	for _, child in ipairs(emoteList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "Template" then
			child:Destroy()
		end
	end`;

  const replacementEmoteListStart = `updateEmoteList = function(emotes)
	-- Synchronously clean up existing buttons to prevent task.spawn race condition
	for _, child in ipairs(emoteList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "Template" then
			child:Destroy()
		end
	end

	-- Special Actions (Lay Down / Relaxation Poses)
	local function createSpecialAction(actionName, callback)
		local sBtn = Instance.new("TextButton")
		sBtn.Name = "SpecialAction_" .. actionName
		sBtn.Size = CONFIG.ButtonSize
		sBtn.BackgroundColor3 = Color3.fromRGB(30, 42, 60)
		sBtn.BorderSizePixel = 0
		sBtn.Text = "  " .. actionName
		sBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
		sBtn.Font = CONFIG.ButtonFont
		sBtn.TextSize = CONFIG.ButtonTextSize
		sBtn.TextXAlignment = Enum.TextXAlignment.Left
		sBtn.AutoButtonColor = true
		sBtn.ClipsDescendants = true
		sBtn.LayoutOrder = -100

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = sBtn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(90, 130, 180)
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = sBtn

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.Parent = sBtn

		sBtn.Activated:Connect(function()
			stopCurrentEmote()
			callback()
			mainFrame.Visible = false
		end)
		sBtn.Parent = emoteList
	end

	if not showingFavorites and (not searchBar or searchBar.Text == "") then
		createSpecialAction("🛌 Lay Down (Terlentang)", function()
			if _G.SuwaLieDown then
				_G.SuwaLieDown.enterPose("Terlentang")
			end
		end)
		createSpecialAction("🛌 Lay Down (Tengkurap)", function()
			if _G.SuwaLieDown then
				_G.SuwaLieDown.enterPose("Tengkurap")
			end
		end)
	end`;

  clientSource = clientSource.replace(targetEmoteListStart, replacementEmoteListStart);

  // Add UIDock pill button integration and chat command at the bottom of EmoteSystemClient
  const hookBottom = `
-- ==================== TOP DOCK & CHAT COMMAND INTEGRATION ====================
task.spawn(function()
	local ok, UIDock = pcall(function()
		local ps = player:WaitForChild("PlayerScripts", 15)
		local c = ps:WaitForChild("Client", 15)
		local ctrl = c:WaitForChild("controllers", 15)
		local uidockMod = ctrl:WaitForChild("UIDock", 15)
		return require(uidockMod)
	end)
	if ok and UIDock then
		dockButton = UIDock.pillButton("Emotes", 1)
		dockButton.Name = "EmotesButton"
		dockButton.ZIndex = 2
		dockButton.Parent = UIDock.getTopRightRow()
		dockButton.Activated:Connect(toggleFrame)
		emoteButton.Visible = false
		updateEmoteButtonVisibility()
	end
end)

local TextChatService = game:GetService("TextChatService")
local function onChatMessage(msg)
	local clean = string.lower(string.gsub(msg, "^%s+", ""):gsub("%s+$", ""))
	if clean == "/dance" or clean == "/emote" or clean == "/emotes" or clean == "/joget" then
		toggleFrame()
	end
end
player.Chatted:Connect(onChatMessage)
task.spawn(function()
	pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			local textChannels = TextChatService:WaitForChild("TextChannels", 5)
			if textChannels then
				local rbxGeneral = textChannels:WaitForChild("RBXGeneral", 5)
				if rbxGeneral and rbxGeneral:IsA("TextChannel") then
					rbxGeneral.MessageReceived:Connect(function(textChatMessage)
						if textChatMessage.TextSource and textChatMessage.TextSource.UserId == player.UserId then
							onChatMessage(textChatMessage.Text)
						end
					end)
				end
			end
		end
	end)
end)
`;

  clientSource = clientSource + hookBottom;

  fs.writeFileSync('scripts/clean_EmoteSystemClient.lua', clientSource);
  console.log('clean_EmoteSystemClient.lua updated.');

  // 2. AutoResize code
  const autoResizeSrc = `-- AutoResize for EmoteSystemGui with responsive height clamping
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local screenGui = script.Parent

local REFERENCE_WIDTH = 1180
local REFERENCE_HEIGHT = 640
local MIN_SCALE = 0.5

local function scaleFactor()
	local camera = Workspace.CurrentCamera
	local size = if camera
		then camera.ViewportSize
		else Vector2.new(REFERENCE_WIDTH, REFERENCE_HEIGHT)
	if size.X <= 0 or size.Y <= 0 then
		return 1
	end
	local fit = math.min(size.X / REFERENCE_WIDTH, size.Y / REFERENCE_HEIGHT)
	return math.clamp(fit, MIN_SCALE, 1)
end

local uiScale = screenGui:FindFirstChildOfClass('UIScale') or Instance.new('UIScale')
uiScale.Parent = screenGui

local mainFrame = screenGui:WaitForChild('MainFrame')

local function refresh()
	local factor = scaleFactor()
	uiScale.Scale = factor

	-- Responsive height for MainFrame on mobile / small viewports:
	local camera = Workspace.CurrentCamera
	local vHeight = if camera and camera.ViewportSize.Y > 0 then camera.ViewportSize.Y else REFERENCE_HEIGHT
	local availableY = (vHeight / factor) - 58 - 20
	local targetHeight = math.clamp(math.floor(availableY), 180, 320)
	mainFrame.Size = UDim2.new(0, 250, 0, targetHeight)
	mainFrame.AnchorPoint = Vector2.new(1, 0)
	mainFrame.Position = UDim2.new(1, -16, 0, 58)
end

local function watch(camera)
	if camera then
		camera:GetPropertyChangedSignal('ViewportSize'):Connect(refresh)
	end
end

refresh()
watch(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	watch(Workspace.CurrentCamera)
	refresh()
end)
`;
  fs.writeFileSync('scripts/scratch_AutoResize.lua', autoResizeSrc);

  // 3. Deploy to Roblox Studio via executeLuau
  console.log('Deploying updates to Roblox Studio...');
  const deployScript = `
    local es = game:GetService("StarterGui"):FindFirstChild("EmoteSystemGui")
    if not es then return "EmoteSystemGui not found" end

    -- Hide old standalone button
    local oldBtn = es:FindFirstChild("EmoteButton")
    if oldBtn then
      oldBtn.Visible = false
    end

    -- Anchor MainFrame on the top right
    local mf = es:FindFirstChild("MainFrame")
    if mf then
      mf.AnchorPoint = Vector2.new(1, 0)
      mf.Position = UDim2.new(1, -16, 0, 58)
      mf.Visible = false
    end

    -- Update AutoResize
    local ar = es:FindFirstChild("AutoResize")
    if ar then
      ar.Source = [===[${autoResizeSrc}]===]
    end

    -- Update EmoteSystemClient
    local esc = es:FindFirstChild("EmoteSystemClient")
    if esc then
      esc.Source = [===[${clientSource}]===]
    end

    return "EmoteSystemGui updated in Studio successfully!"
  `;

  const res = await executeLuau(deployScript, 'Edit');
  console.log('Studio Deploy Result:', res?.content?.[0]?.text);

  console.log('--- UI Cleanup Completed Successfully ---');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
