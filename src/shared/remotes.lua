--!strict

-- Registry remote API. Satu sumber kebenaran nama RemoteEvent/RemoteFunction.
-- Server & client memakai nama yang sama.

export type RemoteNames = {
	workRequest: string,
	fishCast: string,
	fishReel: string,
	shopBuy: string,
	questAccept: string,
	questClaim: string,
	npcInteract: string,
	schoolCheckIn: string,
	bikeRequest: string,
	getProfile: string,
	getShopCatalog: string,
	getQuestLog: string,
	getTimeInfo: string,
}

export type RemoteDefinitions = {
	events: { string },
	functions: { string },
}

local Remotes: RemoteDefinitions = {
	events = {
		'WorkRequest',
		'FishCast',
		'FishReel',
		'ShopBuy',
		'QuestAccept',
		'QuestClaim',
		'NPCInteract',
		'SchoolCheckIn',
		'BikeRequest',
		'NPCOpenDialog',
		'QuizSubmit',
		'FishingState',
		'InventoryUpdated',
		'OpenShop',
		'ShopResult',
		'InventoryAction',
	},
	functions = {
		'GetProfile',
		'GetShopCatalog',
		'GetQuestLog',
		'GetTimeInfo',
		'NPCGetDialog',
		'LessonGet',
		'GetInventory',
	},
}

-- Helper: cek apakah nama remote valid (cegah typo).
local function assertValid(name: string)
	for _, existing in Remotes.events do
		if existing == name then
			return
		end
	end
	for _, existing in Remotes.functions do
		if existing == name then
			return
		end
	end
	error(`Remote "{name}" is not defined in Remotes registry`, 2)
end

return {
	events = Remotes.events,
	functions = Remotes.functions,
	assertValid = assertValid,
}
