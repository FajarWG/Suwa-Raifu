--!strict

-- ProfileAPI (server): hookup remote GetProfile & QuestAccept/Claim.
-- Tempat mendaftarkan remote yang melayani client.

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local QuestService = require(script.Parent:WaitForChild('QuestService'))

local ProfileAPI = {}

local function pushHudState(player: Player)
	local profile = ProfileService.getProfile(player.UserId)
	if profile then
		RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
	end
	RemoteRegistry.fireClient(player, 'QuestLogUpdated', QuestService.getActiveQuests(player.UserId))
end

function ProfileAPI.init()
	-- Beri client profile (sanitized, tanpa data sensitif)
	RemoteRegistry.registerFunction('GetProfile', function(player: Player)
		return ProfileService.getProfile(player.UserId)
	end)

	-- Client accept quest (quest service menangani pemberian item & reward)
	RemoteRegistry.registerEvent('QuestAccept', function(player: Player, questId: unknown)
		if type(questId) ~= 'string' then
			return
		end
		QuestService.acceptQuest(player.UserId, questId)
		pushHudState(player)
	end)

	-- Client claim quest reward
	RemoteRegistry.registerEvent('QuestClaim', function(player: Player, questId: unknown)
		if type(questId) ~= 'string' then
			return
		end
		QuestService.completeQuest(player.UserId, questId)
		pushHudState(player)
	end)

	-- Client ambil quest aktif (untuk HUD)
	RemoteRegistry.registerFunction('GetQuestLog', function(player: Player)
		return QuestService.getActiveQuests(player.UserId)
	end)

	ProfileService.onProfileLoaded(function(player: Player)
		pushHudState(player)
	end)
end

return ProfileAPI
