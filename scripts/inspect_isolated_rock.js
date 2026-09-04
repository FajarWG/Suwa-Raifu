const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local t = workspace.Terrain
local center = Vector3.new(-127, 376, -1867)
local region = Region3.new(center - Vector3.new(20, 20, 20), center + Vector3.new(20, 20, 20)):ExpandToGrid(4)
local mats, occs = t:ReadVoxels(region, 4)
local size = mats.Size

local totalOcc = 0
local count = 0
local minY, maxY = 9999, -9999
local minX, maxX = 9999, -9999
local minZ, maxZ = 9999, -9999

for x = 1, size.X do
    for y = 1, size.Y do
        for z = 1, size.Z do
            if occs[x][y][z] > 0 then
                count = count + 1
                totalOcc = totalOcc + occs[x][y][z]
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

-- Also raycast straight down from the bottom of this rock to see where the ground is!
local rDown = workspace:Raycast(Vector3.new(-127, minY - 1, -1867), Vector3.new(0, -200, 0))

return {
    voxelCount = count,
    bounds = { minX = minX, maxX = maxX, minY = minY, maxY = maxY, minZ = minZ, maxZ = maxZ },
    groundBelow = rDown and {
        hitPos = { rDown.Position.X, rDown.Position.Y, rDown.Position.Z },
        mat = tostring(rDown.Material),
        instance = rDown.Instance:GetFullName(),
        dropDistance = (minY - rDown.Position.Y)
    } or "no ground found"
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
