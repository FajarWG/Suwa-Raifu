const { executeLuau } = require('./mcp-exec.js');

const costumeConfigCode = `local CostumeConfig = {}

CostumeConfig.Presets = {
	-- TRADITIONAL & CULTURAL
	{
		id = "yukata_navy",
		name = "Navy Summer Yukata (紺の夏浴衣)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 12557329485,
		pants = 12557348926,
		shirtTemplate = "http://www.roblox.com/asset/?id=12557329456",
		pantsTemplate = "http://www.roblox.com/asset/?id=12557348902",
		description = "Traditional summer yukata, ideal for peaceful evening strolls along Lake Suwa."
	},
	{
		id = "yukata_sakura",
		name = "Sakura Floral Yukata (桜の浴衣)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 79326241303163,
		pants = 101332222597295,
		shirtTemplate = "http://www.roblox.com/asset/?id=86879614867795",
		pantsTemplate = "http://www.roblox.com/asset/?id=116271433567649",
		description = "Graceful soft pink sakura blossom yukata with an elegant obi sash."
	},
	{
		id = "miko_shrine",
		name = "Suwa Shrine Maiden (諏訪の巫女装束)",
		category = "Traditional",
		categoryIcon = "⛩️",
		shirt = 89608123771601,
		pants = 79227464689155,
		shirtTemplate = "http://www.roblox.com/asset/?id=74725036785431",
		pantsTemplate = "http://www.roblox.com/asset/?id=92559863248202",
		description = "Sacred red hakama and pure white vestments of the Suwa Taisha shrine maidens."
	},
	{
		id = "kitsune_guardian",
		name = "Kitsune Shrine Guardian (白狐の霊装)",
		category = "Traditional",
		categoryIcon = "🦊",
		shirt = 3218143244,
		pants = 3218143520,
		shirtTemplate = "http://www.roblox.com/asset/?id=3218143214",
		pantsTemplate = "http://www.roblox.com/asset/?id=3218143496",
		description = "Sacred white fox spirit robe blessed for night lantern processions."
	},

	-- SCHOOL UNIFORMS
	{
		id = "gakuran_male",
		name = "Gakuran High School (男子学ラン制服)",
		category = "School",
		categoryIcon = "🎒",
		shirt = 6914550284,
		pants = 6914552071,
		shirtTemplate = "http://www.roblox.com/asset/?id=6914550277",
		pantsTemplate = "http://www.roblox.com/asset/?id=6914552062",
		description = "Classic Japanese high school boys uniform with golden buttons."
	},
	{
		id = "sailor_female",
		name = "Classic Sailor Uniform (セーラー女子制服)",
		category = "School",
		categoryIcon = "🎒",
		shirt = 8959935056,
		pants = 1770015436,
		shirtTemplate = "http://www.roblox.com/asset/?id=8959935025",
		pantsTemplate = "http://www.roblox.com/asset/?id=1770015426",
		description = "Iconic navy pleated skirt and crisp neckerchief Japanese sailor uniform."
	},

	-- ANIME SPECIAL
	{
		id = "taki_tachibana",
		name = "Taki Tachibana - Your Name (立花 瀧)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 5935442599,
		pants = 8047585078,
		shirtTemplate = "http://www.roblox.com/asset/?id=5935442591",
		pantsTemplate = "http://www.roblox.com/asset/?id=8047585070",
		description = "Tokyo school uniform worn by Taki when searching for Itomori & Lake Suwa."
	},
	{
		id = "mitsuha_miyamizu",
		name = "Mitsuha Miyamizu - Your Name (宮水 三葉)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 6070119438,
		pants = 5935447664,
		shirtTemplate = "http://www.roblox.com/asset/?id=6070119411",
		pantsTemplate = "http://www.roblox.com/asset/?id=5935447651",
		description = "Itomori High School sailor uniform with the iconic braided red ribbon."
	},
	{
		id = "tanjiro_kamado",
		name = "Tanjiro - Demon Slayer (竈門 炭治郎)",
		category = "Anime",
		categoryIcon = "⚔️",
		shirt = 6078620265,
		pants = 6078621916,
		shirtTemplate = "http://www.roblox.com/asset/?id=6078620221",
		pantsTemplate = "http://www.roblox.com/asset/?id=6078621881",
		description = "Iconic green & black checkered haori worn by the Demon Slayer Corps warrior."
	},
	{
		id = "nezuko_kamado",
		name = "Nezuko - Demon Slayer (竈門 禰豆子)",
		category = "Anime",
		categoryIcon = "🌸",
		shirt = 9804978856,
		pants = 9805010066,
		shirtTemplate = "http://www.roblox.com/asset/?id=9804978841",
		pantsTemplate = "http://www.roblox.com/asset/?id=9805010062",
		description = "Pink asanoha geometric kimono with dark haori and checkered sash."
	},
	{
		id = "satoru_gojo",
		name = "Satoru Gojo - Jujutsu Kaisen (五条 悟)",
		category = "Anime",
		categoryIcon = "👁️",
		shirt = 8303172932,
		pants = 16151335982,
		shirtTemplate = "http://www.roblox.com/asset/?id=8303172927",
		pantsTemplate = "http://www.roblox.com/asset/?id=16151335911",
		description = "High-collar dark uniform worn by the strongest Jujutsu High teacher."
	},

	-- EVENT & FESTIVALS
	{
		id = "halloween_pumpkin",
		name = "Pumpkin Festival Haori (南瓜の祭法被)",
		category = "Event",
		categoryIcon = "🎃",
		shirt = 14227797884,
		pants = 4646484209,
		shirtTemplate = "http://www.roblox.com/asset/?id=14227797829",
		pantsTemplate = "http://www.roblox.com/asset/?id=4646484173",
		description = "Vibrant orange & midnight black Jack-o-Lantern festival coat."
	},
	{
		id = "halloween_vampire",
		name = "Halloween Gothic Kimono (宵闇の着物)",
		category = "Event",
		categoryIcon = "🦇",
		shirt = 2432814442,
		pants = 2432814944,
		shirtTemplate = "http://www.roblox.com/asset/?id=2432814438",
		pantsTemplate = "http://www.roblox.com/asset/?id=2432814941",
		description = "Enchanting gothic dark-red kimono for mysterious lakeside Halloween nights."
	},
}

CostumeConfig.Categories = {
	{ id = "All", label = "All / すべて" },
	{ id = "Traditional", label = "👘 Traditional / 和風" },
	{ id = "School", label = "🎒 School / 制服" },
	{ id = "Anime", label = "🌠 Anime / アニメ" },
	{ id = "Event", label = "🎃 Event / 祭" },
}

function CostumeConfig.GetById(id)
	for _, preset in ipairs(CostumeConfig.Presets) do
		if preset.id == id then
			return preset
		end
	end
	return nil
end

return CostumeConfig
`;

async function main() {
  console.log('Deploying verified CostumeConfig to ReplicatedStorage...');
  const res1 = await executeLuau(`
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local conf = ReplicatedStorage:FindFirstChild("SuwaCostumeConfig")
    if not conf then
        conf = Instance.new("ModuleScript")
        conf.Name = "SuwaCostumeConfig"
        conf.Parent = ReplicatedStorage
    end
    conf.Source = [===[${costumeConfigCode}]===]
    return "SuwaCostumeConfig updated!"
  `, 'Edit');
  console.log('Result 1:', res1);

  console.log('Updating BebeqAvatarLocal to use direct templates for guaranteed textures...');
  const res2 = await executeLuau(`
    local s = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("BebeqAvatarLocal")
    if s then
        local src = s.Source
        -- Ensure preview uses preset.shirtTemplate and preset.pantsTemplate
        src = string.gsub(src, 'shirt%.ShirtTemplate = "rbxassetid://" %.%. tostring%(preset%.shirt%)', 'shirt.ShirtTemplate = preset.shirtTemplate or ("rbxassetid://" .. tostring(preset.shirt))')
        src = string.gsub(src, 'pants%.PantsTemplate = "rbxassetid://" %.%. tostring%(preset%.pants%)', 'pants.PantsTemplate = preset.pantsTemplate or ("rbxassetid://" .. tostring(preset.pants))')
        s.Source = src
        return "BebeqAvatarLocal preview updated!"
    end
    return "BebeqAvatarLocal not found"
  `, 'Edit');
  console.log('Result 2:', res2);

  console.log('Updating BebeqAvatarServer to ensure template textures are applied directly...');
  const res3 = await executeLuau(`
    local s = game:GetService("ServerScriptService"):FindFirstChild("BebeqAvatarServer", true)
    if s then
        s.Source = [===[-- ServerScriptService.BebeqAvatarServer
-- Applies Suwa Life costumes to player characters safely and instantly with verified textures
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local outfitEvent = ReplicatedStorage:FindFirstChild("ApplyOutfitEvent")
if not outfitEvent then
	outfitEvent = Instance.new("RemoteEvent")
	outfitEvent.Name = "ApplyOutfitEvent"
	outfitEvent.Parent = ReplicatedStorage
end

local CostumeConfig = require(ReplicatedStorage:WaitForChild("SuwaCostumeConfig"))

outfitEvent.OnServerEvent:Connect(function(player, action, outfitId)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	if action == "Apply" and outfitId then
		local preset = CostumeConfig.GetById(outfitId)
		if not preset then return end

		local currentDesc = hum:GetAppliedDescription() or Instance.new("HumanoidDescription")
		local currentEmotes = currentDesc:GetEmotes()
		local currentEquipped = currentDesc:GetEquippedEmotes()

		-- Clone current description to preserve body shape, hair, and accessories
		local newDesc = currentDesc:Clone()
		newDesc.Shirt = preset.shirt
		newDesc.Pants = preset.pants

		pcall(function()
			newDesc:SetEmotes(currentEmotes)
			newDesc:SetEquippedEmotes(currentEquipped)
		end)

		-- Apply description officially
		pcall(function()
			hum:ApplyDescription(newDesc)
		end)

		-- Direct template application to ensure 100% instant textures and no plain/blank outfits
		local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
		shirt.ShirtTemplate = preset.shirtTemplate or ("rbxassetid://" .. tostring(preset.shirt))

		local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
		pants.PantsTemplate = preset.pantsTemplate or ("rbxassetid://" .. tostring(preset.pants))

	elseif action == "Reset" then
		local success, defaultDesc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end)

		if success and defaultDesc then
			local currentDesc = hum:GetAppliedDescription()
			if currentDesc then
				pcall(function()
					defaultDesc:SetEmotes(currentDesc:GetEmotes())
					defaultDesc:SetEquippedEmotes(currentDesc:GetEquippedEmotes())
				end)
			end
			pcall(function()
				hum:ApplyDescription(defaultDesc)
			end)
		end
	end
end)
]===]
        return "BebeqAvatarServer updated!"
    end
    return "BebeqAvatarServer not found"
  `, 'Edit');
  console.log('Result 3:', res3);
}

main().catch(console.error);
