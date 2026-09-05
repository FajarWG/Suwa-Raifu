import subprocess, json

with open('scripts/scratch_StudioFishingGameService.lua', 'r') as f:
    code = f.read()

# 1. Replace buildShop prompt triggered
old_prompt = """\tprompt.Triggered:Connect(function(player)
\t\tactiveShops[player] = { id = shopId, expiresAt = os.clock() + 30 }
\t\tRemoteRegistry.fireClient(player, 'OpenShop', FishingData.shops[shopId])
\tend)"""

new_prompt = """\tprompt.Triggered:Connect(function(player)
\t\tactiveShops[player] = { id = shopId, expiresAt = os.clock() + 30 }
\t\tlocal shopData = table.clone(FishingData.shops[shopId])
\t\tshopData.title = shopData.name
\t\tshopData.catalog = shopData.items
\t\tlocal profile = ProfileService.getProfile(player.UserId)
\t\tshopData.yen = profile and profile.economy.yen or 999999
\t\tRemoteRegistry.fireClient(player, 'OpenShop', shopData)
\tend)"""

assert old_prompt in code, 'old_prompt not found'
code = code.replace(old_prompt, new_prompt)

# 2. Replace buyItem and inventoryAction
p_buy_start = code.find('local function buyItem(player: Player, payload: any)')
p_buy_end = code.find('local function inventoryAction(', p_buy_start)
p_inv_end = code.find('function FishingGameService.init()', p_buy_end)

new_buy_and_inv = '''local function buyItem(player: Player, payload: any)
\tif typeof(payload) ~= 'table' or typeof(payload.shopId) ~= 'string' or typeof(payload.itemId) ~= 'string' then
\t\treturn
\tend
\tlocal access = activeShops[player]
\tif not access or access.id ~= payload.shopId or access.expiresAt < os.clock() then
\t\tRemoteRegistry.fireClient(player, 'ShopResult', false, 'Move closer to the shop counter.')
\t\treturn
\tend
\tlocal shop = FishingData.shops[payload.shopId]
\tif not shop then
\t\treturn
\tend
\tlocal selected = nil
\tfor _, item in shop.items do
\t\tif item.id == payload.itemId then
\t\t\tselected = item
\t\t\tbreak
\t\tend
\tend
\tif not selected then
\t\treturn
\tend
\tlocal profile = ProfileService.getProfile(player.UserId)
\tif not profile then
\t\tRemoteRegistry.fireClient(player, 'ShopResult', false, 'Profile is still loading.')
\t\treturn
\tend
\tif selected.price > 0 and profile.economy.yen < selected.price then
\t\tRemoteRegistry.fireClient(player, 'ShopResult', false, 'Not enough yen.')
\t\treturn
\tend
\tif selected.price > 0 then
\t\tprofile.economy.yen -= selected.price
\tend
\tInventoryService.addItem(player.UserId, selected.id, selected.amount or 1)
\tpushInventory(player)
\tRemoteRegistry.fireClient(player, 'ShopResult', true, 'Added ' .. selected.name .. ' to Bag!')
end

local function inventoryAction(player: Player, payload: any)
\tif typeof(payload) ~= 'table' or typeof(payload.id) ~= 'string' then
\t\treturn
\tend
\tlocal profile = ProfileService.getProfile(player.UserId)
\tif not profile then
\t\treturn
\tend
\tlocal id = payload.id
\tif payload.category == 'fish' then
\t\tif (profile.inventory.fish[id] or 0) <= 0 then
\t\t\treturn
\t\tend
\t\tif payload.action == 'sell' then
\t\t\tlocal def = FishingData.fish and FishingData.fish[id]
\t\t\tlocal price = def and def.price or 150
\t\t\tprofile.inventory.fish[id] -= 1
\t\t\tif profile.inventory.fish[id] <= 0 then
\t\t\t\tprofile.inventory.fish[id] = nil
\t\t\tend
\t\t\tprofile.economy.yen += price
\t\t\tpushInventory(player)
\t\t\tRemoteRegistry.fireClient(player, 'ShopResult', true, 'Sold ' .. (def and def.name or id) .. ' for ¥' .. tostring(price) .. '!')
\t\t\treturn
\t\tend
\t\tlocal definition = FishingData.fish and FishingData.fish[id]
\t\tif definition then
\t\t\tcreateFishTool(player, id, definition.name, definition.color)
\t\tend
\telse
\t\tif (profile.inventory.items[id] or 0) <= 0 then
\t\t\treturn
\t\tend
\t\tcreateSimpleItemTool(player, id, FishingData.itemNames[id] or id)
\tend
end

'''

code = code[:p_buy_start] + new_buy_and_inv + code[p_inv_end:]

# 3. Replace createSimpleItemTool
with open('src/server/services/FishingGameService.lua', 'r') as f_src:
    src_code = f_src.read()

p_tool_start_src = src_code.find('local function createSimpleItemTool(')
p_tool_end_src = src_code.find('local function removeSessionVisuals(', p_tool_start_src)
assert p_tool_start_src != -1 and p_tool_end_src != -1
new_tool_func = src_code[p_tool_start_src:p_tool_end_src]

p_tool_start_dst = code.find('local function createSimpleItemTool(')
p_tool_end_dst = code.find('local function removeSessionVisuals(', p_tool_start_dst)
assert p_tool_start_dst != -1 and p_tool_end_dst != -1
code = code[:p_tool_start_dst] + new_tool_func + code[p_tool_end_dst:]

with open('src/server/services/FishingGameService.lua', 'w') as f_out:
    f_out.write(code)

print('Updated src/server/services/FishingGameService.lua successfully! New length:', len(code))
