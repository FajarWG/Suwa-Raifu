const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local pt6 = game.ReplicatedStorage:FindFirstChild("ParkTree6")
local clone = workspace:FindFirstChild("PureStoreModelAtParkTree6")

local cf1, sz1 = pt6:GetBoundingBox()
local cf2, sz2 = clone:GetBoundingBox()

clone:ScaleTo(sz1.Y / sz2.Y)
clone:PivotTo(cf1)

return "Scaled clone to match pt6"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  const treePos = [-28.0, 17.0, -155.0];
  const camPos = [-8.0, 13.0, -148.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/pure_creator_store_scaled.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured scaled pure store model to:", out);
}

main().catch(console.error);
