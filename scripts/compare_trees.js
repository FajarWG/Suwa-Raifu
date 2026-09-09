const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local orig = workspace:FindFirstChild("TestOriginalFromStore")
local park = workspace.SuwaLakesidePark.NaturalShorelineDetails.ParkTree7 -- ParkTree7 was not modified by test_parktree6!

local function inspect(m, name)
  local rep = { "=== " .. name .. " ===" }
  for _, desc in ipairs(m:GetDescendants()) do
    if desc:IsA("BasePart") then
      table.insert(rep, string.format("Part: %s [%s] MeshId=%s TextureID=%s Color=%s Mat=%s",
        desc.Name, desc.ClassName,
        desc:IsA("MeshPart") and desc.MeshId or "none",
        desc:IsA("MeshPart") and desc.TextureID or "none",
        tostring(desc.Color), tostring(desc.Material)))
      for _, ch in ipairs(desc:GetChildren()) do
        if ch:IsA("SurfaceAppearance") then
          table.insert(rep, string.format("  SA: ColorMap=%s Metal=%s Normal=%s Rough=%s Alpha=%s",
            tostring(ch.ColorMap), tostring(ch.MetalnessMap), tostring(ch.NormalMap), tostring(ch.RoughnessMap), tostring(ch.AlphaMode)))
        elseif ch:IsA("Texture") then
          table.insert(rep, string.format("  Texture: %s Color3=%s", tostring(ch.Texture), tostring(ch.Color3)))
        end
      end
    end
  end
  return table.concat(rep, "\\n")
end

return inspect(orig, "Original from Creator Store") .. "\\n\\n" .. inspect(park, "ParkTree7 from Workspace")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
