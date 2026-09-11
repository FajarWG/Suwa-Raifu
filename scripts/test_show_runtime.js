const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 7000));

  const startCode = `
if _G.SuwaFireworks and _G.SuwaFireworks.start then
    _G.SuwaFireworks.start(0)
    return "Started show via _G.SuwaFireworks.start(0)!"
end
return "SuwaFireworks not ready in _G"
`;

  const sRes = await executeLuau(startCode, 'Server');
  console.log('Start result:', sRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 2500));

  const checkCode = `
local shells = {}
local bursts = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc.Name == "FireworkShell" then
        table.insert(shells, string.format("%s pos=(%.1f, %.1f, %.1f)", desc.Name, desc.Position.X, desc.Position.Y, desc.Position.Z))
    elseif desc.Name:find("SafeFireworkBurst") then
        local stars = desc:FindFirstChild("Stars", true)
        local count = stars and stars.Parent and "emitting" or "no emitter"
        table.insert(bursts, string.format("%s (%s) pos=(%.1f, %.1f, %.1f)", desc.Name, count, desc:GetPivot().Position.X, desc:GetPivot().Position.Y, desc:GetPivot().Position.Z))
    end
end
return string.format("Active Shells (%d): %s\\nActive Bursts (%d): %s",
    #shells, table.concat(shells, ", "), #bursts, table.concat(bursts, ", "))
`;

  const cRes = await executeLuau(checkCode, 'Server');
  console.log('Check 1:');
  console.log(cRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 3000));

  const cRes2 = await executeLuau(checkCode, 'Server');
  console.log('Check 2:');
  console.log(cRes2.content?.[0]?.text);

  console.log('Stopping Play session...');
  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
