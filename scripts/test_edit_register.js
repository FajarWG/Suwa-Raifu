const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ksp = game:GetService("KeyframeSequenceProvider")
local ss = game:GetService("ServerStorage")
local customKfs = ss:FindFirstChild("CustomEmoteKeyframes")
if not customKfs then return "No CustomEmoteKeyframes folder" end

local results = {}
for _, kfs in ipairs(customKfs:GetChildren()) do
    if kfs:IsA("KeyframeSequence") then
        local ok, animId = pcall(function()
            return ksp:RegisterKeyframeSequence(kfs)
        end)
        table.insert(results, string.format("%s: ok=%s, animId=%s", kfs.Name, tostring(ok), tostring(animId)))
    end
end

return table.concat(results, "\\n")
`;

  console.log('Testing RegisterKeyframeSequence in Edit datamodel...');
  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
