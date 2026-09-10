const { executeLuau } = require('./mcp-exec.js');

async function run() {
  const code = `
    local pl = workspace.TownRoadNetwork.TownBlocks:FindFirstChild("McDonaldsParkingLot")
    if not pl then
      pl = Instance.new("Model")
      pl.Name = "McDonaldsParkingLot"
      pl.Parent = workspace.TownRoadNetwork.TownBlocks
    end

    local ASPHALT_COLOR = Color3.fromRGB(35, 36, 38)
    local CURB_COLOR = Color3.fromRGB(180, 180, 175)
    local TOP_Y = 6.06
    local THICKNESS = 2.0
    local POS_Y = TOP_Y - (THICKNESS / 2)

    -- 1. Clear terrain under entire McDonald's block
    workspace.Terrain:FillBlock(
      CFrame.new(-382, 3.5, 68),
      Vector3.new(106, 6, 126),
      Enum.Material.Air
    )

    -- 2. Full Asphalt Lot: X=[-432, -332], Z=[8, 128]
    -- Completely fills the entire block to all four surrounding roads!
    local asphalt = pl:FindFirstChild("AsphaltLot")
    if not asphalt then
      asphalt = Instance.new("Part")
      asphalt.Name = "AsphaltLot"
      asphalt.Parent = pl
    end
    asphalt.Anchored = true
    asphalt.CanCollide = true
    asphalt.Material = Enum.Material.Asphalt
    asphalt.Color = ASPHALT_COLOR
    asphalt.Size = Vector3.new(100, THICKNESS, 120)
    asphalt.Position = Vector3.new(-382, POS_Y, 68)

    -- Clean up redundant side driveway links (now fully covered by main asphalt)
    local westDrive = pl:FindFirstChild("DrivewayLink_West")
    if westDrive then westDrive:Destroy() end
    local eastDrive = pl:FindFirstChild("DrivewayLink_East")
    if eastDrive then eastDrive:Destroy() end

    -- 3. South Main Driveway Link (connecting through sidewalk to Route 50)
    local driveway = pl:FindFirstChild("DrivewayLink")
    if not driveway then
      driveway = Instance.new("Part")
      driveway.Name = "DrivewayLink"
      driveway.Parent = pl
    end
    driveway.Anchored = true
    driveway.CanCollide = true
    driveway.Material = Enum.Material.Asphalt
    driveway.Color = ASPHALT_COLOR
    driveway.Size = Vector3.new(28, THICKNESS, 6)
    driveway.Position = Vector3.new(-380, POS_Y, 5)

    -- 4. Continuous, Airtight Perimeter Curbs (No gaps, no holes)
    for _, name in ipairs({
      "Curb_West_North", "Curb_West_South", "Curb_East_North", "Curb_East_South",
      "Curb_South_Back", "Curb_North_West", "Curb_North_East"
    }) do
      local old = pl:FindFirstChild(name)
      if old then old:Destroy() end
    end

    local function makeCurb(name, size, pos)
      local c = pl:FindFirstChild(name)
      if not c then
        c = Instance.new("Part")
        c.Name = name
        c.Parent = pl
      end
      c.Anchored = true
      c.CanCollide = true
      c.Material = Enum.Material.Concrete
      c.Color = CURB_COLOR
      c.Size = size
      c.Position = pos
      return c
    end

    -- Continuous West curb (120 studs long, no bolongan)
    makeCurb("Curb_West_Perimeter", Vector3.new(0.6, 0.35, 120), Vector3.new(-431.7, 6.18, 68))
    -- Continuous East curb (120 studs long, no bolongan)
    makeCurb("Curb_East_Perimeter", Vector3.new(0.6, 0.35, 120), Vector3.new(-332.3, 6.18, 68))
    -- Continuous South rear curb (100 studs wide along ResAvenue_1 at Z=128)
    makeCurb("Curb_South_Rear", Vector3.new(100, 0.35, 0.6), Vector3.new(-382, 6.18, 127.7))
    -- North sidewalk curbs
    makeCurb("Curb_North_West", Vector3.new(38, 0.4, 0.6), Vector3.new(-413, 6.18, 8.3))
    makeCurb("Curb_North_East", Vector3.new(34, 0.4, 0.6), Vector3.new(-349, 6.18, 8.3))
    makeCurb("Curb_Entrance_Left", Vector3.new(0.6, 0.35, 6), Vector3.new(-394.3, 6.18, 5))
    makeCurb("Curb_Entrance_Right", Vector3.new(0.6, 0.35, 6), Vector3.new(-365.7, 6.18, 5))

    -- 5. Parking Lines & Wheel Stops
    local lineXList = { -420, -408, -396, -384, -372, -360, -348, -336 }
    local existingLines = {}
    for _, p in ipairs(pl:GetChildren()) do
      if p.Name == "ParkingLine" then table.insert(existingLines, p) end
    end
    for i, x in ipairs(lineXList) do
      local p = existingLines[i] or Instance.new("Part")
      p.Name = "ParkingLine"
      p.Anchored = true
      p.CanCollide = false
      p.Material = Enum.Material.SmoothPlastic
      p.Color = Color3.fromRGB(245, 245, 245)
      p.Size = Vector3.new(0.45, 0.04, 14)
      p.Position = Vector3.new(x, TOP_Y + 0.02, 35)
      p.Parent = pl
    end

    local stallCenters = { -414, -402, -390, -378, -366, -354, -342 }
    for _, p in ipairs(pl:GetChildren()) do
      if p.Name:find("WheelStop") then p:Destroy() end
    end
    for i, cx in ipairs(stallCenters) do
      local ws = Instance.new("Part")
      ws.Name = "WheelStop_" .. i
      ws.Anchored = true
      ws.CanCollide = true
      ws.Material = Enum.Material.Concrete
      ws.Color = Color3.fromRGB(235, 195, 30)
      ws.Size = Vector3.new(5.5, 0.35, 0.8)
      ws.Position = Vector3.new(cx, TOP_Y + 0.175, 41)
      ws.Parent = pl
    end

    return "SUCCESS: McDonald's lot 100% full to roads with airtight continuous curbs!"
  `;

  const datamodel = process.argv[2] || 'Server';
  const res = await executeLuau(code, datamodel);
  console.log('Execution result:', res?.content?.[0]?.text);
}

run().catch(console.error);
