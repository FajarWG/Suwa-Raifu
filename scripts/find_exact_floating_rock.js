const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local step
for _, c in ipairs(trail:GetChildren()) do
    if c.Name:find("Step") and (c.Position - Vector3.new(-196.0, 361.9, -1920.0)).Magnitude < 8 then
        step = c
        break
    end
end
local cf = step.CFrame
local camPos = cf.Position - cf.LookVector * 12 + Vector3.new(0, 5, 0)
local targetPos = cf.Position + cf.LookVector * 15 + Vector3.new(0, 6, 0)
local lookDir = (targetPos - camPos).Unit

-- Sample voxels in a cone/box in front of camPos
local t = workspace.Terrain
local nearbyVoxels = {}
local region = Region3.new(camPos - Vector3.new(30, 15, 30), camPos + Vector3.new(30, 30, 30)):ExpandToGrid(4)
local mats, occs = t:ReadVoxels(region, 4)
local size = mats.Size

for x = 1, size.X do
    for y = 1, size.Y do
        for z = 1, size.Z do
            if occs[x][y][z] > 0 then
                local worldPos = region.CFrame.Position - (region.Size / 2) + Vector3.new((x - 0.5) * 4, (y - 0.5) * 4, (z - 0.5) * 4)
                -- check distance to camPos
                local d = (worldPos - camPos).Magnitude
                if d < 40 and worldPos.Y > camPos.Y - 5 then
                    table.insert(nearbyVoxels, {
                        pos = { worldPos.X, worldPos.Y, worldPos.Z },
                        mat = tostring(mats[x][y][z]),
                        occ = occs[x][y][z],
                        dist = d
                    })
                end
            end
        end
    end
end

return {
    camPos = { camPos.X, camPos.Y, camPos.Z },
    targetPos = { targetPos.X, targetPos.Y, targetPos.Z },
    count = #nearbyVoxels,
    voxels = nearbyVoxels
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
