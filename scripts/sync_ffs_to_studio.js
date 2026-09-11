const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const diskCode = fs.readFileSync('/Users/mac/code/roblox/Suwa-Raifu/src/server/services/FireworksFestivalService.lua', 'utf-8');
  console.log('Disk code length:', diskCode.length);

  // We can write it via chunks or a script in Studio
  // To avoid string escape issues with 45KB in executeLuau string literal, write to a temp file or chunk it
  const chunkSize = 8000;
  const chunks = [];
  for (let i = 0; i < diskCode.length; i += chunkSize) {
    chunks.push(diskCode.slice(i, i + chunkSize));
  }
  console.log(`Sending ${chunks.length} chunks to Studio...`);

  // Clear or reset temp holder
  await executeLuau(`_G.__codeChunks = {}`, 'Edit');

  for (let i = 0; i < chunks.length; i++) {
    const chunkStr = JSON.stringify(chunks[i]);
    await executeLuau(`table.insert(_G.__codeChunks, ${chunkStr})`, 'Edit');
  }

  const finalizeCode = `
local sss = game:GetService("ServerScriptService")
local mod = sss.Server.services:FindFirstChild("FireworksFestivalService")
if not mod then return "No FFS module in ServerScriptService" end

local fullCode = table.concat(_G.__codeChunks, "")
_G.__codeChunks = nil
mod.Source = fullCode
return "Successfully synced upgraded FireworksFestivalService to Studio! Length: " .. #mod.Source
`;

  const res = await executeLuau(finalizeCode, 'Edit');
  console.log('Result:', res.content?.[0]?.text);
}

main().catch(console.error).finally(() => process.exit(0));
