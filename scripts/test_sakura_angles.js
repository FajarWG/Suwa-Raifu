const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local compFolder = workspace:FindFirstChild("ComparisonTrees")
if not compFolder then return "ComparisonTrees not found" end

local t2 = compFolder:FindFirstChild("2_PBR_NonMetallic")
if t2 then
  local leaf = t2:FindFirstChild("Leaf", true)
  if leaf then
    leaf.Color = Color3.fromRGB(255, 255, 255)
    local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
    if sa then
      sa.RoughnessMap = "" -- remove roughness map if it makes it too glossy/dark
    end
  end
end

-- Add Tree 4: PBR with full white tint and default roughness
local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
local t4 = orig:Clone()
t4.Name = "4_Tuned_PBR"
local leaf4 = t4:FindFirstChild("Leaf", true)
if leaf4 then
  leaf4.Color = Color3.fromRGB(255, 240, 245)
  local sa = leaf4:FindFirstChildOfClass("SurfaceAppearance")
  if sa then
    sa.MetalnessMap = ""
    sa.NormalMap = ""
    sa.RoughnessMap = ""
  end
end
t4:PivotTo(CFrame.new(80, 100, 0))
t4.Parent = compFolder

return "Configured trees"
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : res);

  // Capture from Sunlit side (West looking East towards X=0):
  // Sun is at ~ClockTime 17.45 (West).
  // If camera is at X = -120, Y = 110, Z = 0 looking at (0, 100, 0): Sun is behind the camera!
  const targetPosSunlit = [0.0, 100.0, 0.0];
  const camPosSunlit = [-110.0, 110.0, 0.0];
  const outSunlit = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_sunlit_angle.png";
  await captureScreen(outSunlit, camPosSunlit, targetPosSunlit);
  console.log("Captured sunlit angle to:", outSunlit);

  // Also capture from daytime ClockTime = 14:00 (mid-afternoon standard bright light)
  await executeLuau(`
    game:GetService("Lighting").ClockTime = 14.0
  `, 'Edit');

  const outNoon = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_daytime_comparison.png";
  await captureScreen(outNoon, [0.0, 105.0, 100.0], [0.0, 100.0, 0.0]);
  console.log("Captured daytime to:", outNoon);

  // Revert ClockTime to 17.45
  await executeLuau(`
    game:GetService("Lighting").ClockTime = 17.45
  `, 'Edit');
}

main().catch(console.error);
