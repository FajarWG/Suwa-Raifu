const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local res = { bridges = {}, fire = {} }
for _, c in ipairs(trail:GetChildren()) do
    local n = c.Name:lower()
    if n:find("bridge") or n:find("ramp") or n:find("beam") then
        table.insert(res.bridges, { name = c.Name, pos = tostring(c.Position), size = tostring(c.Size) })
    elseif n:find("fire") then
        table.insert(res.fire, { name = c.Name, pos = tostring(c.Position), size = tostring(c.Size) })
    end
end
return res
`;
  const r = await executeLuau(code);
  console.log(r.content[0].text);
}

main().catch(console.error);
