const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local pt6 = game.ReplicatedStorage:FindFirstChild("ParkTree6")
local clone = workspace:FindFirstChild("PureStoreModelAtParkTree6")

local cf1, sz1 = pt6:GetBoundingBox()
local cf2, sz2 = clone:GetBoundingBox()

return string.format("pt6 pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f)\\nclone pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f)",
  cf1.Position.X, cf1.Position.Y, cf1.Position.Z, sz1.X, sz1.Y, sz1.Z,
  cf2.Position.X, cf2.Position.Y, cf2.Position.Z, sz2.X, sz2.Y, sz2.Z)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
