const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "OriginalCherryBlossomM not found" end

local preview = workspace:FindFirstChild("CreatorStorePreview")
if preview then preview:Destroy() end

preview = orig:Clone()
preview.Name = "CreatorStorePreview"
preview:PivotTo(CFrame.new(0, 100, 0))
preview.Parent = workspace

local cf, sz = preview:GetBoundingBox()
return string.format("Placed CreatorStorePreview at pos=(%.1f,%.1f,%.1f) size=(%.1f,%.1f,%.1f)",
  cf.Position.X, cf.Position.Y, cf.Position.Z, sz.X, sz.Y, sz.Z)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  // Position camera 50 studs away in front of the tree looking at center
  const targetPos = [0.0, 100.0, 0.0];
  const camPos = [0.0, 105.0, 60.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/creator_store_isolated_preview.png";

  await captureScreen(out, camPos, targetPos);
  console.log("Captured isolated preview to:", out);
}

main().catch(console.error);
