const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.SuwaLakesidePlayground:FindFirstChild("CoupleSwingSakuraTree")
if not tree then return "CoupleSwingSakuraTree not found" end

local rep = {}
table.insert(rep, "FullName: " .. tree:GetFullName())
for _, d in ipairs(tree:GetDescendants()) do
  if d:IsA("MeshPart") then
    table.insert(rep, string.format("MeshPart: %s | MeshId=%s | TextureID=%s | Color=%s | Mat=%s | Transp=%.2f",
      d.Name, d.MeshId, d.TextureID, tostring(d.Color), tostring(d.Material), d.Transparency))
  elseif d:IsA("SurfaceAppearance") then
    table.insert(rep, string.format("SurfaceAppearance: %s | Color=%s | Metal=%s | Norm=%s | Rough=%s | Alpha=%s",
      d:GetFullName(), d.ColorMap, d.MetalnessMap, d.NormalMap, d.RoughnessMap, tostring(d.AlphaMode)))
  elseif d:IsA("SpecialMesh") then
    table.insert(rep, string.format("SpecialMesh: %s | MeshId=%s | TextureId=%s", d.Name, d.MeshId, d.TextureId))
  elseif d:IsA("Texture") or d:IsA("Decal") then
    table.insert(rep, string.format("%s: %s | Texture=%s | Color3=%s", d.ClassName, d.Name, d.Texture, tostring(d.Color3)))
  end
end
return table.concat(rep, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
