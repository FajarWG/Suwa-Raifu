const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local swingTree = workspace.SuwaLakesidePark.SuwaLakesidePlayground:FindFirstChild("CoupleSwingSakuraTree")
if not swingTree then return "CoupleSwingSakuraTree not found" end

local leaf = swingTree:FindFirstChild("Leaf", true)
if not leaf then return "Leaf not found" end

leaf.Color = Color3.fromRGB(255, 255, 255)
leaf.Material = Enum.Material.Plastic
leaf.TextureID = "rbxassetid://4668043207"

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

return "Updated CoupleSwingSakuraTree Leaf with authentic texture and fixed PBR"
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);

  // 1. Capture at NIGHT (ClockTime = 21.5, matching user screenshot)
  await executeLuau(`game:GetService("Lighting").ClockTime = 21.5`, "Edit");
  
  // Swings position

  const camPosNight = [-14.0, 96.0, -56.0];
  const targetPosNight = [-22.0, 97.0, -82.0];
  const outNight = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/swing_tree_night_test.png";
  await captureScreen(outNight, camPosNight, targetPosNight);
  console.log("Captured night swing to:", outNight);

  // 2. Capture at DAYTIME (ClockTime = 14.0)
  await executeLuau(`game:GetService("Lighting").ClockTime = 14.0`, "Edit");
  const outDay = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/swing_tree_day_test.png";
  await captureScreen(outDay, camPosNight, targetPosNight);
  console.log("Captured day swing to:", outDay);

  // Restore ClockTime to 17.45
  await executeLuau(`game:GetService("Lighting").ClockTime = 17.45`, "Edit");
}

main().catch(console.error);
