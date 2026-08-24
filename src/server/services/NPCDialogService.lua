--!strict

-- NPCDialogService (server): menyajikan dialog tree NPC & memproses aksi.
-- Remote: NPCInteract (event, client -> server), NPCGetDialog (function).

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local NPCs = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('NPCs'))

local function handleInteract(player: Player, npcId: string)
	local npc = NPCs[npcId]
	if not npc then
		warn(`[NPC] Unknown NPC: {npcId}`)
		return
	end

	-- Beri client dialog (client akan fetch node via RemoteFunction)
	RemoteRegistry.fireClient(player, 'NPCOpenDialog', {
		npcId = npcId,
		intent = npc.defaultIntent,
	})
end

local function getDialogForPlayer(npcId: string, nodeId: string?)
	local npc = NPCs[npcId]
	if not npc then
		return nil
	end
	local flow = npc.dialogFlows[npc.defaultIntent]
	if not flow then
		return nil
	end
	local node = nodeId and flow.nodes[nodeId] or flow.nodes[flow.rootNodeId]
	if not node then
		return nil
	end
	return {
		npcId = npcId,
		node = node,
	}
end

local NPCDialogService = {}

function NPCDialogService.init()
	RemoteRegistry.registerEvent('NPCInteract', function(player: Player, npcId: unknown)
		if type(npcId) ~= 'string' then
			return
		end
		handleInteract(player, npcId)
	end)

	RemoteRegistry.registerFunction('NPCGetDialog', function(_player: Player, npcId: unknown, nodeId: unknown)
		if type(npcId) ~= 'string' then
			return nil
		end
		local nodeIdStr = type(nodeId) == 'string' and nodeId or nil
		return getDialogForPlayer(npcId, nodeIdStr)
	end)
end

return NPCDialogService
