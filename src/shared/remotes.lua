--!strict

-- Remote registry: the single source of truth for RemoteEvent/RemoteFunction
-- names. Server and client both read these.

export type RemoteNames = {
	workRequest: string,
	fishCast: string,
	fishReel: string,
	shopBuy: string,
	bikeRequest: string,
	vehicleBoost: string,
	vehicleHop: string,
	getProfile: string,
	getShopCatalog: string,
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
		'BikeRequest',
		'FishingState',
		'InventoryUpdated',
		'OpenShop',
		'ShopResult',
		'InventoryAction',
		'VehicleBoost',
		'VehicleHop',
		'ProfileUpdated',
	},
	functions = {
		'GetProfile',
		'GetShopCatalog',
		'GetTimeInfo',
		'GetInventory',
	},
}

-- Guards against typos in remote names.
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
