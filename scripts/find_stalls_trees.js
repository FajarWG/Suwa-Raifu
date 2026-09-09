const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local center = Vector3.new(5.0, 8.6, -112.0)
local rep = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("Model") and (desc.Name:find("Sakura") or desc.Name:find("Cherry") or desc.Name:find("ParkTree")) then
    local cf, sz = desc:GetBoundingBox()
    local dist = (cf.Position - center).Magnitude
    if dist < 200 then
      table.insert(rep, string.format("Dist=%.1f %s pos=(%.1f,%.1f,%.1f)", dist, desc:GetFullName(), cf.Position.X, cf.Position.Y, cf.Position.Z))
    end
  end
end
return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
