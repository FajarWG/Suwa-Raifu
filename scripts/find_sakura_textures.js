const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
for _, desc in ipairs(game:GetDescendants()) do
  if desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance") or desc:IsA("ParticleEmitter") then
    local name = desc.Name:lower()
    local parentName = desc.Parent and desc.Parent.Name:lower() or ""
    if name:find("sakura") or name:find("cherry") or name:find("petal") or name:find("blossom")
      or parentName:find("sakura") or parentName:find("cherry") or parentName:find("petal") then
      local tex = ""
      if desc:IsA("Decal") or desc:IsA("Texture") then tex = desc.Texture
      elseif desc:IsA("SurfaceAppearance") then tex = tostring(desc.ColorMap)
      elseif desc:IsA("ParticleEmitter") then tex = desc.Texture end
      table.insert(rep, string.format("%s [%s] Texture=%s", desc:GetFullName(), desc.ClassName, tex))
    end
  end
end
return "Found " .. #rep .. " textures:\n" .. table.concat(rep, "\n"):sub(1, 3500)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
