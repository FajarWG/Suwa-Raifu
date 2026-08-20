--!strict

-- Builds the lakeside as real Roblox terrain when a fresh Rojo place starts.

local TERRAIN_VERSION = 11

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
	terrain.WaterColor = Color3.fromRGB(48, 118, 151)
	terrain.WaterTransparency = 0.8
	terrain.WaterReflectance = 0.25
	terrain.WaterWaveSize = 0.15
	terrain.WaterWaveSpeed = 6

	-- A broad body of water, with the opposite shore far enough away to read as
	-- Lake Suwa rather than a canal. Terrain water is swimmable and has no hard
	-- collision surface.
	terrain:FillBlock(CFrame.new(0, -24, -810), Vector3.new(1900, 48, 1140), Enum.Material.Water)

	-- Solid land base under park, road, and buildings
	terrain:FillBlock(CFrame.new(0, -4, 60), Vector3.new(1600, 10, 520), Enum.Material.Grass)

	-- A chain of overlapping, rotated shallow-water coves connects the deep lake
	-- to the beach. This removes the ruler-straight water boundary while keeping
	-- every cove joined to the swimmable Terrain Water volume.
	local lakeCoves = {
		{ x = -680, z = -226, width = 150, depth = 48, yaw = -8 },
		{ x = -570, z = -222, width = 138, depth = 54, yaw = 7 },
		{ x = -455, z = -226, width = 145, depth = 48, yaw = 10 },
		{ x = -340, z = -220, width = 140, depth = 58, yaw = -6 },
		{ x = -225, z = -225, width = 145, depth = 50, yaw = -9 },
		{ x = -110, z = -219, width = 142, depth = 58, yaw = 8 },
		{ x = 5, z = -224, width = 148, depth = 50, yaw = 11 },
		{ x = 120, z = -218, width = 142, depth = 60, yaw = -7 },
		{ x = 235, z = -223, width = 145, depth = 52, yaw = -10 },
		{ x = 350, z = -219, width = 140, depth = 58, yaw = 7 },
		{ x = 465, z = -225, width = 146, depth = 50, yaw = 10 },
		{ x = 580, z = -220, width = 140, depth = 58, yaw = -8 },
		{ x = 690, z = -226, width = 148, depth = 48, yaw = 6 },
	}
	for _, cove in lakeCoves do
		terrain:FillBlock(
			CFrame.new(cove.x, -10, cove.z) * CFrame.Angles(0, math.rad(cove.yaw), 0),
			Vector3.new(cove.width, 20, cove.depth),
			Enum.Material.Water
		)
		terrain:FillBall(Vector3.new(cove.x, -13, cove.z + cove.depth * 0.32), 13, Enum.Material.Water)
	end

	-- Build the shoreline as overlapping natural terrain pockets instead of a
	-- single ruler-straight strip. Grass fingers, sand and pebble alternate along
	-- the waterline, matching the changing edge visible in the photo set.
	for x = -700, 700, 55 do
		local wave = math.sin(x / 82) * 9 + math.cos(x / 165) * 5
		local shoreZ = -221 + wave
		terrain:FillBall(Vector3.new(x, -29, shoreZ + 16), 31, Enum.Material.Grass)
		terrain:FillBall(Vector3.new(x, -27.5, shoreZ), 28, Enum.Material.Sand)
		if math.floor((x + 700) / 55) % 3 ~= 1 then
			terrain:FillBall(Vector3.new(x + 9, -24, shoreZ - 2), 23, Enum.Material.Pebble)
		end
	end

	-- Low rolling mounds support the raised/lowered promenade. Their height is
	-- deliberately subtle: enough to feel like a real park, but still accessible
	-- to walking avatars and mamachari without sudden terrain cliffs.
	local parkMounds = {
		{ position = Vector3.new(-610, -34, -165), radius = 35 },
		{ position = Vector3.new(-510, -35, -154), radius = 37 },
		{ position = Vector3.new(-400, -35, -142), radius = 39 },
		{ position = Vector3.new(-285, -36, -150), radius = 38 },
		{ position = Vector3.new(-175, -36, -163), radius = 37 },
		{ position = Vector3.new(-65, -35, -150), radius = 38 },
		{ position = Vector3.new(55, -35, -132), radius = 39 },
		{ position = Vector3.new(155, -36, -128), radius = 40 },
		{ position = Vector3.new(270, -36, -147), radius = 38 },
		{ position = Vector3.new(390, -35, -164), radius = 38 },
		{ position = Vector3.new(510, -35, -161), radius = 37 },
		{ position = Vector3.new(625, -34, -177), radius = 35 },
		{ position = Vector3.new(-520, -43, -88), radius = 46 },
		{ position = Vector3.new(-405, -44, -82), radius = 47 },
		{ position = Vector3.new(-295, -43, -91), radius = 47 },
		{ position = Vector3.new(-165, -44, -82), radius = 48 },
		{ position = Vector3.new(-35, -43, -83), radius = 48 },
		{ position = Vector3.new(105, -43, -86), radius = 47 },
		{ position = Vector3.new(245, -44, -89), radius = 47 },
		{ position = Vector3.new(385, -43, -83), radius = 46 },
		{ position = Vector3.new(515, -41, -78), radius = 44 },
	}
	for _, mound in parkMounds do
		terrain:FillBall(mound.position, mound.radius, Enum.Material.Ground)
		terrain:FillBall(mound.position + Vector3.new(0, 3, 0), mound.radius - 4, Enum.Material.Grass)
	end

	-- Public facilities need deliberately level pads. Carve only the space above
	-- the base shelf; rolling terrain remains between facilities and along paths.
	local levelFacilityZones = {
		{ center = Vector3.new(-320, 12.5, -94), size = Vector3.new(112, 25, 78) }, -- playground
		{ center = Vector3.new(70, 12.5, -100), size = Vector3.new(128, 25, 52) }, -- shelter + ashiyu
		{ center = Vector3.new(455, 12.5, -73), size = Vector3.new(150, 25, 72) }, -- toilet + bicycle parking
		{ center = Vector3.new(345, 12.5, -73), size = Vector3.new(42, 25, 34) }, -- tackle shop
		{ center = Vector3.new(-145, 12.5, -65), size = Vector3.new(42, 25, 34) }, -- ice cream shop
		{ center = Vector3.new(-220, 12.5, -35), size = Vector3.new(100, 25, 72) }, -- fitness plaza
	}
	for _, zone in levelFacilityZones do
		terrain:FillBlock(CFrame.new(zone.center), zone.size, Enum.Material.Air)
	end

	-- Recess the ashiyu into the otherwise level facility pad. The air cut is
	-- deliberately wider than the water so the park service can build real stone
	-- walls around a four-stud-deep basin instead of laying a puddle on the lawn.
	terrain:FillBlock(CFrame.new(102, -1.15, -96), Vector3.new(42, 5.5, 16), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(102, -1.0, -96), Vector3.new(36, 4, 10), Enum.Material.Water)

	-- Small rain puddles occupy deliberately flat grass pockets away from the
	-- main paths and facilities. They are shallow Terrain Water, so avatars step
	-- through them rather than entering the swimming state.
	local puddles = {
		{ position = Vector3.new(-650, -0.45, -92), size = Vector3.new(24, 0.9, 11), yaw = 14 },
		{ position = Vector3.new(360, -0.45, -32), size = Vector3.new(20, 0.9, 9), yaw = -11 },
		{ position = Vector3.new(650, -0.45, -105), size = Vector3.new(18, 0.9, 10), yaw = 9 },
	}
	for _, puddle in puddles do
		local puddleCFrame = CFrame.new(puddle.position) * CFrame.Angles(0, math.rad(puddle.yaw), 0)
		terrain:FillBlock(puddleCFrame, puddle.size, Enum.Material.Water)
		terrain:FillBlock(
			CFrame.new(puddle.position + Vector3.new(puddle.size.X * 0.32, 0, 1.5))
				* CFrame.Angles(0, math.rad(puddle.yaw - 18), 0),
			Vector3.new(puddle.size.X * 0.48, puddle.size.Y, puddle.size.Z * 0.7),
			Enum.Material.Water
		)
	end

	terrain:FillBlock(CFrame.new(0, -55, -1410), Vector3.new(1900, 110, 300), Enum.Material.Rock)

	for _, hill in hills do
		terrain:FillBall(hill.position, hill.radius, Enum.Material.Rock)
		terrain:FillBall(hill.position + Vector3.new(0, 6, 5), hill.radius - 7, Enum.Material.Grass)
	end

	-- Festival island uses broad, shallow terrain layers instead of exposed rock
	-- spheres. Rock remains below the water, sand forms a continuous beach and a
	-- slightly raised grass crown supplies a natural 20-player festival lawn.
	local islandLobes = {
		{ x = 0, z = -610, rock = 64, sand = 62, grass = 54 },
		{ x = -48, z = -608, rock = 42, sand = 40, grass = 33 },
		{ x = 48, z = -614, rock = 42, sand = 40, grass = 33 },
		{ x = -5, z = -567, rock = 40, sand = 38, grass = 31 },
		{ x = 7, z = -653, rock = 40, sand = 38, grass = 31 },
	}
	for _, lobe in islandLobes do
		terrain:FillCylinder(CFrame.new(lobe.x, -8, lobe.z), 15, lobe.rock, Enum.Material.Rock)
	end
	for _, lobe in islandLobes do
		terrain:FillCylinder(CFrame.new(lobe.x, -1.5, lobe.z), 5, lobe.sand, Enum.Material.Sand)
	end
	for _, lobe in islandLobes do
		terrain:FillCylinder(CFrame.new(lobe.x, 1.1, lobe.z), 2.2, lobe.grass + 3, Enum.Material.Ground)
	end
	for _, lobe in islandLobes do
		terrain:FillCylinder(CFrame.new(lobe.x, 1.3, lobe.z), 2.6, lobe.grass, Enum.Material.Grass)
	end
	for _, patch in
		{
			{ x = -20, z = -603, radius = 27 },
			{ x = 24, z = -620, radius = 24 },
			{ x = 3, z = -578, radius = 19 },
		}
	do
		terrain:FillCylinder(CFrame.new(patch.x, 2.9, patch.z), 1.2, patch.radius, Enum.Material.Grass)
	end
	terrain:SetAttribute('HatsushimaIslandCenter', Vector3.new(0, 0, -610))
	terrain:SetAttribute('HatsushimaIslandDiameterStuds', 180)
	terrain:SetAttribute('HatsushimaFestivalCapacity', 20)
	terrain:SetAttribute('PreserveCentralLakeIsland', true)
	terrain:SetAttribute('SwimmableLake', true)
	terrain:SetAttribute('NaturalCoveCount', #lakeCoves)
	terrain:SetAttribute('ShallowPuddleCount', #puddles)

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
	if cityGround then
		cityGround:Destroy()
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
