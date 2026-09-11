const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ksp = game:GetService("KeyframeSequenceProvider")
local ss = game:GetService("ServerStorage")
local rs = game:GetService("ReplicatedStorage")

-- 1. Ensure Emotes folder exists
local emotesFolder = rs:FindFirstChild("Emotes")
if not emotesFolder then
    emotesFolder = Instance.new("Folder")
    emotesFolder.Name = "Emotes"
    emotesFolder.Parent = rs
end

-- 2. Delete broken emotes
local broken = { ["Shake Dance"] = true, ["Tuff"] = true, ["If You're The Best"] = true }
for _, child in ipairs(emotesFolder:GetChildren()) do
    if broken[child.Name] then
        child:Destroy()
    end
end

-- 3. Also mirror CustomEmoteKeyframes to ReplicatedStorage so client has access if needed
local srcKfs = ss:FindFirstChild("CustomEmoteKeyframes")
local repKfs = rs:FindFirstChild("CustomEmoteKeyframes")
if not repKfs then
    repKfs = Instance.new("Folder")
    repKfs.Name = "CustomEmoteKeyframes"
    repKfs.Parent = rs
end

if srcKfs then
    for _, kfs in ipairs(srcKfs:GetChildren()) do
        if not repKfs:FindFirstChild(kfs.Name) then
            local clone = kfs:Clone()
            clone.Parent = repKfs
        end
    end
end

-- 4. Register each KeyframeSequence and create Animation in ReplicatedStorage.Emotes
local registeredList = {}
for _, kfs in ipairs(srcKfs:GetChildren()) do
    if kfs:IsA("KeyframeSequence") then
        local ok, animId = pcall(function()
            return ksp:RegisterKeyframeSequence(kfs)
        end)
        if ok and animId then
            local anim = emotesFolder:FindFirstChild(kfs.Name)
            if not anim then
                anim = Instance.new("Animation")
                anim.Name = kfs.Name
                anim.Parent = emotesFolder
            end
            anim.AnimationId = animId
            table.insert(registeredList, string.format("%s -> %s", kfs.Name, animId))
        else
            table.insert(registeredList, string.format("%s FAILED: %s", kfs.Name, tostring(animId)))
        end
    end
end

local total = {}
for _, anim in ipairs(emotesFolder:GetChildren()) do
    table.insert(total, string.format("[%s] ID: %s", anim.Name, anim:IsA("Animation") and anim.AnimationId or "N/A"))
end
table.sort(total)

return "POPULATE SUCCESS! Total emotes in ReplicatedStorage.Emotes: " .. #total .. "\\n" .. table.concat(total, "\\n")
`;

  console.log('Populating emotes in Edit datamodel...');
  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
