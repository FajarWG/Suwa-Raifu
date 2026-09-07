const { executeLuau } = require('./mcp-exec.js');

(async () => {
  const code = `
    local seven = workspace.TownRoadNetwork.TownBlocks.Store_7ElevenClean.Model["Seven Eleven"]
    if not seven then return "Seven Eleven not found!" end

    -- Helper to create or get an invisible trigger part with a prompt
    local function setupTrigger(name, cf, size, actionText, objectText, maxDist, shopKey)
      local existing = seven:FindFirstChild(name)
      if existing then existing:Destroy() end

      local p = Instance.new("Part")
      p.Name = name
      p.CFrame = cf
      p.Size = size
      p.Transparency = 1
      p.Anchored = true
      p.CanCollide = false
      p.Parent = seven

      local prompt = Instance.new("ProximityPrompt")
      prompt.Name = "SevenElevenPrompt"
      prompt.ActionText = actionText
      prompt.ObjectText = objectText
      prompt.MaxActivationDistance = maxDist or 13
      prompt.RequiresLineOfSight = false
      prompt.HoldDuration = 0
      prompt.Parent = p

      prompt.Triggered:Connect(function(player)
        local FishingData = require(game:GetService("ReplicatedStorage").Shared.data.Fishing)
        local ProfileService = require(game:GetService("ServerScriptService").Server.services.ProfileService)
        local RemoteRegistry = require(game:GetService("ServerScriptService").Server.services.RemoteRegistryService)

        local shopData = table.clone(FishingData.shops[shopKey] or FishingData.shops["seven_eleven"])
        shopData.shopId = shopKey
        shopData.id = shopKey
        shopData.title = shopData.name
        shopData.catalog = shopData.items
        local profile = ProfileService.getProfile(player.UserId)
        shopData.yen = profile and profile.economy.yen or 500
        RemoteRegistry.fireClient(player, "OpenShop", shopData)
      end)

      return p
    end

    -- Remove old poorly-positioned prompts from cooler and shelves
    for _, d in ipairs(seven:GetDescendants()) do
      if d:IsA("ProximityPrompt") and (d.Parent.Name == "Smooth Block Model" or d.Parent.Name == "Part") and not d.Parent.Name:find("Register") and not d.Parent.Name:find("Torso") and not d.Parent.Name:find("Trigger") then
        d:Destroy()
      end
    end

    -- 1. Cooler Doors (Picture 3)
    setupTrigger("Trigger_CoolerLeft", CFrame.new(126.0, 10.5, 70.8), Vector3.new(7, 6, 2),
      "商品を見る / Browse (E)", "7-Eleven 冷蔵ドリンク (Cold Drinks)", 14, "seven_eleven_drinks")

    setupTrigger("Trigger_CoolerRight", CFrame.new(138.0, 10.5, 70.8), Vector3.new(7, 6, 2),
      "商品を見る / Browse (E)", "7-Eleven 冷蔵ドリンク (Cold Drinks)", 14, "seven_eleven_drinks")

    -- 2. Soda & Slurpee Machine (Picture 4)
    setupTrigger("Trigger_SodaMachine", CFrame.new(148.5, 11.2, 53.0), Vector3.new(2.5, 4.5, 4.5),
      "ドリンクを注ぐ / Pour Drink (E)", "7-Eleven スラーピー・ドリンクバー (Slurpee & Soda)", 13, "seven_eleven_slurpee")

    -- 3. Chips & Junk Food Rack (Picture 3, right side next to Doritos)
    setupTrigger("Trigger_JunkRack", CFrame.new(148.0, 10.5, 57.2), Vector3.new(2.5, 5.0, 7.5),
      "商品を見る / Browse (E)", "7-Eleven スナック・ポテトチップス (Chips & Snacks)", 13, "seven_eleven_food")

    -- 4. Bento & Meals Shelf (Picture 2, under Coca-Cola)
    setupTrigger("Trigger_BentoShelf", CFrame.new(106.5, 10.2, 39.0), Vector3.new(11, 3.5, 2.5),
      "商品を見る / Browse (E)", "7-Eleven お弁当・ご飯 (Bento & Meals)", 14, "seven_eleven_food")

    -- 5. Window Shelf (Picture 1, front window)
    setupTrigger("Trigger_WindowShelf", CFrame.new(141.0, 10.2, 39.0), Vector3.new(14, 3.5, 2.5),
      "商品を見る / Browse (E)", "7-Eleven おにぎり・お菓子 (Snacks & Onigiri)", 14, "seven_eleven_food")

    return "Successfully configured all triggers for Cooler, Soda Machine, Chips Rack, and Shelves!"
  `;
  const res = await executeLuau(code, 'Server');
  console.log(res);
})();
