const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

local function getGroundY(x, z)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Include
    p.FilterDescendantsInstances = {terrain}
    local r = workspace:Raycast(Vector3.new(x, 350, z), Vector3.new(0, -100, 0), p)
    return r and r.Position.Y or 300.18
end

-- Remove old AestheticCampfire
local existing = trail:FindFirstChild("AestheticCampfire")
if existing then
    existing:Destroy()
end

local campModel = Instance.new("Model")
campModel.Name = "AestheticCampfire"
campModel.Parent = trail

local cX, cZ = -24.0, -1774.0
local centerGroundY = getGroundY(cX, cZ)
local center = Vector3.new(cX, centerGroundY, cZ)

-- 1. Fire Hearth (Ash Pit Base)
-- Sunk slightly into the ground so there is zero gap regardless of minor slope
local hearth = Instance.new("Part")
hearth.Name = "CampHearth"
hearth.Size = Vector3.new(9.6, 0.8, 9.6)
hearth.CFrame = CFrame.new(center.X, center.Y + 0.1, center.Z)
hearth.Material = Enum.Material.Ground
hearth.Color = Color3.fromRGB(45, 38, 30)
hearth.Anchored = true
hearth.Parent = campModel

-- 2. Glowing Embers Bed
local embers = Instance.new("Part")
embers.Name = "FireEmbers"
embers.Size = Vector3.new(4.6, 0.4, 4.6)
embers.CFrame = CFrame.new(center.X, center.Y + 0.4, center.Z)
embers.Material = Enum.Material.Neon
embers.Color = Color3.fromRGB(255, 85, 20)
embers.Anchored = true
embers.Parent = campModel

-- Warm Campfire Light
local light = Instance.new("PointLight")
light.Name = "CampfireLight"
light.Color = Color3.fromRGB(255, 175, 80)
light.Brightness = 3.2
light.Range = 28
light.Shadows = true
light.Parent = embers

-- Flame and Smoke Particle Emitters
local fireParticles = Instance.new("ParticleEmitter")
fireParticles.Name = "CampfireFlames"
fireParticles.Texture = "rbxassetid://14365285883"
fireParticles.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 120, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 10))
})
fireParticles.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.8),
    NumberSequenceKeypoint.new(0.5, 1.8),
    NumberSequenceKeypoint.new(1, 0.2)
})
fireParticles.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(0.7, 0.3),
    NumberSequenceKeypoint.new(1, 1)
})
fireParticles.Lifetime = NumberRange.new(0.6, 1.1)
fireParticles.Rate = 22
fireParticles.Speed = NumberRange.new(3.5, 5.5)
fireParticles.SpreadAngle = Vector2.new(15, 15)
fireParticles.LightEmission = 0.95
fireParticles.Parent = embers

local smoke = Instance.new("ParticleEmitter")
smoke.Name = "CampfireSmoke"
smoke.Texture = "rbxassetid://14365285883"
smoke.Color = ColorSequence.new(Color3.fromRGB(120, 115, 110))
smoke.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1.2),
    NumberSequenceKeypoint.new(1, 4.5)
})
smoke.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.6),
    NumberSequenceKeypoint.new(0.6, 0.75),
    NumberSequenceKeypoint.new(1, 1)
})
smoke.Lifetime = NumberRange.new(2.5, 4.0)
smoke.Rate = 6
smoke.Speed = NumberRange.new(3.0, 5.0)
smoke.SpreadAngle = Vector2.new(20, 20)
smoke.Parent = embers

-- Crackle Sound
local sound = Instance.new("Sound")
sound.Name = "FireCrackle"
sound.SoundId = "rbxassetid://9114223171"
sound.Volume = 0.65
sound.Looped = true
sound.MaxDistance = 55
sound.RollOffMode = Enum.RollOffMode.Linear
sound.Parent = embers
sound:Play()

-- 3. Stone Fire Ring (14 natural stones, each grounded individually)
local numStones = 14
local stoneRadius = 4.3
for i = 1, numStones do
    local angle = (i / numStones) * math.pi * 2
    local sX = center.X + math.cos(angle) * stoneRadius
    local sZ = center.Z + math.sin(angle) * stoneRadius
    local sGroundY = getGroundY(sX, sZ)
    
    local stoneH = 1.3 + math.cos(i) * 0.2
    local stone = Instance.new("Part")
    stone.Name = "FireStone"
    stone.Size = Vector3.new(2.1 + math.sin(i*2)*0.3, stoneH, 1.8 + math.sin(i)*0.2)
    -- Sunk 0.3 studs into terrain so it sits firmly embedded in the ground
    local stoneY = sGroundY + (stoneH / 2) - 0.25
    stone.CFrame = CFrame.new(sX, stoneY, sZ) * CFrame.Angles(math.sin(i)*0.1, angle + math.pi/2, math.cos(i)*0.1)
    stone.Material = Enum.Material.Slate
    stone.Color = Color3.fromRGB(75 + (i%3)*5, 75 + (i%2)*5, 80)
    stone.Anchored = true
    stone.Parent = campModel
end

-- 4. Campfire Firewood Logs (stacked tepee / pyre)
for i = 1, 6 do
    local ang = (i / 6) * math.pi * 2
    local log = Instance.new("Part")
    log.Name = "FireWoodLog"
    log.Shape = Enum.PartType.Cylinder
    log.Size = Vector3.new(3.6, 0.8, 0.8)
    local logBase = center + Vector3.new(math.cos(ang)*1.8, 0.4, math.sin(ang)*1.8)
    local logTop = center + Vector3.new(math.cos(ang)*0.3, 2.0, math.sin(ang)*0.3)
    log.CFrame = CFrame.lookAt((logBase + logTop)/2, logTop) * CFrame.Angles(0, math.pi/2, 0)
    log.Material = Enum.Material.Wood
    log.Color = Color3.fromRGB(70, 48, 30)
    log.Anchored = true
    log.Parent = campModel
end

-- 5. Cast Iron Cooking Tripod & Hanging Pot
local apex = center + Vector3.new(0, 4.4, 0)
local tripodRadius = 3.3
for i = 1, 3 do
    local tAng = (i / 3) * math.pi * 2 + math.pi/6
    local footX = center.X + math.cos(tAng) * tripodRadius
    local footZ = center.Z + math.sin(tAng) * tripodRadius
    local footGroundY = getGroundY(footX, footZ)
    local foot = Vector3.new(footX, footGroundY - 0.2, footZ)
    
    local legLength = (apex - foot).Magnitude
    local leg = Instance.new("Part")
    leg.Name = "TripodLeg"
    leg.Size = Vector3.new(0.25, 0.25, legLength)
    leg.CFrame = CFrame.lookAt((foot + apex) / 2, apex)
    leg.Material = Enum.Material.Metal
    leg.Color = Color3.fromRGB(30, 30, 32)
    leg.Anchored = true
    leg.Parent = campModel
end

local pot = Instance.new("Part")
pot.Name = "CampPot"
pot.Shape = Enum.PartType.Cylinder
pot.Size = Vector3.new(1.8, 1.6, 1.6)
pot.CFrame = CFrame.new(center.X, center.Y + 2.3, center.Z) * CFrame.Angles(0, 0, math.pi/2)
pot.Material = Enum.Material.Metal
pot.Color = Color3.fromRGB(35, 35, 40)
pot.Anchored = true
pot.Parent = campModel

-- 6. 4 Sturdy Log Benches (Fully grounded with zero floating gap!)
local benchRadius = 9.5
local benchAngles = {
    -math.pi * 0.75, -- South-West
    -math.pi * 0.25, -- North-West
    math.pi * 0.25,  -- North-East
    math.pi * 0.75   -- South-East
}

for bIdx, bAng in ipairs(benchAngles) do
    local bX = center.X + math.cos(bAng) * benchRadius
    local bZ = center.Z + math.sin(bAng) * benchRadius
    local bRot = CFrame.Angles(0, -bAng - math.pi/2, 0)
    
    -- Compute exact world position for Leg 1 and Leg 2
    local leg1Rel = bRot * Vector3.new(-2.4, 0, 0)
    local leg2Rel = bRot * Vector3.new(2.4, 0, 0)
    local leg1X, leg1Z = bX + leg1Rel.X, bZ + leg1Rel.Z
    local leg2X, leg2Z = bX + leg2Rel.X, bZ + leg2Rel.Z
    
    local leg1Ground = getGroundY(leg1X, leg1Z)
    local leg2Ground = getGroundY(leg2X, leg2Z)
    local benchBaseGround = math.max(leg1Ground, leg2Ground)
    
    -- Seat Plank sits 1.5 studs above the base ground
    local plankY = benchBaseGround + 1.5
    local seatPlank = Instance.new("Part")
    seatPlank.Name = "BenchPlank"
    seatPlank.Size = Vector3.new(7.0, 0.8, 2.0)
    seatPlank.CFrame = CFrame.new(bX, plankY, bZ) * bRot
    seatPlank.Material = Enum.Material.Wood
    seatPlank.Color = Color3.fromRGB(115, 80, 50)
    seatPlank.Anchored = true
    seatPlank.Parent = campModel
    
    local benchModel = Instance.new("Model")
    benchModel.Name = "CampfireBench" .. bIdx
    benchModel.Parent = campModel
    seatPlank.Parent = benchModel
    
    -- Ground each leg dynamically from the bottom of the plank down into the dirt!
    local plankBottomY = plankY - 0.4
    local legsInfo = {
        { x = leg1X, z = leg1Z, gY = leg1Ground },
        { x = leg2X, z = leg2Z, gY = leg2Ground }
    }
    
    for lIdx, lInfo in ipairs(legsInfo) do
        local sinkGroundY = lInfo.gY - 0.4 -- penetrates 0.4 studs into terrain
        local legH = math.max(0.8, plankBottomY - sinkGroundY)
        local legCenterY = (plankBottomY + sinkGroundY) / 2
        
        local leg = Instance.new("Part")
        leg.Name = "BenchLeg" .. lIdx
        leg.Shape = Enum.PartType.Cylinder
        -- In Roblox, cylinder length is Size.X, diameter is Size.Y and Size.Z
        leg.Size = Vector3.new(legH, 1.3, 1.3)
        -- Rotate 90 deg so Cylinder length (X) aligns vertically with world Y
        leg.CFrame = CFrame.new(lInfo.x, legCenterY, lInfo.z) * CFrame.Angles(0, 0, math.pi/2)
        leg.Material = Enum.Material.Wood
        leg.Color = Color3.fromRGB(75, 50, 30)
        leg.Anchored = true
        leg.Parent = benchModel
    end
    
    -- 2 Functional Seats on each bench, oriented facing the campfire!
    local seatOffsets = { -1.6, 1.6 }
    for sIdx, sOff in ipairs(seatOffsets) do
        local seat = Instance.new("Seat")
        seat.Name = "BenchSeat" .. sIdx
        seat.Size = Vector3.new(1.8, 0.4, 1.6)
        local seatPos = (seatPlank.CFrame * CFrame.new(sOff, 0.45, 0)).Position
        seat.CFrame = CFrame.lookAt(seatPos, Vector3.new(center.X, seatPos.Y, center.Z))
        seat.Transparency = 1
        seat.CanCollide = false
        seat.Anchored = true
        seat.Parent = benchModel
    end
    
    -- Side stump table, fully grounded into terrain
    local stumpRel = bRot * Vector3.new(4.3, 0, 0)
    local stumpX, stumpZ = bX + stumpRel.X, bZ + stumpRel.Z
    local stumpGround = getGroundY(stumpX, stumpZ)
    local stumpTopY = plankY + 0.2
    local stumpBottomY = stumpGround - 0.4
    local stumpH = math.max(0.8, stumpTopY - stumpBottomY)
    local stumpCenterY = (stumpTopY + stumpBottomY) / 2
    
    local stump = Instance.new("Part")
    stump.Name = "SideStump"
    stump.Shape = Enum.PartType.Cylinder
    stump.Size = Vector3.new(stumpH, 1.8, 1.8)
    stump.CFrame = CFrame.new(stumpX, stumpCenterY, stumpZ) * CFrame.Angles(0, 0, math.pi/2)
    stump.Material = Enum.Material.Wood
    stump.Color = Color3.fromRGB(90, 60, 38)
    stump.Anchored = true
    stump.Parent = benchModel
    
    -- Mug on stump
    local mug = Instance.new("Part")
    mug.Name = "CoffeeMug"
    mug.Shape = Enum.PartType.Cylinder
    mug.Size = Vector3.new(0.6, 0.5, 0.5)
    mug.CFrame = CFrame.new(stumpX, stumpTopY + 0.3, stumpZ) * CFrame.Angles(0, 0, math.pi/2)
    mug.Material = Enum.Material.SmoothPlastic
    mug.Color = (bIdx % 2 == 0) and Color3.fromRGB(190, 60, 50) or Color3.fromRGB(40, 110, 160)
    mug.Anchored = true
    mug.Parent = benchModel
end

-- 7. Camping Tents (firmly planted on flat terrain)
local tentConfigs = {
    { x = center.X - 18, z = center.Z - 12, ang = 0.4, col = Color3.fromRGB(40, 85, 60) }, -- Forest green
    { x = center.X - 10, z = center.Z + 16, ang = -0.5, col = Color3.fromRGB(160, 95, 45) } -- Amber orange
}

for tIdx, tConf in ipairs(tentConfigs) do
    local tGroundY = getGroundY(tConf.x, tConf.z)
    local tentModel = Instance.new("Model")
    tentModel.Name = "AestheticTent" .. tIdx
    tentModel.Parent = campModel
    
    local tBaseCf = CFrame.new(tConf.x, tGroundY, tConf.z) * CFrame.Angles(0, tConf.ang, 0)
    
    -- Tent Ground Tarp / Floor (sits right on the grass)
    local tFloor = Instance.new("Part")
    tFloor.Name = "Floor"
    tFloor.Size = Vector3.new(7.6, 0.3, 9.6)
    tFloor.CFrame = tBaseCf * CFrame.new(0, 0.1, 0)
    tFloor.Material = Enum.Material.Fabric
    tFloor.Color = Color3.fromRGB(35, 35, 35)
    tFloor.Anchored = true
    tFloor.Parent = tentModel
    
    -- Left Slope
    local wedgeL = Instance.new("WedgePart")
    wedgeL.Name = "SlopeL"
    wedgeL.Size = Vector3.new(9.6, 4.6, 3.8)
    wedgeL.CFrame = tBaseCf * CFrame.new(-1.9, 2.45, 0) * CFrame.Angles(0, math.pi/2, 0)
    wedgeL.Material = Enum.Material.Fabric
    wedgeL.Color = tConf.col
    wedgeL.Anchored = true
    wedgeL.Parent = tentModel
    
    -- Right Slope
    local wedgeR = Instance.new("WedgePart")
    wedgeR.Name = "SlopeR"
    wedgeR.Size = Vector3.new(9.6, 4.6, 3.8)
    wedgeR.CFrame = tBaseCf * CFrame.new(1.9, 2.45, 0) * CFrame.Angles(0, -math.pi/2, 0)
    wedgeR.Material = Enum.Material.Fabric
    wedgeR.Color = tConf.col
    wedgeR.Anchored = true
    wedgeR.Parent = tentModel
    
    -- Ridge Pole
    local ridge = Instance.new("Part")
    ridge.Name = "RidgePole"
    ridge.Size = Vector3.new(0.4, 0.4, 10.0)
    ridge.CFrame = tBaseCf * CFrame.new(0, 4.8, 0)
    ridge.Material = Enum.Material.Wood
    ridge.Color = Color3.fromRGB(80, 55, 35)
    ridge.Anchored = true
    ridge.Parent = tentModel
end

return "Aesthetic campfire and campsite elements grounded successfully!"
`;

  console.log('Grounding campfire campsite elements...');
  const res = await executeLuau(code, 'Server');
  console.log('Result:', JSON.stringify(res, null, 2));

  // 1. Capture low-angle perspective matching Image 2 to verify legs and campfire ground contact
  console.log('Capturing low-angle ground contact view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/scratch/campfire_grounded_low_angle.png',
    [-34, 301.2, -1777],
    [-24, 301.0, -1774]
  );

  // 2. Capture top-down overview matching Image 1
  console.log('Capturing overview...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/scratch/campfire_grounded_overview.png',
    [-24, 318, -1760],
    [-24, 300.5, -1774]
  );
  console.log('Done!');
}

main().catch(console.error);
