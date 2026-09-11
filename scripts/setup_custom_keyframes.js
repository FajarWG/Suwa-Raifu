const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ksp = game:GetService("KeyframeSequenceProvider")
local ss = game:GetService("ServerStorage")
local rs = game:GetService("ReplicatedStorage")

-- 1. Remove broken animations from ReplicatedStorage.Emotes
local emotesFolder = rs:FindFirstChild("Emotes")
local brokenNames = { ["Shake Dance"] = true, ["Tuff"] = true, ["If You're The Best"] = true }
local removed = {}

if emotesFolder then
    for _, child in ipairs(emotesFolder:GetChildren()) do
        if brokenNames[child.Name] then
            table.insert(removed, child.Name)
            child:Destroy()
        end
    end
end

-- 2. Setup ServerStorage.CustomEmoteKeyframes
local customKfsFolder = ss:FindFirstChild("CustomEmoteKeyframes")
if not customKfsFolder then
    customKfsFolder = Instance.new("Folder")
    customKfsFolder.Name = "CustomEmoteKeyframes"
    customKfsFolder.Parent = ss
end

local addedKfs = {}

-- 3. Download Brazil Dances into CustomEmoteKeyframes if not present
local brazilDances = {
    { name = "Dance Brazil", assetId = "102422651829022" },
    { name = "Brazilian Phonk", assetId = "94117880039127" }
}

for _, b in ipairs(brazilDances) do
    local existing = customKfsFolder:FindFirstChild(b.name)
    if not existing then
        local ok, kfs = pcall(function()
            return ksp:GetKeyframeSequenceAsync("rbxassetid://" .. b.assetId)
        end)
        if ok and kfs then
            local clone = kfs:Clone()
            clone.Name = b.name
            clone.Parent = customKfsFolder
            kfs:Destroy()
            table.insert(addedKfs, b.name .. " (fetched & cloned from " .. b.assetId .. ")")
        else
            table.insert(addedKfs, b.name .. " (FAILED to fetch: " .. tostring(kfs) .. ")")
        end
    else
        table.insert(addedKfs, b.name .. " (already exists)")
    end
end

-- 4. Copy selected top dances from Pack_IndianCode
local pack = ss:FindFirstChild("Pack_IndianCode")
local animSaves = pack and pack:FindFirstChild("Dummy") and pack.Dummy:FindFirstChild("AnimSaves")
local extraDances = {
    "Orange Justice",
    "Floss",
    "Electro Shuffle",
    "Macarena",
    "Take The L",
    "Default Dance",
    "Breakdown"
}

if animSaves then
    for _, danceName in ipairs(extraDances) do
        local existing = customKfsFolder:FindFirstChild(danceName)
        if not existing then
            local orig = animSaves:FindFirstChild(danceName)
            if orig and orig:IsA("KeyframeSequence") then
                local clone = orig:Clone()
                clone.Parent = customKfsFolder
                table.insert(addedKfs, danceName .. " (copied from AnimSaves)")
            end
        else
            table.insert(addedKfs, danceName .. " (already exists)")
        end
    end
end

local lines = {}
table.insert(lines, "Removed broken emotes: " .. table.concat(removed, ", "))
table.insert(lines, "CustomEmoteKeyframes count: " .. #customKfsFolder:GetChildren())
for _, child in ipairs(customKfsFolder:GetChildren()) do
    table.insert(lines, "  - " .. child.Name .. " (" .. child.ClassName .. ")")
end

return table.concat(lines, "\\n")
`;

  console.log('Running setup in Edit datamodel...');
  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
