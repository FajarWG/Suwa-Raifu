--!strict

-- ProfileController (client): fetches the player profile from the server.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local profile: ProfileTypes.Profile?

local ProfileController = {}

function ProfileController.getProfile(): ProfileTypes.Profile?
	return profile
end

function ProfileController.init()
	RemoteController.onEvent('ProfileUpdated', function(newProfile)
		if type(newProfile) == 'table' then
			profile = newProfile
		end
	end)

	task.spawn(function()
		local result = RemoteController.invoke('GetProfile')
		if type(result) == 'table' then
			profile = result
		end
	end)
end

return ProfileController
