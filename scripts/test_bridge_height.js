const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local terrain = workspace.Terrain
local p1 = Vector3.new(10, 163.6, -1535) -- top bridge deck
local p2 = Vector3.new(4, 163.6, -1607)  -- bottom bridge deck

-- Check terrain height along right side (x = 18)
local heights = {}
for z = -1535, -1607, -10 do
    local ray = Ray.new(Vector3.new(18, 300, z), Vector3.new(0, -250, 0))
    local part, hit = workspace:FindPartOnRay(ray)
    table.insert(heights, { z = z, hitY = hit and hit.Y or nil, part = part and part.Name or "nil" })
end
return heights
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
