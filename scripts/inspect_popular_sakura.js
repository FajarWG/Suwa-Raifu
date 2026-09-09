const { executeLuau } = require('./mcp-exec.js');

async function inspectTree() {
  const code = `
local tree = workspace:FindFirstChild("🌸 Sakura Cherry Blossom Spring Tree Realistic")
if not tree then return "not found" end
local rep = {}
for _, d in ipairs(tree:GetDescendants()) do
  if d:IsA("SurfaceAppearance") then
    table.insert(rep, "SA: " .. d:GetFullName() .. " Color=" .. tostring(d.ColorMap) .. " Alpha=" .. tostring(d.AlphaMode) .. " Metal=" .. tostring(d.MetalnessMap))
  elseif d:IsA("MeshPart") then
    table.insert(rep, "MeshPart: " .. d:GetFullName() .. " Texture=" .. tostring(d.TextureID) .. " Color=" .. tostring(d.Color) .. " Mat=" .. tostring(d.Material))
  elseif d:IsA("SpecialMesh") then
    table.insert(rep, "SpecialMesh: " .. d:GetFullName() .. " Texture=" .. tostring(d.TextureId))
  elseif d:IsA("Decal") or d:IsA("Texture") then
    table.insert(rep, d.ClassName .. ": " .. d:GetFullName() .. " Texture=" .. tostring(d.Texture))
  end
end
return table.concat(rep, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}
inspectTree().catch(console.error);
