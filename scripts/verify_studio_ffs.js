const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local sss = game:GetService("ServerScriptService")
local mod = sss.Server.services:FindFirstChild("FireworksFestivalService")
if not mod then return "No FFS module" end

local hasStartShow = string.find(mod.Source, "FireworksFestivalService.startShow") ~= nil
local hasNewApex = string.find(mod.Source, "apexLow = 290") ~= nil
local hasFacingCam = string.find(mod.Source, "Enum.ParticleOrientation.FacingCamera") ~= nil

return string.format("FFS in Studio:\\n- Length: %d\\n- hasStartShow: %s\\n- hasNewApex (290): %s\\n- hasFacingCam: %s",
    #mod.Source, tostring(hasStartShow), tostring(hasNewApex), tostring(hasFacingCam))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
