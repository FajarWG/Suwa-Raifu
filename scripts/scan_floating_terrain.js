const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local t = workspace.Terrain
-- Scan a region around turn 229
local center = Vector3.new(-196, 365, -1920)
local minBound = center - Vector3.new(40, 40, 40)
local maxBound = center + Vector3.new(40, 40, 40)
local region = Region3.new(minBound, maxBound):ExpandToGrid(4)

local mats, occs = t:ReadVoxels(region, 4)
local size = mats.Size
local voxelCoords = {}

for x = 1, size.X do
    for y = 1, size.Y do
        for z = 1, size.Z do
            if occs[x][y][z] > 0 then
                -- compute world position
                local worldPos = region.CFrame.Position - (region.Size / 2) + Vector3.new((x - 0.5) * 4, (y - 0.5) * 4, (z - 0.5) * 4)
                table.insert(voxelCoords, {
                    x = worldPos.X,
                    y = worldPos.Y,
                    z = worldPos.Z,
                    mat = tostring(mats[x][y][z]),
                    occ = occs[x][y][z]
                })
            end
        end
    end
end

-- Find connected components or isolated clusters of voxels
return {
    totalVoxels = #voxelCoords,
    sampleVoxels = { unpack(voxelCoords, 1, math.min(30, #voxelCoords)) }
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
