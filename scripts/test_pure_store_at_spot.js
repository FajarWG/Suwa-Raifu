const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "OriginalCherryBlossomM not found" end

-- Get existing ParkTree6 CFrame
local pt6 = workspace.SuwaLakesidePark.NaturalShorelineDetails.ParkTree6
local pt6CFrame = pt6:GetBoundingBox()

-- Replace or place clone right at ParkTree6 location
local testClone = workspace:FindFirstChild("PureStoreModelAtParkTree6")
if testClone then testClone:Destroy() end

testClone = orig:Clone()
testClone.Name = "PureStoreModelAtParkTree6"
testClone:PivotTo(pt6CFrame)
testClone.Parent = workspace

-- Temporarily hide existing ParkTree6 so only pure store model is visible
pt6.Parent = game.ReplicatedStorage

return "Placed 100% pure Creator Store model at ParkTree6"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  // Take screenshot from exact user camera angle
  const treePos = [-28.0, 17.0, -155.0];
  const camPos = [-8.0, 13.0, -148.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/pure_creator_store_at_user_spot.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured pure Creator Store model to:", out);
}

main().catch(console.error);
