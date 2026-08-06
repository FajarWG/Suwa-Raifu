--!strict

-- Server-side Remote Registry.
-- Membuat instance RemoteEvent/RemoteFunction berdasarkan shared/remotes.lua
-- dan menyediakan fireClient / invokeClient helpers.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Remotes = require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('remotes'))

local remotesFolder = Instance.new('Folder')
remotesFolder.Name = 'Remotes'
remotesFolder.Parent = ReplicatedStorage

local events: { [string]: RemoteEvent } = {}
local functions: { [string]: RemoteFunction } = {}

for _, name in Remotes.events do
	Remotes.assertValid(name)
	local event = Instance.new('RemoteEvent')
	event.Name = name
	event.Parent = remotesFolder
	events[name] = event
end

for _, name in Remotes.functions do
	Remotes.assertValid(name)
	local fn = Instance.new('RemoteFunction')
	fn.Name = name
	fn.Parent = remotesFolder
	functions[name] = fn
end

local RemoteRegistry = {
	events = events,
	functions = functions,
}

function RemoteRegistry.getEvent(name: string): RemoteEvent
	return events[name]
end

function RemoteRegistry.getFunction(name: string): RemoteFunction
	return functions[name]
end

function RemoteRegistry.fireClient(player: Player, name: string, ...)
	local event = events[name]
	if event then
		event:FireClient(player, ...)
	else
		warn(`[Remotes] Unknown event fired to client: {name}`)
	end
end

function RemoteRegistry.invokeClient(player: Player, name: string, ...)
	local fn = functions[name]
	if fn then
		return fn:InvokeClient(player, ...)
	end
	warn(`[Remotes] Unknown function invoked on client: {name}`)
	return nil
end

-- Rate limit wrapper: hanya allow N calls/detik per player per remote.
local Math = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('Math'))
local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))

local limiter = Math.makeRateLimiter(Config.remoteRateLimit)

function RemoteRegistry.registerEvent(name: string, handler: (player: Player, ...any) -> ())
	Remotes.assertValid(name)
	local event = events[name]
	if not event then
		error(`[Remotes] registerEvent: unknown name "{name}"`, 2)
	end
	event.OnServerEvent:Connect(function(player: Player, ...)
		local now = os.clock()
		if limiter(player.UserId .. ':' .. name, now) then
			local ok, err = pcall(handler, player, ...)
			if not ok then
				warn(`[Remotes] handler error for {name}: {err}`)
			end
		else
			warn(`[Remotes] Rate limited: {player.Name} on {name}`)
		end
	end)
end

function RemoteRegistry.registerFunction(name: string, handler: (player: Player, ...any) -> any)
	Remotes.assertValid(name)
	local fn = functions[name]
	if not fn then
		error(`[Remotes] registerFunction: unknown name "{name}"`, 2)
	end
	fn.OnServerInvoke = function(player: Player, ...)
		return handler(player, ...)
	end
end

return RemoteRegistry
