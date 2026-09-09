const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local tree = workspace.SuwaLakesidePark.ShorelineExtensions.ShoreSakura_8
local leaf = tree:FindFirstChild("Leaf", true)
if leaf then
  local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
  if sa then
    sa.Parent = nil -- temporarily remove
  end
  leaf.Color = Color3.fromRGB(255, 165, 195) -- Sakura pink
  leaf.Material = Enum.Material.SmoothPlastic
  return "Updated Leaf color to pink and removed SurfaceAppearance"
end
return "Leaf not found"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  const treePos = [-846.0, 22.0, -155.0];
  const camPos = [-825.0, 26.0, -175.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_pink_test.png";
  
  await captureScreen(out, camPos, treePos);
  console.log("Captured test to:", out);
}

main().catch(console.error);
