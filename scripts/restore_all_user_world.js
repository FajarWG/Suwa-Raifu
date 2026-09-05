const { executeLuau, captureScreen } = require('./mcp-exec.js');
const { execSync } = require('child_process');

async function main() {
  console.log('=== RESTORING AND FIXING ALL WORLD ELEMENTS IN EDIT DATAMODEL ===');

  // =========================================================================
  // 1. BROKEN BRIDGE ROPE LADDER (Photo 1)
  // =========================================================================
  console.log('\n[1/4] Building Broken Bridge Rope Ladder...');
  const codeBrokenBridge = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local bp = nil
local ts = nil

for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "BrokenPlank" and (c.Position - Vector3.new(-127.2, 313.2, -1860.7)).Magnitude < 1 then
        bp = c
    end
    if c.Name == "TrailStep" and (c.Position - Vector3.new(-130.8, 322.4, -1863.8)).Magnitude < 1 then
        ts = c
    end
end

if not bp or not ts then
    return { error = "Could not find BrokenPlank or TrailStep" }
end

local oldModel = trail:FindFirstChild("BrokenBridgeRopeLadder")
if oldModel then oldModel:Destroy() end

local model = Instance.new("Model")
model.Name = "BrokenBridgeRopeLadder"
model.Parent = trail

local topFaceCf = ts.CFrame * CFrame.new(0, ts.Size.Y/2, -ts.Size.Z/2)
local topAnchor = topFaceCf * CFrame.new(0, 0, 0.4)
local botAnchor = bp.CFrame * CFrame.new(0, bp.Size.Y/2, -0.4)

local pTop = topAnchor.Position
local pBot = botAnchor.Position
local ladderVec = pTop - pBot
local ladderDist = ladderVec.Magnitude
local ladderWidth = 4.0
local halfW = ladderWidth / 2

local ropeColor = Color3.fromRGB(165, 135, 95)
local woodColor = Color3.fromRGB(110, 78, 50)
local ironColor = Color3.fromRGB(45, 45, 50)

-- Top Anchor Posts & Handrails
for _, sideX in ipairs({-halfW - 0.4, halfW + 0.4}) do
    local post = Instance.new("Part")
    post.Name = "TopAnchorPost"
    post.Size = Vector3.new(0.6, 3.8, 0.6)
    post.CFrame = topFaceCf * CFrame.new(sideX, 1.9, 0.9)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(75, 50, 32)
    post.Anchored = true
    post.Parent = model

    local ring = Instance.new("Part")
    ring.Name = "IronAnchorRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.3, 0.8, 0.8)
    ring.CFrame = post.CFrame * CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, math.pi/2, 0)
    ring.Material = Enum.Material.Metal
    ring.Color = ironColor
    ring.Anchored = true
    ring.Parent = model
end

-- Bottom Rope Cleats
for _, sideX in ipairs({-halfW, halfW}) do
    local cleat = Instance.new("Part")
    cleat.Name = "BottomCleat"
    cleat.Size = Vector3.new(0.6, 0.4, 0.8)
    cleat.CFrame = botAnchor * CFrame.new(sideX, 0.2, -0.3)
    cleat.Material = Enum.Material.Wood
    cleat.Color = Color3.fromRGB(65, 42, 28)
    cleat.Anchored = true
    cleat.Parent = model
end

-- Side Suspension Ropes
for _, sideX in ipairs({-halfW, halfW}) do
    local pSideBot = (botAnchor * CFrame.new(sideX, 0.2, 0)).Position
    local pSideTop = (topAnchor * CFrame.new(sideX, 0, 0)).Position
    local ropeVec = pSideTop - pSideBot
    local ropeDist = ropeVec.Magnitude
    local ropeCf = CFrame.lookAt((pSideTop + pSideBot)/2, pSideTop)

    local sideRope = Instance.new("Part")
    sideRope.Name = "LadderRopeSide"
    sideRope.Shape = Enum.PartType.Cylinder
    sideRope.Size = Vector3.new(ropeDist, 0.32, 0.32)
    sideRope.CFrame = ropeCf * CFrame.Angles(0, math.pi/2, 0)
    sideRope.Material = Enum.Material.Fabric
    sideRope.Color = ropeColor
    sideRope.Anchored = true
    sideRope.Parent = model
end

-- Rungs
local numRungs = 9
for i = 1, numRungs do
    local alpha = i / (numRungs + 1)
    local rungCenter = pBot:Lerp(pTop, alpha)
    local catenarySag = math.sin(alpha * math.pi) * 0.35
    rungCenter = rungCenter - Vector3.new(0, catenarySag, 0)

    local lookDir = (pTop - pBot).Unit
    local rungCf = CFrame.lookAt(rungCenter, rungCenter + lookDir)

    local rung = Instance.new("Part")
    rung.Name = "LadderRung" .. i
    rung.Size = Vector3.new(ladderWidth + 0.4, 0.45, 0.8)
    rung.CFrame = rungCf * CFrame.Angles(0, 0, 0)
    rung.Material = Enum.Material.WoodPlanks
    rung.Color = woodColor
    rung.Anchored = true
    rung.Parent = model

    -- Knots
    for _, kX in ipairs({-halfW, halfW}) do
        local knot = Instance.new("Part")
        knot.Name = "RopeKnot"
        knot.Shape = Enum.PartType.Ball
        knot.Size = Vector3.new(0.55, 0.55, 0.55)
        knot.CFrame = rung.CFrame * CFrame.new(kX, 0, 0)
        knot.Material = Enum.Material.Fabric
        knot.Color = ropeColor
        knot.Anchored = true
        knot.Parent = model
    end
end

-- Climbable TrussPart in center
local centerTruss = Instance.new("TrussPart")
centerTruss.Name = "RopeLadderClimbTruss"
centerTruss.Size = Vector3.new(2, math.ceil(ladderDist), 2)
centerTruss.CFrame = CFrame.lookAt((pTop + pBot)/2, pTop) * CFrame.Angles(math.pi/2, 0, 0)
centerTruss.Transparency = 1
centerTruss.CanCollide = false
centerTruss.Anchored = true
centerTruss.Parent = model

-- Signpost with lantern
local signPost = Instance.new("Part")
signPost.Name = "RopeLadderSignPost"
signPost.Size = Vector3.new(0.6, 5.0, 0.6)
signPost.CFrame = topFaceCf * CFrame.new(halfW + 1.6, 2.5, 1.2)
signPost.Material = Enum.Material.Wood
signPost.Color = Color3.fromRGB(60, 40, 25)
signPost.Anchored = true
signPost.Parent = model

local signBoard = Instance.new("Part")
signBoard.Name = "RopeLadderSignBoard"
signBoard.Size = Vector3.new(2.8, 1.4, 0.2)
signBoard.CFrame = signPost.CFrame * CFrame.new(0, 1.2, -0.4)
signBoard.Material = Enum.Material.Wood
signBoard.Color = Color3.fromRGB(50, 35, 22)
signBoard.Anchored = true
signBoard.Parent = model

local ltn = Instance.new("Part")
ltn.Name = "RopeLadderLantern"
ltn.Size = Vector3.new(0.8, 1.0, 0.8)
ltn.CFrame = signPost.CFrame * CFrame.new(0, 2.5, 0)
ltn.Material = Enum.Material.Neon
ltn.Color = Color3.fromRGB(255, 215, 140)
ltn.Anchored = true
ltn.Parent = model

local lgt = Instance.new("PointLight")
lgt.Color = Color3.fromRGB(255, 185, 100)
lgt.Brightness = 2.5
lgt.Range = 16
lgt.Parent = ltn

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = signBoard

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "🧗 縄梯子\\nROPE LADDER"
txt.TextColor3 = Color3.fromRGB(245, 225, 185)
txt.TextSize = 15
txt.Font = Enum.Font.GothamBold
txt.Parent = sg

return "Broken Bridge Rope Ladder built successfully!"
`;
  const res1 = await executeLuau(codeBrokenBridge, 'Edit');
  console.log('Broken Bridge:', res1.content[0].text);

  // =========================================================================
  // 2. WALKWAY ROPE LADDER (Photo 2)
  // =========================================================================
  console.log('\n[2/4] Building Walkway Rope Ladder...');
  const codeWalkway = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local ts = nil
local bp = nil

for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" and (c.Position - Vector3.new(-87.25, 302.0, -1826.25)).Magnitude < 1.5 then
        ts = c
    elseif c.Name == "BrokenPlank" and (c.Position - Vector3.new(-90.82, 313.21, -1829.33)).Magnitude < 1.5 then
        bp = c
    end
end

if not ts or not bp then
    return { error = "Could not find Walkway ts or bp" }
end

local old = trail:FindFirstChild("WalkwayRopeLadder")
if old then old:Destroy() end

local model = Instance.new("Model")
model.Name = "WalkwayRopeLadder"
model.Parent = trail

local approachDir = (Vector3.new(bp.Position.X, 0, bp.Position.Z) - Vector3.new(ts.Position.X, 0, ts.Position.Z)).Unit
local ladderNormal = approachDir
local ladderRight = Vector3.new(-ladderNormal.Z, 0, ladderNormal.X)

local topPlankY = bp.Position.Y + bp.Size.Y / 2
local pTop = Vector3.new(bp.Position.X, topPlankY, bp.Position.Z) - ladderNormal * (bp.Size.Z / 2 + 0.2)

local botLandingY = ts.Position.Y + ts.Size.Y / 2
local pBot = Vector3.new(pTop.X, botLandingY, pTop.Z) + ladderNormal * 0.4

local ladderVec = pTop - pBot
local ladderDist = ladderVec.Magnitude
local ladderWidth = 4.0
local halfW = ladderWidth / 2

local ropeColor = Color3.fromRGB(165, 135, 95)
local woodColor = Color3.fromRGB(105, 75, 48)
local ironColor = Color3.fromRGB(45, 45, 50)

-- Top Anchor Cleats on Walkway Planks
for _, sDir in ipairs({-1, 1}) do
    local cleatPos = pTop + ladderRight * (sDir * halfW) + ladderNormal * 0.5
    local cleat = Instance.new("Part")
    cleat.Name = "TopWalkwayCleat"
    cleat.Size = Vector3.new(0.6, 0.4, 0.9)
    cleat.CFrame = CFrame.lookAt(cleatPos, cleatPos + ladderNormal)
    cleat.Material = Enum.Material.Wood
    cleat.Color = Color3.fromRGB(65, 42, 28)
    cleat.Anchored = true
    cleat.Parent = model

    local ring = Instance.new("Part")
    ring.Name = "IronCleatRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.3, 0.7, 0.7)
    ring.CFrame = cleat.CFrame * CFrame.new(0, 0.25, -0.3) * CFrame.Angles(0, math.pi/2, 0)
    ring.Material = Enum.Material.Metal
    ring.Color = ironColor
    ring.Anchored = true
    ring.Parent = model
end

-- Bottom Trail Posts
for _, sDir in ipairs({-1, 1}) do
    local postPos = pBot + ladderRight * (sDir * (halfW + 0.4)) - ladderNormal * 0.3
    local post = Instance.new("Part")
    post.Name = "BotTrailAnchorPost"
    post.Size = Vector3.new(0.7, 3.2, 0.7)
    post.CFrame = CFrame.new(postPos.X, postPos.Y + 1.4, postPos.Z)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(75, 50, 32)
    post.Anchored = true
    post.Parent = model
end

-- Side Ropes
for _, sDir in ipairs({-1, 1}) do
    local topRopePos = pTop + ladderRight * (sDir * halfW)
    local botRopePos = pBot + ladderRight * (sDir * halfW)
    local ropeVec = topRopePos - botRopePos
    local ropeMid = (topRopePos + botRopePos) / 2
    local ropeCf = CFrame.lookAt(ropeMid, topRopePos)

    local rope = Instance.new("Part")
    rope.Name = "LadderSideRope"
    rope.Shape = Enum.PartType.Cylinder
    rope.Size = Vector3.new(ropeVec.Magnitude, 0.32, 0.32)
    rope.CFrame = ropeCf * CFrame.Angles(0, math.pi/2, 0)
    rope.Material = Enum.Material.Fabric
    rope.Color = ropeColor
    rope.Anchored = true
    rope.Parent = model
end

-- Rungs
local numRungs = 8
for i = 1, numRungs do
    local alpha = i / (numRungs + 1)
    local rungPos = pBot:Lerp(pTop, alpha)
    local rungCf = CFrame.lookAt(rungPos, rungPos + ladderNormal)

    local rung = Instance.new("Part")
    rung.Name = "WalkwayLadderRung" .. i
    rung.Size = Vector3.new(ladderWidth + 0.5, 0.42, 0.8)
    rung.CFrame = rungCf
    rung.Material = Enum.Material.WoodPlanks
    rung.Color = woodColor
    rung.Anchored = true
    rung.Parent = model

    for _, sDir in ipairs({-1, 1}) do
        local knot = Instance.new("Part")
        knot.Name = "RungKnot"
        knot.Shape = Enum.PartType.Ball
        knot.Size = Vector3.new(0.55, 0.55, 0.55)
        knot.CFrame = rungCf * CFrame.new(sDir * halfW, 0, 0)
        knot.Material = Enum.Material.Fabric
        knot.Color = ropeColor
        knot.Anchored = true
        knot.Parent = model
    end
end

-- Central Climb Truss
local climbTruss = Instance.new("TrussPart")
climbTruss.Name = "WalkwayLadderClimbTruss"
climbTruss.Size = Vector3.new(2, math.ceil(ladderDist), 2)
climbTruss.CFrame = CFrame.lookAt((pTop + pBot) / 2, pTop) * CFrame.Angles(math.pi/2, 0, 0)
climbTruss.Transparency = 1
climbTruss.CanCollide = false
climbTruss.Anchored = true
climbTruss.Parent = model

-- Trail Sign
local signBoard = Instance.new("Part")
signBoard.Name = "WalkwayLadderSign"
signBoard.Size = Vector3.new(2.4, 1.2, 0.2)
signBoard.CFrame = CFrame.new(pBot.X + ladderRight.X * (halfW + 1.2), pBot.Y + 2.0, pBot.Z + ladderRight.Z * (halfW + 1.2))
signBoard.Material = Enum.Material.Wood
signBoard.Color = Color3.fromRGB(55, 38, 25)
signBoard.Anchored = true
signBoard.Parent = model

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = signBoard

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "🧗 縄梯子\\nROPE LADDER"
txt.TextColor3 = Color3.fromRGB(245, 225, 185)
txt.TextSize = 14
txt.Font = Enum.Font.SourceSansBold
txt.Parent = sg

return "Walkway Rope Ladder built successfully!"
`;
  const res2 = await executeLuau(codeWalkway, 'Edit');
  console.log('Walkway Rope Ladder:', res2.content[0].text);

  // =========================================================================
  // 3. CAMPFIRE & 2-SEATER GROUNDED BENCHES (Photo 3)
  // =========================================================================
  console.log('\n[3/4] Building Aesthetic Campfire with Grounded 2-Seater Benches Facing Fire...');
  const codeCampfire = `
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
if existing then existing:Destroy() end

local campModel = Instance.new("Model")
campModel.Name = "AestheticCampfire"
campModel.Parent = trail

local cX, cZ = -24.0, -1774.0
local centerGroundY = getGroundY(cX, cZ)
local center = Vector3.new(cX, centerGroundY, cZ)

-- 1. Fire Hearth (Ash Pit Base)
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

local light = Instance.new("PointLight")
light.Name = "CampfireLight"
light.Color = Color3.fromRGB(255, 175, 80)
light.Brightness = 3.2
light.Range = 28
light.Shadows = true
light.Parent = embers

-- Flame & Smoke
local flame = Instance.new("ParticleEmitter")
flame.Name = "Flames"
flame.Texture = "rbxassetid://58542624"
flame.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 0))
})
flame.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1.4),
    NumberSequenceKeypoint.new(0.6, 2.2),
    NumberSequenceKeypoint.new(1, 0.2)
})
flame.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(0.7, 0.3),
    NumberSequenceKeypoint.new(1, 1.0)
})
flame.Lifetime = NumberRange.new(0.6, 1.1)
flame.Rate = 42
flame.Speed = NumberRange.new(3.5, 6.0)
flame.SpreadAngle = Vector2.new(18, 18)
flame.EmissionDirection = Enum.NormalId.Top
flame.LightEmission = 0.95
flame.Parent = embers

local smoke = Instance.new("ParticleEmitter")
smoke.Name = "CampSmoke"
smoke.Texture = "rbxassetid://58542624"
smoke.Color = ColorSequence.new(Color3.fromRGB(75, 75, 75), Color3.fromRGB(150, 150, 150))
smoke.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.8),
    NumberSequenceKeypoint.new(0.5, 3.5),
    NumberSequenceKeypoint.new(1, 6.5)
})
smoke.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.7),
    NumberSequenceKeypoint.new(0.4, 0.45),
    NumberSequenceKeypoint.new(1, 1.0)
})
smoke.Lifetime = NumberRange.new(3.0, 5.0)
smoke.Rate = 14
smoke.Speed = NumberRange.new(2.5, 4.5)
smoke.SpreadAngle = Vector2.new(14, 14)
smoke.EmissionDirection = Enum.NormalId.Top
smoke.Parent = embers

-- Firewood Logs in Teepee formation
local logAngles = {0, 45, 90, 135, 180, 225, 270, 315}
for _, ang in ipairs(logAngles) do
    local rad = math.rad(ang)
    local log = Instance.new("Part")
    log.Name = "FireWoodLog"
    log.Size = Vector3.new(0.7, 3.6, 0.7)
    local logPos = center + Vector3.new(math.cos(rad) * 1.2, 1.1, math.sin(rad) * 1.2)
    log.CFrame = CFrame.lookAt(logPos, center + Vector3.new(0, 2.2, 0)) * CFrame.Angles(math.pi/2, 0, 0)
    log.Material = Enum.Material.Wood
    log.Color = Color3.fromRGB(65, 42, 25)
    log.Anchored = true
    log.Parent = campModel
end

-- Fire ring stones
local numStones = 12
for i = 1, numStones do
    local ang = (i / numStones) * math.pi * 2
    local sX = cX + math.cos(ang) * 4.2
    local sZ = cZ + math.sin(ang) * 4.2
    local sY = getGroundY(sX, sZ)
    local stone = Instance.new("Part")
    stone.Name = "FireStone"
    stone.Size = Vector3.new(1.8, 1.1, 1.5)
    stone.CFrame = CFrame.new(sX, sY + 0.35, sZ) * CFrame.Angles(0, ang, 0)
    stone.Material = Enum.Material.Slate
    stone.Color = ((i % 2 == 0) and Color3.fromRGB(115, 110, 105) or Color3.fromRGB(90, 85, 80))
    stone.Anchored = true
    stone.Parent = campModel
end

-- Iron Tripod & Cooking Pot
local tripodRadius = 2.4
local tripodHeight = 5.2
local apexPos = center + Vector3.new(0, tripodHeight, 0)
for legIdx = 1, 3 do
    local ang = (legIdx / 3) * math.pi * 2
    local basePos = center + Vector3.new(math.cos(ang) * tripodRadius, 0.2, math.sin(ang) * tripodRadius)
    local legVec = apexPos - basePos
    local tLeg = Instance.new("Part")
    tLeg.Name = "TripodLeg"
    tLeg.Shape = Enum.PartType.Cylinder
    tLeg.Size = Vector3.new(legVec.Magnitude, 0.16, 0.16)
    tLeg.CFrame = CFrame.lookAt((basePos + apexPos)/2, apexPos) * CFrame.Angles(0, math.pi/2, 0)
    tLeg.Material = Enum.Material.Metal
    tLeg.Color = Color3.fromRGB(35, 35, 35)
    tLeg.Anchored = true
    tLeg.Parent = campModel
end

local pot = Instance.new("Part")
pot.Name = "CampPot"
pot.Shape = Enum.PartType.Cylinder
pot.Size = Vector3.new(1.4, 1.6, 1.6)
pot.CFrame = CFrame.new(center.X, center.Y + 3.2, center.Z) * CFrame.Angles(0, 0, math.pi/2)
pot.Material = Enum.Material.Metal
pot.Color = Color3.fromRGB(30, 30, 30)
pot.Anchored = true
pot.Parent = campModel

-- 4. Four Grounded Log Benches with 2 Seats each, facing the fire
-- Benches placed at 4 angles around fire (radius = 9.0 studs)
local benchAngles = {
    { name = "CampfireBench1", ang = 0 },             -- East
    { name = "CampfireBench2", ang = math.pi * 0.5 },  -- South
    { name = "CampfireBench3", ang = math.pi },        -- West
    { name = "CampfireBench4", ang = math.pi * 1.5 },  -- North
}

for _, bCfg in ipairs(benchAngles) do
    local bModel = Instance.new("Model")
    bModel.Name = bCfg.name
    bModel.Parent = campModel

    local rad = 9.0
    local bX = cX + math.cos(bCfg.ang) * rad
    local bZ = cZ + math.sin(bCfg.ang) * rad
    local bGroundY = getGroundY(bX, bZ)

    -- Vector towards the fire center
    local toFire = (Vector3.new(cX, bGroundY, cZ) - Vector3.new(bX, bGroundY, bZ)).Unit
    -- Tangent along bench length
    local alongBench = Vector3.new(-toFire.Z, 0, toFire.X).Unit

    -- Main Bench Plank (Length 7.5, Width 1.8, Thickness 0.6)
    -- Plank sits comfortably at bGroundY + 1.2
    local plankY = bGroundY + 1.2
    local plankPos = Vector3.new(bX, plankY, bZ)

    local plank = Instance.new("Part")
    plank.Name = "BenchPlank"
    plank.Size = Vector3.new(1.8, 0.6, 7.5)
    -- LookVector faces along bench or towards fire; let us orient with LookVector = alongBench, UpVector = (0,1,0)
    plank.CFrame = CFrame.lookAt(plankPos, plankPos + alongBench)
    plank.Material = Enum.Material.Wood
    plank.Color = Color3.fromRGB(115, 78, 48)
    plank.Anchored = true
    plank.Parent = bModel

    -- Two heavy log legs firmly grounded (sinking deep into the terrain so ZERO floating)
    for _, lSign in ipairs({-2.4, 2.4}) do
        local legX = bX + alongBench.X * lSign
        local legZ = bZ + alongBench.Z * lSign
        local legGroundY = getGroundY(legX, legZ)
        -- Make leg 2.4 studs tall, top at plankY, sinking at least 0.9 studs below ground
        local legCenterY = (plankY - 0.3 + (legGroundY - 0.9)) / 2
        local legHeight = (plankY - 0.3) - (legGroundY - 0.9)

        local leg = Instance.new("Part")
        leg.Name = "BenchLeg"
        leg.Size = Vector3.new(1.6, legHeight, 1.4)
        leg.CFrame = CFrame.new(legX, legCenterY, legZ) * CFrame.lookAt(Vector3.zero, alongBench)
        leg.Material = Enum.Material.Wood
        leg.Color = Color3.fromRGB(75, 48, 28)
        leg.Anchored = true
        leg.Parent = bModel
    end

    -- TWO SEATS PER BENCH (1 tempat duduk bisa ber-2!)
    -- Offset -1.8 and +1.8 along the bench length
    for seatIdx, sOff in ipairs({-1.8, 1.8}) do
        local sX = bX + alongBench.X * sOff
        local sZ = bZ + alongBench.Z * sOff
        local sPos = Vector3.new(sX, plankY + 0.35, sZ)

        local seat = Instance.new("Seat")
        seat.Name = "BenchSeat" .. seatIdx
        seat.Size = Vector3.new(1.6, 0.2, 1.6)
        -- CRITICAL: seat LookVector points DIRECTLY TOWARDS THE CAMPFIRE CENTER!
        seat.CFrame = CFrame.lookAt(sPos, Vector3.new(cX, sPos.Y, cZ))
        seat.Transparency = 1
        seat.CanCollide = false
        seat.Anchored = true
        seat.Parent = bModel
    end

    -- Decorative coffee mug on a side stump near the bench
    local stumpX = bX + alongBench.X * 4.4 + toFire.X * 0.4
    local stumpZ = bZ + alongBench.Z * 4.4 + toFire.Z * 0.4
    local stumpGroundY = getGroundY(stumpX, stumpZ)
    local stump = Instance.new("Part")
    stump.Name = "SideStump"
    stump.Shape = Enum.PartType.Cylinder
    stump.Size = Vector3.new(1.2, 1.6, 1.6)
    stump.CFrame = CFrame.new(stumpX, stumpGroundY + 0.6, stumpZ) * CFrame.Angles(0, 0, math.pi/2)
    stump.Material = Enum.Material.Wood
    stump.Color = Color3.fromRGB(80, 52, 32)
    stump.Anchored = true
    stump.Parent = bModel

    local mug = Instance.new("Part")
    mug.Name = "CoffeeMug"
    mug.Shape = Enum.PartType.Cylinder
    mug.Size = Vector3.new(0.5, 0.4, 0.4)
    mug.CFrame = CFrame.new(stumpX, stumpGroundY + 1.45, stumpZ) * CFrame.Angles(0, 0, math.pi/2)
    mug.Material = Enum.Material.SmoothPlastic
    mug.Color = (bCfg.ang == 0 and Color3.fromRGB(200, 60, 50) or Color3.fromRGB(40, 100, 160))
    mug.Anchored = true
    mug.Parent = bModel
end

return "Campfire with grounded 2-seater benches facing fire built successfully!"
`;
  const res3 = await executeLuau(codeCampfire, 'Edit');
  console.log('Campfire:', res3.content[0].text);

  // =========================================================================
  // 4. CABIN INTERIOR: STOOLS FACING TABLE + BUNK BEDS SLEEP SCRIPT (Photo 4)
  // =========================================================================
  console.log('\n[4/4] Building Mountain Cabin Interior (Stools facing table & Bunk Bed Sleeping)...');
  const codeCabin = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

local oldHutInterior = trail:FindFirstChild("HutInteriorFurnishings")
if oldHutInterior then oldHutInterior:Destroy() end

local interior = Instance.new("Model")
interior.Name = "HutInteriorFurnishings"
interior.Parent = trail

local floorY = 299.4
local hutCenter = Vector3.new(-96.0, floorY, -1804.0)

-- 1. Tatami Wood Planks Floor
local matFloor = Instance.new("Part")
matFloor.Name = "InteriorTatamiFloor"
matFloor.Size = Vector3.new(24.5, 0.2, 16.5)
matFloor.CFrame = CFrame.new(-96.0, floorY + 0.1, -1804.0)
matFloor.Material = Enum.Material.WoodPlanks
matFloor.Color = Color3.fromRGB(155, 128, 85)
matFloor.Anchored = true
matFloor.Parent = interior

-- 2. Warm Hanging Lanterns
for lIdx, lPos in ipairs({ Vector3.new(-102.0, floorY + 8.5, -1804.0), Vector3.new(-90.0, floorY + 8.5, -1804.0) }) do
    local chain = Instance.new("Part")
    chain.Name = "LanternChain" .. lIdx
    chain.Size = Vector3.new(0.1, 2.5, 0.1)
    chain.CFrame = CFrame.new(lPos + Vector3.new(0, 1.25, 0))
    chain.Material = Enum.Material.Metal
    chain.Color = Color3.fromRGB(40, 40, 40)
    chain.Anchored = true
    chain.Parent = interior

    local lantern = Instance.new("Part")
    lantern.Name = "HangingLantern" .. lIdx
    lantern.Size = Vector3.new(1.4, 1.8, 1.4)
    lantern.CFrame = CFrame.new(lPos)
    lantern.Material = Enum.Material.Neon
    lantern.Color = Color3.fromRGB(255, 215, 140)
    lantern.Anchored = true
    lantern.Parent = interior

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 195, 120)
    light.Brightness = 2.4
    light.Range = 24
    light.Shadows = true
    light.Parent = lantern
end

-- 3. Bunk Beds (NO SEAT OBJECTS! Pure visual frame with Sleeping interactive triggers)
local bunkConfigs = {
    { name = "BunkBed1", pos = Vector3.new(-104.5, floorY, -1808.5), blanketColor = Color3.fromRGB(35, 75, 55) },
    { name = "BunkBed2", pos = Vector3.new(-104.5, floorY, -1801.5), blanketColor = Color3.fromRGB(45, 60, 95) }
}

for _, bCfg in ipairs(bunkConfigs) do
    local bunkModel = Instance.new("Model")
    bunkModel.Name = bCfg.name
    bunkModel.Parent = interior

    local bPos = bCfg.pos
    local postOffsets = {
        Vector3.new(-3.4, 4.2, -2.4),
        Vector3.new(-3.4, 4.2, 2.4),
        Vector3.new(3.4, 4.2, -2.4),
        Vector3.new(3.4, 4.2, 2.4)
    }
    for _, pOff in ipairs(postOffsets) do
        local post = Instance.new("Part")
        post.Name = "BunkPost"
        post.Size = Vector3.new(0.5, 8.4, 0.5)
        post.CFrame = CFrame.new(bPos + pOff)
        post.Material = Enum.Material.Wood
        post.Color = Color3.fromRGB(80, 50, 30)
        post.Anchored = true
        post.Parent = bunkModel
    end

    -- Lower Bunk Frame & Mattress
    local lFrame = Instance.new("Part")
    lFrame.Name = "LowerBunkFrame"
    lFrame.Size = Vector3.new(7.2, 0.4, 5.2)
    lFrame.CFrame = CFrame.new(bPos + Vector3.new(0, 1.4, 0))
    lFrame.Material = Enum.Material.Wood
    lFrame.Color = Color3.fromRGB(90, 60, 35)
    lFrame.Anchored = true
    lFrame.Parent = bunkModel

    local lMattress = Instance.new("Part")
    lMattress.Name = "LowerMattress"
    lMattress.Size = Vector3.new(6.6, 0.5, 4.6)
    lMattress.CFrame = CFrame.new(bPos + Vector3.new(0, 1.6, 0))
    lMattress.Material = Enum.Material.Fabric
    lMattress.Color = Color3.fromRGB(235, 230, 218)
    lMattress.Anchored = true
    lMattress.Parent = bunkModel

    local lPillow = Instance.new("Part")
    lPillow.Name = "LowerPillow"
    lPillow.Size = Vector3.new(1.6, 0.4, 3.4)
    lPillow.CFrame = CFrame.new(bPos + Vector3.new(-2.3, 1.8, 0))
    lPillow.Material = Enum.Material.Fabric
    lPillow.Color = Color3.fromRGB(245, 245, 240)
    lPillow.Anchored = true
    lPillow.Parent = bunkModel

    local lBlanket = Instance.new("Part")
    lBlanket.Name = "LowerBlanket"
    lBlanket.Size = Vector3.new(4.2, 0.55, 4.7)
    lBlanket.CFrame = CFrame.new(bPos + Vector3.new(1.0, 1.65, 0))
    lBlanket.Material = Enum.Material.Fabric
    lBlanket.Color = bCfg.blanketColor
    lBlanket.Anchored = true
    lBlanket.Parent = bunkModel

    -- Upper Bunk Frame & Mattress
    local uFrame = Instance.new("Part")
    uFrame.Name = "UpperBunkFrame"
    uFrame.Size = Vector3.new(7.2, 0.4, 5.2)
    uFrame.CFrame = CFrame.new(bPos + Vector3.new(0, 5.0, 0))
    uFrame.Material = Enum.Material.Wood
    uFrame.Color = Color3.fromRGB(90, 60, 35)
    uFrame.Anchored = true
    uFrame.Parent = bunkModel

    local uMattress = Instance.new("Part")
    uMattress.Name = "UpperMattress"
    uMattress.Size = Vector3.new(6.6, 0.5, 4.6)
    uMattress.CFrame = CFrame.new(bPos + Vector3.new(0, 5.2, 0))
    uMattress.Material = Enum.Material.Fabric
    uMattress.Color = Color3.fromRGB(235, 230, 218)
    uMattress.Anchored = true
    uMattress.Parent = bunkModel

    local uPillow = Instance.new("Part")
    uPillow.Name = "UpperPillow"
    uPillow.Size = Vector3.new(1.6, 0.4, 3.4)
    uPillow.CFrame = CFrame.new(bPos + Vector3.new(-2.3, 5.4, 0))
    uPillow.Material = Enum.Material.Fabric
    uPillow.Color = Color3.fromRGB(245, 245, 240)
    uPillow.Anchored = true
    uPillow.Parent = bunkModel

    local uBlanket = Instance.new("Part")
    uBlanket.Name = "UpperBlanket"
    uBlanket.Size = Vector3.new(4.2, 0.55, 4.7)
    uBlanket.CFrame = CFrame.new(bPos + Vector3.new(1.0, 5.25, 0))
    uBlanket.Material = Enum.Material.Fabric
    uBlanket.Color = bCfg.blanketColor
    uBlanket.Anchored = true
    uBlanket.Parent = bunkModel

    -- Wooden ladder rungs on the side
    for rungIdx = 1, 5 do
        local rung = Instance.new("Part")
        rung.Name = "BunkLadderRung"
        rung.Size = Vector3.new(0.3, 0.3, 2.2)
        rung.CFrame = CFrame.new(bPos + Vector3.new(3.4, 0.8 + rungIdx * 0.8, 0))
        rung.Material = Enum.Material.Wood
        rung.Color = Color3.fromRGB(110, 75, 45)
        rung.Anchored = true
        rung.Parent = bunkModel
    end
end

-- 4. Interactive BedSpots for Sleeping (All 4 Bunks)
local bedSpotsFolder = Instance.new("Folder")
bedSpotsFolder.Name = "BedSpots"
bedSpotsFolder.Parent = interior

local bedConfigs = {
    { name = "Bunk1_Lower", bedPos = Vector3.new(-104.8, 301.65, -1808.5), standPos = Vector3.new(-100.5, 301.4, -1808.5) },
    { name = "Bunk1_Upper", bedPos = Vector3.new(-104.8, 305.25, -1808.5), standPos = Vector3.new(-100.5, 301.4, -1808.5) },
    { name = "Bunk2_Lower", bedPos = Vector3.new(-104.8, 301.65, -1801.5), standPos = Vector3.new(-100.5, 301.4, -1801.5) },
    { name = "Bunk2_Upper", bedPos = Vector3.new(-104.8, 305.25, -1801.5), standPos = Vector3.new(-100.5, 301.4, -1801.5) },
}

for _, cfg in ipairs(bedConfigs) do
    local spot = Instance.new("Part")
    spot.Name = cfg.name
    spot.Size = Vector3.new(5.0, 0.5, 3.5)
    spot.CFrame = CFrame.new(cfg.bedPos)
    spot.Transparency = 1
    spot.CanCollide = false
    spot.Anchored = true
    spot.Parent = bedSpotsFolder

    local standVal = Instance.new("Vector3Value")
    standVal.Name = "StandPos"
    standVal.Value = cfg.standPos
    standVal.Parent = spot

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SleepPrompt"
    prompt.ActionText = "Sleep / 眠る"
    prompt.ObjectText = "Bunk Bed / ベッド"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 8
    prompt.Parent = spot
end

-- 5. Persistent Server Script for Cabin Bed Sleeping
local sleepScript = Instance.new("Script")
sleepScript.Name = "CabinBedSleepScript"
sleepScript.Source = [[
local bedSpotsFolder = script.Parent:WaitForChild("BedSpots")

local bedRotation = CFrame.fromMatrix(
    Vector3.zero,
    Vector3.new(0, 0, 1),
    Vector3.new(-1, 0, 0)
)

local sleepingPlayers = {}

for _, spot in ipairs(bedSpotsFolder:GetChildren()) do
    if spot:IsA("BasePart") then
        local prompt = spot:WaitForChild("SleepPrompt")
        local standVal = spot:WaitForChild("StandPos")
        local standPos = standVal.Value
        local bedPos = spot.Position
        local occupiedPlayer = nil
        local wakeConn = nil

        local function wakeUp()
            if not occupiedPlayer then return end
            local p = occupiedPlayer
            occupiedPlayer = nil
            sleepingPlayers[p] = nil

            if wakeConn then
                wakeConn:Disconnect()
                wakeConn = nil
            end

            local char = p.Character
            if char then
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and hum then
                    root.Anchored = false
                    hum.PlatformStand = false
                    root.CFrame = CFrame.new(standPos) * CFrame.Angles(0, math.pi/2, 0)
                end
            end

            local wakePrompt = spot:FindFirstChild("WakePrompt")
            if wakePrompt then wakePrompt:Destroy() end

            prompt.Enabled = true
        end

        prompt.Triggered:Connect(function(player)
            if occupiedPlayer or sleepingPlayers[player] then return end
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum or not root or hum.Health <= 0 then return end

            occupiedPlayer = player
            sleepingPlayers[player] = true
            prompt.Enabled = false

            hum.Sit = false
            hum.PlatformStand = true
            root.CFrame = CFrame.new(bedPos) * bedRotation
            root.Anchored = true

            local wakePrompt = Instance.new("ProximityPrompt")
            wakePrompt.Name = "WakePrompt"
            wakePrompt.ActionText = "Wake Up / 起きる"
            wakePrompt.ObjectText = "Bunk Bed / ベッド"
            wakePrompt.KeyboardKeyCode = Enum.KeyCode.E
            wakePrompt.HoldDuration = 0
            wakePrompt.RequiresLineOfSight = false
            wakePrompt.MaxActivationDistance = 10
            wakePrompt.Parent = spot

            wakePrompt.Triggered:Connect(function(p)
                if p == occupiedPlayer then
                    wakeUp()
                end
            end)

            wakeConn = hum:GetPropertyChangedSignal("Jump"):Connect(function()
                if hum.Jump then
                    wakeUp()
                end
            end)
        end)
    end
end
]]
sleepScript.Parent = interior

-- 6. Dining Table & 4 Stools (ALL FACING DIRECTLY TOWARDS THE TABLE!)
local tableModel = Instance.new("Model")
tableModel.Name = "DiningTableArea"
tableModel.Parent = interior

local tablePos = Vector3.new(-89.0, floorY + 2.0, -1805.0)

local tableTop = Instance.new("Part")
tableTop.Name = "DiningTableTop"
tableTop.Size = Vector3.new(6.0, 0.4, 4.0)
tableTop.CFrame = CFrame.new(tablePos)
tableTop.Material = Enum.Material.Wood
tableTop.Color = Color3.fromRGB(120, 80, 45)
tableTop.Anchored = true
tableTop.Parent = tableModel

local tLegOffsets = {
    Vector3.new(-2.6, -1.0, -1.6),
    Vector3.new(-2.6, -1.0, 1.6),
    Vector3.new(2.6, -1.0, -1.6),
    Vector3.new(2.6, -1.0, 1.6)
}
for _, tOff in ipairs(tLegOffsets) do
    local tLeg = Instance.new("Part")
    tLeg.Name = "TableLeg"
    tLeg.Size = Vector3.new(0.45, 1.8, 0.45)
    tLeg.CFrame = CFrame.new(tablePos + tOff)
    tLeg.Material = Enum.Material.Wood
    tLeg.Color = Color3.fromRGB(90, 60, 35)
    tLeg.Anchored = true
    tLeg.Parent = tableModel
end

-- Tetsubin Kettle & Trivet
local kettleTrivet = Instance.new("Part")
kettleTrivet.Name = "TeaTrivet"
kettleTrivet.Size = Vector3.new(1.4, 0.1, 1.4)
kettleTrivet.CFrame = CFrame.new(tablePos + Vector3.new(0, 0.25, 0))
kettleTrivet.Material = Enum.Material.Wood
kettleTrivet.Color = Color3.fromRGB(50, 35, 25)
kettleTrivet.Anchored = true
kettleTrivet.Parent = tableModel

local kettle = Instance.new("Part")
kettle.Name = "TetsubinKettle"
kettle.Shape = Enum.PartType.Cylinder
kettle.Size = Vector3.new(1.0, 1.0, 1.0)
kettle.CFrame = CFrame.new(tablePos + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, math.pi/2)
kettle.Material = Enum.Material.Metal
kettle.Color = Color3.fromRGB(30, 30, 30)
kettle.Anchored = true
kettle.Parent = tableModel

-- 4 Teacups
local cupOffsets = {
    Vector3.new(-1.6, 0.35, -1.0),
    Vector3.new(-1.6, 0.35, 1.0),
    Vector3.new(1.6, 0.35, -1.0),
    Vector3.new(1.6, 0.35, 1.0)
}
for cIdx, cOff in ipairs(cupOffsets) do
    local cup = Instance.new("Part")
    cup.Name = "Teacup" .. cIdx
    cup.Shape = Enum.PartType.Cylinder
    cup.Size = Vector3.new(0.45, 0.4, 0.4)
    cup.CFrame = CFrame.new(tablePos + cOff) * CFrame.Angles(0, 0, math.pi/2)
    cup.Material = Enum.Material.SmoothPlastic
    cup.Color = Color3.fromRGB(230, 235, 225)
    cup.Anchored = true
    cup.Parent = tableModel
end

-- 4 Stools with Seats around table
-- CRITICAL FIX: ALL STOOLS ORIENTED LOOKING STRAIGHT INTO THE TABLE!
local stoolConfigs = {
    { name = "TableSeat1", pos = Vector3.new(-89.0, floorY + 0.6, -1808.4) }, -- North stool -> faces South towards table (+Z)
    { name = "TableSeat2", pos = Vector3.new(-89.0, floorY + 0.6, -1801.6) }, -- South stool -> faces North towards table (-Z)
    { name = "TableSeat3", pos = Vector3.new(-92.6, floorY + 0.6, -1805.0) }, -- West stool  -> faces East towards table (+X)
    { name = "TableSeat4", pos = Vector3.new(-85.4, floorY + 0.6, -1805.0) }, -- East stool  -> faces West towards table (-X)
}

for _, sData in ipairs(stoolConfigs) do
    local stool = Instance.new("Seat")
    stool.Name = sData.name
    stool.Size = Vector3.new(1.6, 0.9, 1.6)
    -- LookVector points directly into the center of the dining table!
    stool.CFrame = CFrame.lookAt(sData.pos, Vector3.new(tablePos.X, sData.pos.Y, tablePos.Z))
    stool.Material = Enum.Material.Wood
    stool.Color = Color3.fromRGB(100, 70, 40)
    stool.Anchored = true
    stool.Parent = tableModel
end

-- 7. Back Wall Shelving Unit (Supplies & First Aid)
local shelfPos = Vector3.new(-88.5, floorY + 3.8, -1812.2)
local shelfModel = Instance.new("Model")
shelfModel.Name = "SupplyShelves"
shelfModel.Parent = interior

for tIdx, tY in ipairs({ 0, 2.0, 4.0 }) do
    local shelfBoard = Instance.new("Part")
    shelfBoard.Name = "ShelfBoard" .. tIdx
    shelfBoard.Size = Vector3.new(7.0, 0.3, 1.6)
    shelfBoard.CFrame = CFrame.new(shelfPos + Vector3.new(0, tY, 0))
    shelfBoard.Material = Enum.Material.Wood
    shelfBoard.Color = Color3.fromRGB(85, 55, 32)
    shelfBoard.Anchored = true
    shelfBoard.Parent = shelfModel
end

for _, sX in ipairs({ -3.4, 3.4 }) do
    local sSupport = Instance.new("Part")
    sSupport.Name = "ShelfSupport"
    sSupport.Size = Vector3.new(0.3, 4.5, 1.6)
    sSupport.CFrame = CFrame.new(shelfPos + Vector3.new(sX, 2.0, 0))
    sSupport.Material = Enum.Material.Wood
    sSupport.Color = Color3.fromRGB(80, 50, 30)
    sSupport.Anchored = true
    sSupport.Parent = shelfModel
end

-- First Aid Kit
local aidBox = Instance.new("Part")
aidBox.Name = "FirstAidBox"
aidBox.Size = Vector3.new(1.6, 1.0, 1.0)
aidBox.CFrame = CFrame.new(shelfPos + Vector3.new(-1.8, 2.6, 0))
aidBox.Material = Enum.Material.SmoothPlastic
aidBox.Color = Color3.fromRGB(240, 240, 240)
aidBox.Anchored = true
aidBox.Parent = shelfModel

local crossH = Instance.new("Part")
crossH.Name = "CrossH"
crossH.Size = Vector3.new(0.8, 0.25, 0.05)
crossH.CFrame = aidBox.CFrame * CFrame.new(0, 0, 0.52)
crossH.Material = Enum.Material.SmoothPlastic
crossH.Color = Color3.fromRGB(210, 30, 30)
crossH.Anchored = true
crossH.Parent = shelfModel

local crossV = Instance.new("Part")
crossV.Name = "CrossV"
crossV.Size = Vector3.new(0.25, 0.8, 0.05)
crossV.CFrame = aidBox.CFrame * CFrame.new(0, 0, 0.52)
crossV.Material = Enum.Material.SmoothPlastic
crossV.Color = Color3.fromRGB(210, 30, 30)
crossV.Anchored = true
crossV.Parent = shelfModel

-- Canned Rations & Water Flasks
for canIdx = 1, 5 do
    local can = Instance.new("Part")
    can.Name = "FoodCan" .. canIdx
    can.Shape = Enum.PartType.Cylinder
    can.Size = Vector3.new(0.8, 0.6, 0.6)
    can.CFrame = CFrame.new(shelfPos + Vector3.new(0.5 + (canIdx - 1) * 0.7, 0.6, 0)) * CFrame.Angles(0, 0, math.pi/2)
    can.Material = Enum.Material.Metal
    can.Color = (canIdx % 2 == 0) and Color3.fromRGB(180, 120, 50) or Color3.fromRGB(50, 130, 70)
    can.Anchored = true
    can.Parent = shelfModel
end

for bIdx = 1, 3 do
    local flask = Instance.new("Part")
    flask.Name = "WaterFlask" .. bIdx
    flask.Shape = Enum.PartType.Cylinder
    flask.Size = Vector3.new(1.1, 0.6, 0.6)
    flask.CFrame = CFrame.new(shelfPos + Vector3.new(-1.5 + (bIdx - 1) * 1.2, 4.7, 0)) * CFrame.Angles(0, 0, math.pi/2)
    flask.Material = Enum.Material.Metal
    flask.Color = Color3.fromRGB(40, 100, 160)
    flask.Anchored = true
    flask.Parent = shelfModel
end

-- 8. Wall Trail Map
local mapBoard = Instance.new("Part")
mapBoard.Name = "TrailMapBoard"
mapBoard.Size = Vector3.new(6.0, 4.0, 0.3)
mapBoard.CFrame = CFrame.new(-96.0, floorY + 5.0, -1812.6)
mapBoard.Material = Enum.Material.Wood
mapBoard.Color = Color3.fromRGB(110, 80, 50)
mapBoard.Anchored = true
mapBoard.Parent = interior

local mapPaper = Instance.new("Part")
mapPaper.Name = "TrailMapPaper"
mapPaper.Size = Vector3.new(5.4, 3.4, 0.05)
mapPaper.CFrame = mapBoard.CFrame * CFrame.new(0, 0, 0.18)
mapPaper.Material = Enum.Material.SmoothPlastic
mapPaper.Color = Color3.fromRGB(245, 240, 225)
mapPaper.Anchored = true
mapPaper.Parent = interior

local sGui = Instance.new("SurfaceGui")
sGui.Name = "MapGui"
sGui.Face = Enum.NormalId.Front
sGui.Parent = mapPaper

local mapFrame = Instance.new("Frame")
mapFrame.Size = UDim2.new(1, 0, 1, 0)
mapFrame.BackgroundColor3 = Color3.fromRGB(245, 238, 220)
mapFrame.BorderSizePixel = 0
mapFrame.Parent = sGui

local mapTitle = Instance.new("TextLabel")
mapTitle.Size = UDim2.new(1, 0, 0.25, 0)
mapTitle.BackgroundTransparency = 1
mapTitle.Text = "諏訪山 登山ルート案内\\nSUWA ALPINE TRAIL GUIDE"
mapTitle.TextColor3 = Color3.fromRGB(40, 30, 20)
mapTitle.Font = Enum.Font.SourceSansBold
mapTitle.TextScaled = true
mapTitle.Parent = mapFrame

local mapSubtitle = Instance.new("TextLabel")
mapSubtitle.Size = UDim2.new(0.9, 0, 0.65, 0)
mapSubtitle.Position = UDim2.new(0.05, 0, 0.3, 0)
mapSubtitle.BackgroundTransparency = 1
mapSubtitle.Text = "▲ 山頂神社 SUMMIT SHRINE (750m)\\n↑ 崖ハシゴ CLIFF LADDER\\n↑ 山小屋 MOUNTAIN HUT (305m)\\n↑ つり橋 SUSPENSION BRIDGE\\n● 登山口 TRAILHEAD (0m)"
mapSubtitle.TextColor3 = Color3.fromRGB(60, 45, 30)
mapSubtitle.Font = Enum.Font.SourceSans
mapSubtitle.TextScaled = true
mapSubtitle.TextXAlignment = Enum.TextXAlignment.Left
mapSubtitle.Parent = mapFrame

-- 9. Shoe Rack
local shoeRack = Instance.new("Part")
shoeRack.Name = "ShoeRack"
shoeRack.Size = Vector3.new(3.5, 1.2, 1.4)
shoeRack.CFrame = CFrame.new(-99.5, floorY + 0.6, -1796.5)
shoeRack.Material = Enum.Material.Wood
shoeRack.Color = Color3.fromRGB(90, 60, 35)
shoeRack.Anchored = true
shoeRack.Parent = interior

return "Mountain Cabin Interior with stools facing table & Bunk Bed Sleeping built successfully!"
`;
  const res4 = await executeLuau(codeCabin, 'Edit');
  console.log('Cabin Interior:', res4.content[0].text);

  // =========================================================================
  // 5. DIRECT SAVE IN ROBLOX STUDIO
  // =========================================================================
  console.log('\n[5/5] Saving place directly in Roblox Studio via AppleScript...');
  try {
    execSync(`osascript -e 'tell application "RobloxStudio" to activate' -e 'delay 0.5' -e 'tell application "System Events" to keystroke "s" using command down'`);
    console.log('Successfully sent Cmd+S to Roblox Studio!');
  } catch (err) {
    console.warn('Could not send Cmd+S via AppleScript:', err.message);
  }

  console.log('\n=== ALL RESTORATIONS COMPLETED IN EDIT DATAMODEL! ===');
}

main().catch(console.error);
