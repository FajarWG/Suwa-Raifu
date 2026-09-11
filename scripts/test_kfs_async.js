const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ksp = game:GetService("KeyframeSequenceProvider")
local is = game:GetService("InsertService")

local testIds = {
    "102422651829022",
    "84593715197740",
    "116916777684513",
    "94117880039127",
    "121300673631453",
    "113482211171140",
    "127118661424463"
}

local lines = {}
for _, id in ipairs(testIds) do
    local ok, kfs = pcall(function()
        return ksp:GetKeyframeSequenceAsync("rbxassetid://" .. id)
    end)
    if ok and kfs then
        local keyframes = kfs:GetKeyframes()
        table.insert(lines, string.format("ID %s: KFS SUCCESS! Keyframes: %d, Length: %.2f", id, #keyframes, (keyframes[#keyframes] and keyframes[#keyframes].Time or 0)))
        kfs:Destroy()
    else
        table.insert(lines, string.format("ID %s: KFS failed: %s", id, tostring(kfs)))
    end
end
return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
