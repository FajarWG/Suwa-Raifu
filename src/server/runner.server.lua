--!strict

-- Entry point server. Semua service di-init di sini.

local Services = {}

-- Load & init semua service di folder services.
for _, module in script.Parent:GetChildren() do
	if module:IsA('ModuleScript') and module.Name:match('Service$') then
		local ok, service = pcall(require, module)
		if ok and typeof(service) == 'table' and service.init then
			service.init()
			Services[module.Name] = service
			print(`[Server] Loaded {module.Name}`)
		else
			warn(`[Server] Failed to load {module.Name}: {service}`)
		end
	end
end

print('[Server] Suwa Life server runner ready.')
