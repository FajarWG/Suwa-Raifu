const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
-- 1. Remove leftover test models
local testNames = {"TestOriginalFromStore", "PureStoreModelAtParkTree6", "CreatorStorePreview", "ComparisonTrees", "TestProperPBRTree"}
for _, name in ipairs(testNames) do
  local t = workspace:FindFirstChild(name)
  if t then t:Destroy() end
end

-- 2. Normalize function for a sakura tree
local FACES = {
  Enum.NormalId.Front,
  Enum.NormalId.Back,
  Enum.NormalId.Top,
  Enum.NormalId.Bottom,
  Enum.NormalId.Left,
  Enum.NormalId.Right,
}

local function normalizeLeaf(leaf)
  leaf.Color = Color3.new(0.639216, 0.635294, 0.647059)
  leaf.Material = Enum.Material.Plastic
  leaf.TextureID = "rbxassetid://4668043207"
  leaf.Transparency = 0
  leaf.CastShadow = false

  -- Configure SurfaceAppearance with clean non-metallic PBR
  local sa = leaf:FindFirstChildOfClass("SurfaceAppearance")
  if not sa then
    sa = Instance.new("SurfaceAppearance")
    sa.Parent = leaf
  end
  sa.ColorMap = "rbxassetid://4668043207"
  sa.MetalnessMap = ""
  sa.NormalMap = ""
  sa.RoughnessMap = ""
  sa.AlphaMode = Enum.AlphaMode.Transparency

  -- Ensure fallback Texture instances exist for all 6 faces
  for _, face in ipairs(FACES) do
    local found = false
    for _, ch in ipairs(leaf:GetChildren()) do
      if ch:IsA("Texture") and ch.Face == face then
        ch.Texture = "rbxassetid://4668043207"
        ch.Color3 = Color3.new(1, 1, 1)
        found = true
        break
      end
    end
    if not found then
      local tex = Instance.new("Texture")
      tex.Face = face
      tex.Texture = "rbxassetid://4668043207"
      tex.Color3 = Color3.new(1, 1, 1)
      tex.Parent = leaf
    end
  end
end

-- 3. Apply to CoupleSwingSakuraTree and ParkTree6 for verification
local swingTree = workspace.SuwaLakesidePark.SuwaLakesidePlayground:FindFirstChild("CoupleSwingSakuraTree")
if swingTree then
  local l = swingTree:FindFirstChild("Leaf", true)
  if l then normalizeLeaf(l) end
end

local park6 = workspace.SuwaLakesidePark.NaturalShorelineDetails:FindFirstChild("ParkTree6")
if park6 then
  local l = park6:FindFirstChild("Leaf", true)
  if l then normalizeLeaf(l) end
end

return "Normalized CoupleSwingSakuraTree and ParkTree6"
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);

  // Capture NIGHT view at swings (matching user screenshot)
  await executeLuau(`game:GetService("Lighting").ClockTime = 21.5`, "Edit");
  const outNight = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/normalized_swing_night.png";
  await captureScreen(outNight, [-310.0, 15.5, -120.0], [-308.0, 16.0, -138.0]);
  console.log("Captured night view to:", outNight);

  // Capture DAY view at swings (ClockTime = 14:00)
  await executeLuau(`game:GetService("Lighting").ClockTime = 14.0`, "Edit");
  const outDay = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/normalized_swing_day.png";
  await captureScreen(outDay, [-310.0, 15.5, -120.0], [-308.0, 16.0, -138.0]);
  console.log("Captured day view to:", outDay);

  // Restore
  await executeLuau(`game:GetService("Lighting").ClockTime = 17.45`, "Edit");
}

main().catch(console.error);
