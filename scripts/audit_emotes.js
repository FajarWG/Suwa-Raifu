const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local rs = game:GetService("ReplicatedStorage")
local emotes = rs:FindFirstChild("Emotes")
if not emotes then
    return "No Emotes folder found in ReplicatedStorage"
end

local lines = {}
table.insert(lines, "Emotes children count: " .. #emotes:GetChildren())
for _, child in ipairs(emotes:GetChildren()) do
    local animId = child:IsA("Animation") and child.AnimationId or "N/A"
    table.insert(lines, string.format("- [%s] Class: %s, ID: %s", child.Name, child.ClassName, animId))
end
return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error);
