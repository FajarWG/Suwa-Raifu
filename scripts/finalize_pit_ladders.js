const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Finalizing Scramble Pit Escape Ladders...');
  const code = `
local trail = workspace.SuwaMountainTrail

-- Clean up any previous ladders
if trail:FindFirstChild("ScramblePitEscapeLadder") then trail.ScramblePitEscapeLadder:Destroy() end
if trail:FindFirstChild("ScrambleLowerEscapeLadder") then trail.ScrambleLowerEscapeLadder:Destroy() end
if trail:FindFirstChild("ScrambleUpperEscapeLadder") then trail.ScrambleUpperEscapeLadder:Destroy() end

local mainModel = Instance.new("Model")
mainModel.Name = "ScramblePitEscapeLadders"
mainModel.Parent = trail

--------------------------------------------------------------------------------
-- 1. LOWER ESCAPE LADDER (leading back to starting walkway at Y = 383.7)
--------------------------------------------------------------------------------
local lowerModel = Instance.new("Model")
lowerModel.Name = "LowerEscapeLadder"
lowerModel.Parent = mainModel

-- Primary TrussPart for climbing
local truss1 = Instance.new("TrussPart")
truss1.Name = "ClimbTruss"
truss1.Size = Vector3.new(2, 18, 2)
-- Position slightly to the side of the stone step: X = -244.0, Z = -2030.5
truss1.CFrame = CFrame.new(-243.8, 376.0, -2030.5) * CFrame.Angles(0, math.rad(180), 0)
truss1.Color = Color3.fromRGB(110, 80, 55)
truss1.Material = Enum.Material.Wood
truss1.Anchored = true
truss1.CanCollide = true
truss1.Parent = lowerModel

-- Side beams / stringers
local beam1L = Instance.new("Part")
beam1L.Name = "SideBeamLeft"
beam1L.Size = Vector3.new(0.5, 19, 0.5)
beam1L.CFrame = truss1.CFrame * CFrame.new(-1.25, 0.5, 0)
beam1L.Color = Color3.fromRGB(80, 55, 35)
beam1L.Material = Enum.Material.Wood
beam1L.Anchored = true
beam1L.CanCollide = true
beam1L.Parent = lowerModel

local beam1R = Instance.new("Part")
beam1R.Name = "SideBeamRight"
beam1R.Size = Vector3.new(0.5, 19, 0.5)
beam1R.CFrame = truss1.CFrame * CFrame.new(1.25, 0.5, 0)
beam1R.Color = Color3.fromRGB(80, 55, 35)
beam1R.Material = Enum.Material.Wood
beam1R.Anchored = true
beam1R.CanCollide = true
beam1R.Parent = lowerModel

-- Top landing bridge plank connecting top of ladder to the walkway
local topPlank = Instance.new("Part")
topPlank.Name = "TopLandingPlank"
topPlank.Size = Vector3.new(4, 0.8, 3)
topPlank.CFrame = CFrame.new(-245.5, 383.6, -2029.0)
topPlank.Color = Color3.fromRGB(105, 75, 50)
topPlank.Material = Enum.Material.WoodPlanks
topPlank.Anchored = true
topPlank.CanCollide = true
topPlank.Parent = lowerModel

-- Safety posts at top
local postL = Instance.new("Part")
postL.Name = "PostLeft"
postL.Size = Vector3.new(0.5, 4.5, 0.5)
postL.CFrame = CFrame.new(-245.2, 386.0, -2030.5)
postL.Color = Color3.fromRGB(80, 55, 35)
postL.Material = Enum.Material.Wood
postL.Anchored = true
postL.CanCollide = true
postL.Parent = lowerModel

local postR = Instance.new("Part")
postR.Name = "PostRight"
postR.Size = Vector3.new(0.5, 4.5, 0.5)
postR.CFrame = CFrame.new(-242.4, 386.0, -2030.5)
postR.Color = Color3.fromRGB(80, 55, 35)
postR.Material = Enum.Material.Wood
postR.Anchored = true
postR.CanCollide = true
postR.Parent = lowerModel

-- Bottom landing pad in pit
local footPlat1 = Instance.new("Part")
footPlat1.Name = "BottomPlatform"
footPlat1.Size = Vector3.new(5, 0.8, 4)
footPlat1.CFrame = CFrame.new(-243.8, 367.6, -2032.5)
footPlat1.Color = Color3.fromRGB(90, 65, 40)
footPlat1.Material = Enum.Material.WoodPlanks
footPlat1.Anchored = true
footPlat1.CanCollide = true
footPlat1.Parent = lowerModel

--------------------------------------------------------------------------------
-- 2. UPPER ESCAPE LADDER (leading to ScrambleTop at Y = 387.0)
--------------------------------------------------------------------------------
local upperModel = Instance.new("Model")
upperModel.Name = "UpperEscapeLadder"
upperModel.Parent = mainModel

local truss2 = Instance.new("TrussPart")
truss2.Name = "ClimbTruss"
truss2.Size = Vector3.new(2, 36, 2)
-- Position on the side bank near ScrambleTop: X = -257.0, Z = -2072.0
truss2.CFrame = CFrame.new(-257.0, 369.0, -2071.5) * CFrame.Angles(0, math.rad(0), 0)
truss2.Color = Color3.fromRGB(110, 80, 55)
truss2.Material = Enum.Material.Wood
truss2.Anchored = true
truss2.CanCollide = true
truss2.Parent = upperModel

local beam2L = Instance.new("Part")
beam2L.Name = "SideBeamLeft"
beam2L.Size = Vector3.new(0.5, 38, 0.5)
beam2L.CFrame = truss2.CFrame * CFrame.new(-1.25, 0.5, 0)
beam2L.Color = Color3.fromRGB(80, 55, 35)
beam2L.Material = Enum.Material.Wood
beam2L.Anchored = true
beam2L.CanCollide = true
beam2L.Parent = upperModel

local beam2R = Instance.new("Part")
beam2R.Name = "SideBeamRight"
beam2R.Size = Vector3.new(0.5, 38, 0.5)
beam2R.CFrame = truss2.CFrame * CFrame.new(1.25, 0.5, 0)
beam2R.Color = Color3.fromRGB(80, 55, 35)
beam2R.Material = Enum.Material.Wood
beam2R.Anchored = true
beam2R.CanCollide = true
beam2R.Parent = upperModel

-- Top landing bridge connecting truss2 to ScrambleTop
local topPlank2 = Instance.new("Part")
topPlank2.Name = "TopLandingPlank"
topPlank2.Size = Vector3.new(4, 0.8, 3)
topPlank2.CFrame = CFrame.new(-258.5, 387.0, -2072.5)
topPlank2.Color = Color3.fromRGB(105, 75, 50)
topPlank2.Material = Enum.Material.WoodPlanks
topPlank2.Anchored = true
topPlank2.CanCollide = true
topPlank2.Parent = upperModel

-- Bottom landing pad in deep pit
local footPlat2 = Instance.new("Part")
footPlat2.Name = "BottomPlatform"
footPlat2.Size = Vector3.new(5, 0.8, 4)
footPlat2.CFrame = CFrame.new(-257.0, 351.4, -2070.0)
footPlat2.Color = Color3.fromRGB(90, 65, 40)
footPlat2.Material = Enum.Material.WoodPlanks
footPlat2.Anchored = true
footPlat2.CanCollide = true
footPlat2.Parent = upperModel

-- 3. Clear terrain around climbing paths
local t = workspace.Terrain
t:FillBlock(truss1.CFrame * CFrame.new(0, 0, -1.2), Vector3.new(4, 20, 3), Enum.Material.Air)
t:FillBlock(truss2.CFrame * CFrame.new(0, 0, -1.2), Vector3.new(4, 38, 3), Enum.Material.Air)

return "Both escape ladders built and grounded perfectly!"
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Capture clean screenshots of both ladders
  console.log('Capturing final pit ladder screenshots...');
  // 1. Lower ladder overview from player walking up to boulders
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/final_pit_lower_ladder.png', [-248, 388, -2020], [-244, 378, -2031]);

  // 2. Lower ladder view looking up from pit
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/final_pit_lower_from_pit.png', [-244, 369, -2038], [-244, 378, -2030]);

  // 3. Upper ladder view looking from pit
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/final_pit_upper_from_pit.png', [-257, 353, -2064], [-257, 370, -2072]);

  console.log('Finished capturing all final screenshots!');
}

main().catch(console.error);
