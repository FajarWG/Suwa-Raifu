const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local terrain = workspace.Terrain
local trail = workspace.SuwaMountainTrail

-- 1. Fill solid rock block covering the entire rocky pass
-- From (-135, 335, -1865) to (-185, 365, -1905)
-- We will fill consecutive overlapping blocks following the staircase
local steps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local p = c.Position
        if p.Z <= -1865 and p.Z >= -1905 and p.X < -130 and p.X > -185 then
            table.insert(steps, p)
        end
    end
end
table.sort(steps, function(a,b) return a.Z > b.Z end)

-- Solid massive rock covering each step from 6 studs up to 25 studs high, width 22 studs
for i = 1, #steps do
    local p = steps[i]
    local rockCenter = p + Vector3.new(0, 15, 0)
    terrain:FillBlock(CFrame.new(rockCenter), Vector3.new(22, 18, 6), Enum.Material.Rock)
end

-- 2. Carve a clean, spacious walking tunnel corridor: width 10, height 12 studs directly above steps
for i = 1, #steps do
    local p = steps[i]
    local airCenter = p + Vector3.new(0, 6.5, 0)
    terrain:FillBlock(CFrame.new(airCenter), Vector3.new(10, 11, 5), Enum.Material.Air)
end

-- Clear generous entrance and exit portals
terrain:FillBlock(CFrame.new(-135, 332, -1865), Vector3.new(14, 14, 10), Enum.Material.Air)
terrain:FillBlock(CFrame.new(-178, 356, -1905), Vector3.new(14, 14, 10), Enum.Material.Air)

return { success = true, steps = #steps }
`;

  console.log('Solidifying Rock Tunnel...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot from similar angle as Image 4
  console.log('Capturing solid rock tunnel entrance screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_rock_tunnel_solid.png',
    [-130, 328, -1860],
    [-155, 338, -1885]
  );
  console.log('Solid rock tunnel screenshot captured!');
}

main().catch(console.error);
