const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("Model") and (desc.Name:lower():find("sakura") or desc.Name:lower():find("cherry") or desc.Name:lower():find("blossom")) then
    local leaf = desc:FindFirstChild("Leaf", true) or desc:FindFirstChild("Leaves", true) or desc:FindFirstChild("Foliage", true)
    if leaf and leaf:IsA("BasePart") then
      local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
      local sm = leaf:FindFirstChildOfClass("SpecialMesh")
      table.insert(rep, string.format("%s -> LeafClass=%s Color=(%.2f,%.2f,%.2f) Brick=%s SA=%s SA_ColorMap=%s TextureID=%s",
        desc:GetFullName(),
        leaf.ClassName,
        leaf.Color.R, leaf.Color.G, leaf.Color.B,
        leaf.BrickColor.Name,
        sa and sa.Name or "none",
        sa and tostring(sa.ColorMap) or "none",
        leaf:IsA("MeshPart") and tostring(leaf.TextureID) or (sm and tostring(sm.TextureId) or "none")
      ))
    end
  end
end
return "Total: " .. #rep .. "\\n" .. table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
