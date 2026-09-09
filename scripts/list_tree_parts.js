const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.ShorelineExtensions.ShoreSakura_8
local rep = {}
for _, desc in ipairs(tree:GetDescendants()) do
  if desc:IsA("BasePart") then
    table.insert(rep, string.format("%s (%s) Pos=(%.1f,%.1f,%.1f) Size=(%.1f,%.1f,%.1f) Color=(%.2f,%.2f,%.2f) Class=%s",
      desc:GetFullName(), desc.Name, desc.Position.X, desc.Position.Y, desc.Position.Z,
      desc.Size.X, desc.Size.Y, desc.Size.Z, desc.Color.R, desc.Color.G, desc.Color.B, desc.ClassName))
  end
end
return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
