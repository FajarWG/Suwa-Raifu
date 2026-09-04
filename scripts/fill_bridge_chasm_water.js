const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")
local terrain = workspace.Terrain

-- 1. Remove the old 69-step BridgeReturnTrail and west truss ladder
local oldTrail = trail:FindFirstChild("BridgeReturnTrail")
if oldTrail then oldTrail:Destroy() end

-- 2. Fill the deep chasm with Water
-- The crater floor is at Y = 61. We fill water up to Y = 115!
terrain:FillBlock(CFrame.new(12, 88, -1570), Vector3.new(45, 54, 50), Enum.Material.Water)

-- 3. Add a floating wooden dock / ladder platform in the water
local waterModel = Instance.new("Model")
waterModel.Name = "BridgeChasmWaterEscape"
waterModel.Parent = trail

local dockY = 115.5
local dockPos = Vector3.new(10, dockY, -1548)

local dock = Instance.new("Part")
dock.Name = "WaterEscapeDock"
dock.Size = Vector3.new(10, 1.2, 8)
dock.CFrame = CFrame.new(dockPos)
dock.Material = Enum.Material.WoodPlanks
dock.Color = Color3.fromRGB(115, 80, 50)
dock.Anchored = true
dock.Parent = waterModel

-- Dock Lantern
local dLanternPost = Instance.new("Part")
dLanternPost.Name = "DockLanternPost"
dLanternPost.Size = Vector3.new(0.6, 6, 0.6)
dLanternPost.CFrame = dock.CFrame * CFrame.new(3.5, 3.6, 2.5)
dLanternPost.Material = Enum.Material.Wood
dLanternPost.Color = Color3.fromRGB(80, 55, 35)
dLanternPost.Anchored = true
dLanternPost.Parent = waterModel

local dLantern = Instance.new("Part")
dLantern.Name = "DockLantern"
dLantern.Size = Vector3.new(1.0, 1.4, 1.0)
dLantern.CFrame = dLanternPost.CFrame * CFrame.new(0, 3.2, 0)
dLantern.Material = Enum.Material.Neon
dLantern.Color = Color3.fromRGB(255, 210, 130)
dLantern.Anchored = true
dLantern.Parent = waterModel

local dLgt = Instance.new("PointLight")
dLgt.Color = Color3.fromRGB(255, 175, 90)
dLgt.Brightness = 2.8
dLgt.Range = 26
dLgt.Shadows = true
dLgt.Parent = dLantern

-- Dock Sign
local dSign = Instance.new("Part")
dSign.Name = "DockSign"
dSign.Size = Vector3.new(6.5, 1.5, 0.3)
dSign.CFrame = dLanternPost.CFrame * CFrame.new(-3.5, 1.0, 0)
dSign.Material = Enum.Material.Wood
dSign.Color = Color3.fromRGB(45, 30, 20)
dSign.Anchored = true
dSign.Parent = waterModel

local dSg = Instance.new("SurfaceGui")
dSg.Face = Enum.NormalId.Front
dSg.Parent = dSign

local dTxt = Instance.new("TextLabel")
dTxt.Size = UDim2.new(1, 0, 1, 0)
dTxt.BackgroundTransparency = 1
dTxt.Text = "つり橋 復帰ハシゴ\\nBRIDGE ESCAPE LADDER (RETRY)"
dTxt.TextColor3 = Color3.fromRGB(250, 240, 220)
dTxt.Font = Enum.Font.SourceSansBold
dTxt.TextScaled = true
dTxt.Parent = dSg

-- 4. Clean vertical escape ladder from the dock up to the bridge entrance platform
-- Dock is at Y = 115.5, bridge entrance is at (10, 163.6, -1535)
-- Height to climb = 163.6 - 115.5 = ~48 studs!
local ladderHeight = 49
local ladderTruss = Instance.new("TrussPart")
ladderTruss.Name = "ChasmEscapeTruss"
ladderTruss.Size = Vector3.new(2, ladderHeight, 2)
ladderTruss.CFrame = CFrame.new(10.0, 115.5 + ladderHeight/2, -1537.0)
ladderTruss.Material = Enum.Material.Wood
ladderTruss.Color = Color3.fromRGB(130, 90, 55)
ladderTruss.Anchored = true
ladderTruss.CanCollide = true
ladderTruss.Parent = waterModel

-- Side guard posts
local postL = Instance.new("Part")
postL.Name = "LadderPostL"
postL.Size = Vector3.new(0.6, ladderHeight + 2, 0.6)
postL.CFrame = CFrame.new(8.6, 115.5 + (ladderHeight + 2)/2, -1537.0)
postL.Material = Enum.Material.Wood
postL.Color = Color3.fromRGB(80, 55, 35)
postL.Anchored = true
postL.Parent = waterModel

local postR = Instance.new("Part")
postR.Name = "LadderPostR"
postR.Size = Vector3.new(0.6, ladderHeight + 2, 0.6)
postR.CFrame = CFrame.new(11.4, 115.5 + (ladderHeight + 2)/2, -1537.0)
postR.Material = Enum.Material.Wood
postR.Color = Color3.fromRGB(80, 55, 35)
postR.Anchored = true
postR.Parent = waterModel

-- Top Landing connection to bridge deck
local topLanding = Instance.new("Part")
topLanding.Name = "LadderTopLanding"
topLanding.Size = Vector3.new(5, 0.8, 4)
topLanding.CFrame = CFrame.new(10.0, 164.0, -1536.0)
topLanding.Material = Enum.Material.WoodPlanks
topLanding.Color = Color3.fromRGB(115, 80, 50)
topLanding.Anchored = true
topLanding.Parent = waterModel

return { success = true, waterY = dockY, ladderHeight = ladderHeight }
`;

  console.log('Filling Chasm with Water & Building Escape Dock...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot from similar angle as Image 2 & 3
  console.log('Capturing water chasm screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_water_chasm.png',
    [10, 175, -1530],
    [12, 115, -1560]
  );
  console.log('Water chasm screenshot captured!');
}

main().catch(console.error);
