const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
-- Check path along bottom of pit from Z = -2070 to Z = -2030 at X = -248 to -256
local pitHits = {}
for z = -2068, -2030, 4 do
    local r = workspace:Raycast(Vector3.new(-250, 390, z), Vector3.new(0, -60, 0))
    if r then
        table.insert(pitHits, string.format("z=%d: Y=%.1f (%s, mat=%s)", z, r.Position.Y, r.Instance.Name, tostring(r.Material)))
    end
end
return table.concat(pitHits, "\\n")
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
