const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.NaturalShorelineDetails.ParkTree6
local leaf = tree:FindFirstChild("Leaf", true)
if leaf then
  local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
  if sa then
    sa.Parent = nil
  end
  leaf.Color = Color3.fromRGB(255, 170, 205) -- Beautiful Japanese Sakura Pink
  leaf.Material = Enum.Material.SmoothPlastic
  leaf.CastShadow = false -- Eliminates harsh dark self-shadows on foliage
  return "Updated ParkTree6 leaf"
end
return "Leaf not found in ParkTree6"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  // Position camera standing on path/grass looking towards ParkTree6 and school/sun in background
  const treePos = [-28.0, 17.0, -155.0];
  const camPos = [-8.0, 13.0, -148.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/parktree6_pink_test.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured ParkTree6 test to:", out);
}

main().catch(console.error);
