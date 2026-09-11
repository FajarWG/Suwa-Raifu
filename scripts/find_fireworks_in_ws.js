const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local matches = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    local name = desc.Name:lower()
    if name:find("firework") or name:find("hanabi") or name:find("bebeq") or name:find("mortar") or name:find("petasan") then
        table.insert(matches, string.format("%s (%s) - Parent: %s", desc:GetFullName(), desc.ClassName, desc.Parent and desc.Parent.Name or "nil"))
    end
end
return "Found " .. #matches .. " firework/hanabi descendants:\\n" .. table.concat(matches, "\\n", 1, math.min(#matches, 60))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
