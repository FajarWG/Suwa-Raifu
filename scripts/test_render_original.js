const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "OriginalCherryBlossomM not found" end

local clone = orig:Clone()
clone.Name = "TestOriginalFromStore"
-- Move it right beside the camera so we can inspect it directly
clone:PivotTo(CFrame.new(-18.0, 10.0, -150.0))
clone.Parent = workspace
return "Placed TestOriginalFromStore at (-18, 10, -150)"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  const treePos = [-18.0, 16.0, -150.0];
  const camPos = [-4.0, 14.0, -145.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/original_creator_store_rendered.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured original model to:", out);
}

main().catch(console.error);
