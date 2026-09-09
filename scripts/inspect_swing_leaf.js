const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.SuwaLakesidePlayground:FindFirstChild("CoupleSwingSakuraTree")
local leaf = tree and tree:FindFirstChild("Leaf", true)
if not leaf then return "no leaf" end

local rep = {}
table.insert(rep, "Leaf.Color = " .. tostring(leaf.Color))
table.insert(rep, "Leaf.TextureID = " .. tostring(leaf.TextureID))
table.insert(rep, "Leaf.Material = " .. tostring(leaf.Material))
table.insert(rep, "Leaf.Transparency = " .. tostring(leaf.Transparency))

for _, ch in ipairs(leaf:GetChildren()) do
  table.insert(rep, "Child: " .. ch.ClassName .. " " .. ch.Name)
  if ch:IsA("SurfaceAppearance") then
    table.insert(rep, string.format("  ColorMap=%s Metal=%s Norm=%s Rough=%s Alpha=%s",
      ch.ColorMap, ch.MetalnessMap, ch.NormalMap, ch.RoughnessMap, tostring(ch.AlphaMode)))
  elseif ch:IsA("Texture") or ch:IsA("Decal") then
    table.insert(rep, string.format("  Texture=%s Color3=%s", ch.Texture, tostring(ch.Color3)))
  end
end
return table.concat(rep, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
