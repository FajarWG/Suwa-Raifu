const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.ShorelineExtensions.ShoreSakura_8
local rep = {}
table.insert(rep, "Tree: " .. tree:GetFullName())

for _, desc in ipairs(tree:GetDescendants()) do
  if desc:IsA("BasePart") then
    local info = string.format(
      "%s [%s] Color=(%.2f, %.2f, %.2f) BrickColor=%s Mat=%s Trans=%.2f",
      desc.Name, desc.ClassName, desc.Color.R, desc.Color.G, desc.Color.B,
      desc.BrickColor.Name, tostring(desc.Material), desc.Transparency
    )
    if desc:IsA("MeshPart") then
      info = info .. " TextureID=" .. tostring(desc.TextureID) .. " MeshId=" .. tostring(desc.MeshId)
    end
    table.insert(rep, info)
    
    for _, child in ipairs(desc:GetChildren()) do
      if child:IsA("SpecialMesh") then
        table.insert(rep, string.format("  -> SpecialMesh MeshId=%s TextureId=%s VertexColor=(%.2f, %.2f, %.2f)",
          child.MeshId, child.TextureId, child.VertexColor.X, child.VertexColor.Y, child.VertexColor.Z))
      elseif child:IsA("SurfaceAppearance") then
        table.insert(rep, string.format("  -> SurfaceAppearance ColorMap=%s AlphaMode=%s",
          tostring(child.ColorMap), tostring(child.AlphaMode)))
      elseif child:IsA("Texture") or child:IsA("Decal") then
        table.insert(rep, string.format("  -> %s [%s] Texture=%s Color3=(%.2f, %.2f, %.2f)",
          child.Name, child.ClassName, child.Texture, child.Color3.R, child.Color3.G, child.Color3.B))
      elseif child:IsA("ParticleEmitter") then
        table.insert(rep, string.format("  -> ParticleEmitter Texture=%s", child.Texture))
      end
    end
  end
end

return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
