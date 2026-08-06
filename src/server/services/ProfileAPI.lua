--!strict

-- ProfileAPI (server): hookup remote GetProfile & QuestAccept/Claim.
-- Tempat mendaftarkan remote yang melayani client.

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local QuestService = require(script.Parent:WaitForChild('QuestService'))

local ProfileAPI = {}

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
	end)

	-- Client claim quest reward
	RemoteRegistry.registerEvent('QuestClaim', function(player: Player, questId: unknown)
		if type(questId) ~= 'string' then
			return
		end
		QuestService.completeQuest(player.UserId, questId)
	end)

	-- Client ambil quest aktif (untuk HUD)
	RemoteRegistry.registerFunction('GetQuestLog', function(player: Player)
		return QuestService.getActiveQuests(player.UserId)
	end)
end

return ProfileAPI
