const { executeLuau } = require('./mcp-exec.js');

(async () => {
  const code = `
    local seven = workspace.TownRoadNetwork.TownBlocks.Store_7ElevenClean.Model["Seven Eleven"]
    if not seven then return "Seven Eleven not found!" end

    local previousStock = seven:FindFirstChild("ShelfStock")
    if previousStock then
      previousStock:Destroy()
    end

    local stockModel = Instance.new("Model")
    stockModel.Name = "ShelfStock"
    stockModel.Parent = seven

    local function makePart(parent, name, size, cf, color, mat, trans)
      local p = Instance.new("Part")
      p.Name = name
      p.Size = size
      p.CFrame = cf
      p.Color = color
      p.Material = mat or Enum.Material.SmoothPlastic
      p.Transparency = trans or 0
      p.Anchored = true
      p.CanCollide = false
      p.TopSurface = Enum.SurfaceType.Smooth
      p.BottomSurface = Enum.SurfaceType.Smooth
      p.Parent = parent
      return p
    end

    local function makeWedge(parent, name, size, cf, color, mat, trans)
      local p = Instance.new("WedgePart")
      p.Name = name
      p.Size = size
      p.CFrame = cf
      p.Color = color
      p.Material = mat or Enum.Material.SmoothPlastic
      p.Transparency = trans or 0
      p.Anchored = true
      p.CanCollide = false
      p.TopSurface = Enum.SurfaceType.Smooth
      p.BottomSurface = Enum.SurfaceType.Smooth
      p.Parent = parent
      return p
    end

    local count = 0

    -- ==========================================
    -- 1. WINDOW SHELF (Shelf 2)
    -- Lower tier: Y = 9.4, Upper tier: Y = 10.8
    -- ==========================================
    local windowGroup = Instance.new("Model")
    windowGroup.Name = "WindowShelfStock"
    windowGroup.Parent = stockModel

    -- (A) Lower Tier Onigiri (X = 133.2 to 137.5, Y = 9.4)
    for row = 1, 2 do
      local zPos = 38.3 + (row - 1) * 0.7
      for col = 1, 5 do
        local xPos = 133.2 + (col - 1) * 0.85
        makeWedge(windowGroup, "Onigiri", Vector3.new(0.65, 0.65, 0.5),
          CFrame.new(xPos, 9.4 + 0.32, zPos) * CFrame.Angles(0, math.rad(180), 0),
          Color3.fromRGB(248, 248, 245)
        )
        makePart(windowGroup, "Nori", Vector3.new(0.66, 0.32, 0.28),
          CFrame.new(xPos, 9.4 + 0.18, zPos - 0.05),
          Color3.fromRGB(22, 26, 22)
        )
        local stickerCol = (col % 2 == 1) and Color3.fromRGB(215, 45, 45) or Color3.fromRGB(45, 115, 215)
        makePart(windowGroup, "Label", Vector3.new(0.2, 0.2, 0.05),
          CFrame.new(xPos, 9.4 + 0.38, zPos - 0.26),
          stickerCol
        )
        count += 1
      end
    end

    -- (B) Lower Tier Melonpan (X = 138.2 to 141.5, Y = 9.4)
    for row = 1, 2 do
      local zPos = 38.3 + (row - 1) * 0.75
      for col = 1, 4 do
        local xPos = 138.2 + (col - 1) * 0.85
        local bun = makePart(windowGroup, "Melonpan", Vector3.new(0.72, 0.38, 0.72),
          CFrame.new(xPos, 9.4 + 0.2, zPos),
          Color3.fromRGB(238, 198, 120),
          Enum.Material.Sand
        )
        bun.Shape = Enum.PartType.Cylinder
        bun.CFrame = CFrame.new(xPos, 9.4 + 0.2, zPos) * CFrame.Angles(0, 0, math.rad(90))
        count += 1
      end
    end

    -- (C) Lower Tier Pocky Boxes (X = 142.3 to 145.2, Y = 9.4)
    for col = 1, 5 do
      local xPos = 142.3 + (col - 1) * 0.65
      makePart(windowGroup, "PockyBox", Vector3.new(0.55, 0.95, 0.3),
        CFrame.new(xPos, 9.4 + 0.48, 38.5) * CFrame.Angles(math.rad(-10), math.rad(15 * (col % 3 - 1)), 0),
        Color3.fromRGB(205, 28, 28)
      )
      makePart(windowGroup, "PockyTop", Vector3.new(0.56, 0.28, 0.31),
        CFrame.new(xPos, 9.4 + 0.82, 38.5) * CFrame.Angles(math.rad(-10), math.rad(15 * (col % 3 - 1)), 0),
        Color3.fromRGB(75, 42, 22)
      )
      count += 1
    end

    -- (D) Lower Tier Chips & Snack Bags (X = 145.8 to 149.0, Y = 9.4)
    local bagColors = {
      Color3.fromRGB(235, 195, 35),
      Color3.fromRGB(45, 150, 65),
      Color3.fromRGB(220, 50, 40),
      Color3.fromRGB(230, 115, 25),
      Color3.fromRGB(40, 110, 205),
    }
    for col = 1, 5 do
      local xPos = 145.8 + (col - 1) * 0.65
      makePart(windowGroup, "SnackBag", Vector3.new(0.65, 0.95, 0.4),
        CFrame.new(xPos, 9.4 + 0.48, 38.6) * CFrame.Angles(math.rad(-12), math.rad(10 * (col % 3 - 1)), 0),
        bagColors[col]
      )
      count += 1
    end

    -- (E) Upper Tier Window Shelf (Y = 11.2, X = 133 to 148, Z = 38.2)
    for col = 1, 12 do
      local xPos = 134.0 + (col - 1) * 1.15
      local bCol = bagColors[(col % #bagColors) + 1]
      makePart(windowGroup, "UpperSnack", Vector3.new(0.55, 0.85, 0.35),
        CFrame.new(xPos, 11.2 + 0.43, 38.2) * CFrame.Angles(math.rad(-10), math.rad(12 * (col % 3 - 1)), 0),
        bCol
      )
      count += 1
    end

    -- ==========================================
    -- 2. WALL SHELF (Shelf) -> Bento, Meals, Sandwiches
    -- ==========================================
    local bentoGroup = Instance.new("Model")
    bentoGroup.Name = "BentoShelfStock"
    bentoGroup.Parent = stockModel

    -- (A) Bento Boxes Lower Tier (Under Coca-Cola, X = 102.5 to 110, Z = 38.7, Y = 9.4)
    for col = 1, 5 do
      local xPos = 102.5 + (col - 1) * 1.55
      for row = 1, 2 do
        local zPos = 38.2 + (row - 1) * 0.9
        makePart(bentoGroup, "BentoTray", Vector3.new(1.35, 0.22, 0.82),
          CFrame.new(xPos, 9.4 + 0.11, zPos),
          Color3.fromRGB(28, 28, 30)
        )
        makePart(bentoGroup, "BentoLid", Vector3.new(1.36, 0.15, 0.83),
          CFrame.new(xPos, 9.4 + 0.28, zPos),
          Color3.fromRGB(245, 250, 255),
          Enum.Material.Glass,
          0.6
        )
        makePart(bentoGroup, "Rice", Vector3.new(0.55, 0.12, 0.68),
          CFrame.new(xPos - 0.32, 9.4 + 0.2, zPos),
          Color3.fromRGB(250, 250, 248)
        )
        makePart(bentoGroup, "Ume", Vector3.new(0.12, 0.14, 0.12),
          CFrame.new(xPos - 0.32, 9.4 + 0.24, zPos),
          Color3.fromRGB(200, 35, 35)
        )
        makePart(bentoGroup, "Katsu", Vector3.new(0.55, 0.14, 0.68),
          CFrame.new(xPos + 0.32, 9.4 + 0.21, zPos),
          Color3.fromRGB(165, 100, 35)
        )
        count += 1
      end
    end

    -- (B) Upper Tier Bento & Meal Trays (Under Coca-Cola, Y = 11.2, X = 102.5 to 110, Z = 38.2)
    for col = 1, 5 do
      local xPos = 102.8 + (col - 1) * 1.55
      makePart(bentoGroup, "UpperBento", Vector3.new(1.3, 0.25, 0.75),
        CFrame.new(xPos, 11.2 + 0.13, 38.2),
        Color3.fromRGB(30, 32, 34)
      )
      makePart(bentoGroup, "UpperLid", Vector3.new(1.32, 0.12, 0.76),
        CFrame.new(xPos, 11.2 + 0.25, 38.2),
        Color3.fromRGB(245, 250, 255),
        Enum.Material.Glass,
        0.55
      )
      makePart(bentoGroup, "UpperCurry", Vector3.new(1.2, 0.1, 0.65),
        CFrame.new(xPos, 11.2 + 0.18, 38.2),
        Color3.fromRGB(175, 105, 35)
      )
      count += 1
    end

    -- (C) Sandwiches (X = 101.5, Z = 42 to 49, Y = 9.4)
    for i = 1, 7 do
      local zPos = 42.5 + (i - 1) * 0.95
      makeWedge(bentoGroup, "Sandwich", Vector3.new(0.65, 0.75, 0.65),
        CFrame.new(101.4, 9.4 + 0.38, zPos) * CFrame.Angles(0, math.rad(90), 0),
        Color3.fromRGB(252, 252, 248)
      )
      makePart(bentoGroup, "EggFilling", Vector3.new(0.12, 0.65, 0.45),
        CFrame.new(101.6, 9.4 + 0.35, zPos),
        Color3.fromRGB(248, 218, 55)
      )
      makePart(bentoGroup, "Lettuce", Vector3.new(0.12, 0.65, 0.15),
        CFrame.new(101.6, 9.4 + 0.35, zPos + 0.18),
        Color3.fromRGB(55, 150, 60)
      )
      count += 1
    end

    -- (D) Nanachiki & Hot Chicken Warmer Boxes (X = 101.5, Z = 50 to 56, Y = 9.4)
    for i = 1, 5 do
      local zPos = 50.5 + (i - 1) * 1.1
      makePart(bentoGroup, "ChickenPouch", Vector3.new(0.55, 0.65, 0.85),
        CFrame.new(101.4, 9.4 + 0.33, zPos),
        Color3.fromRGB(225, 45, 35)
      )
      makePart(bentoGroup, "CrispyChicken", Vector3.new(0.48, 0.45, 0.75),
        CFrame.new(101.4, 9.4 + 0.68, zPos),
        Color3.fromRGB(205, 130, 40),
        Enum.Material.Granite
      )
      count += 1
    end

    -- (E) Cup Noodles Stacks (X = 101.5, Z = 57 to 64, Y = 9.4)
    local cupColors = {
      Color3.fromRGB(225, 40, 40),
      Color3.fromRGB(235, 195, 30),
      Color3.fromRGB(45, 120, 205),
      Color3.fromRGB(50, 160, 75),
    }
    for i = 1, 6 do
      local zPos = 57.5 + (i - 1) * 1.05
      local col = cupColors[(i % #cupColors) + 1]
      local cup = makePart(bentoGroup, "CupRamen", Vector3.new(0.72, 0.78, 0.72),
        CFrame.new(101.4, 9.4 + 0.39, zPos),
        Color3.fromRGB(248, 245, 240)
      )
      cup.Shape = Enum.PartType.Cylinder
      cup.CFrame = CFrame.new(101.4, 9.4 + 0.39, zPos) * CFrame.Angles(0, 0, math.rad(90))
      makePart(bentoGroup, "RamenLid", Vector3.new(0.08, 0.74, 0.74),
        CFrame.new(101.4, 9.4 + 0.78, zPos),
        col
      )
      count += 1
    end

    return "Successfully stocked shelves with " .. tostring(count) .. " items across all tiers!"
  `;
  const res = await executeLuau(code, 'Server');
  console.log(res);
})();
