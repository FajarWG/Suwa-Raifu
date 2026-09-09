const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local center = Vector3.new(-846.0, 27.4, -155.0)
local rep = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("BasePart") and desc.Name == "Leaf" then
    local dist = (desc.Position - center).Magnitude
    if dist < 120 then
      local sa = desc:FindFirstChildOfClass("SurfaceAppearance")
      table.insert(rep, string.format("Dist=%.1f %s Color=(%.2f,%.2f,%.2f) HasSA=%s",
        dist, desc:GetFullName(), desc.Color.R, desc.Color.G, desc.Color.B, tostring(sa ~= nil)))
    end
  end
end
return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
