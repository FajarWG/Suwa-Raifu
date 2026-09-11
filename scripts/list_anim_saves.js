const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ss = game:GetService("ServerStorage")
local pack = ss:FindFirstChild("Pack_IndianCode")
local animSaves = pack and pack:FindFirstChild("Dummy") and pack.Dummy:FindFirstChild("AnimSaves")
if not animSaves then
    return "No AnimSaves found"
end

local names = {}
for _, child in ipairs(animSaves:GetChildren()) do
    if child:IsA("KeyframeSequence") then
        table.insert(names, child.Name)
    end
end
table.sort(names)
return string.format("Found %d KeyframeSequences:\\n%s", #names, table.concat(names, ", "))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
