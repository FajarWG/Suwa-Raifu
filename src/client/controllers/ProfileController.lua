--!strict

-- ProfileController (client): mengambil profile dari server & menyimpan
-- locale lokal untuk LocalizationService.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local LocalizationService =
	require(ReplicatedStorage.Shared:WaitForChild('services'):WaitForChild('LocalizationService'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local profile: ProfileTypes.Profile?

local ProfileController = {}

function ProfileController.getProfile(): ProfileTypes.Profile?
	return profile
end

function ProfileController.init()
	-- Ambil profile dari server (RemoteFunction GetProfile)
	task.spawn(function()
		local result = RemoteController.invoke('GetProfile')
		if type(result) == 'table' then
			profile = result
			local locale = LocalizationService.getLocaleForProfile(result)
			-- Set locale untuk dialog & school controller
			local DialogController = require(script.Parent:WaitForChild('DialogController'))
			DialogController.setLocale(locale)
			local SchoolController = require(script.Parent:WaitForChild('SchoolController'))
			SchoolController.setLocale(locale)
		end
	end)
end

return ProfileController
