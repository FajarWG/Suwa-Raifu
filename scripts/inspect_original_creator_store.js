const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local m = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not m then return "OriginalCherryBlossomM not found in ReplicatedStorage" end

local rep = {}
table.insert(rep, "Inspecting Original Model from Creator Store: " .. m:GetFullName())

for _, desc in ipairs(m:GetDescendants()) do
  if desc:IsA("BasePart") then
    local info = string.format("%s [%s] Color=(%.2f,%.2f,%.2f) Brick=%s Mat=%s Trans=%.2f DoubleSided=%s CastShadow=%s",
      desc.Name, desc.ClassName, desc.Color.R, desc.Color.G, desc.Color.B,
      desc.BrickColor.Name, tostring(desc.Material), desc.Transparency,
      tostring(desc:IsA("MeshPart") and desc.DoubleSided or false),
      tostring(desc.CastShadow)
    )
    if desc:IsA("MeshPart") then
      info = info .. " MeshId=" .. tostring(desc.MeshId) .. " TextureID=" .. tostring(desc.TextureID)
    end
    table.insert(rep, info)

    for _, ch in ipairs(desc:GetChildren()) do
      if ch:IsA("SurfaceAppearance") then
        table.insert(rep, string.format("  -> SurfaceAppearance Name=%s ColorMap=%s MetalnessMap=%s NormalMap=%s RoughnessMap=%s AlphaMode=%s",
          ch.Name, tostring(ch.ColorMap), tostring(ch.MetalnessMap), tostring(ch.NormalMap), tostring(ch.RoughnessMap), tostring(ch.AlphaMode)))
      elseif ch:IsA("SpecialMesh") then
        table.insert(rep, string.format("  -> SpecialMesh MeshId=%s TextureId=%s VertexColor=(%.2f,%.2f,%.2f)",
          ch.MeshId, ch.TextureId, ch.VertexColor.X, ch.VertexColor.Y, ch.VertexColor.Z))
      elseif ch:IsA("Texture") or ch:IsA("Decal") then
        table.insert(rep, string.format("  -> %s Texture=%s Color3=(%.2f,%.2f,%.2f)", ch.ClassName, ch.Texture, ch.Color3.R, ch.Color3.G, ch.Color3.B))
      elseif ch:IsA("ParticleEmitter") then
        table.insert(rep, string.format("  -> ParticleEmitter Texture=%s Color=%s", ch.Texture, tostring(ch.Color)))
      end
    end
  elseif desc:IsA("Script") or desc:IsA("LocalScript") then
    table.insert(rep, string.format("SCRIPT: %s [%s] Enabled=%s SourceLen=%d", desc:GetFullName(), desc.ClassName, tostring(desc.Enabled), #desc.Source))
  end
end

return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
