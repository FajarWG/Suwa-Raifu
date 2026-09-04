const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- Remove old CanyonTunnel model if exists
local oldTunnel = trail:FindFirstChild("CanyonInclineTunnel")
if oldTunnel then oldTunnel:Destroy() end

local tunnelModel = Instance.new("Model")
tunnelModel.Name = "CanyonInclineTunnel"
tunnelModel.Parent = trail

local startPos = Vector3.new(-34.0, 171.0, -1698.0)
local endPos = Vector3.new(-60.0, 296.0, -1740.0)
local dir = (endPos - startPos)
local totalDist = dir.Magnitude
local unitDir = dir.Unit

-- Incline rotation
local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
local yaw = math.atan2(-flatDir.X, -flatDir.Z) -- around Y
local pitch = math.asin(unitDir.Y) -- climb angle

-- 1. Fill Terrain Ceiling across the canyon trench
-- We step along the incline and bridge the left and right hill walls
local numSegments = 25
for i = 0, numSegments do
    local frac = i / numSegments
    local center = startPos + unitDir * (frac * totalDist)
    
    -- Roof block: placed above the walking path
    local roofCenter = center + Vector3.new(0, 14, 0)
    local roofCFrame = CFrame.new(roofCenter) * CFrame.Angles(0, yaw, 0)
    
    -- Fill rock arch and grass surface
    terrain:FillBlock(roofCFrame * CFrame.new(0, -2, 0), Vector3.new(18, 6, 8), Enum.Material.Rock)
    terrain:FillBlock(roofCFrame * CFrame.new(0, 3, 0), Vector3.new(22, 6, 10), Enum.Material.Grass)
    
    -- Carve walking clearance (width 12, height 12)
    local clearCenter = center + Vector3.new(0, 6, 0)
    local clearCFrame = CFrame.new(clearCenter) * CFrame.Angles(0, yaw, 0)
    terrain:FillBlock(clearCFrame, Vector3.new(13, 11, 8), Enum.Material.Air)
end

-- 2. Build Timber Arches along the tunnel interior
local numArches = 8
for i = 0, numArches do
    local frac = i / numArches
    local pCenter = startPos + unitDir * (frac * totalDist)
    local archBaseCf = CFrame.new(pCenter) * CFrame.Angles(0, yaw, 0)
    
    local archModel = Instance.new("Model")
    archModel.Name = (i == 0 and "TunnelEntranceLower") or (i == numArches and "TunnelEntranceUpper") or ("TunnelRib" .. i)
    archModel.Parent = tunnelModel
    
    local isPortal = (i == 0 or i == numArches)
    local colSize = isPortal and Vector3.new(1.8, 14, 1.8) or Vector3.new(1.2, 12, 1.2)
    local beamSize = isPortal and Vector3.new(15, 2.2, 2.2) or Vector3.new(13.5, 1.4, 1.4)
    local colHeight = isPortal and 7 or 6
    local woodCol = isPortal and Color3.fromRGB(65, 42, 28) or Color3.fromRGB(80, 52, 34)
    
    -- Left Column
    local colL = Instance.new("Part")
    colL.Name = "ArchColL"
    colL.Size = colSize
    colL.CFrame = archBaseCf * CFrame.new(-6.2, colHeight, 0)
    colL.Material = Enum.Material.Wood
    colL.Color = woodCol
    colL.Anchored = true
    colL.Parent = archModel
    
    -- Right Column
    local colR = Instance.new("Part")
    colR.Name = "ArchColR"
    colR.Size = colSize
    colR.CFrame = archBaseCf * CFrame.new(6.2, colHeight, 0)
    colR.Material = Enum.Material.Wood
    colR.Color = woodCol
    colR.Anchored = true
    colR.Parent = archModel
    
    -- Top Overhead Crossbeam
    local beam = Instance.new("Part")
    beam.Name = "ArchBeam"
    beam.Size = beamSize
    beam.CFrame = archBaseCf * CFrame.new(0, colHeight * 2, 0)
    beam.Material = Enum.Material.Wood
    beam.Color = woodCol
    beam.Anchored = true
    beam.Parent = archModel
    
    -- Diagonal Braces
    local braceL = Instance.new("Part")
    braceL.Name = "BraceL"
    braceL.Size = Vector3.new(0.8, 3.5, 0.8)
    braceL.CFrame = archBaseCf * CFrame.new(-4.8, colHeight * 2 - 1.2, 0) * CFrame.Angles(0, 0, math.pi/4)
    braceL.Material = Enum.Material.Wood
    braceL.Color = woodCol
    braceL.Anchored = true
    braceL.Parent = archModel
    
    local braceR = Instance.new("Part")
    braceR.Name = "BraceR"
    braceR.Size = Vector3.new(0.8, 3.5, 0.8)
    braceR.CFrame = archBaseCf * CFrame.new(4.8, colHeight * 2 - 1.2, 0) * CFrame.Angles(0, 0, -math.pi/4)
    braceR.Material = Enum.Material.Wood
    braceR.Color = woodCol
    braceR.Anchored = true
    braceR.Parent = archModel
    
    -- Portal Signboard on entrance and exit
    if isPortal then
        local sign = Instance.new("Part")
        sign.Name = "TunnelSign"
        sign.Size = Vector3.new(10, 1.8, 0.4)
        sign.CFrame = archBaseCf * CFrame.new(0, colHeight * 2 + 1.8, (i == 0 and -0.8 or 0.8))
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
    
    -- Hanging Lantern inside tunnel on alternate ribs
    if i > 0 and i < numArches and i % 2 == 1 then
        local lantern = Instance.new("Part")
        lantern.Name = "TunnelLantern"
        lantern.Size = Vector3.new(1.0, 1.4, 1.0)
        lantern.CFrame = archBaseCf * CFrame.new(0, colHeight * 2 - 1.2, 0)
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
end

return { success = true, totalDist = totalDist, arches = numArches + 1 }
`;

  console.log('Building Canyon Incline Tunnel...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot from bottom looking up into the tunnel (Image 3 angle)
  console.log('Capturing canyon tunnel lower entrance screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_canyon_tunnel_lower.png',
    [-30, 176, -1688],
    [-45, 220, -1720]
  );

  // Capture screenshot looking inside the tunnel
  console.log('Capturing canyon tunnel interior screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_canyon_tunnel_interior.png',
    [-36, 185, -1703],
    [-50, 235, -1725]
  );
  console.log('Canyon tunnel screenshots captured!');
}

main().catch(console.error);
