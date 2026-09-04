const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local camPos = Vector3.new(-257, 353, -2064)
-- The rock is to the left of [-257, 370, -2072] in the sky
-- Let's raycast in a fan towards the left (-X, -Z)
local hits = {}
for angle = -30, 0, 2 do
    for pitch = 0, 30, 2 do
        local radA = math.rad(angle)
        local radP = math.rad(pitch)
        -- base dir is (0, 0.4, -0.9)
        local dir = (CFrame.Angles(radP, radA, 0) * Vector3.new(-0.3, 0.3, -0.9)).Unit * 500
        local r = workspace:Raycast(camPos, dir)
        if r and r.Instance:IsA("Terrain") and r.Material == Enum.Material.Rock then
            -- check if air below it
            local rDown = workspace:Raycast(r.Position - Vector3.new(0, 5, 0), Vector3.new(0, -100, 0))
            if rDown and rDown.Distance > 15 then
                table.insert(hits, {
                    pos = { r.Position.X, r.Position.Y, r.Position.Z },
                    dist = r.Distance,
                    drop = rDown.Distance,
                    groundMat = tostring(rDown.Material)
                })
            end
        end
    end
end
return hits
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
