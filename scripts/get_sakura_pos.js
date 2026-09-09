const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.ShorelineExtensions.ShoreSakura_8
local leaf = tree:FindFirstChild("Leaf", true)
local trunk = tree:FindFirstChild("Trunk", true) or tree:FindFirstChildWhichIsA("BasePart", true)

local pos = leaf and leaf.Position or (trunk and trunk.Position or Vector3.zero)
return string.format("Tree pos: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
