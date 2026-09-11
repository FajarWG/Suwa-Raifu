const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ksp = game:GetService("KeyframeSequenceProvider")
local ss = game:GetService("ServerStorage")

local ok, kfs = pcall(function()
    return ksp:GetKeyframeSequenceAsync("rbxassetid://102422651829022")
end)

if not ok or not kfs then return "Fetch failed: " .. tostring(kfs) end

local cloneOk, clone = pcall(function()
    return kfs:Clone()
end)

local cloneParentOk, err = false, ""
if cloneOk and clone then
    cloneParentOk, err = pcall(function()
        clone.Parent = ss
    end)
    if cloneParentOk then clone:Destroy() end
end

return string.format("Original archivable: %s, locked: %s | Clone ok: %s | Clone parent ok: %s (err: %s)",
    tostring(kfs.Archivable), tostring(kfs.DataCost), tostring(cloneOk), tostring(cloneParentOk), tostring(err))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
