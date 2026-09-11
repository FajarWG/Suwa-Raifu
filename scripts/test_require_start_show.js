const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('1. Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 6000));

  console.log('2. Requiring service and calling startShow(0)...');
  const startCode = `
local sss = game:GetService("ServerScriptService")
local mod = sss.Server.services:FindFirstChild("FireworksFestivalService")
if not mod then return "No FFS module" end

local service = require(mod)
if service.startShow then
    service.startShow(0)
    return "Called service.startShow(0) successfully!"
else
    return "service.startShow is nil! Keys: " .. table.concat(table.keys(service), ", ")
end
`;

  const sRes = await executeLuau(startCode, 'Server');
  console.log('Start result:', sRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 2000));

  console.log('3. Checking active shells and bursts in workspace...');
  const checkCode = `
local shells = {}
local bursts = {}
local fanJets = {}

for _, desc in ipairs(workspace:GetDescendants()) do
    if desc.Name == "FireworkShell" then
        table.insert(shells, string.format("pos=(%.1f, %.1f, %.1f)", desc.Position.X, desc.Position.Y, desc.Position.Z))
    elseif desc.Name:find("SafeFireworkBurst") then
        local stars = desc:FindFirstChild("Stars", true)
        table.insert(bursts, string.format("%s pos=(%.1f, %.1f, %.1f)", desc.Name, desc:GetPivot().Position.X, desc:GetPivot().Position.Y, desc:GetPivot().Position.Z))
    elseif desc.Name == "FanJet" then
        table.insert(fanJets, string.format("pos=(%.1f, %.1f, %.1f)", desc.Position.X, desc.Position.Y, desc.Position.Z))
    end
end

return string.format("Active Shells (%d): %s\\nActive Bursts (%d): %s\\nActive FanJets (%d): %s",
    #shells, table.concat(shells, ", "), #bursts, table.concat(bursts, ", "), #fanJets, table.concat(fanJets, ", "))
`;

  const cRes = await executeLuau(checkCode, 'Server');
  console.log('Check at +2s:');
  console.log(cRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 2500));

  const cRes2 = await executeLuau(checkCode, 'Server');
  console.log('Check at +4.5s:');
  console.log(cRes2.content?.[0]?.text);

  console.log('4. Stopping Play session...');
  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
