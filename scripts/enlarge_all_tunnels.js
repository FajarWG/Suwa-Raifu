const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- =========================================================================
-- PART 1: WIDEN & ENLARGE CANYON ROCK GALLERY (諏訪山 登坂洞門)
-- Make it 18 studs wide and 16 studs high for groups of players walking together!
-- =========================================================================
local oldGallery = trail:FindFirstChild("CanyonRockGallery")
if oldGallery then oldGallery:Destroy() end

local steps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local p = c.Position
        if p.Z <= -1695 and p.Z >= -1745 and p.X < -25 then
            table.insert(steps, p)
        end
    end
end
table.sort(steps, function(a, b) return a.Y < b.Y end)

-- Carve super-wide, super-tall clearance along all 72 steps: width 22, height 22
for i = 1, #steps do
    local p = steps[i]
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 10, 0)), Vector3.new(22, 20, 6), Enum.Material.Air)
end

-- Clear extra wide lower entrance zone
terrain:FillBlock(CFrame.new(-34, 184, -1698), Vector3.new(26, 24, 18), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-30, 178, -1690), Vector3.new(24, 22, 16), Enum.Material.Air)

-- Clear extra wide upper exit zone
terrain:FillBlock(CFrame.new(-60, 312, -1740), Vector3.new(26, 24, 18), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-63, 310, -1750), Vector3.new(26, 22, 22), Enum.Material.Air)

-- Build Grand Extra-Wide Timber Gallery
local galleryModel = Instance.new("Model")
galleryModel.Name = "CanyonRockGallery"
galleryModel.Parent = trail

local startPos = Vector3.new(-34.0, 171.0, -1698.0)
local endPos = Vector3.new(-60.0, 298.6, -1740.0)
local dir = (endPos - startPos)
local totalDist = dir.Magnitude
local unitDir = dir.Unit
local flatDir = Vector3.new(dir.X, 0, dir.Z).Unit
local yaw = math.atan2(-flatDir.X, -flatDir.Z)

local numFrames = 10
local framePositions = {}

-- Super-spacious dimensions: width = 18 studs, height = 16 studs!
local colH = 16
local halfW = 8.5
local beamW = 20
local beamH = 2.4

for i = 0, numFrames do
    local frac = i / numFrames
    local pCenter = startPos + unitDir * (frac * totalDist)
    local frameCf = CFrame.new(pCenter) * CFrame.Angles(0, yaw, 0)
    table.insert(framePositions, frameCf)
    
    local isPortal = (i == 0 or i == numFrames)
    local frameModel = Instance.new("Model")
    frameModel.Name = (i == 0 and "GalleryPortalLower") or (i == numFrames and "GalleryPortalUpper") or ("GalleryRib" .. i)
    frameModel.Parent = galleryModel
    
    local colW = isPortal and 2.0 or 1.4
    local woodCol = isPortal and Color3.fromRGB(55, 36, 24) or Color3.fromRGB(75, 48, 32)
    
    -- Left Column (at -8.5 studs from center)
    local colL = Instance.new("Part")
    colL.Name = "ColL"
    colL.Size = Vector3.new(colW, colH, colW)
    colL.CFrame = frameCf * CFrame.new(-halfW, colH/2, 0)
    colL.Material = Enum.Material.Wood
    colL.Color = woodCol
    colL.Anchored = true
    colL.Parent = frameModel
    
    -- Right Column (at +8.5 studs from center)
    local colR = Instance.new("Part")
    colR.Name = "ColR"
    colR.Size = Vector3.new(colW, colH, colW)
    colR.CFrame = frameCf * CFrame.new(halfW, colH/2, 0)
    colR.Material = Enum.Material.Wood
    colR.Color = woodCol
    colR.Anchored = true
    colR.Parent = frameModel
    
    -- Overhead Crossbeam (at Y = 16 studs above step!)
    local beam = Instance.new("Part")
    beam.Name = "Beam"
    beam.Size = Vector3.new(beamW, beamH, beamH)
    beam.CFrame = frameCf * CFrame.new(0, colH + beamH/2, 0)
    beam.Material = Enum.Material.Wood
    beam.Color = woodCol
    beam.Anchored = true
    beam.Parent = frameModel
    
    -- Diagonal Braces
    local braceL = Instance.new("Part")
    braceL.Name = "BraceL"
    braceL.Size = Vector3.new(0.8, 4.2, 0.8)
    braceL.CFrame = frameCf * CFrame.new(-halfW + 1.8, colH - 1.5, 0) * CFrame.Angles(0, 0, math.pi/4)
    braceL.Material = Enum.Material.Wood
    braceL.Color = woodCol
    braceL.Anchored = true
    braceL.Parent = frameModel
    
    local braceR = Instance.new("Part")
    braceR.Name = "BraceR"
    braceR.Size = Vector3.new(0.8, 4.2, 0.8)
    braceR.CFrame = frameCf * CFrame.new(halfW - 1.8, colH - 1.5, 0) * CFrame.Angles(0, 0, -math.pi/4)
    braceR.Material = Enum.Material.Wood
    braceR.Color = woodCol
    braceR.Anchored = true
    braceR.Parent = frameModel
    
    -- Portal Signboard & Traditional Eaves
    if isPortal then
        local sign = Instance.new("Part")
        sign.Name = "PortalSign"
        sign.Size = Vector3.new(15, 2.5, 0.5)
        sign.CFrame = frameCf * CFrame.new(0, colH + beamH + 1.5, (i == 0 and -0.8 or 0.8))
        sign.Material = Enum.Material.Wood
        sign.Color = Color3.fromRGB(40, 26, 16)
        sign.Anchored = true
        sign.Parent = frameModel
        
        local sg = Instance.new("SurfaceGui")
        sg.Face = (i == 0 and Enum.NormalId.Front or Enum.NormalId.Back)
        sg.Parent = sign
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = (i == 0 and "諏訪山 登坂洞門 - CANYON ROCK GALLERY") or "山頂連絡口 - SUMMIT TRAIL EXIT"
        txt.TextColor3 = Color3.fromRGB(245, 235, 215)
        txt.Font = Enum.Font.SourceSansBold
        txt.TextScaled = true
        txt.Parent = sg
        
        -- Eaves Roof
        local eave = Instance.new("Part")
        eave.Name = "PortalEave"
        eave.Size = Vector3.new(beamW + 3, 0.9, 4.0)
        eave.CFrame = frameCf * CFrame.new(0, colH + beamH + 3.2, (i == 0 and -0.4 or 0.4))
        eave.Material = Enum.Material.Slate
        eave.Color = Color3.fromRGB(50, 52, 54)
        eave.Anchored = true
        eave.Parent = frameModel
    end
    
    -- Warm Lanterns on beam
    if i % 2 == 0 or isPortal then
        for _, sideX in ipairs({-4.0, 4.0}) do
            local lantern = Instance.new("Part")
            lantern.Name = "GalleryLantern"
            lantern.Size = Vector3.new(1.0, 1.4, 1.0)
            lantern.CFrame = frameCf * CFrame.new(sideX, colH - 1.2, 0)
            lantern.Material = Enum.Material.Neon
            lantern.Color = Color3.fromRGB(255, 215, 140)
            lantern.Anchored = true
            lantern.Parent = frameModel
            
            local lgt = Instance.new("PointLight")
            lgt.Color = Color3.fromRGB(255, 180, 100)
            lgt.Brightness = 2.6
            lgt.Range = 26
            lgt.Shadows = true
            lgt.Parent = lantern
        end
    end
end

-- Semi-open timber roof rafters
for i = 1, #framePositions - 1 do
    local cfA = framePositions[i]
    local cfB = framePositions[i+1]
    local midCf = cfA:Lerp(cfB, 0.5)
    local distAB = (cfB.Position - cfA.Position).Magnitude
    
    for _, sideX in ipairs({-halfW, -halfW/2, 0, halfW/2, halfW}) do
        local rafter = Instance.new("Part")
        rafter.Name = "Rafter"
        rafter.Size = Vector3.new(0.8, 0.8, distAB + 0.4)
        rafter.CFrame = midCf * CFrame.new(sideX, colH + 1.2, 0)
        rafter.Material = Enum.Material.Wood
        rafter.Color = Color3.fromRGB(60, 40, 26)
        rafter.Anchored = true
        rafter.Parent = galleryModel
    end
    
    local roofPlank = Instance.new("Part")
    roofPlank.Name = "GalleryRoof"
    roofPlank.Size = Vector3.new(18.0, 0.5, distAB - 1.0)
    roofPlank.CFrame = midCf * CFrame.new(0, colH + 1.8, 0)
    roofPlank.Material = Enum.Material.WoodPlanks
    roofPlank.Color = Color3.fromRGB(70, 48, 32)
    roofPlank.Anchored = true
    roofPlank.Parent = galleryModel
end


-- =========================================================================
-- PART 2: WIDEN & ENLARGE ROCK CAVERN TUNNEL (岩窟洞門)
-- Carve it to 18 studs wide and 16 studs high!
-- =========================================================================
local cavernSteps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local p = c.Position
        if p.Z <= -1865 and p.Z >= -1905 and p.X < -130 and p.X > -185 then
            table.insert(cavernSteps, p)
        end
    end
end
table.sort(cavernSteps, function(a,b) return a.Z > b.Z end)

-- Carve extra-wide air passage: width 18 studs, height 16 studs!
for i = 1, #cavernSteps do
    local p = cavernSteps[i]
    local airCenter = p + Vector3.new(0, 8.5, 0)
    terrain:FillBlock(CFrame.new(airCenter), Vector3.new(18, 16, 6), Enum.Material.Air)
end

-- Clear extra-wide portals for cavern
terrain:FillBlock(CFrame.new(-135, 334, -1865), Vector3.new(20, 18, 14), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-178, 358, -1905), Vector3.new(20, 18, 14), Enum.Material.Air)

-- Adjust entrance arch of rock tunnel if exists
local rockTunnel = trail:FindFirstChild("StaircaseRockTunnel")
if rockTunnel then
    local arch = rockTunnel:FindFirstChild("RockTunnelEntranceArch")
    if arch then
        local beam = arch:FindFirstChild("ArchBeam")
        local colL = arch:FindFirstChild("ArchColL")
        local colR = arch:FindFirstChild("ArchColR")
        local sign = arch:FindFirstChild("TunnelSign")
        local cf = CFrame.new(-135, 332, -1865) * CFrame.Angles(0, math.rad(-140), 0)
        if beam then beam.Size = Vector3.new(20, 2.2, 2.2); beam.CFrame = cf * CFrame.new(0, 15, 0) end
        if colL then colL.Size = Vector3.new(1.8, 15, 1.8); colL.CFrame = cf * CFrame.new(-8.5, 7.5, 0) end
        if colR then colR.Size = Vector3.new(1.8, 15, 1.8); colR.CFrame = cf * CFrame.new(8.5, 7.5, 0) end
        if sign then sign.Size = Vector3.new(14, 2.2, 0.4); sign.CFrame = cf * CFrame.new(0, 17, -0.6) end
    end
end

return {
    success = true,
    gallerySteps = #steps,
    cavernSteps = #cavernSteps
}
`;

  console.log('Enlarging both tunnels to 18-stud super-wide capacity...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture lower entrance of Canyon Gallery showing super-wide 18-stud opening
  console.log('Capturing wide canyon lower entrance view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_gallery_super_wide_entrance.png',
    [-32, 175, -1684],
    [-38, 185, -1704]
  );

  // 2. Capture interior of Canyon Gallery showing 18-stud wide path
  console.log('Capturing wide canyon interior view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_gallery_super_wide_interior.png',
    [-42, 222, -1710],
    [-50, 255, -1723]
  );

  // 3. Capture Rock Cavern Tunnel entrance showing enlarged 18-stud bore
  console.log('Capturing wide rock cavern entrance view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_rock_cavern_super_wide.png',
    [-128, 332, -1856],
    [-145, 338, -1875]
  );

  console.log('All super-wide tunnel screenshots captured successfully!');
}

main().catch(console.error);
