const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rs = game:GetService("ReplicatedStorage")
local sss = game:GetService("ServerScriptService")

local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
local ffs = sss:FindFirstChild("Server") and sss.Server:FindFirstChild("services") and sss.Server.services:FindFirstChild("FireworksFestivalService")

return string.format("Bebeq exists: %s | FFS exists: %s | LaunchBattery exists: %s",
    tostring(bebeq ~= nil), tostring(ffs ~= nil), tostring(workspace:FindFirstChild("FireworksLaunchBattery") ~= nil))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
