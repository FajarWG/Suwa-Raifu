const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

local mainModel = trail:FindFirstChild("BridgeChasmReturnStairs")
if not mainModel then return {error = "No BridgeChasmReturnStairs"} end

-- 1. Remove old return stairs, planks, posts, stilts
for _, c in ipairs(mainModel:GetChildren()) do
    if c.Name:find("Retry") or c.Name:find("RailingPost") or c.Name:find("StairLantern") or c.Name:find("Return") or c.Name:find("SupportStilt") or c.Name:find("GroundWalkway") or c.Name:find("Plank") or c.Name:find("Crest") then
        c:Destroy()
    end
end

-- 2. Shape terrain properly:
-- A) Solidify the cliff face behind MidTierLanding and under steps 1-8 so stairs climb a real cliff wall
terrain:FillBlock(CFrame.new(16, 85, -1545), Vector3.new(10, 56, 8), Enum.Material.Rock)
terrain:FillBlock(CFrame.new(16, 114, -1545), Vector3.new(10, 2, 8), Enum.Material.Grass)

-- B) Smooth the grassy ridge between Z = -1532 and Z = -1516
-- First clear air above Y = 140.5 so there are no mounds covering the path
terrain:FillBlock(CFrame.new(16, 146, -1523), Vector3.new(16, 10, 18), Enum.Material.Air)
-- Fill nice flat grass foundation at Y = 140.0
terrain:FillBlock(CFrame.new(16, 137, -1523), Vector3.new(16, 6.0, 18), Enum.Material.Grass)

-- 3. Steps Flight 1: From MidTierLanding (14, 110.6, -1550) up to Cliff Crest (17.5, 137.0, -1533)
local startP = Vector3.new(14.0, 111.2, -1548.0)
local crestP = Vector3.new(17.5, 137.0, -1533.0)

local dir1 = (crestP - startP)
local nSteps1 = 18
local stepW = 6.0
local stepD = 2.4
local stepH = 1.4

for s = 1, nSteps1 do
    local alpha = s / nSteps1
    local p = startP:Lerp(crestP, alpha)
    local dFlat = Vector3.new(dir1.X, 0, dir1.Z).Unit
    local yaw = math.atan2(-dFlat.X, -dFlat.Z)
    local cf = CFrame.new(p) * CFrame.Angles(0, yaw, 0)
    
    local step = Instance.new("Part")
    step.Name = "RetryStep_" .. s
    step.Size = Vector3.new(stepW, stepH, stepD)
    step.CFrame = cf
    step.Material = Enum.Material.WoodPlanks
    step.Color = Color3.fromRGB(120, 85, 55)
    step.Anchored = true
    step.CanCollide = true
    step.Parent = mainModel
    
    -- Timber Support Stilts under every 2 steps
    if s % 2 == 0 or s == 1 or s == nSteps1 then
        for _, sideX in ipairs({-stepW/2 + 0.6, stepW/2 - 0.6}) do
            local stiltTop = cf * CFrame.new(sideX, -stepH/2, 0)
            local ray = Ray.new(stiltTop.Position, Vector3.new(0, -50, 0))
            local hit, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, {trail})
            local stiltLen = math.max(1.5, (stiltTop.Position.Y - hitPos.Y))
            
            local stilt = Instance.new("Part")
            stilt.Name = "SupportStilt_" .. s
            stilt.Size = Vector3.new(0.8, stiltLen + 0.8, 0.8)
            stilt.CFrame = CFrame.new(stiltTop.Position - Vector3.new(0, stiltLen/2 - 0.4, 0))
            stilt.Material = Enum.Material.Wood
            stilt.Color = Color3.fromRGB(60, 42, 28)
            stilt.Anchored = true
            stilt.CanCollide = false
            stilt.Parent = mainModel
        end
    end
    
    -- Railing Posts & Lanterns
    if s % 4 == 0 or s == nSteps1 or s == 1 then
        for _, sideX in ipairs({-stepW/2 - 0.3, stepW/2 + 0.3}) do
            local post = Instance.new("Part")
            post.Name = "RailingPost_" .. s
            post.Size = Vector3.new(0.5, 3.8, 0.5)
            post.CFrame = cf * CFrame.new(sideX, 2.0, 0)
            post.Material = Enum.Material.Wood
            post.Color = Color3.fromRGB(75, 50, 32)
            post.Anchored = true
            post.Parent = mainModel
        end
        
        local ltn = Instance.new("Part")
        ltn.Name = "StairLantern_" .. s
        ltn.Size = Vector3.new(0.8, 1.1, 0.8)
        ltn.CFrame = cf * CFrame.new(-stepW/2 - 0.3, 4.4, 0)
        ltn.Material = Enum.Material.Neon
        ltn.Color = Color3.fromRGB(255, 215, 140)
        ltn.Anchored = true
        ltn.Parent = mainModel
        
        local lgt = Instance.new("PointLight")
        lgt.Color = Color3.fromRGB(255, 180, 95)
        lgt.Brightness = 2.2
        lgt.Range = 18
        lgt.Parent = ltn
    end
    
    -- Headroom clearance
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 8, 0)), Vector3.new(10, 14, 4), Enum.Material.Air)
end

-- Continuous Handrail Beams connecting the posts
for s = 1, nSteps1 - 1 do
    local alphaA = s / nSteps1
    local alphaB = (s + 1) / nSteps1
    local pA = startP:Lerp(crestP, alphaA)
    local pB = startP:Lerp(crestP, alphaB)
    local dist = (pB - pA).Magnitude
    local dFlat = Vector3.new(dir1.X, 0, dir1.Z).Unit
    local yaw = math.atan2(-dFlat.X, -dFlat.Z)
    local pitch = math.atan2(pB.Y - pA.Y, Vector3.new(pB.X - pA.X, 0, pB.Z - pA.Z).Magnitude)
    
    for _, sideX in ipairs({-stepW/2 - 0.3, stepW/2 + 0.3}) do
        local railCf = CFrame.new((pA + pB)/2 + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(sideX, 0, 0) * CFrame.Angles(-pitch, 0, 0)
        local rail = Instance.new("Part")
        rail.Name = "ContinuousHandrail_" .. s
        rail.Size = Vector3.new(0.4, 0.5, dist + 0.4)
        rail.CFrame = railCf
        rail.Material = Enum.Material.Wood
        rail.Color = Color3.fromRGB(65, 42, 28)
        rail.Anchored = true
        rail.Parent = mainModel
    end
end

-- 4. Flight 2: Crest onto the grassy ground (Y=137 to Y=140.2)
local groundEntranceP = Vector3.new(18.0, 140.2, -1528.0)
local nSteps2 = 3
for s = 1, nSteps2 do
    local alpha = s / nSteps2
    local p = crestP:Lerp(groundEntranceP, alpha)
    local cf = CFrame.new(p) * CFrame.Angles(0, math.atan2(-(groundEntranceP.X - crestP.X), -(groundEntranceP.Z - crestP.Z)), 0)
    
    local step = Instance.new("Part")
    step.Name = "RetryCrestStep_" .. s
    step.Size = Vector3.new(stepW, 1.2, 2.4)
    step.CFrame = cf
    step.Material = Enum.Material.WoodPlanks
    step.Color = Color3.fromRGB(120, 85, 55)
    step.Anchored = true
    step.CanCollide = true
    step.Parent = mainModel
    
    local stilt = Instance.new("Part")
    stilt.Name = "CrestBase_" .. s
    stilt.Size = Vector3.new(stepW + 0.2, 1.6, 2.6)
    stilt.CFrame = cf * CFrame.new(0, -0.8, 0)
    stilt.Material = Enum.Material.Slate
    stilt.Color = Color3.fromRGB(75, 76, 78)
    stilt.Anchored = true
    stilt.Parent = mainModel
    
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 6, 0)), Vector3.new(10, 12, 4), Enum.Material.Air)
end

-- 5. Ground Boardwalk connecting from (18.0, 140.2, -1528) along the grass to (13.5, 140.1, -1517)
local walkWaypoints = {
    Vector3.new(18.0, 140.2, -1528.0),
    Vector3.new(17.5, 140.2, -1524.0),
    Vector3.new(16.0, 140.1, -1520.5),
    Vector3.new(13.5, 140.1, -1517.0)
}

for w = 1, #walkWaypoints - 1 do
    local pA = walkWaypoints[w]
    local pB = walkWaypoints[w + 1]
    local segDist = (pB - pA).Magnitude
    local segDir = (pB - pA).Unit
    local segYaw = math.atan2(-segDir.X, -segDir.Z)
    
    local nPlanks = math.max(2, math.floor(segDist / 1.8))
    for pl = 1, nPlanks do
        local alpha = pl / nPlanks
        local p = pA:Lerp(pB, alpha)
        
        -- Exact raycast to get terrain surface Y
        local ray = Ray.new(Vector3.new(p.X, 155, p.Z), Vector3.new(0, -30, 0))
        local hit, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, {trail})
        local groundY = hitPos.Y
        
        local plank = Instance.new("Part")
        plank.Name = "GroundWalkwayPlank_" .. w .. "_" .. pl
        plank.Size = Vector3.new(5.0, 0.6, 1.6)
        plank.CFrame = CFrame.new(p.X, groundY + 0.35, p.Z) * CFrame.Angles(0, segYaw, 0)
        plank.Material = Enum.Material.WoodPlanks
        plank.Color = Color3.fromRGB(115, 80, 50)
        plank.Anchored = true
        plank.CanCollide = true
        plank.Parent = mainModel
        
        local gravel = Instance.new("Part")
        gravel.Name = "PlankGravelBorder"
        gravel.Size = Vector3.new(5.8, 0.4, 2.0)
        gravel.CFrame = CFrame.new(p.X, groundY + 0.08, p.Z) * CFrame.Angles(0, segYaw, 0)
        gravel.Material = Enum.Material.Slate
        gravel.Color = Color3.fromRGB(85, 85, 88)
        gravel.Anchored = true
        gravel.CanCollide = false
        gravel.Parent = mainModel
    end
end

-- 6. Handsome Japanese Trail Marker Sign at the ground junction (facing the incoming player!)
local signPost = Instance.new("Part")
signPost.Name = "ReturnSignPost"
signPost.Size = Vector3.new(0.7, 6.5, 0.7)
signPost.CFrame = CFrame.new(15.2, 143.2, -1516.5)
signPost.Material = Enum.Material.Wood
signPost.Color = Color3.fromRGB(65, 42, 28)
signPost.Anchored = true
signPost.Parent = mainModel

local signBoard = Instance.new("Part")
signBoard.Name = "ReturnSignBoard"
signBoard.Size = Vector3.new(5.4, 2.2, 0.4)
signBoard.CFrame = signPost.CFrame * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.pi/4, 0)
signBoard.Material = Enum.Material.Wood
signBoard.Color = Color3.fromRGB(45, 30, 20)
signBoard.Anchored = true
signBoard.Parent = mainModel

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = signBoard

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "← つり橋 (再挑戦)\\nTO BRIDGE (RETRY)"
txt.TextColor3 = Color3.fromRGB(250, 240, 220)
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true
txt.Parent = sg

-- Lantern on signpost
local signLtn = Instance.new("Part")
signLtn.Name = "SignLantern"
signLtn.Size = Vector3.new(0.9, 1.2, 0.9)
signLtn.CFrame = signPost.CFrame * CFrame.new(0, 3.8, 0)
signLtn.Material = Enum.Material.Neon
signLtn.Color = Color3.fromRGB(255, 215, 140)
signLtn.Anchored = true
signLtn.Parent = mainModel

local sLgt = Instance.new("PointLight")
sLgt.Color = Color3.fromRGB(255, 180, 95)
sLgt.Brightness = 2.4
sLgt.Range = 20
sLgt.Parent = signLtn

return {success = true, nSteps = nSteps1 + nSteps2}
`;

  console.log('Building grounded return trail...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture user screenshot match (media_1788508385958.jpg)
  console.log('Capturing match screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_grounded_return_stairs.png',
    [26, 143, -1508],
    [10, 125, -1540]
  );
  
  // Capture view from ground junction looking towards the bridge start
  console.log('Capturing junction view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_ground_junction.png',
    [18, 143, -1514],
    [12, 143, -1525]
  );
}

main().catch(console.error);
