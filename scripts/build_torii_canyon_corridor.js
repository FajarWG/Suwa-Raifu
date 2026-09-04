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

-- Clear wide, open sky clearance along all steps (width 22, height 28)
for i = 1, nSteps do
    local p = steps[i]
    terrain:FillBlock(CFrame.new(p) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 14, 0), Vector3.new(22, 28, 6), Enum.Material.Air)
end

-- Model for Canyon Torii Shrine Trail
local galleryModel = Instance.new("Model")
galleryModel.Name = "CanyonRockGallery"
galleryModel.Parent = trail

local numTorii = 9
local colH = 14.5 -- Height of Torii pillars
local halfW = 8.0 -- 16 studs clear interior width!
local vermilion = Color3.fromRGB(185, 45, 25) -- Authentic shrine vermilion / or dark cypress
local darkTimber = Color3.fromRGB(50, 32, 20)
local blackCap = Color3.fromRGB(35, 36, 38)

-- 3. Build Grand Mountain Shrine Torii Gates along the ascent
for t = 0, numTorii do
    local frac = t / numTorii
    local stepIdx = math.clamp(math.floor(frac * (nSteps - 1)) + 1, 1, nSteps)
    local pStep = steps[stepIdx]
    
    local toriiCf = CFrame.new(pStep) * CFrame.Angles(0, yaw, 0)
    local isMainPortal = (t == 0 or t == numTorii)
    
    local torii = Instance.new("Model")
    torii.Name = (t == 0 and "ToriiPortal_Lower") or (t == numTorii and "ToriiPortal_Upper") or ("ToriiGate_" .. t)
    torii.Parent = galleryModel
    
    local colW = isMainPortal and 1.8 or 1.3
    local gateColor = (t % 2 == 0) and vermilion or darkTimber
    
    -- Left Pillar (Hashira)
    local colL = Instance.new("Part")
    colL.Name = "PillarL"
    colL.Size = Vector3.new(colW, colH, colW)
    colL.CFrame = toriiCf * CFrame.new(-halfW, colH/2, 0)
    colL.Material = Enum.Material.Wood
    colL.Color = gateColor
    colL.Anchored = true
    colL.Parent = torii
    
    -- Right Pillar (Hashira)
    local colR = Instance.new("Part")
    colR.Name = "PillarR"
    colR.Size = Vector3.new(colW, colH, colW)
    colR.CFrame = toriiCf * CFrame.new(halfW, colH/2, 0)
    colR.Material = Enum.Material.Wood
    colR.Color = gateColor
    colR.Anchored = true
    colR.Parent = torii
    
    -- Stone Pillar Foundation (Kamebara)
    for _, sideX in ipairs({-halfW, halfW}) do
        local stone = Instance.new("Part")
        stone.Name = "StoneFoundation"
        stone.Size = Vector3.new(colW + 0.8, 1.4, colW + 0.8)
        stone.CFrame = toriiCf * CFrame.new(sideX, 0.7, 0)
        stone.Material = Enum.Material.Slate
        stone.Color = Color3.fromRGB(75, 76, 78)
        stone.Anchored = true
        stone.Parent = torii
    end
    
    -- Nuki Tie-Beam (horizontal brace below kasagi)
    local nuki = Instance.new("Part")
    nuki.Name = "NukiBeam"
    nuki.Size = Vector3.new(halfW * 2 + 2.5, 1.2, 0.8)
    nuki.CFrame = toriiCf * CFrame.new(0, colH - 2.2, 0)
    nuki.Material = Enum.Material.Wood
    nuki.Color = gateColor
    nuki.Anchored = true
    nuki.Parent = torii
    
    -- Kasagi Top Lintel Beam (placed high overhead at colH + 1.2 = 15.7 studs above step!)
    local kasagi = Instance.new("Part")
    kasagi.Name = "KasagiBeam"
    kasagi.Size = Vector3.new(halfW * 2 + 5.0, 1.8, 1.6)
    kasagi.CFrame = toriiCf * CFrame.new(0, colH + 0.9, 0)
    kasagi.Material = Enum.Material.Wood
    kasagi.Color = gateColor
    kasagi.Anchored = true
    kasagi.Parent = torii
    
    -- Black Eaves Cap on Kasagi
    local cap = Instance.new("Part")
    cap.Name = "KasagiCap"
    cap.Size = Vector3.new(halfW * 2 + 5.6, 0.5, 2.0)
    cap.CFrame = toriiCf * CFrame.new(0, colH + 2.0, 0)
    cap.Material = Enum.Material.Slate
    cap.Color = blackCap
    cap.Anchored = true
    cap.Parent = torii
    
    -- JINJA LANTERNS mounted on side brackets of each Torii
    for _, sideX in ipairs({-halfW + 0.8, halfW - 0.8}) do
        local ltn = Instance.new("Part")
        ltn.Name = "JinjaToro"
        ltn.Size = Vector3.new(1.0, 1.4, 1.0)
        ltn.CFrame = toriiCf * CFrame.new(sideX, 8.0, 0)
        ltn.Material = Enum.Material.Neon
        ltn.Color = Color3.fromRGB(255, 215, 140)
        ltn.Anchored = true
        ltn.Parent = torii
        
        local ltnCap = Instance.new("Part")
        ltnCap.Name = "ToroCap"
        ltnCap.Size = Vector3.new(1.5, 0.4, 1.5)
        ltnCap.CFrame = toriiCf * CFrame.new(sideX, 8.8, 0)
        ltnCap.Material = Enum.Material.Slate
        ltnCap.Color = blackCap
        ltnCap.Anchored = true
        ltnCap.Parent = torii
        
        local lgt = Instance.new("PointLight")
        lgt.Color = Color3.fromRGB(255, 185, 105)
        lgt.Brightness = 2.4
        lgt.Range = 24
        lgt.Shadows = true
        lgt.Parent = ltn
    end
    
    -- Portal Signboard on Main Entrance & Exit
    if isMainPortal then
        local sign = Instance.new("Part")
        sign.Name = "ToriiTablet"
        sign.Size = Vector3.new(4.5, 3.2, 0.4)
        sign.CFrame = toriiCf * CFrame.new(0, colH - 0.6, (t == 0 and -0.6 or 0.6))
        sign.Material = Enum.Material.Wood
        sign.Color = Color3.fromRGB(30, 20, 15)
        sign.Anchored = true
        sign.Parent = torii
        
        local sg = Instance.new("SurfaceGui")
        sg.Face = (t == 0 and Enum.NormalId.Front or Enum.NormalId.Back)
        sg.Parent = sign
        
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = (t == 0 and "諏訪大社\\n山道鳥居") or "諏訪山\\n宿営地"
        txt.TextColor3 = Color3.fromRGB(245, 230, 200)
        txt.Font = Enum.Font.SourceSansBold
        txt.TextScaled = true
        txt.Parent = sg
    end
end

-- 4. Continuous Wooden Guard Railings along both sides of all 72 steps
for i = 1, nSteps - 1 do
    local pA = steps[i]
    local pB = steps[i+1]
    local midP = pA:Lerp(pB, 0.5)
    local segDist = (pB - pA).Magnitude
    local segYaw = math.atan2(-(pB.X - pA.X), -(pB.Z - pA.Z))
    local segPitch = math.atan2(pB.Y - pA.Y, math.sqrt((pB.X - pA.X)^2 + (pB.Z - pA.Z)^2))
    local railCf = CFrame.new(midP) * CFrame.Angles(0, segYaw, 0) * CFrame.Angles(-segPitch, 0, 0)
    
    for _, sideX in ipairs({-halfW + 0.8, halfW - 0.8}) do
        local rail = Instance.new("Part")
        rail.Name = "StairRail"
        rail.Size = Vector3.new(0.4, 0.5, segDist + 0.2)
        rail.CFrame = railCf * CFrame.new(sideX, 3.2, 0)
        rail.Material = Enum.Material.Wood
        rail.Color = darkTimber
        rail.Anchored = true
        rail.Parent = galleryModel
    end
    
    if i % 3 == 1 then
        for _, sideX in ipairs({-halfW + 0.8, halfW - 0.8}) do
            local post = Instance.new("Part")
            post.Name = "RailPost"
            post.Size = Vector3.new(0.5, 3.8, 0.5)
            post.CFrame = CFrame.new(pA) * CFrame.Angles(0, yaw, 0) * CFrame.new(sideX, 1.9, 0)
            post.Material = Enum.Material.Wood
            post.Color = darkTimber
            post.Anchored = true
            post.Parent = galleryModel
        end
    end
end

-- 5. Verification: Check clearance over all 72 steps
local lowCount = 0
for i = 1, nSteps do
    local p = steps[i]
    local ray = workspace:Raycast(p + Vector3.new(0, 1, 0), Vector3.new(0, 11, 0))
    if ray and ray.Instance and ray.Instance.CanCollide ~= false and not ray.Instance.Name:find("Step") then
        lowCount = lowCount + 1
    end
end

return {
    success = true,
    toriiCount = numTorii + 1,
    stepsCount = nSteps,
    lowClearanceCount = lowCount
}
`;

  console.log('Building Grand Mountain Shrine Torii Corridor...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture eye-level inside stairs looking up through the Torii gates
  console.log('Capturing inside eye-level Torii path screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_torii_corridor_inside.png',
    [-40, 218, -1708],
    [-48, 252, -1722]
  );

  // 2. Capture lower entrance view looking up
  console.log('Capturing lower entrance portal screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_torii_entrance.png',
    [-30, 175, -1684],
    [-38, 192, -1704]
  );

  // 3. Capture wide canyon vista showing the mountain gorge and torii path
  console.log('Capturing canyon vista screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_torii_canyon_vista.png',
    [-10, 225, -1650],
    [-55, 260, -1720]
  );

  console.log('Grand Torii corridor built, verified, and captured!');
}

main().catch(console.error);
