const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local StarterGui = game:GetService("StarterGui")
local emoteGui = StarterGui:FindFirstChild("EmoteSystemGui")
if not emoteGui then return "No EmoteSystemGui found" end

local lines = {}
for _, desc in ipairs(emoteGui:GetDescendants()) do
    if desc:IsA("LocalScript") or desc:IsA("Script") or desc:IsA("ModuleScript") then
        table.insert(lines, string.format("Script: %s (%s) - Parent: %s", desc:GetFullName(), desc.ClassName, desc.Parent.Name))
    end
end

return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
