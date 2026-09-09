const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, desc in ipairs(game:GetDescendants()) do
  if desc:IsA("Model") and (desc.Name == "Cherry Blossom M" or desc.Name == "Cherry blossom 1" or desc.Name == "pink tree") then
    table.insert(rep, desc:GetFullName())
  end
end
return "Found " .. #rep .. " models:\n" .. table.concat(rep, "\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
