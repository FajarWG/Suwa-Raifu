const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
if bebeq then
    local sh = bebeq:FindFirstChild("ServerHandler")
    if sh and sh:IsA("Script") then
        sh.Disabled = true
        return "Disabled BebeqFireworkSystem.ServerHandler so it does not conflict with upgraded FireworksFestivalService!"
    end
end
return "No ServerHandler to disable"
`;

  console.log('Disabling conflicting old Bebeq ServerHandler...');
  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
