const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local rep = {}
local leafCount = 0
local trunkCount = 0
local pileCount = 0

-- Clean up any test models in workspace
local testModels = {
  "TestOriginalFromStore",
  "PureStoreModelAtParkTree6",
  "CreatorStorePreview",
  "ComparisonTrees",
  "TestProperPBRTree",
  "ParkTree6_FixedPreview"
}
for _, name in ipairs(testModels) do
  local m = workspace:FindFirstChild(name)
  if m then m:Destroy() end
end

-- Also check inside NaturalShorelineDetails for test models
local natural = workspace:FindFirstChild("SuwaLakesidePark") and workspace.SuwaLakesidePark:FindFirstChild("NaturalShorelineDetails")
if natural then
  local p6 = natural:FindFirstChild("ParkTree6_FixedPreview")
  if p6 then p6:Destroy() end
  local stashed = game.ReplicatedStorage:FindFirstChild("ParkTree6")
  if stashed then stashed.Parent = natural end
end

local FACES = {
  Enum.NormalId.Front,
  Enum.NormalId.Back,
  Enum.NormalId.Top,
  Enum.NormalId.Bottom,
  Enum.NormalId.Left,
  Enum.NormalId.Right,
}

for _, desc in ipairs(workspace:GetDescendants()) do
  -- 1. Leaf MeshParts
  if desc:IsA("MeshPart") and (desc.MeshId:find("5547037928") or (desc.Name == "Leaf" and desc.Parent and desc.Parent.Name:find("tree"))) then
    desc.Color = Color3.fromRGB(255, 225, 235)
    desc.Material = Enum.Material.Plastic
    desc.TextureID = "rbxassetid://4668043207"
    desc.Transparency = 0
    desc.CastShadow = false

    local sa = desc:FindFirstChildOfClass("SurfaceAppearance")
    if not sa then
      sa = Instance.new("SurfaceAppearance")
      sa.Parent = desc
    end
    sa.ColorMap = "rbxassetid://4668043207"
    sa.MetalnessMap = ""
    sa.NormalMap = ""
    sa.RoughnessMap = ""
    sa.AlphaMode = Enum.AlphaMode.Transparency

    -- Ensure fallback 6 face textures
    for _, face in ipairs(FACES) do
      local found = false
      for _, ch in ipairs(desc:GetChildren()) do
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
        tex.Parent = desc
      end
    end
    leafCount = leafCount + 1

  -- 2. Trunk MeshParts
  elseif desc:IsA("MeshPart") and (desc.MeshId:find("740991432") or desc.Name:find("Dead tree") or desc.Name == "Tree") then
    desc.TextureID = "rbxassetid://740989141"
    desc.Color = Color3.new(0.639216, 0.635294, 0.647059)
    desc.Material = Enum.Material.Plastic
    trunkCount = trunkCount + 1

  -- 3. Ground flower piles
  elseif desc:IsA("MeshPart") and (desc.MeshId:find("4665707228") or desc.Name:lower():find("flowerpile") or desc.Name:lower():find("flower pile")) then
    desc.TextureID = "rbxassetid://4665748451"
    pileCount = pileCount + 1
  end
end

return string.format("Normalization complete: %d leaves, %d trunks, %d flower piles updated",
  leafCount, trunkCount, pileCount)
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);

  // Capture 1: Night time matching user's Ferris wheel view
  await executeLuau(`game:GetService("Lighting").ClockTime = 21.5`, "Edit");
  const out1 = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/normalized_ferris_night.png";
  // Camera near Ferris wheel looking at the park sakura tree and lake
  await captureScreen(out1, [-220.0, 30.0, -80.0], [-270.0, 35.0, -120.0]);
  console.log("Captured night Ferris view to:", out1);

  // Capture 2: Night time matching user's Swing view
  const out2 = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/normalized_swing_final_night.png";
  await captureScreen(out2, [-310.0, 15.5, -120.0], [-308.0, 16.0, -138.0]);
  console.log("Captured night swing view to:", out2);

  // Capture 3: Daytime matching park promenade view
  await executeLuau(`game:GetService("Lighting").ClockTime = 14.0`, "Edit");
  const out3 = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/normalized_park_day.png";
  await captureScreen(out3, [20.0, 20.0, -125.0], [-28.0, 20.0, -155.0]);
  console.log("Captured daytime park view to:", out3);

  // Restore
  await executeLuau(`game:GetService("Lighting").ClockTime = 17.45`, "Edit");
}

main().catch(console.error);
