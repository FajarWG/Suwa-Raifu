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
if not step then return "Step not found" end

local cf = step.CFrame
local camPos = cf.Position - cf.LookVector * 12 + Vector3.new(0, 5, 0)
local targetPos = cf.Position + cf.LookVector * 15 + Vector3.new(0, 6, 0)

-- Cast rays in a grid around targetPos from camPos to find the rock
local hits = {}
for dx = -10, 10, 2 do
    for dy = -5, 15, 2 do
        local aim = targetPos + cf.RightVector * dx + Vector3.new(0, dy, 0)
        local dir = (aim - camPos).Unit * 100
        local res = workspace:Raycast(camPos, dir)
        if res and res.Instance:IsA("Terrain") then
            table.insert(hits, {
                hitPos = { res.Position.X, res.Position.Y, res.Position.Z },
                mat = tostring(res.Material),
                dist = res.Distance,
                dx = dx,
                dy = dy
            })
        end
    end
end

return {
    stepPos = tostring(step.Position),
    stepName = step.Name,
    camPos = tostring(camPos),
    hitCount = #hits,
    hits = hits
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
