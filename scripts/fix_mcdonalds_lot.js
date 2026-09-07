const { executeLuau } = require('./mcp-exec.js');

async function run() {
  const code = `
    local pl = workspace.TownRoadNetwork.TownBlocks:FindFirstChild("McDonaldsParkingLot")
    if not pl then return "McDonaldsParkingLot not found!" end

    -- 1. Main Asphalt Pad (covering parking lot and drive-thru perimeter)
    local asphalt = pl:FindFirstChild("AsphaltLot")
    if not asphalt then
      asphalt = Instance.new("Part")
      asphalt.Name = "AsphaltLot"
      asphalt.Parent = pl
    end
    asphalt.Anchored = true
    asphalt.CanCollide = true
    asphalt.Size = Vector3.new(102, 0.4, 118)
    asphalt.Position = Vector3.new(-380, 6.08, 64)
    asphalt.Material = Enum.Material.Asphalt
    asphalt.Color = Color3.fromRGB(35, 36, 38)

    -- 2. Driveway Links to surrounding roads
    -- South Main Entrance
    local driveway = pl:FindFirstChild("DrivewayLink")
    if not driveway then
      driveway = Instance.new("Part")
      driveway.Name = "DrivewayLink"
      driveway.Parent = pl
    end
    driveway.Anchored = true
    driveway.CanCollide = true
    driveway.Size = Vector3.new(34, 0.4, 8)
    driveway.Position = Vector3.new(-380, 6.08, 4.5)
    driveway.Material = Enum.Material.Asphalt
    driveway.Color = Color3.fromRGB(35, 36, 38)

    -- West Driveway / Drive-Thru Entrance
    local westDrive = pl:FindFirstChild("DrivewayLink_West")
    if not westDrive then
      westDrive = Instance.new("Part")
      westDrive.Name = "DrivewayLink_West"
      westDrive.Parent = pl
    end
    westDrive.Anchored = true
    westDrive.CanCollide = true
    westDrive.Size = Vector3.new(8, 0.4, 16)
    westDrive.Position = Vector3.new(-433, 6.08, 25)
    westDrive.Material = Enum.Material.Asphalt
    westDrive.Color = Color3.fromRGB(35, 36, 38)

    -- East Drive-Thru Exit
    local eastDrive = pl:FindFirstChild("DrivewayLink_East")
    if not eastDrive then
      eastDrive = Instance.new("Part")
      eastDrive.Name = "DrivewayLink_East"
      eastDrive.Parent = pl
    end
    eastDrive.Anchored = true
    eastDrive.CanCollide = true
    eastDrive.Size = Vector3.new(8, 0.4, 16)
    eastDrive.Position = Vector3.new(-327, 6.08, 85)
    eastDrive.Material = Enum.Material.Asphalt
    eastDrive.Color = Color3.fromRGB(35, 36, 38)

    -- 3. Parking Lines (crisp white stripes sitting on asphalt)
    local lineXList = { -420, -408, -396, -384, -372, -360, -348, -336 }
    local existingLines = {}
    for _, p in ipairs(pl:GetChildren()) do
      if p.Name == "ParkingLine" then
        table.insert(existingLines, p)
      end
    end

    for i, x in ipairs(lineXList) do
      local p = existingLines[i]
      if not p then
        p = Instance.new("Part")
        p.Name = "ParkingLine"
        p.Parent = pl
      end
      p.Anchored = true
      p.CanCollide = false
      p.Material = Enum.Material.SmoothPlastic
      p.Color = Color3.fromRGB(245, 245, 245)
      p.Size = Vector3.new(0.45, 0.04, 14)
      p.Position = Vector3.new(x, 6.29, 35)
    end

    -- 4. Yellow Wheel Stops for each parking stall
    -- Clear previous wheel stops
    for _, p in ipairs(pl:GetChildren()) do
      if p.Name:find("WheelStop") then p:Destroy() end
    end

    local stallCenters = { -414, -402, -390, -378, -366, -354, -342 }
    for i, cx in ipairs(stallCenters) do
      local ws = Instance.new("Part")
      ws.Name = "WheelStop_" .. i
      ws.Anchored = true
      ws.CanCollide = true
      ws.Material = Enum.Material.Concrete
      ws.Color = Color3.fromRGB(235, 195, 30)
      ws.Size = Vector3.new(5.5, 0.38, 0.8)
      ws.Position = Vector3.new(cx, 6.45, 41)
      ws.Parent = pl
    end

    return "SUCCESS: McDonald's asphalt lot and drive-thru fully paved and configured!"
  `;

  const res = await executeLuau(code, 'Edit');
  console.log('Execution result:', res);
}

run().catch(console.error);
