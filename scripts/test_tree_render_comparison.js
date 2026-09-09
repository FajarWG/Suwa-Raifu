const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "OriginalCherryBlossomM not found" end

local compFolder = workspace:FindFirstChild("ComparisonTrees")
if compFolder then compFolder:Destroy() end
compFolder = Instance.new("Folder")
compFolder.Name = "ComparisonTrees"
compFolder.Parent = workspace

-- Tree 1: Pure untouched Creator Store (with the metallic bug)
local tree1 = orig:Clone()
tree1.Name = "1_Original_CreatorStore"
tree1:PivotTo(CFrame.new(-40, 100, 0))
tree1.Parent = compFolder

-- Tree 2: PBR Fix (MetalnessMap and NormalMap cleared, keeping authentic ColorMap & AlphaMode)
local tree2 = orig:Clone()
tree2.Name = "2_PBR_NonMetallic"
for _, d in ipairs(tree2:GetDescendants()) do
  if d:IsA("SurfaceAppearance") then
    d.MetalnessMap = ""
    d.NormalMap = ""
    -- keep ColorMap = rbxassetid://4668043207, RoughnessMap, AlphaMode = Transparency
  end
end
tree2:PivotTo(CFrame.new(0, 100, 0))
tree2.Parent = compFolder

-- Tree 3: Classic Texture (SurfaceAppearance removed, pure MeshPart.TextureID = 4668043207)
local tree3 = orig:Clone()
tree3.Name = "3_Classic_TextureOnly"
for _, d in ipairs(tree3:GetDescendants()) do
  if d:IsA("SurfaceAppearance") then
    d:Destroy()
  end
end
tree3:PivotTo(CFrame.new(40, 100, 0))
tree3.Parent = compFolder

return "Comparison trees created at X = -40, 0, +40"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  // Capture wide shot of all 3 trees side by side
  const targetPos = [0.0, 100.0, 0.0];
  const camPos = [0.0, 105.0, 100.0];
  const outWide = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_three_way_comparison.png";
  await captureScreen(outWide, camPos, targetPos);
  console.log("Captured comparison to:", outWide);

  // Also capture close-up of Tree 2 (PBR Non-Metallic)
  const targetPos2 = [0.0, 100.0, 0.0];
  const camPos2 = [0.0, 103.0, 45.0];
  const outClose = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_pbr_fixed_closeup.png";
  await captureScreen(outClose, camPos2, targetPos2);
  console.log("Captured close-up to:", outClose);
}

main().catch(console.error);
