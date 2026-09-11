const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local tagged = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc:IsA("BasePart") and desc:GetAttribute("FireworksLaunchPoint") then
        table.insert(tagged, string.format("%s pos=(%.1f, %.1f, %.1f)", desc:GetFullName(), desc.Position.X, desc.Position.Y, desc.Position.Z))
    end
end
return "Tagged FireworksLaunchPoint count: " .. #tagged .. "\\n" .. table.concat(tagged, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
