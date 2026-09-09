const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local clone = workspace:FindFirstChild("PureStoreModelAtParkTree6")
local cf, sz = clone:GetBoundingBox()
return string.format("Clone center: (%.1f, %.1f, %.1f) size=(%.1f, %.1f, %.1f)", cf.Position.X, cf.Position.Y, cf.Position.Z, sz.X, sz.Y, sz.Z)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);
}

main().catch(console.error);
