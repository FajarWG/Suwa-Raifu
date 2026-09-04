const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

-- Remove old model if exists
local oldLadder = trail:FindFirstChild("PillarPitEscapeLadder")
if oldLadder then oldLadder:Destroy() end

local model = Instance.new("Model")
model.Name = "PillarPitEscapeLadder"
model.Parent = trail

-- Top landing is at the start platform of the stepping pillars:
-- Start platform is at (-14, 172.7, -1660)
-- Pit floor right below it is at (-14, 132.5, -1663)
local topPos = Vector3.new(-14.0, 173.5, -1662.0)
local bottomPos = Vector3.new(-14.0, 132.5, -1663.5)
local height = topPos.Y - bottomPos.Y -- ~41 studs

-- 1. Pit Floor Landing Platform
local landing = Instance.new("Part")
landing.Name = "PitLandingPlatform"
landing.Size = Vector3.new(10, 1.2, 8)
landing.CFrame = CFrame.new(bottomPos + Vector3.new(0, 0.6, 2))
landing.Material = Enum.Material.WoodPlanks
landing.Color = Color3.fromRGB(115, 80, 50)
landing.Anchored = true
landing.Parent = model

-- 2. Escape Truss Ladder
local truss = Instance.new("TrussPart")
truss.Name = "EscapeTruss"
truss.Size = Vector3.new(2, height + 3, 2)
-- Angle slightly backwards against the cliff
truss.CFrame = CFrame.new(bottomPos + Vector3.new(0, (height + 3)/2, 0))
truss.Material = Enum.Material.Wood
truss.Color = Color3.fromRGB(130, 90, 55)
truss.Anchored = true
truss.CanCollide = true
truss.Parent = model

-- 3. Side Guide Posts & Handrails along the ladder
local postL = Instance.new("Part")
postL.Name = "LadderPostL"
postL.Size = Vector3.new(0.6, height + 4, 0.6)
postL.CFrame = CFrame.new(bottomPos + Vector3.new(-1.4, (height + 4)/2, 0))
postL.Material = Enum.Material.Wood
postL.Color = Color3.fromRGB(80, 55, 35)
postL.Anchored = true
postL.Parent = model

local postR = Instance.new("Part")
postR.Name = "LadderPostR"
postR.Size = Vector3.new(0.6, height + 4, 0.6)
postR.CFrame = CFrame.new(bottomPos + Vector3.new(1.4, (height + 4)/2, 0))
postR.Material = Enum.Material.Wood
postR.Color = Color3.fromRGB(80, 55, 35)
postR.Anchored = true
postR.Parent = model

-- 4. Bottom Lantern & Sign
local lanternPost = Instance.new("Part")
lanternPost.Name = "LanternPost"
lanternPost.Size = Vector3.new(0.6, 6, 0.6)
lanternPost.CFrame = landing.CFrame * CFrame.new(3.5, 3.6, 2.5)
lanternPost.Material = Enum.Material.Wood
lanternPost.Color = Color3.fromRGB(80, 55, 35)
lanternPost.Anchored = true
lanternPost.Parent = model

local lantern = Instance.new("Part")
lantern.Name = "PitLantern"
lantern.Size = Vector3.new(1.0, 1.4, 1.0)
lantern.CFrame = lanternPost.CFrame * CFrame.new(0, 3.2, 0)
lantern.Material = Enum.Material.Neon
lantern.Color = Color3.fromRGB(255, 210, 130)
lantern.Anchored = true
lantern.Parent = model

local lgt = Instance.new("PointLight")
lgt.Color = Color3.fromRGB(255, 175, 90)
lgt.Brightness = 2.8
lgt.Range = 24
lgt.Shadows = true
lgt.Parent = lantern

local sign = Instance.new("Part")
sign.Name = "PitSign"
sign.Size = Vector3.new(6.5, 1.5, 0.3)
sign.CFrame = lanternPost.CFrame * CFrame.new(-3.5, 1.0, 0)
sign.Material = Enum.Material.Wood
sign.Color = Color3.fromRGB(45, 30, 20)
sign.Anchored = true
sign.Parent = model

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = sign

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "柱飛び 復帰ハシゴ\\nPILLAR ESCAPE LADDER (RETRY)"
txt.TextColor3 = Color3.fromRGB(250, 240, 220)
txt.Font = Enum.Font.SourceSansBold
txt.TextScaled = true
txt.Parent = sg

-- 5. Top Exit Step / Platform onto TrailStep
local topStep = Instance.new("Part")
topStep.Name = "TopEscapeLanding"
topStep.Size = Vector3.new(6, 0.8, 4)
topStep.CFrame = CFrame.new(-14.0, 173.0, -1661.0)
topStep.Material = Enum.Material.WoodPlanks
topStep.Color = Color3.fromRGB(115, 80, 50)
topStep.Anchored = true
topStep.Parent = model

return { success = true, height = height }
`;

  console.log('Building Pillar Pit Escape Ladder...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture screenshot from bottom of pit looking up the ladder
  console.log('Capturing pit ladder screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pillar_pit_ladder.png',
    [-14, 136, -1656],
    [-14, 155, -1663]
  );

  // Capture top view looking down into pit (similar to Image 2)
  console.log('Capturing top down pit screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pillar_pit_top_down.png',
    [-14, 185, -1650],
    [-22, 160, -1675]
  );
  console.log('Pillar pit screenshots captured!');
}

main().catch(console.error);
