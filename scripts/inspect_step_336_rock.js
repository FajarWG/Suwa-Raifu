const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local t = workspace.Terrain
local center = Vector3.new(-308, 569, -2260)
local region = Region3.new(center - Vector3.new(25, 25, 25), center + Vector3.new(25, 25, 25)):ExpandToGrid(4)
local mats, occs = t:ReadVoxels(region, 4)
local s = mats.Size

local count = 0
local minY, maxY = 9999, -9999
local minX, maxX = 9999, -9999
local minZ, maxZ = 9999, -9999

for x = 1, s.X do
    for y = 1, s.Y do
        for z = 1, s.Z do
            if occs[x][y][z] > 0 then
                count = count + 1
                local wp = region.CFrame.Position - (region.Size / 2) + Vector3.new((x - 0.5) * 4, (y - 0.5) * 4, (z - 0.5) * 4)
                if wp.Y < minY then minY = wp.Y end
                if wp.Y > maxY then maxY = wp.Y end
                if wp.X < minX then minX = wp.X end
                if wp.X > maxX then maxX = wp.X end
                if wp.Z < minZ then minZ = wp.Z end
                if wp.Z > maxZ then maxZ = wp.Z end
            end
        end
    end
end

-- Find nearest trail step
local trail = workspace.SuwaMountainTrail
local nearSteps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name:find("Step") then
        local d = (c.Position - center).Magnitude
        if d < 60 then
            table.insert(nearSteps, { name = c.Name, pos = tostring(c.Position), dist = d })
        end
    end
end

return {
    voxelCount = count,
    bounds = { minX = minX, maxX = maxX, minY = minY, maxY = maxY, minZ = minZ, maxZ = maxZ },
    nearSteps = nearSteps
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Take screenshot from step 336 looking at this rock!
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/inspect_rock_step_336.png', [-322, 545, -2255], [-308, 565, -2260]);
  console.log('Saved inspect_rock_step_336.png');
}

main().catch(console.error);
