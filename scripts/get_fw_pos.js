const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local fw = workspace:FindFirstChild("FerrisWheel", true)
local pos = fw and (fw:IsA("Model") and (fw.PrimaryPart and fw.PrimaryPart.Position or fw:GetBoundingBox().Position) or fw.Position) or Vector3.zero
return string.format("FerrisWheel pos: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
