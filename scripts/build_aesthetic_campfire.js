const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

-- 1. Remove old CampLogSeat
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "CampLogSeat" then
        c:Destroy()
    end
end

-- Also clean up the half-buried messy TentSide/TentRidge/TentFloor that clipped into the hill next to fire
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TentSide" or c.Name == "TentRidge" or c.Name == "TentFloor" then
        c:Destroy()
    end
end

-- Remove old AestheticCampfire if exists
local existingModel = trail:FindFirstChild("AestheticCampfire")
if existingModel then existingModel:Destroy() end

local campModel = Instance.new("Model")
campModel.Name = "AestheticCampfire"
campModel.Parent = trail

local center = Vector3.new(-24.0, 301.8, -1774.0)

-- Clean up existing FireRing and FireLogs if they exist
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "FireRing" or c.Name == "FireLogs" or c.Name == "FireHearth" then
        c:Destroy()
    end
end

-- Build Fire Hearth / Ash Pit
local hearth = Instance.new("Part")
hearth.Name = "CampHearth"
hearth.Size = Vector3.new(9, 0.6, 9)
hearth.CFrame = CFrame.new(center + Vector3.new(0, -0.2, 0))
hearth.Material = Enum.Material.Ground
hearth.Color = Color3.fromRGB(45, 38, 30)
hearth.Anchored = true
hearth.Parent = campModel

-- Stone Fire Ring
local numStones = 14
local stoneRadius = 4.2
for i = 1, numStones do
    local angle = (i / numStones) * math.pi * 2
    local stone = Instance.new("Part")
    stone.Name = "FireStone"
    stone.Size = Vector3.new(2.1 + math.sin(i*2)*0.3, 1.4 + math.cos(i)*0.2, 1.8 + math.sin(i)*0.2)
    stone.CFrame = CFrame.new(center + Vector3.new(math.cos(angle)*stoneRadius, 0.4, math.sin(angle)*stoneRadius)) 
                 * CFrame.Angles(math.sin(i)*0.1, angle + math.pi/2, math.cos(i)*0.1)
    stone.Material = Enum.Material.Slate
    stone.Color = Color3.fromRGB(75 + (i%3)*5, 75 + (i%2)*5, 80)
    stone.Anchored = true
    stone.Parent = campModel
end

-- Glowing Coals / Embers Bed
local embers = Instance.new("Part")
embers.Name = "FireEmbers"
embers.Size = Vector3.new(4.5, 0.5, 4.5)
embers.CFrame = CFrame.new(center + Vector3.new(0, 0.1, 0))
embers.Material = Enum.Material.Neon
embers.Color = Color3.fromRGB(255, 85, 20)
embers.Anchored = true
embers.Parent = campModel

-- Fire & Light
local fire = Instance.new("Fire")
fire.Size = 7
fire.Heat = 14
fire.Color = Color3.fromRGB(255, 140, 30)
fire.SecondaryColor = Color3.fromRGB(255, 220, 70)
fire.Parent = embers

local fireLight = Instance.new("PointLight")
fireLight.Color = Color3.fromRGB(255, 150, 50)
fireLight.Brightness = 2.8
fireLight.Range = 26
fireLight.Shadows = true
fireLight.Parent = embers

-- Smoke
local smoke = Instance.new("Smoke")
smoke.Color = Color3.fromRGB(180, 180, 180)
smoke.Size = 2
smoke.RiseVelocity = 4
smoke.Opacity = 0.25
smoke.Parent = embers

-- Log teepee stack in fire
for i = 1, 6 do
    local angle = (i / 6) * math.pi * 2
    local log = Instance.new("Part")
    log.Name = "FireWoodLog"
    log.Size = Vector3.new(0.9, 4.2, 0.9)
    log.CFrame = CFrame.new(center + Vector3.new(math.cos(angle)*1.2, 1.4, math.sin(angle)*1.2)) 
               * CFrame.Angles(-0.6, angle, 0)
    log.Material = Enum.Material.Wood
    log.Color = Color3.fromRGB(60, 42, 28)
    log.Anchored = true
    log.Parent = campModel
end

-- Tripod Cooking Stand with Pot
local tripodAngles = { 0, math.pi * 2/3, math.pi * 4/3 }
local tripodRadius = 2.4
local tripodHeight = 5.2
for i, ang in ipairs(tripodAngles) do
    local leg = Instance.new("Part")
    leg.Name = "TripodLeg"
    leg.Size = Vector3.new(0.3, 5.8, 0.3)
    leg.CFrame = CFrame.new(center + Vector3.new(math.cos(ang)*tripodRadius*0.5, tripodHeight*0.5, math.sin(ang)*tripodRadius*0.5))
               * CFrame.Angles(-0.35, ang, 0)
    leg.Material = Enum.Material.Wood
    leg.Color = Color3.fromRGB(80, 55, 35)
    leg.Anchored = true
    leg.Parent = campModel
end

-- Iron pot hanging from tripod apex
local pot = Instance.new("Part")
pot.Name = "CampPot"
pot.Shape = Enum.PartType.Cylinder
pot.Size = Vector3.new(1.8, 1.6, 1.6)
pot.CFrame = CFrame.new(center + Vector3.new(0, 3.2, 0)) * CFrame.Angles(0, 0, math.pi/2)
pot.Material = Enum.Material.Metal
pot.Color = Color3.fromRGB(35, 35, 40)
pot.Anchored = true
pot.Parent = campModel

-- 4 Rustic Wooden Log Benches surrounding the campfire
local benchRadius = 9.5
local benchAngles = {
    -math.pi * 0.75, -- South-West
    -math.pi * 0.25, -- North-West
    math.pi * 0.25,  -- North-East
    math.pi * 0.75   -- South-East
}

for bIdx, bAng in ipairs(benchAngles) do
    local bPos = center + Vector3.new(math.cos(bAng) * benchRadius, 0.2, math.sin(bAng) * benchRadius)
    
    local benchModel = Instance.new("Model")
    benchModel.Name = "CampfireBench" .. bIdx
    benchModel.Parent = campModel
    
    -- Main Seat Plank (Split Log)
    local seatPlank = Instance.new("Part")
    seatPlank.Name = "BenchPlank"
    seatPlank.Size = Vector3.new(7.0, 0.8, 2.0)
    seatPlank.CFrame = CFrame.new(bPos + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, -bAng - math.pi/2, 0)
    seatPlank.Material = Enum.Material.Wood
    seatPlank.Color = Color3.fromRGB(115, 80, 50)
    seatPlank.Anchored = true
    seatPlank.Parent = benchModel
    
    -- 2 Sturdy Log Legs
    local legOffsets = { -2.4, 2.4 }
    for _, legOff in ipairs(legOffsets) do
        local leg = Instance.new("Part")
        leg.Name = "BenchLeg"
        leg.Shape = Enum.PartType.Cylinder
        leg.Size = Vector3.new(1.4, 1.2, 1.2)
        local cf = seatPlank.CFrame * CFrame.new(legOff, -0.6, 0) * CFrame.Angles(0, 0, math.pi/2)
        leg.CFrame = cf
        leg.Material = Enum.Material.Wood
        leg.Color = Color3.fromRGB(75, 50, 30)
        leg.Anchored = true
        leg.Parent = benchModel
    end
    
    -- 2 Functional Seats on each bench!
    local seatOffsets = { -1.6, 1.6 }
    for sIdx, sOff in ipairs(seatOffsets) do
        local seat = Instance.new("Seat")
        seat.Name = "BenchSeat" .. sIdx
        seat.Size = Vector3.new(1.8, 0.4, 1.6)
        local seatPos = (seatPlank.CFrame * CFrame.new(sOff, 0.5, 0)).Position
        seat.CFrame = CFrame.lookAt(seatPos, Vector3.new(center.X, seatPos.Y, center.Z))
        seat.Transparency = 1
        seat.CanCollide = false
        seat.Anchored = true
        seat.Parent = benchModel
    end
    
    -- Side tree stump table for each bench
    local stump = Instance.new("Part")
    stump.Name = "SideStump"
    stump.Shape = Enum.PartType.Cylinder
    stump.Size = Vector3.new(1.6, 1.8, 1.8)
    local stumpCf = seatPlank.CFrame * CFrame.new(4.2, -0.4, 0) * CFrame.Angles(0, 0, math.pi/2)
    stump.CFrame = stumpCf
    stump.Material = Enum.Material.Wood
    stump.Color = Color3.fromRGB(90, 60, 38)
    stump.Anchored = true
    stump.Parent = benchModel
    
    -- Ceramic Mug on stump
    local mug = Instance.new("Part")
    mug.Name = "CoffeeMug"
    mug.Shape = Enum.PartType.Cylinder
    mug.Size = Vector3.new(0.6, 0.5, 0.5)
    mug.CFrame = stumpCf * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.pi/2)
    mug.Material = Enum.Material.SmoothPlastic
    mug.Color = (bIdx % 2 == 0) and Color3.fromRGB(190, 60, 50) or Color3.fromRGB(40, 110, 160)
    mug.Anchored = true
    mug.Parent = benchModel
end

-- Add 2 well-pitched aesthetic camping tents neatly placed behind the benches
local tentConfigs = {
    { pos = center + Vector3.new(-18, 0.3, -12), ang = 0.4, col = Color3.fromRGB(40, 85, 60) }, -- Forest green tent
    { pos = center + Vector3.new(-14, 0.3, 14), ang = -0.6, col = Color3.fromRGB(160, 95, 45) }  -- Amber orange tent
}

for tIdx, tConf in ipairs(tentConfigs) do
    local tentModel = Instance.new("Model")
    tentModel.Name = "AestheticTent" .. tIdx
    tentModel.Parent = campModel
    
    local tBaseCf = CFrame.new(tConf.pos) * CFrame.Angles(0, tConf.ang, 0)
    
    -- Tent Floor
    local tFloor = Instance.new("Part")
    tFloor.Name = "Floor"
    tFloor.Size = Vector3.new(8, 0.3, 10)
    tFloor.CFrame = tBaseCf * CFrame.new(0, 0.15, 0)
    tFloor.Material = Enum.Material.Fabric
    tFloor.Color = Color3.fromRGB(35, 35, 35)
    tFloor.Anchored = true
    tFloor.Parent = tentModel
    
    -- Tent Left Slope (Wedge)
    local wedgeL = Instance.new("WedgePart")
    wedgeL.Name = "SlopeL"
    wedgeL.Size = Vector3.new(10, 5, 4)
    wedgeL.CFrame = tBaseCf * CFrame.new(-2, 2.65, 0) * CFrame.Angles(0, math.pi/2, 0)
    wedgeL.Material = Enum.Material.Fabric
    wedgeL.Color = tConf.col
    wedgeL.Anchored = true
    wedgeL.Parent = tentModel
    
    -- Tent Right Slope (Wedge)
    local wedgeR = Instance.new("WedgePart")
    wedgeR.Name = "SlopeR"
    wedgeR.Size = Vector3.new(10, 5, 4)
    wedgeR.CFrame = tBaseCf * CFrame.new(2, 2.65, 0) * CFrame.Angles(0, -math.pi/2, 0)
    wedgeR.Material = Enum.Material.Fabric
    wedgeR.Color = tConf.col
    wedgeR.Anchored = true
    wedgeR.Parent = tentModel
    
    -- Ridge Pole
    local ridge = Instance.new("Part")
    ridge.Name = "RidgePole"
    ridge.Size = Vector3.new(0.4, 0.4, 10.4)
    ridge.CFrame = tBaseCf * CFrame.new(0, 5.2, 0)
    ridge.Material = Enum.Material.Wood
    ridge.Color = Color3.fromRGB(80, 55, 35)
    ridge.Anchored = true
    ridge.Parent = tentModel
end

return { success = true, benches = #benchAngles, seats = #benchAngles * 2 }
`;

  console.log('Executing build_aesthetic_campfire...');
  const res = await executeLuau(code, 'Server');
  console.log('Result:', res.content[0].text);

  // Capture screenshot from similar angle as Image 1
  console.log('Capturing campfire overview screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/scratch/verify_campfire_benches.png',
    [-24, 322, -1755],
    [-24, 302, -1774]
  );
  console.log('Campfire overview captured!');
}

main().catch(console.error);
