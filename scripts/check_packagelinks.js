const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, d in ipairs(workspace:GetDescendants()) do
  if d:IsA("PackageLink") then
    table.insert(rep, d:GetFullName())
  end
end
if #rep > 0 then
  return table.concat(rep, "\\n")
else
  return "No PackageLinks found in workspace"
end
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
