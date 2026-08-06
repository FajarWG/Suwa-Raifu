--!strict

-- Builds the lakeside as real Roblox terrain when a fresh Rojo place starts.

local TERRAIN_VERSION = 4

local hills = {
	{ position = Vector3.new(-760, -62, -1370), radius = 210 },
	{ position = Vector3.new(-470, -48, -1400), radius = 185 },
	{ position = Vector3.new(-170, -42, -1420), radius = 225 },
	{ position = Vector3.new(150, -55, -1410), radius = 205 },
	{ position = Vector3.new(470, -45, -1390), radius = 215 },
	{ position = Vector3.new(770, -65, -1360), radius = 195 },
}

local TerrainService = {}

local function buildTerrain()
	local terrain = workspace.Terrain
	if terrain:GetAttribute('SuwaTerrainVersion') == TERRAIN_VERSION then
		return
	end

	terrain:Clear()
	terrain.WaterColor = Color3.fromRGB(43, 130, 174)
	terrain.WaterTransparency = 0.28
	terrain.WaterReflectance = 0.18
	terrain.WaterWaveSize = 0.22
	terrain.WaterWaveSpeed = 8

	-- A broad body of water, with the opposite shore far enough away to read as
	-- Lake Suwa rather than a canal. Terrain water is swimmable and has no hard
	-- collision surface.
	terrain:FillBlock(CFrame.new(0, -18, -780), Vector3.new(1900, 36, 1200), Enum.Material.Water)
	terrain:FillBlock(CFrame.new(0, -4, -166), Vector3.new(940, 8, 40), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, -55, -1410), Vector3.new(1900, 110, 300), Enum.Material.Rock)

	for _, hill in hills do
		terrain:FillBall(hill.position, hill.radius, Enum.Material.Rock)
		terrain:FillBall(hill.position + Vector3.new(0, 6, 5), hill.radius - 7, Enum.Material.Grass)
	end

	-- Hatsushima-inspired islet. The shrine, trees and launch equipment are
	-- assembled by LakeActivityService on top of this natural terrain mound.
	terrain:FillBall(Vector3.new(0, -20, -610), 34, Enum.Material.Rock)
	terrain:FillBall(Vector3.new(0, -14, -610), 27, Enum.Material.Grass)

	local clouds = terrain:FindFirstChildOfClass('Clouds') or Instance.new('Clouds')
	clouds.Name = 'SuwaClouds'
	clouds.Cover = 0.28
	clouds.Density = 0.42
	clouds.Color = Color3.fromRGB(240, 246, 250)
	clouds.Parent = terrain
	terrain:SetAttribute('SuwaTerrainVersion', TERRAIN_VERSION)
end

local function removePlaceholders()
	local central = workspace:FindFirstChild('SuwaCentral')
	if not central then
		return
	end

	local cityGround = central:FindFirstChild('CityGround')
	if cityGround and cityGround:IsA('BasePart') then
		cityGround.Size = Vector3.new(760, 1, 430)
		cityGround.CFrame = CFrame.new(0, -0.5, 65)
	end

	for _, name in { 'LakeWater', 'NaturalShoreline', 'MountainBackdrop' } do
		local placeholder = central:FindFirstChild(name)
		if placeholder then
			placeholder:Destroy()
		end
	end
end

function TerrainService.init()
	buildTerrain()
	removePlaceholders()
end

return TerrainService
