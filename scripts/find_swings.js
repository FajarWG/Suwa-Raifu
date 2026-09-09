const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, d in ipairs(workspace:GetDescendants()) do
  if d.Name:lower():find("swing") then
    table.insert(rep, d.ClassName .. ": " .. d:GetFullName())
  end
end
return table.concat(rep, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
