const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

-- Remove old interior model if exists
local oldHutInterior = trail:FindFirstChild("HutInteriorFurnishings")
if oldHutInterior then oldHutInterior:Destroy() end

local interior = Instance.new("Model")
interior.Name = "HutInteriorFurnishings"
interior.Parent = trail

local floorY = 299.4 -- Top of HutFloor
local hutCenter = Vector3.new(-96.0, floorY, -1804.0)

-- 1. Interior Tatami / Wood Floor Layer
local matFloor = Instance.new("Part")
matFloor.Name = "InteriorTatamiFloor"
matFloor.Size = Vector3.new(24.5, 0.2, 16.5)
matFloor.CFrame = CFrame.new(-96.0, floorY + 0.1, -1804.0)
matFloor.Material = Enum.Material.WoodPlanks
matFloor.Color = Color3.fromRGB(155, 128, 85) -- Straw / tatami tone
matFloor.Anchored = true
matFloor.Parent = interior

-- 2. Warm Hanging Lanterns
local lanternPositions = {
    Vector3.new(-102.0, floorY + 8.5, -1804.0),
    Vector3.new(-90.0, floorY + 8.5, -1804.0)
}

for lIdx, lPos in ipairs(lanternPositions) do
    -- Chain from ceiling
    local chain = Instance.new("Part")
    chain.Name = "LanternChain" .. lIdx
    chain.Size = Vector3.new(0.1, 2.5, 0.1)
    chain.CFrame = CFrame.new(lPos + Vector3.new(0, 1.25, 0))
    chain.Material = Enum.Material.Metal
    chain.Color = Color3.fromRGB(40, 40, 40)
    chain.Anchored = true
    chain.Parent = interior

    -- Lantern Frame
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

-- 3. Sleeping Quarters (Double Bunk Bed on Left Wall)
-- Bunk 1 (Back-Left): X = -104, Z = -1808.5
-- Bunk 2 (Front-Left): X = -104, Z = -1801.5
local bunkZPositions = { -1808.5, -1801.5 }
for bIdx, bZ in ipairs(bunkZPositions) do
    local bunkModel = Instance.new("Model")
    bunkModel.Name = "BunkBed" .. bIdx
    bunkModel.Parent = interior

    -- 4 Corner Posts
    local postOffsets = {
        Vector3.new(-3.4, 0, -2.4),
        Vector3.new(-3.4, 0, 2.4),
        Vector3.new(3.4, 0, -2.4),
        Vector3.new(3.4, 0, 2.4)
    }
    for pIdx, pOff in ipairs(postOffsets) do
        local post = Instance.new("Part")
        post.Name = "BunkPost"
        post.Size = Vector3.new(0.6, 7.5, 0.6)
        post.CFrame = CFrame.new(Vector3.new(-104.5, floorY + 3.75, bZ) + pOff)
        post.Material = Enum.Material.Wood
        post.Color = Color3.fromRGB(90, 60, 38)
        post.Anchored = true
        post.Parent = bunkModel
    end

    -- Lower Bunk Platform (Y = floorY + 1.2)
    local lowerFrame = Instance.new("Part")
    lowerFrame.Name = "LowerBunkFrame"
    lowerFrame.Size = Vector3.new(7.2, 0.4, 5.2)
    lowerFrame.CFrame = CFrame.new(-104.5, floorY + 1.2, bZ)
    lowerFrame.Material = Enum.Material.Wood
    lowerFrame.Color = Color3.fromRGB(105, 70, 42)
    lowerFrame.Anchored = true
    lowerFrame.Parent = bunkModel

    local lowerMattress = Instance.new("Part")
    lowerMattress.Name = "LowerMattress"
    lowerMattress.Size = Vector3.new(6.6, 0.5, 4.6)
    lowerMattress.CFrame = CFrame.new(-104.5, floorY + 1.6, bZ)
    lowerMattress.Material = Enum.Material.Fabric
    lowerMattress.Color = Color3.fromRGB(240, 235, 220)
    lowerMattress.Anchored = true
    lowerMattress.Parent = bunkModel

    -- Quilt / Blanket
    local lowerBlanket = Instance.new("Part")
    lowerBlanket.Name = "LowerBlanket"
    lowerBlanket.Size = Vector3.new(4.2, 0.55, 4.4)
    lowerBlanket.CFrame = CFrame.new(-103.3, floorY + 1.65, bZ)
    lowerBlanket.Material = Enum.Material.Fabric
    lowerBlanket.Color = (bIdx == 1) and Color3.fromRGB(45, 80, 120) or Color3.fromRGB(140, 50, 45)
    lowerBlanket.Anchored = true
    lowerBlanket.Parent = bunkModel

    -- Pillow
    local lowerPillow = Instance.new("Part")
    lowerPillow.Name = "LowerPillow"
    lowerPillow.Size = Vector3.new(1.6, 0.4, 3.2)
    lowerPillow.CFrame = CFrame.new(-106.8, floorY + 1.8, bZ)
    lowerPillow.Material = Enum.Material.Fabric
    lowerPillow.Color = Color3.fromRGB(250, 250, 250)
    lowerPillow.Anchored = true
    lowerPillow.Parent = bunkModel

    -- (Bed spots with realistic sleep interaction are configured in BedSpots section below)

    -- Upper Bunk Platform (Y = floorY + 4.8)
    local upperFrame = Instance.new("Part")
    upperFrame.Name = "UpperBunkFrame"
    upperFrame.Size = Vector3.new(7.2, 0.4, 5.2)
    upperFrame.CFrame = CFrame.new(-104.5, floorY + 4.8, bZ)
    upperFrame.Material = Enum.Material.Wood
    upperFrame.Color = Color3.fromRGB(105, 70, 42)
    upperFrame.Anchored = true
    upperFrame.Parent = bunkModel

    local upperMattress = Instance.new("Part")
    upperMattress.Name = "UpperMattress"
    upperMattress.Size = Vector3.new(6.6, 0.5, 4.6)
    upperMattress.CFrame = CFrame.new(-104.5, floorY + 5.2, bZ)
    upperMattress.Material = Enum.Material.Fabric
    upperMattress.Color = Color3.fromRGB(240, 235, 220)
    upperMattress.Anchored = true
    upperMattress.Parent = bunkModel

    local upperBlanket = Instance.new("Part")
    upperBlanket.Name = "UpperBlanket"
    upperBlanket.Size = Vector3.new(4.2, 0.55, 4.4)
    upperBlanket.CFrame = CFrame.new(-103.3, floorY + 5.25, bZ)
    upperBlanket.Material = Enum.Material.Fabric
    upperBlanket.Color = (bIdx == 1) and Color3.fromRGB(150, 90, 40) or Color3.fromRGB(40, 95, 70)
    upperBlanket.Anchored = true
    upperBlanket.Parent = bunkModel

    local upperPillow = Instance.new("Part")
    upperPillow.Name = "UpperPillow"
    upperPillow.Size = Vector3.new(1.6, 0.4, 3.2)
    upperPillow.CFrame = CFrame.new(-106.8, floorY + 5.4, bZ)
    upperPillow.Material = Enum.Material.Fabric
    upperPillow.Color = Color3.fromRGB(250, 250, 250)
    upperPillow.Anchored = true
    upperPillow.Parent = bunkModel

    -- Ladder on side of bunk bed
    for rIdx = 1, 5 do
        local rung = Instance.new("Part")
        rung.Name = "BunkLadderRung"
        rung.Size = Vector3.new(0.3, 0.3, 2.2)
        rung.CFrame = CFrame.new(-101.0, floorY + rIdx * 0.9, bZ)
        rung.Material = Enum.Material.Wood
        rung.Color = Color3.fromRGB(80, 55, 35)
        rung.Anchored = true
        rung.Parent = bunkModel
    end
end

-- 4. Dining & Tea Table (Right Side of Room)
local tablePos = Vector3.new(-89.0, floorY + 2.0, -1805.0)
local tableModel = Instance.new("Model")
tableModel.Name = "DiningTableArea"
tableModel.Parent = interior

local tableTop = Instance.new("Part")
tableTop.Name = "TableTop"
tableTop.Size = Vector3.new(6.0, 0.4, 4.0)
tableTop.CFrame = CFrame.new(tablePos)
tableTop.Material = Enum.Material.Wood
tableTop.Color = Color3.fromRGB(120, 80, 45)
tableTop.Anchored = true
tableTop.Parent = tableModel

-- 4 Table Legs
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

-- Japanese Iron Tea Kettle (Tetsubin) on table
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

-- Kettle Spout
local spout = Instance.new("Part")
spout.Name = "KettleSpout"
spout.Size = Vector3.new(0.3, 0.5, 0.3)
spout.CFrame = CFrame.new(tablePos + Vector3.new(0.6, 0.85, 0)) * CFrame.Angles(0, 0, -0.4)
spout.Material = Enum.Material.Metal
spout.Color = Color3.fromRGB(30, 30, 30)
spout.Anchored = true
spout.Parent = tableModel

-- 4 Ceramic Teacups
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

-- 4 Wooden Stools with Seats around table (Comfortable spacing & legroom, all facing table)
local stoolOffsets = {
    { name = "TableSeat1", off = Vector3.new(0, -1.45, -3.8) }, -- North
    { name = "TableSeat2", off = Vector3.new(0, -1.45, 3.8) },  -- South
    { name = "TableSeat3", off = Vector3.new(-4.8, -1.45, 0) }, -- West (Bunk side)
    { name = "TableSeat4", off = Vector3.new(4.8, -1.45, 0) }   -- East (Wall side)
}
for _, sData in ipairs(stoolOffsets) do
    local stool = Instance.new("Seat")
    stool.Name = sData.name
    stool.Size = Vector3.new(1.6, 0.9, 1.6)
    local sPos = tablePos + sData.off
    stool.CFrame = CFrame.lookAt(sPos, Vector3.new(tablePos.X, sPos.Y, tablePos.Z))
    stool.Material = Enum.Material.Wood
    stool.Color = Color3.fromRGB(100, 70, 40)
    stool.Anchored = true
    stool.Parent = tableModel
end

-- 5. Back Wall Shelving Unit (Supplies & First Aid)
local shelfPos = Vector3.new(-88.5, floorY + 3.8, -1812.2)
local shelfModel = Instance.new("Model")
shelfModel.Name = "SupplyShelves"
shelfModel.Parent = interior

-- Shelf Frame (3 Tiers)
local shelfTiers = { 0, 2.0, 4.0 }
for tIdx, tY in ipairs(shelfTiers) do
    local shelfBoard = Instance.new("Part")
    shelfBoard.Name = "ShelfBoard" .. tIdx
    shelfBoard.Size = Vector3.new(7.0, 0.3, 1.6)
    shelfBoard.CFrame = CFrame.new(shelfPos + Vector3.new(0, tY, 0))
    shelfBoard.Material = Enum.Material.Wood
    shelfBoard.Color = Color3.fromRGB(85, 55, 32)
    shelfBoard.Anchored = true
    shelfBoard.Parent = shelfModel
end

-- Shelf Vertical Side Supports
local shelfSides = { -3.4, 3.4 }
for _, sX in ipairs(shelfSides) do
    local sSupport = Instance.new("Part")
    sSupport.Name = "ShelfSupport"
    sSupport.Size = Vector3.new(0.3, 4.5, 1.6)
    sSupport.CFrame = CFrame.new(shelfPos + Vector3.new(sX, 2.0, 0))
    sSupport.Material = Enum.Material.Wood
    sSupport.Color = Color3.fromRGB(80, 50, 30)
    sSupport.Anchored = true
    sSupport.Parent = shelfModel
end

-- First Aid Kit on middle shelf
local aidBox = Instance.new("Part")
aidBox.Name = "FirstAidBox"
aidBox.Size = Vector3.new(1.6, 1.0, 1.0)
aidBox.CFrame = CFrame.new(shelfPos + Vector3.new(-1.8, 2.6, 0))
aidBox.Material = Enum.Material.SmoothPlastic
aidBox.Color = Color3.fromRGB(240, 240, 240)
aidBox.Anchored = true
aidBox.Parent = shelfModel

-- Red Cross on First Aid Box
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

-- Canned Rations on bottom shelf
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

-- Water bottles / flasks on top shelf
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

-- 6. Wall Trail Map on Back Wall (Centered between bunks and shelves)
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

-- Map SurfaceGui
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

-- 7. Shoe Rack near doorway (Right inside entrance)
local shoeRack = Instance.new("Part")
shoeRack.Name = "ShoeRack"
shoeRack.Size = Vector3.new(3.5, 1.2, 1.4)
shoeRack.CFrame = CFrame.new(-99.5, floorY + 0.6, -1796.5)
shoeRack.Material = Enum.Material.Wood
shoeRack.Color = Color3.fromRGB(90, 60, 35)
shoeRack.Anchored = true
shoeRack.Parent = interior

-- 8. Interactive BedSpots for Sleeping (All 4 Bunk Beds)
local bedsFolder = Instance.new("Folder")
bedsFolder.Name = "BedSpots"
bedsFolder.Parent = interior

local bedRotation = CFrame.fromMatrix(
    Vector3.zero,
    Vector3.new(0, 0, 1),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, -1, 0)
)

local bedConfigs = {
    { name = "Bunk1_Lower", bedPos = Vector3.new(-104.5, 301.6, -1808.5), standPos = Vector3.new(-100.5, 301.4, -1808.5) },
    { name = "Bunk1_Upper", bedPos = Vector3.new(-104.5, 305.2, -1808.5), standPos = Vector3.new(-100.5, 301.4, -1808.5) },
    { name = "Bunk2_Lower", bedPos = Vector3.new(-104.5, 301.6, -1801.5), standPos = Vector3.new(-100.5, 301.4, -1801.5) },
    { name = "Bunk2_Upper", bedPos = Vector3.new(-104.5, 305.2, -1801.5), standPos = Vector3.new(-100.5, 301.4, -1801.5) },
}

local sleepingPlayers = {}

for _, cfg in ipairs(bedConfigs) do
    local spot = Instance.new("Part")
    spot.Name = cfg.name
    spot.Size = Vector3.new(5.0, 0.4, 3.5)
    spot.CFrame = CFrame.new(cfg.bedPos)
    spot.Transparency = 1
    spot.CanCollide = false
    spot.Anchored = true
    spot.Parent = bedsFolder

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SleepPrompt"
    prompt.ActionText = "Tidur"
    prompt.ObjectText = "Tempat Tidur"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 8
    prompt.Parent = spot

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
                root.CFrame = CFrame.new(cfg.standPos) * CFrame.Angles(0, math.pi/2, 0)
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
        root.CFrame = CFrame.new(cfg.bedPos) * bedRotation
        root.Anchored = true

        local wakePrompt = Instance.new("ProximityPrompt")
        wakePrompt.Name = "WakePrompt"
        wakePrompt.ActionText = "Bangun"
        wakePrompt.ObjectText = "Tempat Tidur"
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

return { success = true, items = #interior:GetChildren() }
`;

  console.log('Furnishing Mountain Hut...');
  const res = await executeLuau(code, 'Server');
  console.log('Result:', res.content[0].text);

  // Capture screenshot looking into the hut from outside the doorway
  console.log('Capturing hut doorway view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_hut_doorway.png',
    [-96, 303, -1788],
    [-96, 303, -1805]
  );

  // Also capture interior overview
  console.log('Capturing hut interior overview...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_hut_interior.png',
    [-96, 305, -1798],
    [-96, 302, -1808]
  );
  console.log('Hut screenshots captured!');
}

main().catch(console.error);
