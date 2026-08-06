--!strict

-- Entry point client. Memuat controller.

for _, module in script.Parent:GetChildren() do
	if module:IsA('ModuleScript') and module.Name:match('Controller$') then
		local ok, controller = pcall(require, module)
		if ok and typeof(controller) == 'table' and controller.init then
			controller.init()
			print(`[Client] Loaded {module.Name}`)
		else
			warn(`[Client] Failed to load {module.Name}: {controller}`)
		end
	end
end

print('[Client] Suwa Life client runner ready.')
