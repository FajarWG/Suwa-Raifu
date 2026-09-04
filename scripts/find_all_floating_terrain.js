const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local t = workspace.Terrain
-- Scan the whole mountain trail corridor
-- Trail goes roughly from (0, 50, -1300) to (-500, 750, -2550)
local floatingClusters = {}

-- Sample points along trail
local trail = workspace.SuwaMountainTrail
local checkedRegions = {}

for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" or c.Name == "NarrowLedge" or c.Name:find("Scramble") then
        local p = c.Position
        -- check in a grid around p
        for dx = -40, 40, 20 do
            for dz = -40, 40, 20 do
                local samplePos = Vector3.new(p.X + dx, p.Y + 15, p.Z + dz)
                local key = math.floor(samplePos.X / 16) .. "_" .. math.floor(samplePos.Z / 16)
                if not checkedRegions[key] then
                    checkedRegions[key] = true
                    -- Raycast down to find top surface
                    local rTop = workspace:Raycast(samplePos + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0))
                    if rTop and rTop.Instance:IsA("Terrain") and rTop.Material == Enum.Material.Rock then
                        -- Check if there's air UNDER this hit!
                        local underHit = rTop.Position - Vector3.new(0, 2, 0)
                        -- Raycast down through the rock to see if it ends in mid-air
                        -- We check if voxels below have air
                        local rUnder = workspace:Raycast(underHit - Vector3.new(0, 8, 0), Vector3.new(0, -100, 0))
                        local rAirCheck = workspace:Raycast(underHit, Vector3.new(0, -6, 0))
                        -- Or sample voxels directly
                        local cell = t:WorldToCell(underHit)
                        -- Check voxel 3 cells below
                        local matBelow, occBelow = t:GetCell(cell.X, cell.Y - 2, cell.Z)
                        if occBelow == 0 and rUnder and rUnder.Distance > 10 then
                            table.insert(floatingClusters, {
                                rockPos = { rTop.Position.X, rTop.Position.Y, rTop.Position.Z },
                                dropDist = rUnder.Distance,
                                groundMat = tostring(rUnder.Material),
                                nearStep = c.Name .. " at Y=" .. math.floor(p.Y)
                            })
                        end
                    end
                end
            end
        end
    end
end

return floatingClusters
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
