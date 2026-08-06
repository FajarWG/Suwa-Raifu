--!strict

-- Entry point server. Semua service di-init di sini.
-- RemoteRegistryService harus init paling awal (membuat folder remotes).

local Services = {}

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

-- 1. Remote registry dulu (service lain register remote padanya).
local remoteModule = script.Parent:FindFirstChild('RemoteRegistryService')
if remoteModule and remoteModule:IsA('ModuleScript') then
	initService(remoteModule)
end

-- 2. Service lain.
for _, module in script.Parent:GetChildren() do
	if module:IsA('ModuleScript') and module ~= remoteModule then
		initService(module)
	end
end

print('[Server] Suwa Life server runner ready.')
