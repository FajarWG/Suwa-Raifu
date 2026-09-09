const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local L = game:GetService("Lighting")
local rep = {}
table.insert(rep, string.format("ClockTime=%.2f Brightness=%.2f ExposureCompensation=%.2f",
  L.ClockTime, L.Brightness, L.ExposureCompensation))
table.insert(rep, string.format("Ambient=(%.2f,%.2f,%.2f) OutdoorAmbient=(%.2f,%.2f,%.2f)",
  L.Ambient.R, L.Ambient.G, L.Ambient.B, L.OutdoorAmbient.R, L.OutdoorAmbient.G, L.OutdoorAmbient.B))
table.insert(rep, string.format("ColorShift_Top=(%.2f,%.2f,%.2f) ColorShift_Bottom=(%.2f,%.2f,%.2f)",
  L.ColorShift_Top.R, L.ColorShift_Top.G, L.ColorShift_Top.B, L.ColorShift_Bottom.R, L.ColorShift_Bottom.G, L.ColorShift_Bottom.B))
table.insert(rep, string.format("FogColor=(%.2f,%.2f,%.2f) FogStart=%.1f FogEnd=%.1f",
  L.FogColor.R, L.FogColor.G, L.FogColor.B, L.FogStart, L.FogEnd))

for _, child in ipairs(L:GetChildren()) do
  local info = child.Name .. " [" .. child.ClassName .. "]"
  if child:IsA("ColorCorrectionEffect") then
    info = info .. string.format(" Brightness=%.2f Contrast=%.2f Saturation=%.2f TintColor=(%.2f,%.2f,%.2f) Enabled=%s",
      child.Brightness, child.Contrast, child.Saturation, child.TintColor.R, child.TintColor.G, child.TintColor.B, tostring(child.Enabled))
  elseif child:IsA("Atmosphere") then
    info = info .. string.format(" Density=%.2f Offset=%.2f Color=(%.2f,%.2f,%.2f) Decay=(%.2f,%.2f,%.2f) Glare=%.2f Haze=%.2f",
      child.Density, child.Offset, child.Color.R, child.Color.G, child.Color.B, child.Decay.R, child.Decay.G, child.Decay.B, child.Glare, child.Haze)
  elseif child:IsA("BloomEffect") then
    info = info .. string.format(" Intensity=%.2f Size=%.2f Threshold=%.2f Enabled=%s",
      child.Intensity, child.Size, child.Threshold, tostring(child.Enabled))
  elseif child:IsA("Sky") then
    info = info .. string.format(" SkyboxBk=%s", child.SkyboxBk)
  end
  table.insert(rep, info)
end

return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
