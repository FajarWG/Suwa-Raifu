const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

async function run() {
  const files = [
    {
      path: 'src/shared/data/Fishing.lua',
      target: 'game:GetService("ReplicatedStorage").Shared.data.Fishing',
      name: 'Fishing',
    },
    {
      path: 'src/shared/constants/Config.lua',
      target: 'game:GetService("ReplicatedStorage").Shared.constants.Config',
      name: 'Config',
    },
    {
      path: 'src/client/controllers/InventoryController.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.Client.controllers.InventoryController',
      name: 'InventoryController',
    },
    {
      path: 'src/server/services/ProfileService.lua',
      target: 'game:GetService("ServerScriptService").Server.services.ProfileService',
      name: 'ProfileService',
    },
    {
      path: 'src/server/services/FishingGameService.lua',
      target: 'game:GetService("ServerScriptService").Server.services.FishingGameService',
      name: 'FishingGameService',
    },
  ];

  for (const item of files) {
    const src = fs.readFileSync(item.path, 'utf-8');
    const lua = `
local target = ${item.target}
target.Source = [====[${src}]====]
return "SUCCESS: Updated " .. target:GetFullName() .. " (" .. tostring(#target.Source) .. " bytes)"
`;
    const res = await executeLuau(lua, 'Edit');
    console.log(item.name, '->', res);
  }
}

run().catch(console.error);
