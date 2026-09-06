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
      path: 'scripts/scratch_SuwaCostumeConfig.lua',
      target: 'game:GetService("ReplicatedStorage").SuwaCostumeConfig',
      name: 'SuwaCostumeConfig',
    },
    {
      path: 'src/client/controllers/InventoryController.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.Client.controllers.InventoryController',
      name: 'InventoryController',
    },
    {
      path: 'src/client/controllers/FishingController.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.Client.controllers.FishingController',
      name: 'FishingController',
    },
    {
      path: 'scripts/scratch_BebeqAvatarLocal.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.BebeqAvatarLocal',
      name: 'BebeqAvatarLocal',
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
    {
      path: 'src/server/services/RemoteRegistryService.lua',
      target: 'game:GetService("ServerScriptService").Server.services.RemoteRegistryService',
      name: 'RemoteRegistryService',
    },
    {
      path: 'src/server/services/InventoryService.lua',
      target: 'game:GetService("ServerScriptService").Server.services.InventoryService',
      name: 'InventoryService',
    },
    {
      path: 'src/server/services/VehicleInteractionService.lua',
      target: 'game:GetService("ServerScriptService").Server.services.VehicleInteractionService',
      name: 'VehicleInteractionService',
    },
    {
      path: 'src/shared/remotes.lua',
      target: 'game:GetService("ReplicatedStorage").Shared.remotes',
      name: 'remotes',
    },
    {
      path: 'src/server/services/BicycleService.lua',
      target: 'game:GetService("ServerScriptService").Server.services.BicycleService',
      name: 'BicycleService',
    },
    {
      path: 'src/client/controllers/BicycleController.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.Client.controllers.BicycleController',
      name: 'BicycleController',
    },
    {
      path: 'src/client/controllers/MovementController.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.Client.controllers.MovementController',
      name: 'MovementController',
    },
    {
      path: 'src/client/controllers/UIScaling.lua',
      target: 'game:GetService("StarterPlayer").StarterPlayerScripts.Client.controllers.UIScaling',
      name: 'UIScaling',
    },
    {
      path: 'src/server/runner.server.lua',
      target: 'game:GetService("ServerScriptService").Server.runner',
      name: 'runner',
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
