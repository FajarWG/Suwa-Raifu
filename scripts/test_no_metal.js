const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local clone = workspace:FindFirstChild("PureStoreModelAtParkTree6")
if not clone then return "clone not found" end

local leaf = clone:FindFirstChild("Leaf", true)
if leaf then
  local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
  if sa then
    sa.MetalnessMap = ""
    sa.NormalMap = ""
    sa.RoughnessMap = ""
    return "Cleared MetalnessMap and NormalMap on SurfaceAppearance"
  end
end
return "Leaf or SA not found"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  const treePos = [-28.0, 16.0, -155.0];
  const camPos = [10.0, 14.0, -142.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/pure_store_no_metal.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured no-metal test to:", out);
}

main().catch(console.error);
