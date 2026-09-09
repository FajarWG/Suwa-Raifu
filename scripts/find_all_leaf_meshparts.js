const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local count = 0
local rep = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("MeshPart") and (desc.MeshId:find("5547037928") or desc.Name == "Leaf") then
    count = count + 1
    table.insert(rep, desc:GetFullName())
  end
end
return "Found " .. count .. " sakura leaf MeshParts:\\n" .. table.concat(rep, "\\n"):sub(1, 3500)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
