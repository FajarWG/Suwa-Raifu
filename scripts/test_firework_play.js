const { setPlayState, executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('1. Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 7000));

  console.log('2. Triggering upgraded Hanabi show from Server...');
  const triggerCode = `
local sss = game:GetService("ServerScriptService")
local ffs = sss.Server.services.FireworksFestivalService

local console = workspace:FindFirstChild("FestivalFireworksControl")
local base = console and console:FindFirstChild("FireworksConsole")
local prompt = base and base:FindFirstChild("StartFireworksPrompt")

if prompt then
    prompt.HoldDuration = 0
    prompt:InputHoldBegin()
    prompt:InputHoldEnd()
    return "Triggered StartFireworksPrompt successfully!"
end

return "Prompt not found, checking FireworksFestivalService..."
`;
  const sRes = await executeLuau(triggerCode, 'Server');
  console.log('Server result:', sRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 3000));

  console.log('3. Checking active bursts and shells in Workspace...');
  const checkCode = `
local shells = {}
local bursts = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc.Name == "FireworkShell" then
        table.insert(shells, string.format("Shell pos=(%.1f, %.1f, %.1f)", desc.Position.X, desc.Position.Y, desc.Position.Z))
    elseif desc.Name:find("SafeFireworkBurst") then
        table.insert(bursts, desc.Name)
    end
end
return string.format("Active Shells (%d): %s | Active Bursts (%d): %s",
    #shells, table.concat(shells, ", "), #bursts, table.concat(bursts, ", "))
`;
  const cRes = await executeLuau(checkCode, 'Server');
  console.log('Burst status:', cRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 4000));

  const cRes2 = await executeLuau(checkCode, 'Server');
  console.log('Burst status 2:', cRes2.content?.[0]?.text);

  console.log('4. Stopping Play session...');
  await setPlayState(false);
  console.log('Test completed successfully!');
}

main().catch(console.error).finally(() => process.exit(0));
