const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local Lighting = game:GetService("Lighting")
local rep = {}
table.insert(rep, "ClockTime: " .. tostring(Lighting.ClockTime))
table.insert(rep, "TimeOfDay: " .. tostring(Lighting.TimeOfDay))
table.insert(rep, "OutdoorAmbient: " .. tostring(Lighting.OutdoorAmbient))
table.insert(rep, "Ambient: " .. tostring(Lighting.Ambient))
table.insert(rep, "Brightness: " .. tostring(Lighting.Brightness))
table.insert(rep, "ColorShift_Top: " .. tostring(Lighting.ColorShift_Top))
table.insert(rep, "EnvironmentDiffuseScale: " .. tostring(Lighting.EnvironmentDiffuseScale))
table.insert(rep, "EnvironmentSpecularScale: " .. tostring(Lighting.EnvironmentSpecularScale))


local sky = Lighting:FindFirstChildOfClass("Sky")
if sky then
  table.insert(rep, "Sky: " .. sky.Name .. " SkyboxBk=" .. tostring(sky.SkyboxBk))
end

-- Inspect CreatorStorePreview
local preview = workspace:FindFirstChild("CreatorStorePreview")
if preview then
  for _, d in ipairs(preview:GetDescendants()) do
    if d:IsA("SurfaceAppearance") then
      table.insert(rep, string.format("SA: ColorMap=%s, Metal=%s, Norm=%s, Rough=%s, AlphaMode=%s",
        d.ColorMap, d.MetalnessMap, d.NormalMap, d.RoughnessMap, tostring(d.AlphaMode)))
    elseif d:IsA("MeshPart") then
      table.insert(rep, string.format("MeshPart: %s, Color=%s, TextureID=%s", d.Name, tostring(d.Color), d.TextureID))
    end
  end
end

return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
