const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
if not bebeq then return "No BebeqFireworkSystem" end

local lines = {}
table.insert(lines, "Bebeq children count: " .. #bebeq:GetChildren())
for _, child in ipairs(bebeq:GetChildren()) do
    local posStr = ""
    if child:IsA("Model") then
        local pivot = child:GetPivot()
        posStr = string.format("pos=(%.1f, %.1f, %.1f)", pivot.Position.X, pivot.Position.Y, pivot.Position.Z)
    elseif child:IsA("BasePart") then
        posStr = string.format("pos=(%.1f, %.1f, %.1f)", child.Position.X, child.Position.Y, child.Position.Z)
    end
    table.insert(lines, string.format("- %s (%s) %s", child.Name, child.ClassName, posStr))
end

return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
