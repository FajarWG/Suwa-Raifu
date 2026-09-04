const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- Remove old rock tunnel model if exists
local oldRockTunnel = trail:FindFirstChild("StaircaseRockTunnel")
if oldRockTunnel then oldRockTunnel:Destroy() end

local rockTunnelModel = Instance.new("Model")
rockTunnelModel.Name = "StaircaseRockTunnel"
rockTunnelModel.Parent = trail

-- Get step positions along the rocky pass (between Z = -1865 and Z = -1905)
local steps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local p = c.Position
        if p.Z <= -1865 and p.Z >= -1905 and p.X < -130 and p.X > -185 then
            table.insert(steps, p)
        end
    end
end
table.sort(steps, function(a,b) return a.Z > b.Z end)

-- 1. Build Natural Rock Cavern / Tunnel Roof
-- Connect the left rock and right rock wall across the stairs
for i = 1, #steps do
    local p = steps[i]
    
    -- Rock ceiling arch: placed 8 to 18 studs above the step
    local roofCenter = p + Vector3.new(0, 11, 0)
    
    -- Fill massive rock arch bridging both sides
    terrain:FillBall(roofCenter + Vector3.new(-4, 0, 0), 9, Enum.Material.Rock)
    terrain:FillBall(roofCenter + Vector3.new(4, 0, 0), 9, Enum.Material.Rock)
    terrain:FillBall(roofCenter + Vector3.new(0, 3, 0), 10, Enum.Material.Rock)
    
    -- Carve interior tunnel passage so players can walk through smoothly
    local clearCenter = p + Vector3.new(0, 6, 0)
    terrain:FillBlock(CFrame.new(clearCenter), Vector3.new(11, 10, 5), Enum.Material.Air)
end

-- Extra clearance at entrance and exit
terrain:FillBlock(CFrame.new(-138, 332, -1870), Vector3.new(14, 14, 8), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-175, 354, -1902), Vector3.new(14, 14, 8), Enum.Material.Air)

-- 2. Add Wooden Reinforcement Arches and Lanterns inside the rock tunnel
local keySteps = {
    steps[1],
    steps[math.floor(#steps * 0.35)],
    steps[math.floor(#steps * 0.7)],
    steps[#steps]
}

for aIdx, sPos in ipairs(keySteps) do
    if sPos then
        local isEntrance = (aIdx == 1 or aIdx == #keySteps)
        local frameModel = Instance.new("Model")
        frameModel.Name = isEntrance and ("CavePortal" .. aIdx) or ("CaveArch" .. aIdx)
        frameModel.Parent = rockTunnelModel
        
        -- Left post
        local postL = Instance.new("Part")
        postL.Name = "PostL"
        postL.Size = Vector3.new(1.2, 10, 1.2)
        postL.CFrame = CFrame.new(sPos + Vector3.new(-4.5, 5.0, 0))
        postL.Material = Enum.Material.Wood
        postL.Color = Color3.fromRGB(70, 48, 30)
        postL.Anchored = true
        postL.Parent = frameModel
        
        -- Right post
        local postR = Instance.new("Part")
        postR.Name = "PostR"
        postR.Size = Vector3.new(1.2, 10, 1.2)
        postR.CFrame = CFrame.new(sPos + Vector3.new(4.5, 5.0, 0))
        postR.Material = Enum.Material.Wood
        postR.Color = Color3.fromRGB(70, 48, 30)
        postR.Anchored = true
        postR.Parent = frameModel
        
        -- Arch Beam
        local beam = Instance.new("Part")
        beam.Name = "ArchBeam"
        beam.Size = Vector3.new(11.5, 1.4, 1.4)
        beam.CFrame = CFrame.new(sPos + Vector3.new(0, 9.8, 0))
        beam.Material = Enum.Material.Wood
        beam.Color = Color3.fromRGB(70, 48, 30)
        beam.Anchored = true
        beam.Parent = frameModel
        
        -- Lantern on arch
        local lantern = Instance.new("Part")
        lantern.Name = "CaveLantern"
        lantern.Size = Vector3.new(1.0, 1.4, 1.0)
        lantern.CFrame = CFrame.new(sPos + Vector3.new(0, 8.6, 0))
        lantern.Material = Enum.Material.Neon
        lantern.Color = Color3.fromRGB(255, 210, 130)
        lantern.Anchored = true
        lantern.Parent = frameModel
        
        local lgt = Instance.new("PointLight")
        lgt.Color = Color3.fromRGB(255, 175, 90)
        lgt.Brightness = 2.6
        lgt.Range = 22
        lgt.Shadows = true
        lgt.Parent = lantern
        
        -- If entrance, add signboard
        if isEntrance and aIdx == 1 then
            local sign = Instance.new("Part")
            sign.Name = "CaveSign"
            sign.Size = Vector3.new(8.5, 1.6, 0.4)
            sign.CFrame = CFrame.new(sPos + Vector3.new(0, 11.2, 0.6))
            sign.Material = Enum.Material.Wood
            sign.Color = Color3.fromRGB(45, 30, 20)
            sign.Anchored = true
            sign.Parent = frameModel
            
            local sg = Instance.new("SurfaceGui")
            sg.Face = Enum.NormalId.Back
            sg.Parent = sign
            
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = "岩窟洞門 - ROCK CAVERN TUNNEL"
            txt.TextColor3 = Color3.fromRGB(245, 235, 215)
            txt.Font = Enum.Font.SourceSansBold
            txt.TextScaled = true
            txt.Parent = sg
        end
    end
end

return { success = true, stepsCount = #steps }
`;

  console.log('Building Staircase Rock Tunnel...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot from similar angle as Image 4
  console.log('Capturing rock tunnel entrance screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_rock_tunnel_entrance.png',
    [-130, 328, -1860],
    [-155, 338, -1885]
  );

  // Capture interior view
  console.log('Capturing rock tunnel interior screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_rock_tunnel_interior.png',
    [-142, 333, -1874],
    [-165, 345, -1895]
  );
  console.log('Rock tunnel screenshots captured!');
}

main().catch(console.error);
