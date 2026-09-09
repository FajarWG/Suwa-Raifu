const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  local nameLower = string.lower(desc.Name)
  if string.find(nameLower, "sakura") or string.find(nameLower, "cherry") or string.find(nameLower, "blossom") then
    table.insert(rep, desc:GetFullName() .. " [" .. desc.ClassName .. "]")
    if #rep >= 40 then break end
  end
end
return "Found " .. tostring(#rep) .. " items:\\n" .. table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
