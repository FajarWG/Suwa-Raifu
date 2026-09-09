const { executeLuau } = require('./mcp-exec.js');

async function check() {
  const code = `
local comp = workspace:FindFirstChild("ComparisonTrees")
if not comp then return "none" end
local rep = {}
for _, tree in ipairs(comp:GetChildren()) do
  local leaf = tree:FindFirstChild("Leaf", true)
  if leaf then
    local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
    table.insert(rep, tree.Name .. ":")
    table.insert(rep, "  TextureID=" .. tostring(leaf.TextureID))
    table.insert(rep, "  Color=" .. tostring(leaf.Color))
    table.insert(rep, "  Transparency=" .. tostring(leaf.Transparency))
    table.insert(rep, "  Material=" .. tostring(leaf.Material))
    if sa then
      table.insert(rep, "  SA.ColorMap=" .. tostring(sa.ColorMap))
      table.insert(rep, "  SA.MetalnessMap=" .. tostring(sa.MetalnessMap))
      table.insert(rep, "  SA.NormalMap=" .. tostring(sa.NormalMap))
      table.insert(rep, "  SA.RoughnessMap=" .. tostring(sa.RoughnessMap))
      table.insert(rep, "  SA.AlphaMode=" .. tostring(sa.AlphaMode))
    else
      table.insert(rep, "  NO SurfaceAppearance")
    end
  end
end
return table.concat(rep, "\\n")
`;
  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}
check().catch(console.error);
