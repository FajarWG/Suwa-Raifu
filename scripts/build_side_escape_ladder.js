const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail

-- Remove previous test ladders
if trail:FindFirstChild("ScrambleLowerEscapeLadder") then trail.ScrambleLowerEscapeLadder:Destroy() end
if trail:FindFirstChild("ScrambleUpperEscapeLadder") then trail.ScrambleUpperEscapeLadder:Destroy() end

local ladderModel = Instance.new("Model")
ladderModel.Name = "ScramblePitEscapeLadder"
ladderModel.Parent = trail

-- Entrance step is at pos=(-249.54, 382.05, -2025.69), size=(9, 3.4, 7.23)
-- Right edge of entrance step is at X = -245.0, Z = -2025 to -2029, Y = 383.7 (top surface)
-- Pit floor below is at X = -246.0, Z = -2036.0, Y = 369.0
-- Height diff = 14.7 studs, horizontal diff in Z = 8 studs

-- Create a sturdy wooden ladder angled along the bank
-- TrussPart for climbing
local truss = Instance.new("TrussPart")
truss.Name = "EscapeTruss"
truss.Size = Vector3.new(3, 18, 2)
-- Angle ladder slightly (tilted 15 degrees back against the bank)
truss.CFrame = CFrame.new(-245.0, 376.5, -2031.5) * CFrame.Angles(math.rad(15), math.rad(180), 0)
truss.Color = Color3.fromRGB(110, 80, 55)
truss.Material = Enum.Material.Wood
truss.Anchored = true
truss.CanCollide = true
truss.Parent = ladderModel

-- Left & Right wooden side beams
local leftBeam = Instance.new("Part")
leftBeam.Name = "SideBeamLeft"
leftBeam.Size = Vector3.new(0.6, 20, 0.6)
leftBeam.CFrame = truss.CFrame * CFrame.new(-1.7, 0, 0)
leftBeam.Color = Color3.fromRGB(80, 55, 35)
leftBeam.Material = Enum.Material.Wood
leftBeam.Anchored = true
leftBeam.CanCollide = true
leftBeam.Parent = ladderModel

local rightBeam = Instance.new("Part")
rightBeam.Name = "SideBeamRight"
rightBeam.Size = Vector3.new(0.6, 20, 0.6)
rightBeam.CFrame = truss.CFrame * CFrame.new(1.7, 0, 0)
rightBeam.Color = Color3.fromRGB(80, 55, 35)
rightBeam.Material = Enum.Material.Wood
rightBeam.Anchored = true
rightBeam.CanCollide = true
rightBeam.Parent = ladderModel

-- Handrail posts at top of the ladder
local topPostLeft = Instance.new("Part")
topPostLeft.Name = "HandrailPostLeft"
topPostLeft.Size = Vector3.new(0.6, 4, 0.6)
topPostLeft.CFrame = CFrame.new(-246.7, 385.0, -2029.0)
topPostLeft.Color = Color3.fromRGB(80, 55, 35)
topPostLeft.Material = Enum.Material.Wood
topPostLeft.Anchored = true
topPostLeft.CanCollide = true
topPostLeft.Parent = ladderModel

local topPostRight = Instance.new("Part")
topPostRight.Name = "HandrailPostRight"
topPostRight.Size = Vector3.new(0.6, 4, 0.6)
topPostRight.CFrame = CFrame.new(-243.3, 385.0, -2029.0)
topPostRight.Color = Color3.fromRGB(80, 55, 35)
topPostRight.Material = Enum.Material.Wood
topPostRight.Anchored = true
topPostRight.CanCollide = true
topPostRight.Parent = ladderModel

-- Top connecting handrail bar
local topBar = Instance.new("Part")
topBar.Name = "HandrailBar"
topBar.Size = Vector3.new(4, 0.4, 0.6)
topBar.CFrame = CFrame.new(-245.0, 386.8, -2029.0)
topBar.Color = Color3.fromRGB(80, 55, 35)
topBar.Material = Enum.Material.Wood
topBar.Anchored = true
topBar.CanCollide = true
topBar.Parent = ladderModel

-- Bottom wooden landing platform
local footPlat = Instance.new("Part")
footPlat.Name = "PitFootPlatform"
footPlat.Size = Vector3.new(6, 1, 5)
footPlat.CFrame = CFrame.new(-245.0, 368.5, -2034.5)
footPlat.Color = Color3.fromRGB(95, 70, 45)
footPlat.Material = Enum.Material.WoodPlanks
footPlat.Anchored = true
footPlat.CanCollide = true
footPlat.Parent = ladderModel

-- Clear terrain in front of the ladder for climbing clearance
local t = workspace.Terrain
t:FillBlock(truss.CFrame * CFrame.new(0, 0, -1.5), Vector3.new(5, 20, 4), Enum.Material.Air)

-- Also add a sign pointing to the ladder at the bottom: "TANGGA NAIK" or simple lantern/sign
local signPost = Instance.new("Part")
signPost.Name = "SignPost"
signPost.Size = Vector3.new(0.4, 4, 0.4)
signPost.CFrame = CFrame.new(-241.5, 370.5, -2034.5)
signPost.Color = Color3.fromRGB(80, 55, 35)
signPost.Material = Enum.Material.Wood
signPost.Anchored = true
signPost.CanCollide = true
signPost.Parent = ladderModel

local signBoard = Instance.new("Part")
signBoard.Name = "SignBoard"
signBoard.Size = Vector3.new(2.4, 1.2, 0.3)
signBoard.CFrame = CFrame.new(-241.5, 372.2, -2034.5) * CFrame.Angles(0, math.rad(-90), 0)
signBoard.Color = Color3.fromRGB(230, 215, 190)
signBoard.Material = Enum.Material.Wood
signBoard.Anchored = true
signBoard.CanCollide = false
signBoard.Parent = ladderModel

local sGui = Instance.new("SurfaceGui")
sGui.Face = Enum.NormalId.Front
sGui.Parent = signBoard
local sText = Instance.new("TextLabel")
sText.Size = UDim2.new(1, 0, 1, 0)
sText.BackgroundTransparency = 1
sText.Text = "⬆ TANGGA"
sText.TextColor3 = Color3.fromRGB(60, 40, 20)
sText.TextScaled = true
sText.Font = Enum.Font.FredokaOne
sText.Parent = sGui

return "New rustic escape ladder successfully created at side of entrance deck!"
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Take screenshot matching user's Image 3 perspective (standing on entrance bridge looking into pit)
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pit_ladder_from_bridge.png', [-249.5, 388, -2020], [-252, 375, -2045]);

  // Take screenshot from inside the pit looking up at the ladder and sign
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pit_ladder_from_below.png', [-246.0, 370.0, -2045.0], [-245.0, 376.5, -2031.5]);

  console.log('Finished capturing screenshots!');
}

main().catch(console.error);
