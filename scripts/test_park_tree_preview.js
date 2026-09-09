const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local park = workspace:FindFirstChild("SuwaLakesidePark")
local natural = park and park:FindFirstChild("NaturalShorelineDetails")
if not natural then return "NaturalShorelineDetails not found" end

-- Check ParkTree6
local existing6 = natural:FindFirstChild("ParkTree6")
local targetCF = existing6 and existing6:GetPivot() or CFrame.new(78.5, 93.4, -46.7)

local previewName = "ParkTree6_FixedPreview"
if natural:FindFirstChild(previewName) then natural[previewName]:Destroy() end

local orig = game.ReplicatedStorage:FindFirstChild("OriginalCherryBlossomM")
if not orig then return "OriginalCherryBlossomM not found" end

local newTree = orig:Clone()
newTree.Name = previewName

-- Apply the proper PBR fix to the foliage
local leaf = newTree:FindFirstChild("Leaf", true)
if leaf then
  leaf.Color = Color3.fromRGB(255, 255, 255)
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
end

-- Also hide existing6 temporarily so we see the new one
if existing6 then existing6.Parent = game.ReplicatedStorage end

newTree:PivotTo(targetCF)
newTree.Parent = natural

return "Placed " .. previewName .. " at " .. tostring(targetCF.Position)
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);

  // Position camera on the park walking path looking at ParkTree6
  const targetPos = [78.5, 97.0, -46.7];
  const camPos = [105.0, 95.0, -25.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/park_tree6_fixed_preview.png";

  await captureScreen(out, camPos, targetPos);
  console.log("Captured park preview to:", out);
}

main().catch(console.error);
