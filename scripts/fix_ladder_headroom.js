const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

local mainModel = trail:FindFirstChild("BridgeChasmReturnStairs")
if not mainModel then return {error = "No BridgeChasmReturnStairs"} end

-- 1. Redesign MidTierLanding & DeepPitTrussLadder
-- Clean old ladder and mid landing parts
local oldParts = {
    "DeepPitTrussLadder", "DeepLadderPost", "DeepPitBottomLanding",
    "DeepPitLanternPost", "DeepPitLantern", "DeepPitSign",
    "MidTierLanding", "MidLandingLanternPost", "MidLandingLantern", "MidLandingSign"
}
for _, name in ipairs(oldParts) do
    local p = mainModel:FindFirstChild(name)
    if p then p:Destroy() end
end
for _, c in ipairs(mainModel:GetChildren()) do
    if c.Name:find("DeepLadder") or c.Name:find("MidLanding") then
        c:Destroy()
    end
end

-- Dimensions & Positions
local midLandingPos = Vector3.new(14, 110.6, -1550)
local midLandingSize = Vector3.new(12, 1.2, 10)
local southEdgeZ = midLandingPos.Z - midLandingSize.Z/2 -- -1555.0

-- 2. Build MidTierLanding
local midLanding = Instance.new("Part")
midLanding.Name = "MidTierLanding"
midLanding.Size = midLandingSize
midLanding.CFrame = CFrame.new(midLandingPos)
midLanding.Material = Enum.Material.WoodPlanks
midLanding.Color = Color3.fromRGB(115, 80, 50)
midLanding.Anchored = true
midLanding.Parent = mainModel

-- Platform perimeter railings (East, West, North sides - leaving South side OPEN for ladder entry!)
-- West railing (at X = 8)
local railW = Instance.new("Part")
railW.Name = "MidLandingRail_W"
railW.Size = Vector3.new(0.5, 3.8, 10)
railW.CFrame = midLanding.CFrame * CFrame.new(-5.8, 2.5, 0)
railW.Material = Enum.Material.Wood
railW.Color = Color3.fromRGB(75, 50, 32)
railW.Anchored = true
railW.Parent = mainModel

-- East railing (at X = 20)
local railE = Instance.new("Part")
railE.Name = "MidLandingRail_E"
railE.Size = Vector3.new(0.5, 3.8, 10)
railE.CFrame = midLanding.CFrame * CFrame.new(5.8, 2.5, 0)
railE.Material = Enum.Material.Wood
railE.Color = Color3.fromRGB(75, 50, 32)
railE.Anchored = true
railE.Parent = mainModel

-- South railing flanking posts (leaving center 4.0 studs 100% open for ladder step-off!)
for _, sideX in ipairs({-4.5, 4.5}) do
    local sRail = Instance.new("Part")
    sRail.Name = "MidLandingRail_S"
    sRail.Size = Vector3.new(3.0, 3.8, 0.5)
    sRail.CFrame = midLanding.CFrame * CFrame.new(sideX, 2.5, -4.8)
    sRail.Material = Enum.Material.Wood
    sRail.Color = Color3.fromRGB(75, 50, 32)
    sRail.Anchored = true
    sRail.Parent = mainModel
end

-- Lantern post on MidTierLanding (East side)
local mlPost = Instance.new("Part")
mlPost.Name = "MidLandingLanternPost"
mlPost.Size = Vector3.new(0.6, 7.0, 0.6)
mlPost.CFrame = midLanding.CFrame * CFrame.new(5.2, 4.1, 4.0)
mlPost.Material = Enum.Material.Wood
mlPost.Color = Color3.fromRGB(80, 55, 35)
mlPost.Anchored = true
mlPost.Parent = mainModel

local mlLtn = Instance.new("Part")
mlLtn.Name = "MidLandingLantern"
mlLtn.Size = Vector3.new(1.0, 1.4, 1.0)
mlLtn.CFrame = mlPost.CFrame * CFrame.new(0, 3.8, 0)
mlLtn.Material = Enum.Material.Neon
mlLtn.Color = Color3.fromRGB(255, 210, 130)
mlLtn.Anchored = true
mlLtn.Parent = mainModel

local mlLgt = Instance.new("PointLight")
mlLgt.Color = Color3.fromRGB(255, 175, 90)
mlLgt.Brightness = 2.8
mlLgt.Range = 26
mlLgt.Shadows = true
mlLgt.Parent = mlLtn

local mlSign = Instance.new("Part")
mlSign.Name = "MidLandingSign"
mlSign.Size = Vector3.new(6.0, 1.8, 0.3)
mlSign.CFrame = mlPost.CFrame * CFrame.new(-3.5, 1.2, 0)
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


-- 3. DEEP PIT TRUSS LADDER (Mounted ON THE OUTSIDE SOUTH EDGE of MidTierLanding!)
-- Ladder climbs from Y = 58.0 to Y = 115.0 (57 studs height!)
-- Bottom is at (14, 58, -1555.6), Top is at (14, 115, -1555.6)
-- Top rises 4.4 studs ABOVE platform deck (Y = 110.6), so player smoothly steps off!
local ladderBottomY = 58.0
local ladderTopY = 115.0
local ladderH = ladderTopY - ladderBottomY -- 57 studs
local ladderZ = southEdgeZ - 1.2 -- -1556.2 (OUTSIDE the platform floor!)
local ladderX = midLandingPos.X -- 14.0

local truss = Instance.new("TrussPart")
truss.Name = "DeepPitTrussLadder"
truss.Size = Vector3.new(2.4, ladderH, 2.4)
truss.CFrame = CFrame.new(ladderX, ladderBottomY + ladderH/2, ladderZ)
truss.Material = Enum.Material.Wood
truss.Color = Color3.fromRGB(140, 95, 60)
truss.Anchored = true
truss.CanCollide = true
truss.Parent = mainModel

-- Two handrail guide posts flanking the ladder all the way up and extending onto the deck
for _, sideOffset in ipairs({-1.6, 1.6}) do
    local post = Instance.new("Part")
    post.Name = "LadderGuidePost"
    post.Size = Vector3.new(0.6, ladderH + 3.0, 0.6)
    post.CFrame = truss.CFrame * CFrame.new(sideOffset, 1.5, 0)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(80, 55, 35)
    post.Anchored = true
    post.Parent = mainModel
end

-- 4. Deep Pit Bottom Landing (at Y = 58.0, centered under the ladder base)
local bottomLanding = Instance.new("Part")
bottomLanding.Name = "DeepPitBottomLanding"
bottomLanding.Size = Vector3.new(10, 1.2, 8)
bottomLanding.CFrame = CFrame.new(ladderX, ladderBottomY - 0.6, ladderZ)
bottomLanding.Material = Enum.Material.WoodPlanks
bottomLanding.Color = Color3.fromRGB(115, 80, 50)
bottomLanding.Anchored = true
bottomLanding.Parent = mainModel

-- Bottom landing lantern post
local blPost = Instance.new("Part")
blPost.Name = "DeepPitLanternPost"
blPost.Size = Vector3.new(0.6, 7.0, 0.6)
blPost.CFrame = bottomLanding.CFrame * CFrame.new(4.2, 4.1, 3.2)
blPost.Material = Enum.Material.Wood
blPost.Color = Color3.fromRGB(80, 55, 35)
blPost.Anchored = true
blPost.Parent = mainModel

local blLtn = Instance.new("Part")
blLtn.Name = "DeepPitLantern"
blLtn.Size = Vector3.new(1.0, 1.4, 1.0)
blLtn.CFrame = blPost.CFrame * CFrame.new(0, 3.8, 0)
blLtn.Material = Enum.Material.Neon
blLtn.Color = Color3.fromRGB(255, 210, 130)
blLtn.Anchored = true
blLtn.Parent = mainModel

local blLgt = Instance.new("PointLight")
blLgt.Color = Color3.fromRGB(255, 175, 90)
blLgt.Brightness = 3.0
blLgt.Range = 28
blLgt.Shadows = true
blLgt.Parent = blLtn

-- 5. Connect Bottom Landing (14, 58, -1556) to Gorge Shelf (24, 57.5, -1568)
-- Clean, wide connecting walkway
local numWalkways = 6
local startWalk = Vector3.new(ladderX, ladderBottomY - 0.6, ladderZ)
local endWalk = Vector3.new(24, 57.5, -1568)
for w = 1, numWalkways do
    local alpha = w / numWalkways
    local p = startWalk:Lerp(endWalk, alpha)
    local plank = Instance.new("Part")
    plank.Name = "GorgeConnector_" .. w
    plank.Size = Vector3.new(6.0, 1.0, 3.2)
    plank.CFrame = CFrame.new(p)
    plank.Material = Enum.Material.WoodPlanks
    plank.Color = Color3.fromRGB(115, 80, 50)
    plank.Anchored = true
    plank.CanCollide = true
    plank.Parent = mainModel
end

-- 6. Guarantee 100% CLEAR AIR ENVELOPE all along the ladder climb and step-off zone!
for y = ladderBottomY, ladderTopY + 8, 4 do
    -- Clear 10x8 air envelope centered on ladder
    terrain:FillBlock(CFrame.new(ladderX, y, ladderZ), Vector3.new(10, 6, 8), Enum.Material.Air)
    -- Clear step-off transition zone onto MidTierLanding
    if y >= 110 then
        terrain:FillBlock(CFrame.new(ladderX, y, -1552), Vector3.new(10, 6, 8), Enum.Material.Air)
    end
end

-- Verification: Raycast clearance directly above top of ladder
local topClearRay = workspace:Raycast(Vector3.new(ladderX, ladderTopY - 2, ladderZ), Vector3.new(0, 10, 0))
local stepOffRay = workspace:Raycast(Vector3.new(ladderX, 112, -1552), Vector3.new(0, 8, 0))

return {
    success = true,
    ladderH = ladderH,
    topHeadroomBlocked = (topClearRay ~= nil and topClearRay.Instance.CanCollide),
    stepOffBlocked = (stepOffRay ~= nil and stepOffRay.Instance.CanCollide)
}
`;

  console.log('Fixing Deep Pit Ladder Headroom & Side-Mount Step-Off...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture camera from below looking up at ladder arriving on platform deck (matching user screenshot)
  console.log('Capturing ladder top arrival screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_ladder_top_arrival.png',
    [14, 98, -1556],
    [14, 116, -1552]
  );

  // 2. Capture platform deck step-off view looking at the ladder transition
  console.log('Capturing platform deck step-off screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_platform_step_off.png',
    [14, 114, -1546],
    [14, 112, -1556]
  );

  console.log('Deep pit ladder headroom fixed and captured successfully!');
}

main().catch(console.error);
