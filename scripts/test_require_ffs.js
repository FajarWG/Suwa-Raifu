const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local sss = game:GetService("ServerScriptService")
local mod = sss.Server.services:FindFirstChild("FireworksFestivalService")
if not mod then return "No FireworksFestivalService module" end

local ok, err = pcall(require, mod)
return string.format("require result: ok=%s, err=%s", tostring(ok), tostring(err))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
