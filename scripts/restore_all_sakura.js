const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local count = 0
local SAKURA_PINK = Color3.fromRGB(255, 172, 206)

for _, desc in ipairs(workspace:GetDescendants()) do
  if desc:IsA("MeshPart") and (desc.MeshId:find("5547037928") or (desc.Name == "Leaf" and desc.Parent and desc.Parent.Name:find("tree"))) then
    -- 1. Remove broken SurfaceAppearance that renders as dead grey
    local sa = desc:FindFirstChildOfClass("SurfaceAppearance")
    if sa then
      sa:Destroy()
    end
    
    -- 2. Restore lush, vibrant Japanese Sakura pink
    desc.Color = SAKURA_PINK
    desc.Material = Enum.Material.SmoothPlastic
    desc.CastShadow = false
    
    count = count + 1
  end
end

return string.format("Successfully restored %d sakura trees to authentic vibrant pink!", count)
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  // Capture user perspective at ParkTree6
  const treePos = [-28.0, 17.0, -155.0];
  const camPos = [-8.0, 13.0, -148.0];
  const out1 = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/sakura_restored_user_view.png";
  await captureScreen(out1, camPos, treePos);
  console.log("Captured user perspective to:", out1);

  // Capture wide park perspective showing multiple restored sakura trees
  const parkTreePos = [-60.0, 18.0, -155.0];
  const wideCamPos = [35.0, 28.0, -130.0];
  const out2 = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/sakura_restored_park_wide.png";
  await captureScreen(out2, wideCamPos, parkTreePos);
  console.log("Captured wide park view to:", out2);
}

main().catch(console.error);
