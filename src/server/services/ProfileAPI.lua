--!strict

-- ProfileAPI (server): serves the GetProfile remote to the client.

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))

local ProfileAPI = {}

local function pushHudState(player: Player)
	local profile = ProfileService.getProfile(player.UserId)
	if profile then
		RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
	end
end

function ProfileAPI.init()
	-- Hand the client its profile.
	RemoteRegistry.registerFunction('GetProfile', function(player: Player)
		return ProfileService.getProfile(player.UserId)
	end)

	ProfileService.onProfileLoaded(function(player: Player)
		pushHudState(player)
	end)
end

return ProfileAPI
