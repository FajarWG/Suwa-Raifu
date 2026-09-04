const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local t = workspace.Terrain
local center = Vector3.new(-196.5, 371.0, -1926.8)
local region = Region3.new(center - Vector3.new(8, 8, 8), center + Vector3.new(8, 8, 8)):ExpandToGrid(4)
local mats, occs = t:ReadVoxels(region, 4)
local s = mats.Size
local res = {}
for x = 1, s.X do
    for y = 1, s.Y do
        for z = 1, s.Z do
            if occs[x][y][z] > 0 then
                local wp = region.CFrame.Position - (region.Size / 2) + Vector3.new((x - 0.5) * 4, (y - 0.5) * 4, (z - 0.5) * 4)
                table.insert(res, string.format("pos=(%.1f, %.1f, %.1f) mat=%s occ=%.2f", wp.X, wp.Y, wp.Z, tostring(mats[x][y][z]), occs[x][y][z]))
            end
        end
    end
end
return table.concat(res, "\\n")
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
