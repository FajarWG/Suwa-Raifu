const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

-- Remove old model if exists
local oldPath = trail:FindFirstChild("BridgeReturnTrail")
if oldPath then oldPath:Destroy() end

local model = Instance.new("Model")
model.Name = "BridgeReturnTrail"
model.Parent = trail

-- Return Path Waypoints from Ravine Floor (Y=62) to Bridge Starting Deck (Y=164)
-- Ravine floor is around (24, 62, -1565)
-- We climb along the eastern slope:
local waypoints = {
    Vector3.new(24, 62, -1565),   -- Landing platform at bottom
    Vector3.new(22, 75, -1558),
    Vector3.new(20, 90, -1552),
    Vector3.new(18, 108, -1546),
    Vector3.new(16, 126, -1541),
    Vector3.new(14, 144, -1537),
    Vector3.new(10, 163.6, -1535) -- Top bridge starting deck
}

-- 1. Bottom Landing Platform & Sign
local bottomLanding = Instance.new("Part")
bottomLanding.Name = "ReturnBottomLanding"
bottomLanding.Size = Vector3.new(10, 1.2, 8)
bottomLanding.CFrame = CFrame.new(waypoints[1] + Vector3.new(0, 0.6, 0))
bottomLanding.Material = Enum.Material.WoodPlanks
bottomLanding.Color = Color3.fromRGB(115, 80, 50)
bottomLanding.Anchored = true
bottomLanding.Parent = model

local signPost = Instance.new("Part")
signPost.Name = "SignPost"
signPost.Size = Vector3.new(0.6, 7, 0.6)
signPost.CFrame = bottomLanding.CFrame * CFrame.new(4, 4.1, 3)
signPost.Material = Enum.Material.Wood
signPost.Color = Color3.fromRGB(80, 55, 35)
signPost.Anchored = true
signPost.Parent = model

local sign = Instance.new("Part")
sign.Name = "ReturnSign"
sign.Size = Vector3.new(7.5, 1.8, 0.3)
sign.CFrame = signPost.CFrame * CFrame.new(-3.5, 1.2, 0)
sign.Material = Enum.Material.Wood
sign.Color = Color3.fromRGB(45, 30, 20)
sign.Anchored = true
sign.Parent = model

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = sign

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "つり橋 復帰小道\\nBRIDGE RETRY PATH (CLIMB UP)"
txt.TextColor3 = Color3.fromRGB(250, 240, 220)
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true
txt.Parent = sg

-- Bottom Lantern
local botLantern = Instance.new("Part")
botLantern.Name = "BottomLantern"
botLantern.Size = Vector3.new(1.0, 1.4, 1.0)
botLantern.CFrame = signPost.CFrame * CFrame.new(0, 3.8, 0)
botLantern.Material = Enum.Material.Neon
botLantern.Color = Color3.fromRGB(255, 210, 130)
botLantern.Anchored = true
botLantern.Parent = model

local bLgt = Instance.new("PointLight")
bLgt.Color = Color3.fromRGB(255, 175, 90)
bLgt.Brightness = 2.8
bLgt.Range = 26
bLgt.Shadows = true
bLgt.Parent = botLantern

-- 2. Build Stair Segments connecting each waypoint pair
local totalSteps = 0
for w = 1, #waypoints - 1 do
    local pA = waypoints[w]
    local pB = waypoints[w + 1]
    local dist = (pB - pA).Magnitude
    local dY = pB.Y - pA.Y
    
    -- Number of steps in this flight (rise ~1.2 studs per step)
    local nSteps = math.max(3, math.floor(dY / 1.4))
    
    for s = 1, nSteps do
        totalSteps = totalSteps + 1
        local alpha = s / nSteps
        local stepPos = pA:Lerp(pB, alpha)
        
        -- Facing direction along flight
        local fDir = Vector3.new(pB.X - pA.X, 0, pB.Z - pA.Z).Unit
        local yaw = math.atan2(-fDir.X, -fDir.Z)
        
        local stepPart = Instance.new("Part")
        stepPart.Name = "ReturnStep" .. totalSteps
        stepPart.Size = Vector3.new(5.5, 1.2, 2.4)
        stepPart.CFrame = CFrame.new(stepPos) * CFrame.Angles(0, yaw, 0)
        stepPart.Material = Enum.Material.WoodPlanks
        stepPart.Color = Color3.fromRGB(115, 80, 50)
        stepPart.Anchored = true
        stepPart.Parent = model
        
        -- Add handrail posts every 3 steps
        if s % 3 == 0 or s == nSteps then
            for _, side in ipairs({ -2.8, 2.8 }) do
                local post = Instance.new("Part")
                post.Name = "RailPost"
                post.Size = Vector3.new(0.4, 4.5, 0.4)
                post.CFrame = stepPart.CFrame * CFrame.new(side, 2.25, 0)
                post.Material = Enum.Material.Wood
                post.Color = Color3.fromRGB(75, 50, 30)
                post.Anchored = true
                post.Parent = model
            end
        end
    end
    
    -- Lantern at the top of each intermediate flight
    if w > 1 and w < #waypoints then
        local midLantern = Instance.new("Part")
        midLantern.Name = "MidFlightLantern" .. w
        midLantern.Size = Vector3.new(0.8, 1.2, 0.8)
        midLantern.CFrame = CFrame.new(pB + Vector3.new(2.8, 4.5, 0))
        midLantern.Material = Enum.Material.Neon
        midLantern.Color = Color3.fromRGB(255, 210, 130)
        midLantern.Anchored = true
        midLantern.Parent = model
        
        local mLgt = Instance.new("PointLight")
        mLgt.Color = Color3.fromRGB(255, 175, 90)
        mLgt.Brightness = 2.4
        mLgt.Range = 20
        mLgt.Shadows = true
        mLgt.Parent = midLantern
    end
end

-- 3. Top Connection Ramp into Bridge Deck
local topDeck = Instance.new("Part")
topDeck.Name = "ReturnTopLanding"
topDeck.Size = Vector3.new(7, 1.2, 6)
topDeck.CFrame = CFrame.new(10.0, 163.6, -1535.0)
topDeck.Material = Enum.Material.WoodPlanks
topDeck.Color = Color3.fromRGB(115, 80, 50)
topDeck.Anchored = true
topDeck.Parent = model

-- 4. Also add a Truss Escape Ladder on the west side of the chasm
-- For players who fall to the west side (around X = -4, Z = -1570, Y = 62)
local westTruss = Instance.new("TrussPart")
westTruss.Name = "WestChasmTruss"
westTruss.Size = Vector3.new(2, 60, 2)
westTruss.CFrame = CFrame.new(-2.0, 92.0, -1575.0)
westTruss.Material = Enum.Material.Wood
westTruss.Color = Color3.fromRGB(130, 90, 55)
westTruss.Anchored = true
westTruss.CanCollide = true
westTruss.Parent = model

return { success = true, flights = #waypoints - 1, totalSteps = totalSteps }
`;

  console.log('Building Bridge Return Trail...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot of the return trail climbing up the ridge from the bottom
  console.log('Capturing bridge return trail bottom view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_bridge_return_bottom.png',
    [24, 66, -1572],
    [20, 95, -1552]
  );

  // Capture screenshot from top deck looking down at both bridge and return path
  console.log('Capturing bridge return trail overview...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_bridge_return_overview.png',
    [20, 180, -1525],
    [10, 160, -1565]
  );
  console.log('Bridge return trail screenshots captured!');
}

main().catch(console.error);
