--!strict

-- Server entry point. Every service is initialised here.
-- RemoteRegistryService must go first; the others register remotes on it.

local Services = {}
local servicesFolder = script.Parent:WaitForChild('services')

local function initService(module: ModuleScript)
	local ok, service = pcall(require, module)
	if ok and typeof(service) == 'table' and service.init then
		service.init()
		Services[module.Name] = service
		print(`[Server] Loaded {module.Name}`)
	else
		warn(`[Server] Failed to load {module.Name}: {service}`)
	end
end

-- 1. Remote registry first.
local remoteModule = servicesFolder:FindFirstChild('RemoteRegistryService')
if remoteModule and remoteModule:IsA('ModuleScript') then
	initService(remoteModule)
end

-- 2. Everything else. World dressing (terrain, park, roads, boats, wildlife) is
-- no longer generated in code; it is placed by hand in Studio from the Creator
-- Store, so a Rojo sync never overwrites the build.
--
-- ParkInteractionService runs last: it creates Seat objects on bench props, and
-- VehicleInteractionService must already be listening in order to prompt them.
local interactionModule = servicesFolder:FindFirstChild('ParkInteractionService')
for _, module in servicesFolder:GetChildren() do
	if module:IsA('ModuleScript') and module ~= remoteModule and module ~= interactionModule then
		initService(module)
	end
end

if interactionModule and interactionModule:IsA('ModuleScript') then
	initService(interactionModule)
end

print('[Server] Suwa Life server runner ready.')
