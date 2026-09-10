const { executeLuau } = require('./mcp-exec.js');

async function run() {
  const code = `
    local la = workspace:FindFirstChild("LanguageAcademy", true)
    if not la then return "LanguageAcademy not found!" end

    local grounds = la:FindFirstChild("SchoolGroundsAndPlaza")
    local land = la:FindFirstChild("SchoolLandscaping")
    if not grounds or not land then return "School containers not found!" end

    local ASPHALT_COLOR = Color3.fromRGB(35, 36, 38)
    local CURB_COLOR = Color3.fromRGB(180, 180, 175)
    local LAWN_COLOR = Color3.fromRGB(60, 130, 50)
    local CONCRETE_COLOR = Color3.fromRGB(200, 200, 195)
    local BASE_TOP_Y = 6.06
    local THICKNESS = 2.0
    local POS_Y = BASE_TOP_Y - (THICKNESS / 2)

    -- 1. Clear all erratic terrain voxels (no mounds, no craters)
    workspace.Terrain:FillBlock(
      CFrame.new(-221.0, 12.0, 68.0),
      Vector3.new(210, 20, 136),
      Enum.Material.Air
    )

    -- 2. Solid Full Base Pad: X=[-320.0, -122.0], Z=[8.0, 128.0]
    -- 100% flat like McDonald's, perfectly filling the school block!
    local basePad = grounds:FindFirstChild("SchoolFullBasePad")
    if not basePad then
      basePad = Instance.new("Part")
      basePad.Name = "SchoolFullBasePad"
      basePad.Parent = grounds
    end
    basePad.Anchored = true
    basePad.CanCollide = true
    basePad.Material = Enum.Material.Concrete
    basePad.Color = CONCRETE_COLOR
    basePad.Size = Vector3.new(198, THICKNESS, 120)
    basePad.Position = Vector3.new(-221.0, POS_Y, 68.0)

    -- 3. Front Plaza & Parking Lot (North)
    local frontPlaza = grounds:FindFirstChild("FrontPlazaAsphalt")
    if frontPlaza then
      frontPlaza.Material = Enum.Material.Asphalt
      frontPlaza.Color = ASPHALT_COLOR
      frontPlaza.Size = Vector3.new(155.2, 0.4, 17.2)
      frontPlaza.Position = Vector3.new(-217.5, BASE_TOP_Y + 0.02, 17.4)
    end

    -- 4. Rear Courtyard Asphalt (South) - Full width from X=-319.2 to -122.8
    local courtyard = grounds:FindFirstChild("RearCourtyardAsphalt")
    if courtyard then
      courtyard.Material = Enum.Material.Asphalt
      courtyard.Color = ASPHALT_COLOR
      courtyard.Size = Vector3.new(196.4, 0.4, 43.6)
      courtyard.Position = Vector3.new(-221.0, BASE_TOP_Y + 0.02, 106.2)
    end

    -- 5. Perimeter Curbs
    local function makeCurb(parent, name, size, pos)
      local c = parent:FindFirstChild(name)
      if not c then
        c = Instance.new("Part")
        c.Name = name
        c.Parent = parent
      end
      c.Anchored = true
      c.CanCollide = true
      c.Material = Enum.Material.Concrete
      c.Color = CURB_COLOR
      c.Size = size
      c.Position = pos
      return c
    end

    makeCurb(land, "Curb_West_Perimeter", Vector3.new(0.8, 0.4, 120), Vector3.new(-319.6, BASE_TOP_Y + 0.2, 68.0))
    makeCurb(land, "Curb_East_Perimeter", Vector3.new(0.8, 0.4, 120), Vector3.new(-122.4, BASE_TOP_Y + 0.2, 68.0))

    local rearCurb = grounds:FindFirstChild("RearCurb")
    if rearCurb then
      rearCurb.Size = Vector3.new(198, 0.4, 0.8)
      rearCurb.Position = Vector3.new(-221.0, BASE_TOP_Y + 0.2, 127.6)
    end

    local frontCurb = grounds:FindFirstChild("FrontCurb")
    if frontCurb then
      frontCurb.Size = Vector3.new(198, 0.4, 0.8)
      frontCurb.Position = Vector3.new(-221.0, BASE_TOP_Y + 0.2, 8.4)
    end

    makeCurb(land, "Curb_West_Lawn_South", Vector3.new(19.6, 0.35, 0.8), Vector3.new(-309.4, BASE_TOP_Y + 0.175, 84.0))
    makeCurb(land, "Curb_West_Lawn_East", Vector3.new(0.8, 0.35, 17.2), Vector3.new(-295.5, BASE_TOP_Y + 0.175, 17.4))
    makeCurb(land, "Curb_East_Lawn_South", Vector3.new(12.6, 0.35, 0.8), Vector3.new(-129.1, BASE_TOP_Y + 0.175, 84.0))
    makeCurb(land, "Curb_East_Lawn_West", Vector3.new(0.8, 0.35, 17.2), Vector3.new(-139.5, BASE_TOP_Y + 0.175, 17.4))

    -- 6. Flat Manicured Lawns
    local function makeLawn(name, size, pos)
      local l = land:FindFirstChild(name)
      if not l then
        l = Instance.new("Part")
        l.Name = name
        l.Parent = land
      end
      l.Anchored = true
      l.CanCollide = true
      l.Material = Enum.Material.Grass
      l.Color = LAWN_COLOR
      l.Size = size
      l.Position = pos
      return l
    end

    makeLawn("WestSideGrassLawn", Vector3.new(19.6, 0.2, 57.6), Vector3.new(-309.4, BASE_TOP_Y + 0.1, 54.8))
    makeLawn("FrontLeftGrassLawn", Vector3.new(23.3, 0.2, 17.2), Vector3.new(-307.55, BASE_TOP_Y + 0.1, 17.4))
    makeLawn("EastSideGrassLawn", Vector3.new(12.6, 0.2, 57.6), Vector3.new(-129.1, BASE_TOP_Y + 0.1, 54.8))
    makeLawn("FrontRightGrassLawn", Vector3.new(16.3, 0.2, 17.2), Vector3.new(-130.95, BASE_TOP_Y + 0.1, 17.4))

    return "SUCCESS: School block fully leveled and sealed with solid base pad, 100% flat like McDonald's!"
  `;

  const datamodel = process.argv[2] || 'Server';
  const res = await executeLuau(code, datamodel);
  console.log('Execution result:', res?.content?.[0]?.text);
}

run().catch(console.error);
