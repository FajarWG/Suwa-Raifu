const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local sss = game:GetService("ServerScriptService")
local mod = sss.Server.services:FindFirstChild("FireworksFestivalService")
if not mod then return "No FFS module" end

local hasStartShow = string.find(mod.Source, "FireworksFestivalService.startShow") ~= nil
return string.format("mod.Source length: %d | hasStartShow: %s", #mod.Source, tostring(hasStartShow))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
