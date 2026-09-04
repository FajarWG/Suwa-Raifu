const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- 1. Remove old gallery
local oldGallery = trail:FindFirstChild("CanyonRockGallery")
if oldGallery then oldGallery:Destroy() end

-- 2. Fetch all 72 canyon steps in order
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

local nSteps = #steps
local startPos = steps[1]
local endPos = steps[nSteps]

local dX = endPos.X - startPos.X
local dY = endPos.Y - startPos.Y
local dZ = endPos.Z - startPos.Z
local horizDist = math.sqrt(dX*dX + dZ*dZ)
local pitch = math.atan2(dY, horizDist) -- ~68.8 degrees
local yaw = math.atan2(-dX, -dZ) -- ~31.8 degrees

-- 3. Restore and solidify outer mountain terrain
-- First, fill solid rock along the outer cliff side so there are no floating thin shells or holes
for i = 1, nSteps, 3 do
    local p = steps[i]
    -- Fill solid rock on the outer side (positive X / right side of trail looking up)
    local outerCf = CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.new(16, 6, 0)
    terrain:FillBlock(outerCf, Vector3.new(16, 20, 12), Enum.Material.Rock)
    -- Top with grass
    local grassCf = CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.new(16, 17, 0)
    terrain:FillBlock(grassCf, Vector3.new(16, 4, 12), Enum.Material.Grass)
end

-- Now carve a CLEAN, GENEROUS 20-stud wide x 18-stud high interior corridor along all steps
for i = 1, nSteps do
    local p = steps[i]
    local airCf = CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 9.5, 0)
    terrain:FillBlock(airCf, Vector3.new(20, 18, 5), Enum.Material.Air)
end

-- Clear generous portals at bottom and top
terrain:FillBlock(CFrame.new(startPos) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 10, -6), Vector3.new(24, 22, 16), Enum.Material.Air)
terrain:FillBlock(CFrame.new(endPos) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 10, 6), Vector3.new(24, 22, 16), Enum.Material.Air)


-- 4. Build Grand Japanese Jinja Noborirou (諏訪山 登廊)
local galleryModel = Instance.new("Model")
galleryModel.Name = "CanyonRockGallery"
galleryModel.Parent = trail

local numFrames = 12
local framePositions = {}

local colH = 15.0 -- Generous 15 stud vertical height
local halfW = 8.5 -- 17 stud interior clear width!
local beamW = 20.0
local beamH = 2.0
local woodDark = Color3.fromRGB(50, 32, 20)
local woodFrame = Color3.fromRGB(65, 42, 28)
local roofSlate = Color3.fromRGB(45, 46, 48)

for f = 0, numFrames do
    local frac = f / numFrames
    local stepIdx = math.clamp(math.floor(frac * (nSteps - 1)) + 1, 1, nSteps)
    local pStep = steps[stepIdx]
    
    local frameCf = CFrame.new(pStep) * CFrame.Angles(0, yaw, 0)
    table.insert(framePositions, {cf = frameCf, stepPos = pStep})
    
    local isPortal = (f == 0 or f == numFrames)
    local frameModel = Instance.new("Model")
    frameModel.Name = (f == 0 and "GalleryPortalLower") or (f == numFrames and "GalleryPortalUpper") or ("GalleryFrame_" .. f)
    frameModel.Parent = galleryModel
    
    local colW = isPortal and 2.0 or 1.4
    
    -- Left Column
    local colL = Instance.new("Part")
    colL.Name = "ColL"
    colL.Size = Vector3.new(colW, colH, colW)
    colL.CFrame = frameCf * CFrame.new(-halfW, colH/2, 0)
    colL.Material = Enum.Material.Wood
    colL.Color = isPortal and woodDark or woodFrame
    colL.Anchored = true
    colL.Parent = frameModel
    
    -- Right Column
    local colR = Instance.new("Part")
    colR.Name = "ColR"
    colR.Size = Vector3.new(colW, colH, colW)
    colR.CFrame = frameCf * CFrame.new(halfW, colH/2, 0)
    colR.Material = Enum.Material.Wood
    colR.Color = isPortal and woodDark or woodFrame
    colR.Anchored = true
    colR.Parent = frameModel
    
    -- Foundation Stone Bases
    for _, sideX in ipairs({-halfW, halfW}) do
        local base = Instance.new("Part")
        base.Name = "StoneBase"
        base.Size = Vector3.new(colW + 0.8, 1.2, colW + 0.8)
        base.CFrame = frameCf * CFrame.new(sideX, 0.6, 0)
        base.Material = Enum.Material.Slate
        base.Color = Color3.fromRGB(80, 80, 82)
        base.Anchored = true
        base.Parent = frameModel
    end
    
    -- Horizontal Kasagi Tie Beam (at Y = colH + beamH/2 = 16 studs above step!)
    local beam = Instance.new("Part")
    beam.Name = "Beam"
    beam.Size = Vector3.new(beamW, beamH, beamH)
    beam.CFrame = frameCf * CFrame.new(0, colH + beamH/2, 0)
    beam.Material = Enum.Material.Wood
    beam.Color = isPortal and woodDark or woodFrame
    beam.Anchored = true
    beam.Parent = frameModel
    
    -- Corner Braces (high up at the corners, leaving entire center free)
    local braceL = Instance.new("Part")
    braceL.Name = "BraceL"
    braceL.Size = Vector3.new(0.8, 3.2, 0.8)
    braceL.CFrame = frameCf * CFrame.new(-halfW + 1.4, colH - 1.2, 0) * CFrame.Angles(0, 0, math.pi/4)
    braceL.Material = Enum.Material.Wood
    braceL.Color = woodFrame
    braceL.Anchored = true
    braceL.Parent = frameModel
    
    local braceR = Instance.new("Part")
    braceR.Name = "BraceR"
    braceR.Size = Vector3.new(0.8, 3.2, 0.8)
    braceR.CFrame = frameCf * CFrame.new(halfW - 1.4, colH - 1.2, 0) * CFrame.Angles(0, 0, -math.pi/4)
    braceR.Material = Enum.Material.Wood
    braceR.Color = woodFrame
    braceR.Anchored = true
    braceR.Parent = frameModel
    
    -- SIDE-MOUNTED JINJA LANTERNS (mounted on pillar bracket, ZERO central obstruction!)
    if f % 2 == 0 or isPortal then
        for _, sideX in ipairs({-halfW + 1.0, halfW - 1.0}) do
            local isLeftSide = (sideX < 0)
            
            -- Wooden bracket arm sticking in from column
            local arm = Instance.new("Part")
            arm.Name = "LanternArm"
            arm.Size = Vector3.new(1.2, 0.4, 0.4)
            arm.CFrame = frameCf * CFrame.new(sideX, 8.5, 0)
            arm.Material = Enum.Material.Wood
            arm.Color = woodDark
            arm.Anchored = true
            arm.Parent = frameModel
            
            -- Jinja Lantern Housing
            local ltn = Instance.new("Part")
            ltn.Name = "JinjaLantern"
            ltn.Size = Vector3.new(1.0, 1.4, 1.0)
            ltn.CFrame = frameCf * CFrame.new(sideX, 7.5, 0)
            ltn.Material = Enum.Material.Neon
            ltn.Color = Color3.fromRGB(255, 215, 140)
            ltn.Anchored = true
            ltn.Parent = frameModel
            
            -- Lantern ornamental roof cap
            local ltnCap = Instance.new("Part")
            ltnCap.Name = "LanternCap"
            ltnCap.Size = Vector3.new(1.4, 0.3, 1.4)
            ltnCap.CFrame = frameCf * CFrame.new(sideX, 8.3, 0)
            ltnCap.Material = Enum.Material.Slate
            ltnCap.Color = Color3.fromRGB(40, 42, 44)
            ltnCap.Anchored = true
            ltnCap.Parent = frameModel
            
            local lgt = Instance.new("PointLight")
            lgt.Color = Color3.fromRGB(255, 180, 95)
            lgt.Brightness = 2.4
            lgt.Range = 24
            lgt.Shadows = true
            lgt.Parent = ltn
        end
    end
    
    -- Portal Signboards
    if isPortal then
        local sign = Instance.new("Part")
        sign.Name = "PortalSign"
        sign.Size = Vector3.new(14, 2.2, 0.5)
        sign.CFrame = frameCf * CFrame.new(0, colH + beamH + 1.4, (f == 0 and -0.8 or 0.8))
        sign.Material = Enum.Material.Wood
        sign.Color = Color3.fromRGB(35, 22, 14)
        sign.Anchored = true
        sign.Parent = frameModel
        
        local sg = Instance.new("SurfaceGui")
        sg.Face = (f == 0 and Enum.NormalId.Front or Enum.NormalId.Back)
        sg.Parent = sign
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = (f == 0 and "諏訪山 登廊 - GRAND MOUNTAIN NOBORIROU") or "諏訪山 山頂連絡口 - SUMMIT TRAIL"
        txt.TextColor3 = Color3.fromRGB(245, 235, 215)
        txt.Font = Enum.Font.SourceSansBold
        txt.TextScaled = true
        txt.Parent = sg
    end
end

-- 5. SLANTED ROOF RAFTERS & PANELS ("Dibuat Miring" Exactly Matching Staircase Incline!)
for f = 1, #framePositions - 1 do
    local fA = framePositions[f]
    local fB = framePositions[f+1]
    local pA = fA.stepPos
    local pB = fB.stepPos
    
    local dPos = (pB - pA)
    local segDist = dPos.Magnitude
    local midStep = pA:Lerp(pB, 0.5)
    
    -- Slanted CFrame: origin at midStep, oriented with yaw AND pitch matching stairs
    local segYaw = math.atan2(-dPos.X, -dPos.Z)
    local segHoriz = math.sqrt(dPos.X*dPos.X + dPos.Z*dPos.Z)
    local segPitch = math.atan2(dPos.Y, segHoriz)
    
    local slantedCf = CFrame.new(midStep) * CFrame.Angles(0, segYaw, 0) * CFrame.Angles(-segPitch, 0, 0)
    
    -- Rafter Beams running parallel to slope (at Y = colH + 1.2 = 16.2 studs above stairs)
    for _, sideX in ipairs({-halfW, -halfW/2, 0, halfW/2, halfW}) do
        local rafter = Instance.new("Part")
        rafter.Name = "SlantedRafter"
        rafter.Size = Vector3.new(0.8, 0.8, segDist + 0.4)
        rafter.CFrame = slantedCf * CFrame.new(sideX, colH + 1.2, 0)
        rafter.Material = Enum.Material.Wood
        rafter.Color = woodDark
        rafter.Anchored = true
        rafter.Parent = galleryModel
    end
    
    -- Slanted Gabled Roof Planks (left and right pitched slopes)
    -- Left roof pitch
    local roofL = Instance.new("Part")
    roofL.Name = "SlantedRoofL"
    roofL.Size = Vector3.new(halfW + 1.5, 0.6, segDist + 0.2)
    roofL.CFrame = slantedCf * CFrame.new(-halfW/2, colH + 2.0, 0) * CFrame.Angles(0, 0, math.rad(8))
    roofL.Material = Enum.Material.Slate
    roofL.Color = roofSlate
    roofL.Anchored = true
    roofL.Parent = galleryModel
    
    -- Right roof pitch
    local roofR = Instance.new("Part")
    roofR.Name = "SlantedRoofR"
    roofR.Size = Vector3.new(halfW + 1.5, 0.6, segDist + 0.2)
    roofR.CFrame = slantedCf * CFrame.new(halfW/2, colH + 2.0, 0) * CFrame.Angles(0, 0, math.rad(-8))
    roofR.Material = Enum.Material.Slate
    roofR.Color = roofSlate
    roofR.Anchored = true
    roofR.Parent = galleryModel
    
    -- Ridge Cap (棟)
    local ridge = Instance.new("Part")
    ridge.Name = "SlantedRidge"
    ridge.Size = Vector3.new(1.8, 0.8, segDist + 0.4)
    ridge.CFrame = slantedCf * CFrame.new(0, colH + 2.8, 0)
    ridge.Material = Enum.Material.Slate
    ridge.Color = Color3.fromRGB(35, 36, 38)
    ridge.Anchored = true
    ridge.Parent = galleryModel
end

-- 6. Verification: Check clearance over all 72 steps
local lowClearance = {}
for i = 1, nSteps do
    local p = steps[i]
    -- Raycast 12 studs straight up
    local ray = workspace:Raycast(p + Vector3.new(0, 1, 0), Vector3.new(0, 13, 0))
    if ray and ray.Instance and ray.Instance.CanCollide ~= false and not ray.Instance.Name:find("Step") then
        table.insert(lowClearance, {step = i, hit = ray.Instance:GetFullName(), dist = ray.Distance + 1})
    end
end

return {
    success = true,
    totalSteps = nSteps,
    lowClearanceCount = #lowClearance,
    lowClearance = lowClearance
}
`;

  console.log('Rebuilding CanyonRockGallery with Slanted Jinja Noborirou...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture eye-level inside stairs looking up (matching user previous screenshot)
  console.log('Capturing inside eye-level stairs screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_slanted_noborirou_inside.png',
    [-42, 222, -1710],
    [-50, 255, -1723]
  );

  // 2. Capture lower entrance portal view
  console.log('Capturing lower entrance portal screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_slanted_noborirou_entrance.png',
    [-30, 175, -1685],
    [-38, 188, -1705]
  );

  // 3. Capture outside mountain cliff overview (matching user image with lake in background)
  console.log('Capturing outer mountain cliff screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_slanted_noborirou_outside.png',
    [-15, 230, -1660],
    [-55, 260, -1720]
  );

  console.log('Slanted Noborirou rebuilt, verified, and captured!');
}

main().catch(console.error);
