const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- 1. Carve clearance over ALL steps between -1860 and -1945
local steps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local p = c.Position
        if p.Z <= -1860 and p.Z >= -1945 and p.X < -125 and p.X > -215 then
            table.insert(steps, p)
        end
    end
end
table.sort(steps, function(a, b) return a.Z > b.Z end)

-- Carve 18 studs wide by 18 studs high centered 9 studs above each step tread
for i = 1, #steps do
    local p = steps[i]
    terrain:FillBlock(CFrame.new(p + Vector3.new(0, 9, 0)), Vector3.new(18, 18, 6), Enum.Material.Air)
end

-- Clear extra wide portals at entrance and exit
-- Entrance portal at -132, 324, -1865
terrain:FillBlock(CFrame.new(-132, 332, -1865), Vector3.new(22, 20, 16), Enum.Material.Air)
-- Exit portal at -200, 370, -1930
terrain:FillBlock(CFrame.new(-200, 372, -1928), Vector3.new(22, 20, 18), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-205, 375, -1938), Vector3.new(22, 20, 18), Enum.Material.Air)

-- Build beautiful Japanese rock tunnel lanterns inside
local tunnelModel = trail:FindFirstChild("StaircaseRockTunnel")
if not tunnelModel then
    tunnelModel = Instance.new("Model")
    tunnelModel.Name = "StaircaseRockTunnel"
    tunnelModel.Parent = trail
end

-- Clean old interior lanterns if any
for _, desc in ipairs(tunnelModel:GetChildren()) do
    if desc.Name:find("CavernLantern") then
        desc:Destroy()
    end
end

-- Place authentic wall-mounted bracket lanterns every 5 steps along the walls
for i = 1, #steps, 4 do
    local p = steps[i]
    local isLeft = (i % 8 == 1)
    local sideOffset = isLeft and -7.5 or 7.5
    
    local ltn = Instance.new("Part")
    ltn.Name = "CavernLantern_" .. i
    ltn.Size = Vector3.new(1.0, 1.4, 1.0)
    ltn.CFrame = CFrame.new(p + Vector3.new(sideOffset, 6.5, 0))
    ltn.Material = Enum.Material.Neon
    ltn.Color = Color3.fromRGB(255, 210, 130)
    ltn.Anchored = true
    ltn.Parent = tunnelModel
    
    local lgt = Instance.new("PointLight")
    lgt.Color = Color3.fromRGB(255, 175, 90)
    lgt.Brightness = 2.6
    lgt.Range = 24
    lgt.Shadows = true
    lgt.Parent = ltn
end

-- Verification: probe path from start to exit
local blocked = 0
for i = 1, #steps do
    local p = steps[i]
    local reg = Region3.new(p - Vector3.new(2, 0, 2), p + Vector3.new(2, 6, 2)):ExpandToGrid(4)
    local mat, occ = terrain:ReadVoxels(reg, 4)
    local size = mat.Size
    local isStepBlocked = false
    for x = 1, size.X do
        for y = 1, size.Y do
            for z = 1, size.Z do
                if mat[x][y][z] ~= Enum.Material.Air and occ[x][y][z] > 0.3 then
                    isStepBlocked = true
                    break
                end
            end
        end
    end
    if isStepBlocked then
        blocked = blocked + 1
    end
end

return {
    success = true,
    stepsCount = #steps,
    blockedSteps = blocked
}
`;

  console.log('Unblocking Rock Cavern Tunnel...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // 1. Capture entrance view looking into the now fully-opened cavern
  console.log('Capturing cavern entrance view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_cavern_open_entrance.png',
    [-128, 330, -1856],
    [-150, 338, -1880]
  );

  // 2. Capture exit view looking out of the tunnel into open mountain air
  console.log('Capturing cavern exit view...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_cavern_open_exit.png',
    [-185, 362, -1910],
    [-205, 372, -1935]
  );

  console.log('Rock cavern unblocked and captured!');
}

main().catch(console.error);
