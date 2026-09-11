const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 6000));

  const testLaunch = `
local sss = game:GetService("ServerScriptService")
local ffsModule = sss.Server.services:FindFirstChild("FireworksFestivalService")
if not ffsModule then return "FFS module not found" end

-- Launch a test shell directly
local battery = workspace:FindFirstChild("FireworksLaunchBattery")
local origin = battery and battery:FindFirstChild("LaunchTube1") and battery.LaunchTube1.Position or Vector3.new(0, 5, -707)

-- Check if we can call a test function or trigger chat
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if player then
    -- Test chat command
    player.Chatted:Fire("/firework")
    return "Fired /firework chat event for player: " .. player.Name
end

return "No player found"
`;

  const sRes = await executeLuau(testLaunch, 'Server');
  console.log('Result:', sRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 2000));

  const check = `
local lines = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc.Name == "FireworkShell" or desc.Name:find("SafeFireworkBurst") or desc.Name == "FanJet" then
        table.insert(lines, string.format("%s at pos=(%.1f, %.1f, %.1f)", desc.Name, desc:GetPivot().Position.X, desc:GetPivot().Position.Y, desc:GetPivot().Position.Z))
    end
end
return "Found " .. #lines .. " active firework objects:\\n" .. table.concat(lines, "\\n")
`;
  const cRes = await executeLuau(check, 'Server');
  console.log(cRes.content?.[0]?.text);

  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
