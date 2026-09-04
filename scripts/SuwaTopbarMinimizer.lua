--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

-- By default, topbar apps start hidden as requested: "diawal yang diatas hideapp aja aktif"
_G.SuwaTopbarAppsHidden = true
shared.SuwaTopbarAppsHidden = true

local existingApps = _G.SuwaTopbarApps or shared.SuwaTopbarApps or {}
local appsList = {}
for _, icon in ipairs(existingApps) do
	table.insert(appsList, icon)
	if typeof(icon) == "table" and icon.setEnabled then
		pcall(function()
			icon:setEnabled(false)
		end)
	end
end

local meta = {
	__newindex = function(t, k, v)
		rawset(t, k, v)
		if typeof(v) == "table" and v.setEnabled then
			if _G.SuwaTopbarAppsHidden then
				task.defer(function()
					pcall(function()
						v:setEnabled(false)
					end)
				end)
			else
				task.defer(function()
					pcall(function()
						v:setEnabled(true)
					end)
				end)
			end
		end
	end,
}

_G.SuwaTopbarApps = setmetatable(appsList, meta)
shared.SuwaTopbarApps = _G.SuwaTopbarApps

local toggleIcon = Icon.new()
toggleIcon:setLabel("▷ Show Apps")
toggleIcon:setCaption("Suwa Apps Menu (Click to expand / collapse)")
toggleIcon:setOrder(-100) -- Always pinned to the far left

_G.SuwaToggleIcon = toggleIcon
shared.SuwaToggleIcon = toggleIcon

local function applyState(hidden: boolean)
	_G.SuwaTopbarAppsHidden = hidden
	shared.SuwaTopbarAppsHidden = hidden
	if hidden then
		toggleIcon:setLabel("▷ Show Apps")
		for _, icon in ipairs(_G.SuwaTopbarApps) do
			pcall(function()
				icon:setEnabled(false)
			end)
		end
	else
		toggleIcon:setLabel("◁ Hide Apps")
		for _, icon in ipairs(_G.SuwaTopbarApps) do
			pcall(function()
				icon:setEnabled(true)
			end)
		end
	end
end

-- When selected: apps are hidden
toggleIcon.selected:Connect(function()
	applyState(true)
end)

-- When deselected: apps are shown
toggleIcon.deselected:Connect(function()
	applyState(false)
end)

-- Initialize active/hidden at the start
toggleIcon:select()
applyState(true)

-- Periodic safety enforcement during initial 3 seconds to catch any slow-loading legacy icons
task.spawn(function()
	for _ = 1, 10 do
		task.wait(0.3)
		if _G.SuwaTopbarAppsHidden then
			for _, icon in ipairs(_G.SuwaTopbarApps) do
				pcall(function()
					icon:setEnabled(false)
				end)
			end
		end
	end
end)
