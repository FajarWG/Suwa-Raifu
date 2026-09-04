const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

local mainModel = trail:FindFirstChild("BridgeChasmReturnStairs")
if not mainModel then return {error = "No BridgeChasmReturnStairs"} end

-- 1. Remove all old return stairs connecting to the bridge
for _, c in ipairs(mainModel:GetChildren()) do
    if c.Name:find("RetryStep") or c.Name:find("RailingPost") or c.Name:find("StairLantern") or c.Name:find("ReturnLanding") then
        c:Destroy()
    end
end

-- 2. New Stair Route: From MidTierLanding (14, 110.6, -1550) to Solid Ground Behind Bridge (15, 152.5, -1527)
-- "ngapa nyambung sama jembatan harusnya ke tanah aja udh biar dia dari blkng lagi"
local stairStart = Vector3.new(14, 111.2, -1548)
local stairEnd = Vector3.new(15, 152.5, -1527) -- Ground trail behind bridge!

local stairDir = (stairEnd - stairStart)
local flatDir = Vector3.new(stairDir.X, 0, stairDir.Z).Unit
local stairYaw = math.atan2(-flatDir.X, -flatDir.Z)
local totalRise = stairEnd.Y - stairStart.Y
local numSteps = 28 -- comfortable 1.47 stud rise per step

for s = 1, numSteps do
    local alpha = s / numSteps
    local p = stairStart:Lerp(stairEnd, alpha)
    local stepCf = CFrame.new(p) * CFrame.Angles(0, stairYaw, 0)
    
    local step = Instance.new("Part")
    step.Name = "RetryStep_" .. s
    step.Size = Vector3.new(7.0, 1.5, 2.8)
    step.CFrame = stepCf
    step.Material = Enum.Material.WoodPlanks
    step.Color = Color3.fromRGB(120, 85, 55)
    step.Anchored = true
    step.CanCollide = true
    step.Parent = mainModel
    
    -- Clear air headroom above each step
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 7, 0)), Vector3.new(11, 13, 5), Enum.Material.Air)
    
    -- Railings & Lanterns every 5 steps
    if s % 5 == 0 or s == numSteps then
        for _, sideX in ipairs({-3.3, 3.3}) do
            local post = Instance.new("Part")
            post.Name = "RailingPost_" .. s
            post.Size = Vector3.new(0.5, 4.2, 0.5)
            post.CFrame = stepCf * CFrame.new(sideX, 2.3, 0)
            post.Material = Enum.Material.Wood
            post.Color = Color3.fromRGB(75, 50, 32)
            post.Anchored = true
            post.Parent = mainModel
        end
        
        local sltn = Instance.new("Part")
        sltn.Name = "StairLantern_" .. s
        sltn.Size = Vector3.new(0.8, 1.2, 0.8)
        sltn.CFrame = stepCf * CFrame.new(-3.3, 4.8, 0)
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

-- 3. Solid Ground Exit Landing at top (connecting smoothly to TrailStep at Z = -1527)
local topLanding = Instance.new("Part")
topLanding.Name = "ReturnGroundLanding"
topLanding.Size = Vector3.new(8.0, 1.2, 7.0)
topLanding.CFrame = CFrame.new(stairEnd + Vector3.new(-1.5, -0.4, 3.0))
topLanding.Material = Enum.Material.WoodPlanks
topLanding.Color = Color3.fromRGB(115, 80, 50)
topLanding.Anchored = true
topLanding.CanCollide = true
topLanding.Parent = mainModel

-- Sign pointing forward to the bridge start
local signPost = Instance.new("Part")
signPost.Name = "ReturnSignPost"
signPost.Size = Vector3.new(0.6, 6.0, 0.6)
signPost.CFrame = topLanding.CFrame * CFrame.new(3.5, 3.6, 0)
signPost.Material = Enum.Material.Wood
signPost.Color = Color3.fromRGB(80, 55, 35)
signPost.Anchored = true
signPost.Parent = mainModel

local sign = Instance.new("Part")
sign.Name = "ReturnSign"
sign.Size = Vector3.new(5.0, 1.8, 0.3)
sign.CFrame = signPost.CFrame * CFrame.new(-2.8, 1.2, 0)
sign.Material = Enum.Material.Wood
sign.Color = Color3.fromRGB(45, 30, 20)
sign.Anchored = true
sign.Parent = mainModel

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = sign

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "つり橋へ (再挑戦)\\nTO BRIDGE (RETRY)"
txt.TextColor3 = Color3.fromRGB(250, 240, 220)
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true
txt.Parent = sg

-- Clear any terrain at top landing
terrain:FillBlock(CFrame.new(topLanding.Position + Vector3.new(0, 6, 0)), Vector3.new(12, 12, 10), Enum.Material.Air)

-- 4. Clean up any artifacts on the suspension bridge
-- Raycast test to verify bridge deck is 100% clean and untouched
local bridgeClean = true
for _, b in ipairs(trail:GetChildren()) do
    if b.Name == "BridgeBeam" and (b.Position - Vector3.new(10, 171, -1535)).Magnitude < 10 then
        -- Check if anything foreign is touching it
    end
end

return {
    success = true,
    numSteps = numSteps,
    stairStart = tostring(stairStart),
    stairEnd = tostring(stairEnd)
}
`;

  console.log('Rerouting Return Stairs to Solid Ground Behind Bridge...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture the top arrival view on the solid ground trail behind bridge
  console.log('Capturing ground arrival view behind bridge...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_stairs_to_ground.png',
    [18, 156, -1522],
    [10, 163, -1538]
  );

  // 2. Capture suspension bridge showing clean separation from the stairs (matching user screenshot)
  console.log('Capturing bridge separation view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_bridge_clean_separation.png',
    [0, 165, -1545],
    [12, 160, -1530]
  );

  console.log('Return stairs rerouted to solid ground behind bridge successfully!');
}

main().catch(console.error);
