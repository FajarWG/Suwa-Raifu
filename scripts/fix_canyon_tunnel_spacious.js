const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- 1. Remove old tunnel model
local oldTunnel = trail:FindFirstChild("CanyonInclineTunnel")
if oldTunnel then oldTunnel:Destroy() end

-- 2. First: CLEAR OUT ALL DIRT / MOUNDS along the entire path!
-- Get all steps from (-34, 171, -1698) up to (-70, 298, -1785)
local inclineSteps = {}
local exitSteps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local p = c.Position
        if p.Z <= -1695 and p.Z >= -1745 and p.X < -25 then
            table.insert(inclineSteps, p)
        elseif p.Z < -1745 and p.Z >= -1785 and p.X < -50 then
            table.insert(exitSteps, p)
        end
    end
end
table.sort(inclineSteps, function(a,b) return a.Z > b.Z end)
table.sort(exitSteps, function(a,b) return a.Z > b.Z end)

-- Clear generous walking envelope along the entire incline (width 16, height 18)
for _, p in ipairs(inclineSteps) do
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 9, 0)), Vector3.new(16, 18, 8), Enum.Material.Air)
end

-- Clear out the dirt mound completely covering the exit and continuation steps
for _, p in ipairs(exitSteps) do
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 10, 0)), Vector3.new(18, 20, 10), Enum.Material.Air)
end

-- Clear surrounding entrance and exit areas
terrain:FillBlock(CFrame.new(-34, 180, -1698), Vector3.new(18, 20, 12), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-60, 308, -1740), Vector3.new(20, 22, 14), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-65, 308, -1760), Vector3.new(20, 22, 14), Enum.Material.Air)

-- 3. Now build a TALL, GRAND mountain ridge roof over the incline
-- The roof sits 14 to 26 studs above the stairs, leaving 14 studs of open air below it!
local startPos = Vector3.new(-34.0, 171.0, -1698.0)
local endPos = Vector3.new(-60.0, 296.0, -1740.0)
local dir = (endPos - startPos)
local totalDist = dir.Magnitude
local unitDir = dir.Unit
local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
local yaw = math.atan2(-flatDir.X, -flatDir.Z)

local numSegments = 20
for i = 1, numSegments - 1 do
    local frac = i / numSegments
    local center = startPos + unitDir * (frac * totalDist)
    
    -- Roof is placed high above (from Y + 15 to Y + 24)
    local roofCenter = center + Vector3.new(0, 18, 0)
    local roofCf = CFrame.new(roofCenter) * CFrame.Angles(0, yaw, 0)
    
    terrain:FillBlock(roofCf * CFrame.new(0, -2, 0), Vector3.new(20, 6, 8), Enum.Material.Rock)
    terrain:FillBlock(roofCf * CFrame.new(0, 3, 0), Vector3.new(24, 6, 10), Enum.Material.Grass)
    
    -- Ensure 14 studs of interior clearance
    terrain:FillBlock(CFrame.new(center + Vector3.new(0, 7, 0)) * CFrame.Angles(0, yaw, 0), Vector3.new(14, 14, 8), Enum.Material.Air)
end

-- 4. Build Grand Timber Portal Arches and Interior Timber Frames
local tunnelModel = Instance.new("Model")
tunnelModel.Name = "CanyonInclineTunnel"
tunnelModel.Parent = trail

local numArches = 6
for i = 0, numArches do
    local frac = i / numArches
    local pCenter = startPos + unitDir * (frac * totalDist)
    local archBaseCf = CFrame.new(pCenter) * CFrame.Angles(0, yaw, 0)
    
    local isPortal = (i == 0 or i == numArches)
    local archModel = Instance.new("Model")
    archModel.Name = (i == 0 and "TunnelEntranceLower") or (i == numArches and "TunnelEntranceUpper") or ("TunnelRib" .. i)
    archModel.Parent = tunnelModel
    
    -- Tall columns: height 13 studs!
    local colH = 13
    local colW = isPortal and 1.8 or 1.2
    local beamW = isPortal and 16 or 14
    local beamH = isPortal and 2.2 or 1.6
    local woodCol = isPortal and Color3.fromRGB(65, 42, 28) or Color3.fromRGB(80, 52, 34)
    
    -- Left Column
    local colL = Instance.new("Part")
    colL.Name = "ArchColL"
    colL.Size = Vector3.new(colW, colH, colW)
    colL.CFrame = archBaseCf * CFrame.new(-6.0, colH/2, 0)
    colL.Material = Enum.Material.Wood
    colL.Color = woodCol
    colL.Anchored = true
    colL.Parent = archModel
    
    -- Right Column
    local colR = Instance.new("Part")
    colR.Name = "ArchColR"
    colR.Size = Vector3.new(colW, colH, colW)
    colR.CFrame = archBaseCf * CFrame.new(6.0, colH/2, 0)
    colR.Material = Enum.Material.Wood
    colR.Color = woodCol
    colR.Anchored = true
    colR.Parent = archModel
    
    -- Overhead Crossbeam (at Y = 13 studs above step!)
    local beam = Instance.new("Part")
    beam.Name = "ArchBeam"
    beam.Size = Vector3.new(beamW, beamH, beamH)
    beam.CFrame = archBaseCf * CFrame.new(0, colH + beamH/2, 0)
    beam.Material = Enum.Material.Wood
    beam.Color = woodCol
    beam.Anchored = true
    beam.Parent = archModel
    
    -- Diagonal Braces
    local braceL = Instance.new("Part")
    braceL.Name = "BraceL"
    braceL.Size = Vector3.new(0.8, 3.5, 0.8)
    braceL.CFrame = archBaseCf * CFrame.new(-4.6, colH - 1.2, 0) * CFrame.Angles(0, 0, math.pi/4)
    braceL.Material = Enum.Material.Wood
    braceL.Color = woodCol
    braceL.Anchored = true
    braceL.Parent = archModel
    
    local braceR = Instance.new("Part")
    braceR.Name = "BraceR"
    braceR.Size = Vector3.new(0.8, 3.5, 0.8)
    braceR.CFrame = archBaseCf * CFrame.new(4.6, colH - 1.2, 0) * CFrame.Angles(0, 0, -math.pi/4)
    braceR.Material = Enum.Material.Wood
    braceR.Color = woodCol
    braceR.Anchored = true
    braceR.Parent = archModel
    
    -- Portal Signboard on lower and upper entrance
    if isPortal then
        local sign = Instance.new("Part")
        sign.Name = "TunnelSign"
        sign.Size = Vector3.new(11, 2.0, 0.4)
        sign.CFrame = archBaseCf * CFrame.new(0, colH + beamH + 1.2, (i == 0 and -0.8 or 0.8))
        sign.Material = Enum.Material.Wood
        sign.Color = Color3.fromRGB(45, 30, 20)
        sign.Anchored = true
        sign.Parent = archModel
        
        local sg = Instance.new("SurfaceGui")
        sg.Face = (i == 0 and Enum.NormalId.Front or Enum.NormalId.Back)
        sg.Parent = sign
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = "諏訪山 登坂隧道 - CANYON TUNNEL"
        txt.TextColor3 = Color3.fromRGB(245, 235, 215)
        txt.Font = Enum.Font.SourceSansBold
        txt.TextScaled = true
        txt.Parent = sg
    end
    
    -- Warm Lantern on beam
    local lantern = Instance.new("Part")
    lantern.Name = "TunnelLantern"
    lantern.Size = Vector3.new(1.0, 1.4, 1.0)
    lantern.CFrame = archBaseCf * CFrame.new(0, colH - 1.0, 0)
    lantern.Material = Enum.Material.Neon
    lantern.Color = Color3.fromRGB(255, 210, 130)
    lantern.Anchored = true
    lantern.Parent = archModel
    
    local lgt = Instance.new("PointLight")
    lgt.Color = Color3.fromRGB(255, 175, 90)
    lgt.Brightness = 2.8
    lgt.Range = 26
    lgt.Shadows = true
    lgt.Parent = lantern
end

return { success = true, inclineSteps = #inclineSteps, exitSteps = #exitSteps }
`;

  console.log('Fixing Canyon Incline Tunnel Clearance & Exit...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot of lower entrance (matching Image 4)
  console.log('Capturing lower entrance screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_canyon_tunnel_spacious_lower.png',
    [-32, 178, -1692],
    [-42, 205, -1708]
  );

  // Capture screenshot of upper exit (matching Image 5)
  console.log('Capturing upper exit screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_canyon_tunnel_spacious_exit.png',
    [-68, 305, -1755],
    [-60, 298, -1738]
  );

  // Capture screenshot of path continuation past exit leading to camp
  console.log('Capturing continuation path screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_canyon_continuation_path.png',
    [-58, 304, -1736],
    [-70, 298, -1775]
  );
  console.log('All tunnel clearance screenshots captured!');
}

main().catch(console.error);
