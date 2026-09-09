const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function testFixedPBR() {
  const code = `
-- Clean up test objects
if workspace:FindFirstChild("ComparisonTrees") then workspace.ComparisonTrees:Destroy() end
if workspace:FindFirstChild("CreatorStorePreview") then workspace.CreatorStorePreview:Destroy() end
if workspace:FindFirstChild("🌸 Sakura Cherry Blossom Spring Tree Realistic") then
  workspace["🌸 Sakura Cherry Blossom Spring Tree Realistic"]:Destroy()
end

local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "orig not found" end

-- Create Test Tree with proper PBR maps
local testTree = orig:Clone()
testTree.Name = "TestProperPBRTree"
testTree:PivotTo(CFrame.new(0, 100, 0))

local leaf = testTree:FindFirstChild("Leaf", true)
if leaf then
  leaf.Color = Color3.fromRGB(255, 255, 255)
  local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
  if not sa then
    sa = Instance.new("SurfaceAppearance")
    sa.Parent = leaf
  end
  sa.ColorMap = "rbxassetid://4668043207"
  sa.MetalnessMap = ""
  sa.NormalMap = "rbxassetid://5058677660"
  sa.RoughnessMap = "rbxassetid://5058678265"
  sa.AlphaMode = Enum.AlphaMode.Transparency
end

testTree.Parent = workspace
return "Created TestProperPBRTree at 0, 100, 0"
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);

  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_proper_pbr_fixed.png";
  await captureScreen(out, [0.0, 105.0, 50.0], [0.0, 100.0, 0.0]);
  console.log("Captured fixed PBR to:", out);
}

testFixedPBR().catch(console.error);
