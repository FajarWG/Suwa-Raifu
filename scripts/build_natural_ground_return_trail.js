const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

local mainModel = trail:FindFirstChild("BridgeChasmReturnStairs")
if not mainModel then return {error = "No BridgeChasmReturnStairs"} end

-- 1. Remove all old cliff scaffolding, ladders, mid platform, and cliff stairs
-- Keep ONLY GorgeTier (stairs from lowest basin Y=8 to Y=58) and DeepPitBottomLanding!
for _, c in ipairs(mainModel:GetChildren()) do
    if c.Name ~= "GorgeTier" and c.Name ~= "DeepPitBottomLanding" and c.Name ~= "DeepPitLanternPost" and c.Name ~= "DeepPitLantern" and not c.Name:find("GorgeConnector") then
        c:Destroy()
    end
end

-- 2. Restore cliff wall behind where MidTierLanding used to be into solid, beautiful natural rock
terrain:FillBlock(CFrame.new(15, 115, -1546), Vector3.new(16, 40, 14), Enum.Material.Rock)
terrain:FillBlock(CFrame.new(15, 138, -1535), Vector3.new(16, 12, 14), Enum.Material.Grass)

-- 3. Define natural curving trail waypoints through the eastern valley:
-- From DeepPitBottomLanding (24, 58, -1565) to Main Ground Trail at (18, 124, -1495)
local waypoints = {
    Vector3.new(24.0, 58.0, -1565.0), -- Landing shelf at gorge floor
    Vector3.new(30.0, 64.0, -1558.0),
    Vector3.new(36.0, 74.0, -1550.0),
    Vector3.new(42.0, 86.0, -1540.0),
    Vector3.new(44.0, 100.0, -1530.0),
    Vector3.new(42.0, 114.0, -1520.0),
    Vector3.new(36.0, 122.0, -1510.0),
    Vector3.new(26.0, 124.0, -1502.0),
    Vector3.new(18.0, 124.1, -1495.0)  -- Directly joins main ground trail!
}

local returnTrailModel = Instance.new("Model")
returnTrailModel.Name = "NaturalGroundReturnTrail"
returnTrailModel.Parent = mainModel

-- 4. Carve natural walking terrain corridor and build stone/timber ground steps along the route
local totalSteps = 0
for w = 1, #waypoints - 1 do
    local pA = waypoints[w]
    local pB = waypoints[w + 1]
    local dist = (pB - pA).Magnitude
    local dir = (pB - pA).Unit
    local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
    local yaw = math.atan2(-flatDir.X, -flatDir.Z)
    
    local nSegments = math.max(3, math.floor(dist / 2.5))
    
    for s = 1, nSegments do
        totalSteps = totalSteps + 1
        local alpha = s / nSegments
        local p = pA:Lerp(pB, alpha)
        
        -- Carve smooth ground foundation and air headroom:
        -- Solid ground under path
        terrain:FillBlock(CFrame.new(p - Vector3.new(0, 3, 0)), Vector3.new(10, 6, 5), Enum.Material.Ground)
        terrain:FillBlock(CFrame.new(p - Vector3.new(0, 0.5, 0)), Vector3.new(8, 2, 4.5), Enum.Material.Grass)
        -- Clear walking headroom above path
        terrain:FillBlock(CFrame.new(p + Vector3.new(0, 7, 0)), Vector3.new(10, 12, 5), Enum.Material.Air)
        
        -- Natural wood/stone stepping plank flush on the ground
        local step = Instance.new("Part")
        step.Name = "GroundTrailStep_" .. totalSteps
        step.Size = Vector3.new(6.0, 0.8, 2.2)
        step.CFrame = CFrame.new(p + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, yaw, 0)
        step.Material = Enum.Material.WoodPlanks
        step.Color = Color3.fromRGB(115, 80, 50)
        step.Anchored = true
        step.CanCollide = true
        step.Parent = returnTrailModel
        
        -- Embedded slate foundation under plank
        local base = Instance.new("Part")
        base.Name = "StoneBase"
        base.Size = Vector3.new(6.6, 0.6, 2.6)
        base.CFrame = step.CFrame * CFrame.new(0, -0.4, 0)
        base.Material = Enum.Material.Slate
        base.Color = Color3.fromRGB(75, 76, 78)
        base.Anchored = true
        base.CanCollide = false
        base.Parent = returnTrailModel
        
        -- Rustic wooden trail lantern every 5 steps
        if totalSteps % 5 == 0 then
            local post = Instance.new("Part")
            post.Name = "TrailMarkerPost"
            post.Size = Vector3.new(0.6, 4.0, 0.6)
            post.CFrame = step.CFrame * CFrame.new(-3.8, 1.8, 0)
            post.Material = Enum.Material.Wood
            post.Color = Color3.fromRGB(65, 42, 28)
            post.Anchored = true
            post.Parent = returnTrailModel
            
            local ltn = Instance.new("Part")
            ltn.Name = "TrailLantern"
            ltn.Size = Vector3.new(0.8, 1.1, 0.8)
            ltn.CFrame = post.CFrame * CFrame.new(0, 2.2, 0)
            ltn.Material = Enum.Material.Neon
            ltn.Color = Color3.fromRGB(255, 215, 140)
            ltn.Anchored = true
            ltn.Parent = returnTrailModel
            
            local lgt = Instance.new("PointLight")
            lgt.Color = Color3.fromRGB(255, 180, 95)
            lgt.Brightness = 2.2
            lgt.Range = 18
            lgt.Parent = ltn
        end
    end
end

-- 5. Bottom trail marker at the gorge shelf
local botSignPost = Instance.new("Part")
botSignPost.Name = "GorgeTrailSignPost"
botSignPost.Size = Vector3.new(0.6, 5.5, 0.6)
botSignPost.CFrame = CFrame.new(27.0, 60.5, -1563.0)
botSignPost.Material = Enum.Material.Wood
botSignPost.Color = Color3.fromRGB(65, 42, 28)
botSignPost.Anchored = true
botSignPost.Parent = returnTrailModel

local botSign = Instance.new("Part")
botSign.Name = "GorgeTrailSign"
botSign.Size = Vector3.new(5.0, 1.8, 0.3)
botSign.CFrame = botSignPost.CFrame * CFrame.new(-2.6, 1.0, 0)
botSign.Material = Enum.Material.Wood
botSign.Color = Color3.fromRGB(45, 30, 20)
botSign.Anchored = true
botSign.Parent = returnTrailModel

local botSg = Instance.new("SurfaceGui")
botSg.Face = Enum.NormalId.Front
botSg.Parent = botSign

local botTxt = Instance.new("TextLabel")
botTxt.Size = UDim2.new(1, 0, 1, 0)
botTxt.BackgroundTransparency = 1
botTxt.Text = "山道 復帰小道\\nRETURN TRAIL (CLIMB TO GROUND)"
botTxt.TextColor3 = Color3.fromRGB(250, 240, 220)
botTxt.Font = Enum.Font.SourceSansBold
botTxt.TextScaled = true
botTxt.Parent = botSg

-- 6. Top trail marker sign at the ground junction (Z = -1495)
local topSignPost = Instance.new("Part")
topSignPost.Name = "GroundJunctionSignPost"
topSignPost.Size = Vector3.new(0.6, 5.5, 0.6)
topSignPost.CFrame = CFrame.new(21.0, 126.5, -1494.0)
topSignPost.Material = Enum.Material.Wood
topSignPost.Color = Color3.fromRGB(65, 42, 28)
topSignPost.Anchored = true
topSignPost.Parent = returnTrailModel

local topSign = Instance.new("Part")
topSign.Name = "GroundJunctionSign"
topSign.Size = Vector3.new(5.4, 2.0, 0.3)
topSign.CFrame = topSignPost.CFrame * CFrame.new(0, 1.0, 0) * CFrame.Angles(0, math.pi/2, 0)
topSign.Material = Enum.Material.Wood
topSign.Color = Color3.fromRGB(45, 30, 20)
topSign.Anchored = true
topSign.Parent = returnTrailModel

local topSg = Instance.new("SurfaceGui")
topSg.Face = Enum.NormalId.Front
topSg.Parent = topSign

local topTxt = Instance.new("TextLabel")
topTxt.Size = UDim2.new(1, 0, 1, 0)
topTxt.BackgroundTransparency = 1
topTxt.Text = "← つり橋 (再挑戦) | 谷底復帰道 →\\nTO BRIDGE (RETRY) | FROM RAVINE"
topTxt.TextColor3 = Color3.fromRGB(250, 240, 220)
topTxt.Font = Enum.Font.SourceSansBold
topTxt.TextScaled = true
topTxt.Parent = topSg

return {success = true, totalSteps = totalSteps}
`;

  console.log('Building 100% natural grounded return trail away from bridge...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture wide view of bridge area showing it is now completely clean and detached!
  console.log('Capturing wide view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_natural_ground_return_trail_wide.png',
    [60, 170, -1500],
    [0, 140, -1560]
  );
  
  // Capture view of the new natural grounded trail winding up the eastern valley
  console.log('Capturing eastern valley return trail...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_eastern_valley_trail.png',
    [55, 145, -1510],
    [25, 80, -1550]
  );
}

main().catch(console.error);
