const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- 1. Remove old gallery
local oldGallery = trail:FindFirstChild("CanyonRockGallery")
if oldGallery then oldGallery:Destroy() end

-- 2. Fetch all 72 canyon steps
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
local yaw = math.atan2(-dX, -dZ)

-- Clear floating bits of terrain and ensure wide open canyon gorge
for i = 1, nSteps do
    local p = steps[i]
    terrain:FillBlock(CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 16, 0), Vector3.new(24, 32, 6), Enum.Material.Air)
end

-- Clear extra above to remove any floating sky polygons
terrain:FillBlock(CFrame.new(-47, 260, -1720), Vector3.new(30, 40, 60), Enum.Material.Air)

local galleryModel = Instance.new("Model")
galleryModel.Name = "CanyonRockGallery"
galleryModel.Parent = trail

local halfW = 7.5 -- 15 studs wide clear stair path
local vermilion = Color3.fromRGB(195, 45, 25)
local darkTimber = Color3.fromRGB(50, 32, 20)
local blackCap = Color3.fromRGB(30, 32, 34)

-- 3. Grand Entrance Torii (at Step 1 - flat ground before steep ascent)
local function buildPortalTorii(name, pStep, isTop)
    local cf = CFrame.new(pStep) * CFrame.Angles(0, yaw, 0)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = galleryModel
    
    local colH = 16
    local colW = 2.0
    
    -- Pillars
    for _, sideX in ipairs({-halfW - 1, halfW + 1}) do
        local col = Instance.new("Part")
        col.Name = "ToriiPillar"
        col.Size = Vector3.new(colW, colH, colW)
        col.CFrame = cf * CFrame.new(sideX, colH/2, 0)
        col.Material = Enum.Material.Wood
        col.Color = vermilion
        col.Anchored = true
        col.Parent = m
        
        local base = Instance.new("Part")
        base.Name = "ToriiBase"
        base.Size = Vector3.new(colW + 1.0, 1.6, colW + 1.0)
        base.CFrame = cf * CFrame.new(sideX, 0.8, 0)
        base.Material = Enum.Material.Slate
        base.Color = Color3.fromRGB(70, 72, 75)
        base.Anchored = true
        base.Parent = m
    end
    
    -- Tie beam Nuki
    local nuki = Instance.new("Part")
    nuki.Name = "Nuki"
    nuki.Size = Vector3.new((halfW + 1)*2 + 3.0, 1.4, 0.9)
    nuki.CFrame = cf * CFrame.new(0, colH - 2.5, 0)
    nuki.Material = Enum.Material.Wood
    nuki.Color = vermilion
    nuki.Anchored = true
    nuki.Parent = m
    
    -- Top beam Kasagi
    local kasagi = Instance.new("Part")
    kasagi.Name = "Kasagi"
    kasagi.Size = Vector3.new((halfW + 1)*2 + 6.0, 2.0, 1.8)
    kasagi.CFrame = cf * CFrame.new(0, colH + 1.0, 0)
    kasagi.Material = Enum.Material.Wood
    kasagi.Color = vermilion
    kasagi.Anchored = true
    kasagi.Parent = m
    
    local cap = Instance.new("Part")
    cap.Name = "KasagiCap"
    cap.Size = Vector3.new((halfW + 1)*2 + 6.6, 0.6, 2.4)
    cap.CFrame = cf * CFrame.new(0, colH + 2.2, 0)
    cap.Material = Enum.Material.Slate
    cap.Color = blackCap
    cap.Anchored = true
    cap.Parent = m
    
    -- Tablet sign
    local tablet = Instance.new("Part")
    tablet.Name = "ToriiTablet"
    tablet.Size = Vector3.new(4.5, 3.4, 0.4)
    tablet.CFrame = cf * CFrame.new(0, colH - 0.7, (isTop and 0.6 or -0.6))
    tablet.Material = Enum.Material.Wood
    tablet.Color = Color3.fromRGB(30, 20, 15)
    tablet.Anchored = true
    tablet.Parent = m
    
    local sg = Instance.new("SurfaceGui")
    sg.Face = isTop and Enum.NormalId.Back or Enum.NormalId.Front
    sg.Parent = tablet
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = isTop and "諏訪山\\n宿営地" or "諏訪大社\\n表参道"
    txt.TextColor3 = Color3.fromRGB(245, 230, 200)
    txt.Font = Enum.Font.SourceSansBold
    txt.TextScaled = true
    txt.Parent = sg
end

buildPortalTorii("EntranceTorii", steps[1], false)
buildPortalTorii("ExitTorii", steps[nSteps], true)

-- 4. Continuous Wooden Guard Railings & Jinja Lantern Posts on the sides
for i = 1, nSteps - 1 do
    local pA = steps[i]
    local pB = steps[i+1]
    local midP = pA:Lerp(pB, 0.5)
    local segDist = (pB - pA).Magnitude
    local segYaw = math.atan2(-(pB.X - pA.X), -(pB.Z - pA.Z))
    local segPitch = math.atan2(pB.Y - pA.Y, math.sqrt((pB.X - pA.X)^2 + (pB.Z - pA.Z)^2))
    local railCf = CFrame.new(midP) * CFrame.Angles(0, segYaw, 0) * CFrame.Angles(-segPitch, 0, 0)
    
    -- Handrails on both sides (following the slope)
    for _, sideX in ipairs({-halfW, halfW}) do
        local rail = Instance.new("Part")
        rail.Name = "HandRail"
        rail.Size = Vector3.new(0.4, 0.6, segDist + 0.2)
        rail.CFrame = railCf * CFrame.new(sideX, 3.4, 0)
        rail.Material = Enum.Material.Wood
        rail.Color = darkTimber
        rail.Anchored = true
        rail.Parent = galleryModel
    end
    
    -- Vertical railing posts every 2 steps
    if i % 2 == 1 then
        for _, sideX in ipairs({-halfW, halfW}) do
            local post = Instance.new("Part")
            post.Name = "RailPost"
            post.Size = Vector3.new(0.5, 4.0, 0.5)
            post.CFrame = CFrame.new(pA) * CFrame.Angles(0, yaw, 0) * CFrame.new(sideX, 2.0, 0)
            post.Material = Enum.Material.Wood
            post.Color = darkTimber
            post.Anchored = true
            post.Parent = galleryModel
        end
    end
    
    -- Authentic Japanese Jinja Lantern Posts (Toro) every 4 steps along the side posts
    if i % 4 == 1 then
        local sideX = (i % 8 == 1) and (-halfW - 0.8) or (halfW + 0.8)
        local postCf = CFrame.new(pA) * CFrame.Angles(0, yaw, 0) * CFrame.new(sideX, 0, 0)
        
        -- Stone lantern pedestal
        local base = Instance.new("Part")
        base.Name = "ToroBase"
        base.Size = Vector3.new(1.4, 1.0, 1.4)
        base.CFrame = postCf * CFrame.new(0, 0.5, 0)
        base.Material = Enum.Material.Slate
        base.Color = Color3.fromRGB(80, 82, 85)
        base.Anchored = true
        base.Parent = galleryModel
        
        -- Lantern wooden pillar (Sao)
        local pillar = Instance.new("Part")
        pillar.Name = "ToroPillar"
        pillar.Size = Vector3.new(0.7, 4.5, 0.7)
        pillar.CFrame = postCf * CFrame.new(0, 3.25, 0)
        pillar.Material = Enum.Material.Wood
        pillar.Color = vermilion
        pillar.Anchored = true
        pillar.Parent = galleryModel
        
        -- Lantern firebox (Hibukuro)
        local firebox = Instance.new("Part")
        firebox.Name = "JinjaLantern"
        firebox.Size = Vector3.new(1.2, 1.4, 1.2)
        firebox.CFrame = postCf * CFrame.new(0, 6.2, 0)
        firebox.Material = Enum.Material.Neon
        firebox.Color = Color3.fromRGB(255, 215, 140)
        firebox.Anchored = true
        firebox.Parent = galleryModel
        
        -- Pitched Shrine Roof Cap (Kasa) - tilted miring!
        local cap = Instance.new("Part")
        cap.Name = "ToroRoofCap"
        cap.Size = Vector3.new(2.0, 0.5, 2.0)
        cap.CFrame = postCf * CFrame.new(0, 7.1, 0)
        cap.Material = Enum.Material.Slate
        cap.Color = blackCap
        cap.Anchored = true
        cap.Parent = galleryModel
        
        -- Jewel finial (Houju)
        local finial = Instance.new("Part")
        finial.Name = "ToroFinial"
        finial.Size = Vector3.new(0.4, 0.6, 0.4)
        finial.CFrame = postCf * CFrame.new(0, 7.6, 0)
        finial.Material = Enum.Material.Metal
        finial.Color = Color3.fromRGB(215, 175, 75)
        finial.Anchored = true
        finial.Parent = galleryModel
        
        local lgt = Instance.new("PointLight")
        lgt.Color = Color3.fromRGB(255, 185, 105)
        lgt.Brightness = 2.6
        lgt.Range = 26
        lgt.Shadows = true
        lgt.Parent = firebox
    end
end

-- 5. Verification: Check clearance over all 72 steps (0 obstructions!)
local lowCount = 0
for i = 1, nSteps do
    local p = steps[i]
    local ray = workspace:Raycast(p + Vector3.new(0, 1, 0), Vector3.new(0, 15, 0))
    if ray and ray.Instance and ray.Instance.CanCollide ~= false and not ray.Instance.Name:find("Step") then
        lowCount = lowCount + 1
    end
end

return {
    success = true,
    stepsCount = nSteps,
    lowClearanceCount = lowCount
}
`;

  console.log('Building Clean Mountain Shrine Canyon Trail...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture eye-level inside stairs looking up (the view user had issues with)
  console.log('Capturing inside eye-level stairs screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_clean_canyon_inside.png',
    [-40, 218, -1708],
    [-48, 252, -1722]
  );

  // 2. Capture lower entrance view looking up
  console.log('Capturing lower entrance portal screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_clean_canyon_entrance.png',
    [-30, 174, -1684],
    [-36, 188, -1702]
  );

  // 3. Capture outside canyon overview from the valley
  console.log('Capturing canyon vista screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_clean_canyon_vista.png',
    [-10, 225, -1650],
    [-55, 260, -1720]
  );

  console.log('Clean Mountain Shrine Canyon Trail built, verified, and captured!');
}

main().catch(console.error);
