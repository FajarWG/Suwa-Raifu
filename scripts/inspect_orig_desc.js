const { executeLuau } = require('./mcp-exec.js');

async function inspectOriginal() {
  const code = `
local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "none" end
local rep = {}
for _, d in ipairs(orig:GetDescendants()) do
  table.insert(rep, d.ClassName .. ": " .. d:GetFullName())
  if d:IsA("Texture") or d:IsA("Decal") then
    table.insert(rep, "  Texture=" .. tostring(d.Texture) .. " Face=" .. tostring(d.Face) .. " Color3=" .. tostring(d.Color3))
  end
end
return table.concat(rep, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}
inspectOriginal().catch(console.error);
