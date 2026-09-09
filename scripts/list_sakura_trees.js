const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trees = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("MeshPart") and desc.MeshId:find("5547037928") then
    table.insert(trees, desc:GetFullName())
  end
end
return "Found " .. #trees .. " sakura leaf MeshParts:\\n" .. table.concat(trees, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
