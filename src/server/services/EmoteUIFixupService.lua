--!strict

-- The "Emote Dance & Sync" toolbox asset (StarterGui.EmoteSystemGui, not part
-- of this Rojo project) ships its own emote button and panel at hardcoded
-- positions that were hand-tuned to sit next to whatever the custom top-right
-- HUD dock looked like at the time. That dock is now dynamically sized, so
-- the emote button drifted out of alignment and overlapped it, and the panel
-- opened nowhere near the button that opens it.
--
-- This patches both instances' *default* Position/AnchorPoint directly on the
-- StarterGui template, once, before any player joins. That matters because
-- the asset's own LocalScript does
--   local lastFramePosition = mainFrame.Position
-- once at startup with no yield in between: if we patched the button/panel
-- from a client-side script instead, we'd be racing that line, and losing the
-- race would silently leave the panel opening at the old broken position.
-- Patching the server-side template means every player's PlayerGui clones in
-- with the corrected values already in place, before their local scripts run.

local StarterGui = game:GetService('StarterGui')
local KeyframeSequenceProvider = game:GetService('KeyframeSequenceProvider')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local EmoteUIFixupService = {}

local function registerCustomEmotes()
	local customKfsFolder = ServerStorage:FindFirstChild('CustomEmoteKeyframes')
		or ReplicatedStorage:FindFirstChild('CustomEmoteKeyframes')
	if not customKfsFolder then
		return
	end

	local emotesFolder = ReplicatedStorage:FindFirstChild('Emotes')
	if not emotesFolder then
		emotesFolder = Instance.new('Folder')
		emotesFolder.Name = 'Emotes'
		emotesFolder.Parent = ReplicatedStorage
	end

	-- Remove broken emotes if they ever reappear
	local broken = {
		['Shake Dance'] = true,
		['Tuff'] = true,
		["If You're The Best"] = true,
	}
	for _, child in emotesFolder:GetChildren() do
		if broken[child.Name] then
			child:Destroy()
		end
	end

	-- Register all custom KeyframeSequences
	for _, kfs in customKfsFolder:GetChildren() do
		if kfs:IsA('KeyframeSequence') then
			local ok, animId = pcall(function()
				return KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
			end)

			if ok and typeof(animId) == 'string' and animId ~= '' then
				local anim = emotesFolder:FindFirstChild(kfs.Name)
				if not anim then
					anim = Instance.new('Animation')
					anim.Name = kfs.Name
					anim.Parent = emotesFolder
				end
				if anim:IsA('Animation') then
					anim.AnimationId = animId
				end
			end
		end
	end
end

function EmoteUIFixupService.init()
	-- 1. Register custom dances (Dance Brazil, Orange Justice, Floss, etc.)
	registerCustomEmotes()

	-- 2. Clean StarterGui template positioning for EmoteSystemGui
	local emoteGui = StarterGui:FindFirstChild('EmoteSystemGui')
	if not emoteGui then
		return
	end

	local button = emoteGui:FindFirstChild('EmoteButton')
	if button and button:IsA('GuiObject') then
		button.Visible = false
	end

	local mainFrame = emoteGui:FindFirstChild('MainFrame')
	if mainFrame and mainFrame:IsA('GuiObject') then
		mainFrame.AnchorPoint = Vector2.new(1, 0)
		mainFrame.Position = UDim2.new(1, -16, 0, 58)
		mainFrame.Size = UDim2.new(0, 250, 0, 310)
		mainFrame.ClipsDescendants = true

		local emoteList = mainFrame:FindFirstChild('EmoteList')
		if emoteList and emoteList:IsA('ScrollingFrame') then
			emoteList.Position = UDim2.new(0, 10, 0, 120)
			emoteList.Size = UDim2.new(1, -20, 1, -128)
			emoteList.ClipsDescendants = true
			emoteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
			emoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
			emoteList.ScrollBarThickness = 6
			emoteList.ScrollingDirection = Enum.ScrollingDirection.Y
			emoteList.ElasticBehavior = Enum.ElasticBehavior.Always
		end
	end
end

return EmoteUIFixupService
