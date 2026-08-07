--!strict

-- Entry point server. Semua service di-init di sini.
-- RemoteRegistryService harus init paling awal (membuat folder remotes).

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

-- 1. Remote registry dulu (service lain register remote padanya).
local remoteModule = servicesFolder:FindFirstChild('RemoteRegistryService')
if remoteModule and remoteModule:IsA('ModuleScript') then
	initService(remoteModule)
end

-- 2. Terrain harus selesai sebelum generator taman, kendaraan, toko, dan fauna
-- menghitung elevasi. Ini mencegah aset memakai Y lama lalu melayang/tertimbun.
local terrainModule = servicesFolder:FindFirstChild('TerrainService')
if terrainModule and terrainModule:IsA('ModuleScript') then
	initService(terrainModule)
end

-- 3. Service lain. Interaksi kursi/playground ditunda sampai generator taman
-- selesai agar semua bangku dan ashiyu yang baru dibuat ikut menjadi fungsional.
local bicycleModule = servicesFolder:FindFirstChild('BicycleService')
local interactionModule = servicesFolder:FindFirstChild('ParkInteractionService')
for _, module in servicesFolder:GetChildren() do
	if
		module:IsA('ModuleScript')
		and module ~= remoteModule
		and module ~= terrainModule
		and module ~= bicycleModule
		and module ~= interactionModule
	then
		initService(module)
	end
end

-- Sepeda dirakit setelah permukaan/rak taman tersedia, sehingga raycast awal
-- mengenai pavement sebenarnya dan roda tidak ditanam ke Y dunia yang lama.
if bicycleModule and bicycleModule:IsA('ModuleScript') then
	initService(bicycleModule)
end

if interactionModule and interactionModule:IsA('ModuleScript') then
	initService(interactionModule)
end

print('[Server] Suwa Life server runner ready.')
