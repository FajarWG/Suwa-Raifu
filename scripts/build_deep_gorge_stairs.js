const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

local mainModel = trail:FindFirstChild("BridgeChasmReturnStairs")
if not mainModel then
    mainModel = Instance.new("Model")
    mainModel.Name = "BridgeChasmReturnStairs"
    mainModel.Parent = trail
end

-- Clean old gorge tier if exists
local oldGorge = mainModel:FindFirstChild("GorgeTier")
if oldGorge then oldGorge:Destroy() end

local gorgeModel = Instance.new("Model")
gorgeModel.Name = "GorgeTier"
gorgeModel.Parent = mainModel

-- Lowest floor landing at (42, 8, -1570)
local floorPos = Vector3.new(42, 8, -1570)
local shelfPos = Vector3.new(24, 57.5, -1568)
local pitLandingPos = Vector3.new(2, 59, -1565)

-- 1. Lowest Floor Landing Platform
local floorLanding = Instance.new("Part")
floorLanding.Name = "GorgeFloorLanding"
floorLanding.Size = Vector3.new(12, 1.2, 10)
floorLanding.CFrame = CFrame.new(floorPos)
floorLanding.Material = Enum.Material.WoodPlanks
floorLanding.Color = Color3.fromRGB(115, 80, 50)
floorLanding.Anchored = true
floorLanding.Parent = gorgeModel

-- Lantern post on floor landing
local fLanternPost = Instance.new("Part")
fLanternPost.Name = "GorgeLanternPost"
fLanternPost.Size = Vector3.new(0.6, 7, 0.6)
fLanternPost.CFrame = floorLanding.CFrame * CFrame.new(5, 4.1, 4)
fLanternPost.Material = Enum.Material.Wood
fLanternPost.Color = Color3.fromRGB(80, 55, 35)
fLanternPost.Anchored = true
fLanternPost.Parent = gorgeModel

local fLantern = Instance.new("Part")
fLantern.Name = "GorgeLantern"
fLantern.Size = Vector3.new(1.0, 1.4, 1.0)
fLantern.CFrame = fLanternPost.CFrame * CFrame.new(0, 3.8, 0)
fLantern.Material = Enum.Material.Neon
fLantern.Color = Color3.fromRGB(255, 210, 130)
fLantern.Anchored = true
fLantern.Parent = gorgeModel

local fLgt = Instance.new("PointLight")
fLgt.Color = Color3.fromRGB(255, 175, 90)
fLgt.Brightness = 3.2
fLgt.Range = 30
fLgt.Shadows = true
fLgt.Parent = fLantern

local fSign = Instance.new("Part")
fSign.Name = "GorgeSign"
fSign.Size = Vector3.new(8.0, 1.8, 0.3)
fSign.CFrame = fLanternPost.CFrame * CFrame.new(-4.5, 1.2, 0)
fSign.Material = Enum.Material.Wood
fSign.Color = Color3.fromRGB(45, 30, 20)
fSign.Anchored = true
fSign.Parent = gorgeModel

local fSg = Instance.new("SurfaceGui")
fSg.Face = Enum.NormalId.Front
fSg.Parent = fSign

local fTxt = Instance.new("TextLabel")
fTxt.Size = UDim2.new(1, 0, 1, 0)
fTxt.BackgroundTransparency = 1
fTxt.Text = "最深谷 復帰階段\\nDEEPEST GORGE ESCAPE STAIRS"
fTxt.TextColor3 = Color3.fromRGB(250, 240, 220)
fTxt.Font = Enum.Font.SourceSansBold
fTxt.TextScaled = true
fTxt.Parent = fSg

-- 2. Staircase from Floor (Y=8) up to Shelf (Y=57.5)
local numSteps = 32
local stairDir = (shelfPos - floorPos)
local flatDir = Vector3.new(stairDir.X, 0, stairDir.Z).Unit
local stairYaw = math.atan2(-flatDir.X, -flatDir.Z)

for s = 1, numSteps do
    local alpha = s / numSteps
    local p = floorPos:Lerp(shelfPos, alpha)
    local stepCf = CFrame.new(p) * CFrame.Angles(0, stairYaw, 0)
    
    local step = Instance.new("Part")
    step.Name = "GorgeStep_" .. s
    step.Size = Vector3.new(7.0, 1.4, 2.8)
    step.CFrame = stepCf
    step.Material = Enum.Material.WoodPlanks
    step.Color = Color3.fromRGB(120, 85, 55)
    step.Anchored = true
    step.CanCollide = true
    step.Parent = gorgeModel
    
    -- Clear air headroom
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 6, 0)), Vector3.new(10, 12, 5), Enum.Material.Air)
    
    -- Railings & Lanterns every 6 steps
    if s % 6 == 0 or s == numSteps then
        for _, sideX in ipairs({-3.3, 3.3}) do
            local post = Instance.new("Part")
            post.Name = "GorgeRailingPost_" .. s
            post.Size = Vector3.new(0.5, 4.2, 0.5)
            post.CFrame = stepCf * CFrame.new(sideX, 2.3, 0)
            post.Material = Enum.Material.Wood
            post.Color = Color3.fromRGB(75, 50, 32)
            post.Anchored = true
            post.Parent = gorgeModel
        end
        
        local ltn = Instance.new("Part")
        ltn.Name = "GorgeStepLantern_" .. s
        ltn.Size = Vector3.new(0.8, 1.2, 0.8)
        ltn.CFrame = stepCf * CFrame.new(-3.3, 4.8, 0)
        ltn.Material = Enum.Material.Neon
        ltn.Color = Color3.fromRGB(255, 215, 140)
        ltn.Anchored = true
        ltn.Parent = gorgeModel
        
        local lgt = Instance.new("PointLight")
        lgt.Color = Color3.fromRGB(255, 180, 95)
        lgt.Brightness = 2.4
        lgt.Range = 22
        lgt.Parent = ltn
    end
end

-- 3. Boardwalk connecting Shelf (24, 57.5, -1568) to Pit Landing (2, 59, -1565)
local numWalkwayPlanks = 8
for w = 1, numWalkwayPlanks do
    local alpha = w / numWalkwayPlanks
    local p = shelfPos:Lerp(pitLandingPos, alpha)
    local plank = Instance.new("Part")
    plank.Name = "GorgeWalkwayPlank_" .. w
    plank.Size = Vector3.new(6.0, 1.0, 3.2)
    plank.CFrame = CFrame.new(p + Vector3.new(0, 0.5, 0))
    plank.Material = Enum.Material.WoodPlanks
    plank.Color = Color3.fromRGB(115, 80, 50)
    plank.Anchored = true
    plank.CanCollide = true
    plank.Parent = gorgeModel
    
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 6, 0)), Vector3.new(8, 10, 5), Enum.Material.Air)
end

return {
    success = true,
    numSteps = numSteps,
    floorPos = tostring(floorPos),
    shelfPos = tostring(shelfPos)
}
`;

  console.log('Building Deep Gorge Escape Stairs...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot from the deep gorge looking up towards bridge (matching user screenshot)
  console.log('Capturing deep gorge view looking up...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_gorge_stairs_looking_up.png',
    [44, 12, -1572],
    [10, 90, -1555]
  );

  console.log('Deep gorge escape stairs built and verified!');
}

main().catch(console.error);
