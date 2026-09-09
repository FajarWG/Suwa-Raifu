const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace:FindFirstChild("🌸 Sakura Cherry Blossom Spring Tree Realistic")
if not tree then return "not found" end
tree:PivotTo(CFrame.new(0, 100, 0))
local cf, sz = tree:GetBoundingBox()
return string.format("Tree at pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f)", cf.X, cf.Y, cf.Z, sz.X, sz.Y, sz.Z)
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);

  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/realistic_sakura_tree_preview.png";
  await captureScreen(out, [0.0, 105.0, 45.0], [0.0, 100.0, 0.0]);
  console.log("Captured preview to:", out);
}

main().catch(console.error);
