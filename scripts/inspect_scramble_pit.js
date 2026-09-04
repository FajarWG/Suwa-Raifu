const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local boulders = {}
local otherParts = {}

for _, c in ipairs(trail:GetChildren()) do
    if c.Name:find("Scramble") or c.Name:find("Boulder") or (c:IsA("BasePart") and (c.Position - Vector3.new(-255, 380, -2055)).Magnitude < 40) then
        table.insert(boulders, {
            name = c.Name,
            className = c.ClassName,
            pos = { c.Position.X, c.Position.Y, c.Position.Z },
            size = { c.Size.X, c.Size.Y, c.Size.Z }
        })
    end
end

-- Raycast down to find the pit floor
local floorHits = {}
for z = -2070, -2030, 5 do
    for x = -265, -245, 5 do
        local r = workspace:Raycast(Vector3.new(x, 390, z), Vector3.new(0, -50, 0))
        if r and (not r.Instance.Name:find("Boulder")) and (not r.Instance.Name:find("Step")) then
            table.insert(floorHits, {
                x = x, z = z,
                hitY = r.Position.Y,
                mat = tostring(r.Material),
                name = r.Instance.Name
            })
        end
    end
end

return {
    parts = boulders,
    floorHits = floorHits
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Also take a screenshot matching Image 3!
  // Looking down at the boulders
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/inspect_scramble_pit.png', [-255, 410, -2030], [-255, 375, -2055]);
  console.log('Saved inspect_scramble_pit.png');
}

main().catch(console.error);
