const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const content = fs.readFileSync('/Users/mac/code/roblox/Suwa-Raifu/scripts/clean_EmoteSystemClient.lua', 'utf-8');
  
  const code = `
local StarterGui = game:GetService("StarterGui")
local emoteGui = StarterGui:FindFirstChild("EmoteSystemGui")
local clientScript = emoteGui and emoteGui:FindFirstChild("EmoteSystemClient")
if not clientScript then return "EmoteSystemClient not found" end

local newSource = [===[${content}]===]
clientScript.Source = newSource
return "Updated StarterGui.EmoteSystemGui.EmoteSystemClient successfully!"
`;

  console.log('Syncing clean EmoteSystemClient to Studio...');
  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
