const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("Model") and (desc.Name:find("Sakura") or desc.Name:find("Cherry")) then
    local cf, sz = desc:GetBoundingBox()
    -- Look for benches nearby
    for _, obj in ipairs(workspace:GetDescendants()) do
      if obj:IsA("Model") and (obj.Name:lower():find("bench") or obj.Name:lower():find("stall") or obj.Name:lower():find("yatai")) then
        local ocf = obj:GetBoundingBox()
        if (cf.Position - ocf.Position).Magnitude < 25 then
          table.insert(rep, string.format("Tree %s pos=(%.1f,%.1f,%.1f) near %s pos=(%.1f,%.1f,%.1f)",
            desc:GetFullName(), cf.Position.X, cf.Position.Y, cf.Position.Z,
            obj.Name, ocf.Position.X, ocf.Position.Y, ocf.Position.Z))
          break
        end
      end
    end
  end
end
return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
