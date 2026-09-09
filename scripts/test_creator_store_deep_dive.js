const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local comp = workspace:FindFirstChild("ComparisonTrees")
if comp then comp:Destroy() end

comp = Instance.new("Folder")
comp.Name = "ComparisonTrees"
comp.Parent = workspace

local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "orig not found" end

-- Option A: Untouched Original Creator Store
local tA = orig:Clone()
tA.Name = "A_OriginalStore"
tA:PivotTo(CFrame.new(-60, 100, 0))
tA.Parent = comp

-- Option B: MetalnessMap = "" only (keep original RoughnessMap 257545122, NormalMap = "")
local tB = orig:Clone()
tB.Name = "B_NoMetal_OriginalRough"
local saB = tB:FindFirstChildWhichIsA("SurfaceAppearance", true)
if saB then
  saB.MetalnessMap = ""
  saB.NormalMap = ""
  -- keep saB.RoughnessMap = "rbxassetid://257545122"
end
tB:PivotTo(CFrame.new(-20, 100, 0))
tB.Parent = comp

-- Option C: AlphaMode = Overlay (with no metalness)
local tC = orig:Clone()
tC.Name = "C_AlphaOverlay"
local saC = tC:FindFirstChildWhichIsA("SurfaceAppearance", true)
if saC then
  saC.MetalnessMap = ""
  saC.NormalMap = ""
  saC.AlphaMode = Enum.AlphaMode.Overlay
end
tC:PivotTo(CFrame.new(20, 100, 0))
tC.Parent = comp

-- Option D: No SurfaceAppearance, MeshPart Transparency = 0.01 (Classic alpha cutout)
local tD = orig:Clone()
tD.Name = "D_MeshPart_AlphaCutout"
local leafD = tD:FindFirstChild("Leaf", true)
if leafD then
  local sa = leafD:FindFirstChildOfClass("SurfaceAppearance")
  if sa then sa:Destroy() end
  leafD.TextureID = "rbxassetid://4668043207"
  leafD.Transparency = 0.01
  leafD.Color = Color3.fromRGB(255, 255, 255)
end
tD:PivotTo(CFrame.new(60, 100, 0))
tD.Parent = comp

return "Deep dive options A, B, C, D created"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_options_abcd.png";
  await captureScreen(out, [0.0, 105.0, 120.0], [0.0, 100.0, 0.0]);
  console.log("Captured ABCD comparison to:", out);
}

main().catch(console.error);
