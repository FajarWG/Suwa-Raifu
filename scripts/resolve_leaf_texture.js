const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local insert = game:GetService("InsertService")
local s, m = pcall(function()
  return insert:LoadAsset(4668043207)
end)
if s and m then
  local rep = {}
  for _, d in ipairs(m:GetDescendants()) do
    table.insert(rep, d.ClassName .. ": " .. d.Name)
    if d:IsA("Decal") then
      table.insert(rep, "  Texture = " .. tostring(d.Texture))
    end
  end
  m:Destroy()
  return table.concat(rep, "\\n")
else
  return "Error: " .. tostring(m)
end
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
