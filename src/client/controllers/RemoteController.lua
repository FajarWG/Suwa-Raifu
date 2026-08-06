--!strict

-- RemoteController: client-side wrapper untuk memanggil remote yang
-- diregistrasi di shared/remotes.lua.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local remotesFolder = ReplicatedStorage:WaitForChild('Remotes')
local events: { [string]: RemoteEvent } = {}
local functions: { [string]: RemoteFunction } = {}

for _, child in remotesFolder:GetChildren() do
	if child:IsA('RemoteEvent') then
		events[child.Name] = child
	elseif child:IsA('RemoteFunction') then
		functions[child.Name] = child
	end
end

local RemoteController = {}

function RemoteController.fire(name: string, ...)
	local event = events[name]
	if event then
		event:FireServer(...)
	else
		warn(`[Client] Unknown event: {name}`)
	end
end

function RemoteController.invoke(name: string, ...)
	local fn = functions[name]
	if fn then
		return fn:InvokeServer(...)
	end
	warn(`[Client] Unknown function: {name}`)
	return nil
end

function RemoteController.onEvent(name: string, handler: (...any) -> ())
	local event = events[name]
	if event then
		event.OnClientEvent:Connect(handler)
	else
		warn(`[Client] Cannot listen to unknown event: {name}`)
	end
end

function RemoteController.init()
	-- Skeleton
end

return RemoteController
