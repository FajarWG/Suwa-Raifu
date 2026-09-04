const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

async function run() {
  const newConfigSrc = fs.readFileSync('scripts/scratch_BebeqMusicConfig.lua', 'utf-8');
  const newClientSrc = fs.readFileSync('scripts/scratch_BebeqMusicClient.lua', 'utf-8');

  console.log('Read config length:', newConfigSrc.length);
  console.log('Read client length:', newClientSrc.length);

  // Step 1: Update BebeqMusicConfig
  const configScript = `
local rs = game:GetService("ReplicatedStorage")
local bms = rs:FindFirstChild("BebeqMusicSystem")
if not bms then return "ReplicatedStorage.BebeqMusicSystem not found" end
local cfg = bms:FindFirstChild("BebeqMusicConfig")
if not cfg then return "BebeqMusicConfig not found" end

cfg.Source = [===[${newConfigSrc}]===]
return "SUCCESS: Config updated!"
`;

  const resConfig = await executeLuau(configScript, 'Edit');
  console.log('Config Update Result:', JSON.stringify(resConfig, null, 2));

  // Step 2: Update BebeqMusicClient
  const clientScript = `
local sp = game:GetService("StarterPlayer")
local sps = sp:FindFirstChild("StarterPlayerScripts")
if not sps then return "StarterPlayerScripts not found" end
local cl = sps:FindFirstChild("BebeqMusicClient")
if not cl then return "BebeqMusicClient not found" end

cl.Source = [===[${newClientSrc}]===]
return "SUCCESS: Client updated!"
`;

  const resClient = await executeLuau(clientScript, 'Edit');
  console.log('Client Update Result:', JSON.stringify(resClient, null, 2));
}

run().catch(console.error);
