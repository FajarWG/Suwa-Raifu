const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- 1. Clean up old models
local oldTrail = trail:FindFirstChild("BridgeReturnTrail")
if oldTrail then oldTrail:Destroy() end
local oldWater = trail:FindFirstChild("BridgeChasmWaterEscape")
if oldWater then oldWater:Destroy() end
local oldStairs = trail:FindFirstChild("BridgeChasmReturnStairs")
if oldStairs then oldStairs:Destroy() end

local mainModel = Instance.new("Model")
mainModel.Name = "BridgeChasmReturnStairs"
mainModel.Parent = trail

-- =========================================================================
-- PART 1: DEEP PIT ESCAPE LADDER (From Y = 59 to Y = 110)
-- "disini juga kasih tangga siapa tau masuk ke sini yang lebih dalem"
-- =========================================================================
local deepPitPos = Vector3.new(2, 59, -1565)
local midLandingPos = Vector3.new(14, 110, -1550)
local bridgeDeckPos = Vector3.new(10, 163.6, -1535)

-- 1. Deep Pit Bottom Landing
local deepLanding = Instance.new("Part")
deepLanding.Name = "DeepPitBottomLanding"
deepLanding.Size = Vector3.new(10, 1.2, 8)
deepLanding.CFrame = CFrame.new(deepPitPos + Vector3.new(0, 0.6, 0))
deepLanding.Material = Enum.Material.WoodPlanks
deepLanding.Color = Color3.fromRGB(115, 80, 50)
deepLanding.Anchored = true
deepLanding.Parent = mainModel

-- Deep pit lantern post & sign
local dpLanternPost = Instance.new("Part")
dpLanternPost.Name = "DeepPitLanternPost"
dpLanternPost.Size = Vector3.new(0.6, 7, 0.6)
dpLanternPost.CFrame = deepLanding.CFrame * CFrame.new(4, 4.1, 3)
dpLanternPost.Material = Enum.Material.Wood
dpLanternPost.Color = Color3.fromRGB(80, 55, 35)
dpLanternPost.Anchored = true
dpLanternPost.Parent = mainModel

local dpLantern = Instance.new("Part")
dpLantern.Name = "DeepPitLantern"
dpLantern.Size = Vector3.new(1.0, 1.4, 1.0)
dpLantern.CFrame = dpLanternPost.CFrame * CFrame.new(0, 3.8, 0)
dpLantern.Material = Enum.Material.Neon
dpLantern.Color = Color3.fromRGB(255, 210, 130)
dpLantern.Anchored = true
dpLantern.Parent = mainModel

local dpLgt = Instance.new("PointLight")
dpLgt.Color = Color3.fromRGB(255, 175, 90)
dpLgt.Brightness = 3.0
dpLgt.Range = 28
dpLgt.Shadows = true
dpLgt.Parent = dpLantern

local dpSign = Instance.new("Part")
dpSign.Name = "DeepPitSign"
dpSign.Size = Vector3.new(8.0, 1.8, 0.3)
dpSign.CFrame = dpLanternPost.CFrame * CFrame.new(-4.0, 1.2, 0)
dpSign.Material = Enum.Material.Wood
dpSign.Color = Color3.fromRGB(45, 30, 20)
dpSign.Anchored = true
dpSign.Parent = mainModel

local dpSg = Instance.new("SurfaceGui")
dpSg.Face = Enum.NormalId.Front
dpSg.Parent = dpSign

local dpTxt = Instance.new("TextLabel")
dpTxt.Size = UDim2.new(1, 0, 1, 0)
dpTxt.BackgroundTransparency = 1
dpTxt.Text = "深谷 復帰ハシゴ\\nDEEP CHASM ESCAPE LADDER"
dpTxt.TextColor3 = Color3.fromRGB(250, 240, 220)
dpTxt.Font = Enum.Font.SourceSansBold
dpTxt.TextScaled = true
dpTxt.Parent = dpSg

-- Deep Pit Vertical Escape Truss Ladder (Climbing from Y=60 to Y=110, height ~50 studs)
local ladderH = midLandingPos.Y - deepPitPos.Y + 2
local ladderCenter = Vector3.new(midLandingPos.X - 1.5, deepPitPos.Y + ladderH/2, midLandingPos.Z - 1.5)

local deepTruss = Instance.new("TrussPart")
deepTruss.Name = "DeepPitTrussLadder"
deepTruss.Size = Vector3.new(2.4, ladderH, 2.4)
deepTruss.CFrame = CFrame.new(ladderCenter)
deepTruss.Material = Enum.Material.Wood
deepTruss.Color = Color3.fromRGB(130, 90, 55)
deepTruss.Anchored = true
deepTruss.CanCollide = true
deepTruss.Parent = mainModel

-- Side guide posts for deep pit ladder
for _, sideOffset in ipairs({-1.6, 1.6}) do
    local post = Instance.new("Part")
    post.Name = "DeepLadderPost"
    post.Size = Vector3.new(0.6, ladderH + 2, 0.6)
    post.CFrame = deepTruss.CFrame * CFrame.new(sideOffset, 1, 0)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(80, 55, 35)
    post.Anchored = true
    post.Parent = mainModel
end

-- Clear air envelope along the deep pit ladder
for y = deepPitPos.Y, midLandingPos.Y + 4, 4 do
    terrain:FillBlock(CFrame.new(ladderCenter.X, y, ladderCenter.Z), Vector3.new(8, 6, 8), Enum.Material.Air)
end


-- =========================================================================
-- PART 2: MID TIER LANDING (At Y = 110)
-- =========================================================================
local midLanding = Instance.new("Part")
midLanding.Name = "MidTierLanding"
midLanding.Size = Vector3.new(12, 1.2, 10)
midLanding.CFrame = CFrame.new(midLandingPos + Vector3.new(0, 0.6, 0))
midLanding.Material = Enum.Material.WoodPlanks
midLanding.Color = Color3.fromRGB(115, 80, 50)
midLanding.Anchored = true
midLanding.Parent = mainModel

-- Mid landing lantern post & sign
local mlLanternPost = Instance.new("Part")
mlLanternPost.Name = "MidLandingLanternPost"
mlLanternPost.Size = Vector3.new(0.6, 7, 0.6)
mlLanternPost.CFrame = midLanding.CFrame * CFrame.new(5, 4.1, 3.5)
mlLanternPost.Material = Enum.Material.Wood
mlLanternPost.Color = Color3.fromRGB(80, 55, 35)
mlLanternPost.Anchored = true
mlLanternPost.Parent = mainModel

local mlLantern = Instance.new("Part")
mlLantern.Name = "MidLandingLantern"
mlLantern.Size = Vector3.new(1.0, 1.4, 1.0)
mlLantern.CFrame = mlLanternPost.CFrame * CFrame.new(0, 3.8, 0)
mlLantern.Material = Enum.Material.Neon
mlLantern.Color = Color3.fromRGB(255, 210, 130)
mlLantern.Anchored = true
mlLantern.Parent = mainModel

local mlLgt = Instance.new("PointLight")
mlLgt.Color = Color3.fromRGB(255, 175, 90)
mlLgt.Brightness = 2.8
mlLgt.Range = 26
mlLgt.Shadows = true
mlLgt.Parent = mlLantern

local mlSign = Instance.new("Part")
mlSign.Name = "MidLandingSign"
mlSign.Size = Vector3.new(8.0, 1.8, 0.3)
mlSign.CFrame = mlLanternPost.CFrame * CFrame.new(-4.5, 1.2, 0)
mlSign.Material = Enum.Material.Wood
mlSign.Color = Color3.fromRGB(45, 30, 20)
mlSign.Anchored = true
mlSign.Parent = mainModel

local mlSg = Instance.new("SurfaceGui")
mlSg.Face = Enum.NormalId.Front
mlSg.Parent = mlSign

local mlTxt = Instance.new("TextLabel")
mlTxt.Size = UDim2.new(1, 0, 1, 0)
mlTxt.BackgroundTransparency = 1
mlTxt.Text = "つり橋 復帰階段\\nBRIDGE RETRY STAIRS"
mlTxt.TextColor3 = Color3.fromRGB(250, 240, 220)
mlTxt.Font = Enum.Font.SourceSansBold
mlTxt.TextScaled = true
mlTxt.Parent = mlSg


-- =========================================================================
-- PART 3: CONTINUOUS RETURN STAIRS (From Y = 110 to Bridge Deck Y = 163.6)
-- "jangan dibuat jadi air kaya sebelumnya aja tangga jadi klo orang yang jatoh ya bisa naik tangga tangga"
-- =========================================================================
local stairStart = midLandingPos + Vector3.new(0, 0.6, 2)
local stairEnd = bridgeDeckPos + Vector3.new(0, -0.4, -1)
local totalRise = stairEnd.Y - stairStart.Y -- ~53 studs
local numSteps = 38 -- comfortable ~1.4 stud step rise

local stairDir = (stairEnd - stairStart)
local flatStairDir = Vector3.new(stairDir.X, 0, stairDir.Z).Unit
local stairYaw = math.atan2(-flatStairDir.X, -flatStairDir.Z)

for s = 1, numSteps do
    local alpha = s / numSteps
    local p = stairStart:Lerp(stairEnd, alpha)
    local stepCf = CFrame.new(p) * CFrame.Angles(0, stairYaw, 0)
    
    -- Wide wooden step
    local step = Instance.new("Part")
    step.Name = "RetryStep_" .. s
    step.Size = Vector3.new(8.0, 1.6, 3.2)
    step.CFrame = stepCf
    step.Material = Enum.Material.WoodPlanks
    step.Color = Color3.fromRGB(120, 85, 55)
    step.Anchored = true
    step.CanCollide = true
    step.Parent = mainModel
    
    -- CLEAR AIR HEADROOM OVER EVERY SINGLE STEP to prevent ANY dirt obstruction!
    -- This guarantees 0 dirt clipping!
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 8, 0)), Vector3.new(14, 14, 6), Enum.Material.Air)
    
    -- Add railings and lanterns every 6 steps
    if s % 6 == 0 or s == numSteps then
        for _, sideX in ipairs({-3.8, 3.8}) do
            local post = Instance.new("Part")
            post.Name = "RailingPost_" .. s
            post.Size = Vector3.new(0.5, 4.5, 0.5)
            post.CFrame = stepCf * CFrame.new(sideX, 2.5, 0)
            post.Material = Enum.Material.Wood
            post.Color = Color3.fromRGB(75, 50, 32)
            post.Anchored = true
            post.Parent = mainModel
        end
        
        -- Lantern on left side
        local sltn = Instance.new("Part")
        sltn.Name = "StairLantern_" .. s
        sltn.Size = Vector3.new(0.8, 1.2, 0.8)
        sltn.CFrame = stepCf * CFrame.new(-3.8, 5.0, 0)
        sltn.Material = Enum.Material.Neon
        sltn.Color = Color3.fromRGB(255, 215, 140)
        sltn.Anchored = true
        sltn.Parent = mainModel
        
        local lgt = Instance.new("PointLight")
        lgt.Color = Color3.fromRGB(255, 180, 95)
        lgt.Brightness = 2.4
        lgt.Range = 20
        lgt.Parent = sltn
    end
end

-- Clear wide envelope around bridge connection
terrain:FillBlock(CFrame.new(bridgeDeckPos + Vector3.new(0, 8, 0)), Vector3.new(16, 16, 12), Enum.Material.Air)

return {
    success = true,
    numSteps = numSteps,
    deepPitHeight = ladderH,
    totalRise = totalRise
}
`;

  console.log('Building Dry Chasm Return Stairs & Deep Pit Ladder...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture overview from above (matching user Image 2)
  console.log('Capturing crater overview screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_crater_stairs_overview.png',
    [-15, 195, -1610],
    [10, 110, -1550]
  );

  // 2. Capture deep pit ladder view looking up from deep floor
  console.log('Capturing deep pit ladder screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_deep_pit_ladder.png',
    [2, 65, -1560],
    [14, 105, -1550]
  );

  // 3. Capture stairs view climbing up to the bridge deck
  console.log('Capturing stairs climbing screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_chasm_stairs_climbing.png',
    [14, 115, -1545],
    [10, 160, -1536]
  );

  console.log('All dry chasm screenshots captured!');
}

main().catch(console.error);
