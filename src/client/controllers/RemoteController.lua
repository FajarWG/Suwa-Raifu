--!strict

-- RemoteController: client-side wrapper for calling the remotes that
-- are registered in shared/remotes.lua.
--
-- Remotes are looked up by name on first use rather than snapshotted once at
-- startup: the server creates them in a loop, and a client that enumerates
-- the folder before the last few have replicated down would otherwise treat
-- them as permanently missing for the rest of the session.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- Not just "Remotes": a third-party asset (Emote Dance & Sync) already owns a
-- ReplicatedStorage.Remotes folder, and two same-named siblings made
-- WaitForChild('Remotes') resolve to the wrong one.
local remotesFolder = ReplicatedStorage:WaitForChild('SuwaRemotes')
local events: { [string]: RemoteEvent } = {}
local functions: { [string]: RemoteFunction } = {}

local function getEvent(name: string): RemoteEvent?
	local cached = events[name]
	if cached then
		return cached
	end
	local found = remotesFolder:WaitForChild(name, 5)
	if found and found:IsA('RemoteEvent') then
		events[name] = found
		return found
	end
	return nil
end

local function getFunction(name: string): RemoteFunction?
	local cached = functions[name]
	if cached then
		return cached
	end
	local found = remotesFolder:WaitForChild(name, 5)
	if found and found:IsA('RemoteFunction') then
		functions[name] = found
		return found
	end
	return nil
end

local RemoteController = {}

function RemoteController.fire(name: string, ...)
	local event = getEvent(name)
	if event then
		event:FireServer(...)
	else
		warn(`[Client] Unknown event: {name}`)
	end
end

function RemoteController.invoke(name: string, ...)
	local fn = getFunction(name)
	if fn then
		return fn:InvokeServer(...)
	end
	warn(`[Client] Unknown function: {name}`)
	return nil
end

function RemoteController.onEvent(name: string, handler: (...any) -> ())
	local event = getEvent(name)
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
