const { executeLuau, captureScreen } = require('./mcp-exec.js');
const { execSync } = require('child_process');

async function main() {
  console.log('=== APPLYING COMPLETE WORLD & OUTFIT FIX IN EDIT DATAMODEL ===');

  // =========================================================================
  // 1. UPDATE MITSUHA UNIFORM IN SUWACOSTUMECONFIG
  // =========================================================================
  console.log('\n[1/5] Updating Mitsuha outfit in ReplicatedStorage.SuwaCostumeConfig...');
  const codeMitsuha = `
local cfg = game:GetService("ReplicatedStorage"):FindFirstChild("SuwaCostumeConfig")
if not cfg then return "no SuwaCostumeConfig found" end

local src = cfg.Source
-- Replace shirt and pants IDs for mitsuha_miyamizu
-- We replace the mitsuha block with the authentic school uniform
local pattern = 'id%s*=%s*"mitsuha_miyamizu"[^}]+}'
local newBlock = [[id = "mitsuha_miyamizu",
		name = "Mitsuha Miyamizu - Your Name (宮水 三葉)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 6229692771,
		pants = 6229694164,
		shirtTemplate = "http://www.roblox.com/asset/?id=6229692758",
		pantsTemplate = "http://www.roblox.com/asset/?id=6229694145",
		description = "Itomori High School uniform with the iconic braided red ribbon.\\n組紐の赤リボンが心をつなぐ、三葉の糸守高校制服。"
	}]]

local replaced, count = string.gsub(src, pattern, newBlock)
if count > 0 then
    cfg.Source = replaced
    return "SuwaCostumeConfig updated with Mitsuha School Uniform (6229692771 / 6229694164)!"
else
    return "Could not match mitsuha block, manual check needed"
end
`;
  const resMitsuha = await executeLuau(codeMitsuha, 'Edit');
  console.log('Mitsuha Outfit Update:', resMitsuha.content[0].text);

  // =========================================================================
  // 2. REBUILD CAMPFIRE WITH GROUNDED 2-SEATER BENCHES FACING FIRE
  // =========================================================================
  console.log('\n[2/5] Rebuilding Aesthetic Campfire in Edit mode...');
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

local existing = trail:FindFirstChild("AestheticCampfire")
if existing then existing:Destroy() end

local campModel = Instance.new("Model")
campModel.Name = "AestheticCampfire"
campModel.Parent = trail

local cX, cZ = -24.0, -1774.0
local centerGroundY = getGroundY(cX, cZ)
local center = Vector3.new(cX, centerGroundY, cZ)

-- 1. Fire Hearth (Sunk slightly into ground)
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

-- Native Roblox Fire & Smoke (Guaranteed to render & roar without external asset texture dependency)
local fire = Instance.new("Fire")
fire.Name = "BlazingFire"
fire.Size = 8.5
fire.Heat = 14.0
fire.Color = Color3.fromRGB(255, 145, 30)
fire.SecondaryColor = Color3.fromRGB(255, 50, 10)
fire.Parent = embers

local smoke = Instance.new("Smoke")
smoke.Name = "CampSmoke"
smoke.Size = 3.0
smoke.RiseVelocity = 5.0
smoke.Color = Color3.fromRGB(120, 120, 120)
smoke.Opacity = 0.35
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

-- 12 Stones ringing the fire
for i = 1, 12 do
    local ang = (i / 12) * math.pi * 2
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

-- Tripod & Pot
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

-- 4 LOG BENCHES: SOLIDLY GROUNDED, 2 SEATS EACH, FACING DIRECTLY AT FIRE
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

    local rad = 8.5
    local bX = cX + math.cos(bCfg.ang) * rad
    local bZ = cZ + math.sin(bCfg.ang) * rad
    local bGroundY = getGroundY(bX, bZ)

    -- Vector towards the campfire center
    local toFire = (Vector3.new(cX, 0, cZ) - Vector3.new(bX, 0, bZ)).Unit
    -- Tangent along bench length
    local alongBench = Vector3.new(-toFire.Z, 0, toFire.X).Unit

    -- Plank sits 1.35 studs above the ground at the bench center
    local plankY = bGroundY + 1.35
    local plankPos = Vector3.new(bX, plankY, bZ)

    local plank = Instance.new("Part")
    plank.Name = "BenchPlank"
    plank.Size = Vector3.new(1.8, 0.6, 7.5)
    -- Orient plank so its length (Z axis of part) is alongBench
    plank.CFrame = CFrame.lookAt(plankPos, plankPos + alongBench)
    plank.Material = Enum.Material.Wood
    plank.Color = Color3.fromRGB(115, 78, 48)
    plank.Anchored = true
    plank.Parent = bModel

    -- TWO SOLID LEGS SINKING DEEP INTO TERRAIN (ZERO FLOATING!)
    for _, lSign in ipairs({-2.2, 2.2}) do
        local legX = bX + alongBench.X * lSign
        local legZ = bZ + alongBench.Z * lSign
        local legGroundY = getGroundY(legX, legZ)
        
        -- Leg top connects to bottom of plank (plankY - 0.3)
        -- Leg bottom penetrates 1.5 studs BELOW ground level (legGroundY - 1.5)
        local legTop = plankY - 0.3
        local legBottom = legGroundY - 1.5
        local legHeight = math.max(1.8, legTop - legBottom)
        local legCenterY = (legTop + legBottom) / 2

        local leg = Instance.new("Part")
        leg.Name = "BenchLeg"
        leg.Size = Vector3.new(1.6, legHeight, 1.4)
        leg.CFrame = CFrame.new(legX, legCenterY, legZ) * CFrame.lookAt(Vector3.zero, alongBench)
        leg.Material = Enum.Material.Wood
        leg.Color = Color3.fromRGB(75, 48, 28)
        leg.Anchored = true
        leg.Parent = bModel
    end

    -- TWO FUNCTIONAL SEATS PER BENCH (1 tempat duduk bisa ber-2!)
    -- Both seats oriented facing DIRECTLY into the campfire center!
    for seatIdx, sOff in ipairs({-1.8, 1.8}) do
        local sX = bX + alongBench.X * sOff
        local sZ = bZ + alongBench.Z * sOff
        local sY = plankY + 0.35
        local sPos = Vector3.new(sX, sY, sZ)

        local seat = Instance.new("Seat")
        seat.Name = "BenchSeat" .. seatIdx
        seat.Size = Vector3.new(1.6, 0.2, 1.6)
        -- CRITICAL: LookVector points straight into (cX, sY, cZ)!
        seat.CFrame = CFrame.lookAt(sPos, Vector3.new(cX, sY, cZ))
        seat.Transparency = 1
        seat.CanCollide = false
        seat.Anchored = true
        seat.Parent = bModel
    end

    -- Side stump table with coffee mug
    local stumpX = bX + alongBench.X * 4.4
    local stumpZ = bZ + alongBench.Z * 4.4
    local stumpGroundY = getGroundY(stumpX, stumpZ)
    local stumpTop = plankY + 0.1
    local stumpBottom = stumpGroundY - 1.2
    local stumpH = math.max(1.2, stumpTop - stumpBottom)

    local stump = Instance.new("Part")
    stump.Name = "SideStump"
    stump.Shape = Enum.PartType.Cylinder
    stump.Size = Vector3.new(stumpH, 1.6, 1.6)
    stump.CFrame = CFrame.new(stumpX, (stumpTop + stumpBottom)/2, stumpZ) * CFrame.Angles(0, 0, math.pi/2)
    stump.Material = Enum.Material.Wood
    stump.Color = Color3.fromRGB(80, 52, 32)
    stump.Anchored = true
    stump.Parent = bModel

    local mug = Instance.new("Part")
    mug.Name = "CoffeeMug"
    mug.Shape = Enum.PartType.Cylinder
    mug.Size = Vector3.new(0.5, 0.4, 0.4)
    mug.CFrame = CFrame.new(stumpX, stumpTop + 0.25, stumpZ) * CFrame.Angles(0, 0, math.pi/2)
    mug.Material = Enum.Material.SmoothPlastic
    mug.Color = (bCfg.ang == 0 and Color3.fromRGB(200, 60, 50) or Color3.fromRGB(40, 100, 160))
    mug.Anchored = true
    mug.Parent = bModel
end

-- Aesthetic Tents near campfire
local tent1BaseCf = CFrame.new(-42, getGroundY(-42, -1786), -1786) * CFrame.Angles(0, 0.3, 0)
local t1 = Instance.new("Model")
t1.Name = "AestheticTent1"
t1.Parent = campModel

local t1Floor = Instance.new("Part")
t1Floor.Name = "Floor"
t1Floor.Size = Vector3.new(7.0, 0.3, 10.0)
t1Floor.CFrame = tent1BaseCf * CFrame.new(0, 0.15, 0)
t1Floor.Material = Enum.Material.WoodPlanks
t1Floor.Color = Color3.fromRGB(130, 95, 65)
t1Floor.Anchored = true
t1Floor.Parent = t1

local t1SlopeL = Instance.new("Part")
t1SlopeL.Name = "SlopeL"
t1SlopeL.Size = Vector3.new(0.3, 6.0, 10.0)
t1SlopeL.CFrame = tent1BaseCf * CFrame.new(-2.0, 2.65, 0) * CFrame.Angles(0, 0, -0.6)
t1SlopeL.Material = Enum.Material.Fabric
t1SlopeL.Color = Color3.fromRGB(180, 65, 30)
t1SlopeL.Anchored = true
t1SlopeL.Parent = t1

local t1SlopeR = Instance.new("Part")
t1SlopeR.Name = "SlopeR"
t1SlopeR.Size = Vector3.new(0.3, 6.0, 10.0)
t1SlopeR.CFrame = tent1BaseCf * CFrame.new(2.0, 2.65, 0) * CFrame.Angles(0, 0, 0.6)
t1SlopeR.Material = Enum.Material.Fabric
t1SlopeR.Color = Color3.fromRGB(180, 65, 30)
t1SlopeR.Anchored = true
t1SlopeR.Parent = t1

return "Campfire rebuilt with deeply grounded 2-seater benches facing fire!"
`;
  const resCamp = await executeLuau(codeCampfire, 'Edit');
  console.log('Campfire Rebuild:', resCamp.content[0].text);

  // =========================================================================
  // 3. REBUILD MOUNTAIN CABIN (STOOLS FACING TABLE & BUNK BED SLEEPING)
  // =========================================================================
  console.log('\n[3/5] Rebuilding Mountain Cabin Interior in Edit mode...');
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

-- 2. Hanging Lanterns
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

-- 3. DINING TABLE & 4 STOOLS (ALL FACING DIRECTLY INTO THE TABLE!)
local tableModel = Instance.new("Model")
tableModel.Name = "DiningTableArea"
tableModel.Parent = interior

local tablePos = Vector3.new(-91.0, floorY + 1.8, -1804.5)

local tableTop = Instance.new("Part")
tableTop.Name = "DiningTableTop"
tableTop.Size = Vector3.new(5.6, 0.35, 3.8)
tableTop.CFrame = CFrame.new(tablePos)
tableTop.Material = Enum.Material.Wood
tableTop.Color = Color3.fromRGB(120, 80, 45)
tableTop.Anchored = true
tableTop.Parent = tableModel

local tLegOffsets = {
    Vector3.new(-2.4, -0.9, -1.5),
    Vector3.new(-2.4, -0.9, 1.5),
    Vector3.new(2.4, -0.9, -1.5),
    Vector3.new(2.4, -0.9, 1.5)
}
for _, tOff in ipairs(tLegOffsets) do
    local tLeg = Instance.new("Part")
    tLeg.Name = "TableLeg"
    tLeg.Size = Vector3.new(0.4, 1.6, 0.4)
    tLeg.CFrame = CFrame.new(tablePos + tOff)
    tLeg.Material = Enum.Material.Wood
    tLeg.Color = Color3.fromRGB(90, 60, 35)
    tLeg.Anchored = true
    tLeg.Parent = tableModel
end

-- Tetsubin Kettle & Trivet
local kettleTrivet = Instance.new("Part")
kettleTrivet.Name = "TeaTrivet"
kettleTrivet.Size = Vector3.new(1.3, 0.08, 1.3)
kettleTrivet.CFrame = CFrame.new(tablePos + Vector3.new(0, 0.22, 0))
kettleTrivet.Material = Enum.Material.Wood
kettleTrivet.Color = Color3.fromRGB(50, 35, 25)
kettleTrivet.Anchored = true
kettleTrivet.Parent = tableModel

local kettle = Instance.new("Part")
kettle.Name = "TetsubinKettle"
kettle.Shape = Enum.PartType.Cylinder
kettle.Size = Vector3.new(0.9, 0.9, 0.9)
kettle.CFrame = CFrame.new(tablePos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.pi/2)
kettle.Material = Enum.Material.Metal
kettle.Color = Color3.fromRGB(30, 30, 30)
kettle.Anchored = true
kettle.Parent = tableModel

-- 4 Teacups
local teacupOffsets = {
    Vector3.new(0, 0.3, -1.2),  -- North
    Vector3.new(0, 0.3, 1.2),   -- South
    Vector3.new(-1.8, 0.3, 0),  -- West
    Vector3.new(1.8, 0.3, 0),   -- East
}
for cIdx, cOff in ipairs(teacupOffsets) do
    local cup = Instance.new("Part")
    cup.Name = "Teacup" .. cIdx
    cup.Shape = Enum.PartType.Cylinder
    cup.Size = Vector3.new(0.4, 0.35, 0.35)
    cup.CFrame = CFrame.new(tablePos + cOff) * CFrame.Angles(0, 0, math.pi/2)
    cup.Material = Enum.Material.SmoothPlastic
    cup.Color = Color3.fromRGB(235, 238, 230)
    cup.Anchored = true
    cup.Parent = tableModel
end

-- 4 Stools: EXACTLY SURROUNDING 4 SIDES OF TABLE (DEKAT PAS MENTOK 1.8 STUDS)
local stoolConfigs = {
    { name = "TableSeat1_North", pos = Vector3.new(-91.0, floorY + 0.5, -1808.2) }, -- North stool -> faces South (+Z)
    { name = "TableSeat2_South", pos = Vector3.new(-91.0, floorY + 0.5, -1800.8) }, -- South stool -> faces North (-Z)
    { name = "TableSeat3_West",  pos = Vector3.new(-95.6, floorY + 0.5, -1804.5) }, -- West stool  -> faces East (+X)
    { name = "TableSeat4_East",  pos = Vector3.new(-86.4, floorY + 0.5, -1804.5) }, -- East stool  -> faces West (-X)
}

for _, sData in ipairs(stoolConfigs) do
    local stool = Instance.new("Seat")
    stool.Name = sData.name
    stool.Size = Vector3.new(1.8, 1.0, 1.8)
    stool.CFrame = CFrame.lookAt(sData.pos, Vector3.new(tablePos.X, sData.pos.Y, tablePos.Z))
    stool.Material = Enum.Material.Wood
    stool.Color = Color3.fromRGB(115, 78, 48)
    stool.Anchored = true
    stool.CanCollide = true
    stool.Parent = tableModel
end

-- 4. BUNK BEDS (NO SEAT OBJECTS! CLEAN SLEEPING INTERACTION)
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

    -- Wooden ladder rungs
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

-- 5. Interactive BedSpots for Sleeping (All 4 Bunks)
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
    prompt.MaxActivationDistance = 9
    prompt.Parent = spot
end

-- 6. Server Script for Cabin Bed Sleeping
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

-- 7. Shelving Unit & First Aid
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

-- 8. Trail Map
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

return "Cabin rebuilt with stools facing table and bunk beds sleeping!"
`;
  const resCabin = await executeLuau(codeCabin, 'Edit');
  console.log('Cabin Rebuild:', resCabin.content[0].text);

  // =========================================================================
  // 4. ENSURE BOTH ROPE LADDERS EXIST
  // =========================================================================
  console.log('\n[4/5] Ensuring Rope Ladders exist in Edit mode...');
  const codeCheckLadders = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local bBridge = trail:FindFirstChild("BrokenBridgeRopeLadder")
local wLadder = trail:FindFirstChild("WalkwayRopeLadder")
return { brokenBridge = bBridge ~= nil, walkway = wLadder ~= nil }
`;
  const resLadders = await executeLuau(codeCheckLadders, 'Edit');
  const ladderStatus = JSON.parse(resLadders.content[0].text);
  console.log('Rope Ladders status:', ladderStatus);

  // If broken bridge ladder is missing, rebuild it
  if (!ladderStatus.brokenBridge) {
    console.log('Rebuilding Broken Bridge Rope Ladder...');
    const fs = require('fs');
    const f1 = fs.readFileSync('./scripts/build_broken_bridge_rope_ladder.js', 'utf8');
    const c1 = f1.substring(f1.indexOf('local trail = workspace:WaitForChild("SuwaMountainTrail")'), f1.lastIndexOf('`;'));
    await executeLuau(c1, 'Edit');
  }

  // If walkway ladder is missing, rebuild it
  if (!ladderStatus.walkway) {
    console.log('Rebuilding Walkway Rope Ladder...');
    const fs = require('fs');
    const f2 = fs.readFileSync('./scripts/build_walkway_rope_ladder.js', 'utf8');
    const c2 = f2.substring(f2.indexOf('local trail = workspace:WaitForChild("SuwaMountainTrail")'), f2.lastIndexOf('`;'));
    await executeLuau(c2, 'Edit');
  }

  // =========================================================================
  // 5. FIX HOTEL PLAZA & PARKING LOT Z-FIGHTING
  // =========================================================================
  console.log('\n[5/6] Fixing Hotel Plaza & Parking Lot Z-fighting...');
  const codeHotelPlaza = `
local townBlocks = workspace:FindFirstChild("TownRoadNetwork") and workspace.TownRoadNetwork:FindFirstChild("TownBlocks")
local hotelPlaza = townBlocks and townBlocks:FindFirstChild("HotelPlazaAndParking")
if hotelPlaza then
    local plazaLot = hotelPlaza:FindFirstChild("PlazaLot")
    local driveway = hotelPlaza:FindFirstChild("HotelDrivewayLink")
    local newThickness = 3.0
    local targetTopY = 6.10
    local targetPosY = targetTopY - (newThickness / 2)
    if plazaLot then
        plazaLot.Size = Vector3.new(128, newThickness, 74)
        plazaLot.Position = Vector3.new(355, targetPosY, 45)
    end
    if driveway then
        driveway.Size = Vector3.new(14, newThickness, 6)
        driveway.Position = Vector3.new(355, targetPosY, 5)
    end
    workspace.Terrain:FillBlock(CFrame.new(355, 4.5, 45), Vector3.new(120, 4, 66), Enum.Material.Air)
    return "Hotel plaza and driveway fixed!"
end
return "Hotel plaza not found"
`;
  const resHotelPlaza = await executeLuau(codeHotelPlaza, 'Edit');
  console.log('Hotel Plaza Fix:', resHotelPlaza?.content?.[0]?.text);

  // =========================================================================
  // 6. SET WAYPOINT AND FOCUS ROBLOX STUDIO
  // =========================================================================
  console.log('\n[6/6] Finalizing waypoint and focusing Studio...');
  const codeWaypoint = `
local chs = game:GetService("ChangeHistoryService")
chs:SetWaypoint("Mitsuha Uniform, Campfire Benches, Cabin & Hotel Plaza Fixed")
return "Waypoint set successfully!"
`;
  await executeLuau(codeWaypoint, 'Edit');

  try {
    execSync(`osascript -e 'tell application "RobloxStudio" to activate'`);
    console.log('Roblox Studio brought to front!');
  } catch (e) {}

  console.log('\n=== ALL FIXES APPLIED PERMANENTLY IN EDIT DATAMODEL! ===');
}

main().catch(console.error);
