const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local ramps = {}
for _, c in ipairs(trail:GetChildren()) do
    local n = c.Name:lower()
    if n:find("bridge") or n:find("ramp") or n:find("beam") or n:find("boardwalk") or n:find("incline") then
        local cf = c:IsA("BasePart") and c.Position or (c:IsA("Model") and c:GetPivot().Position or nil)
        local sz = c:IsA("BasePart") and c.Size or (c:IsA("Model") and c:GetExtentsSize() or nil)
        table.insert(ramps, { name = c.Name, pos = tostring(cf), size = tostring(sz), rot = c:IsA("BasePart") and tostring(c.Orientation) or nil })
    end
end
return ramps
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
