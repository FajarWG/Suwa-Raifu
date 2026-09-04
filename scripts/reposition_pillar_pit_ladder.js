const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

-- 1. Remove old ladder model
local oldLadder = trail:FindFirstChild("PillarPitEscapeLadder")
if oldLadder then oldLadder:Destroy() end

local model = Instance.new("Model")
model.Name = "PillarPitEscapeLadder"
model.Parent = trail

-- Find the start platform step
local plat = nil
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" and (c.Position - Vector3.new(-14, 172.6, -1660)).Magnitude < 2 then
        plat = c
        break
    end
end
local platCf = plat.CFrame

-- Position the ladder on the SIDE of the platform (shifted 6.0 studs to the side, away from the jumping path)
-- Side position: platCf * CFrame.new(-5.8, 0, -1.5)
local sideTopCf = platCf * CFrame.new(-5.8, 0.4, -1.5)
local sideTopPos = sideTopCf.Position
local groundY = 132.5
local height = sideTopPos.Y - groundY -- ~40.5 studs

local ladderCf = CFrame.new(sideTopPos.X, groundY + height/2, sideTopPos.Z) * (platCf - platCf.Position)

-- 1. Pit Floor Landing Platform
local pitPlat = Instance.new("Part")
pitPlat.Name = "PitLandingPlatform"
pitPlat.Size = Vector3.new(8, 1.2, 8)
pitPlat.CFrame = CFrame.new(sideTopPos.X, groundY + 0.6, sideTopPos.Z) * (platCf - platCf.Position)
pitPlat.Material = Enum.Material.WoodPlanks
pitPlat.Color = Color3.fromRGB(115, 80, 50)
pitPlat.Anchored = true
pitPlat.Parent = model

-- 2. Escape Truss Ladder
local truss = Instance.new("TrussPart")
truss.Name = "EscapeTruss"
truss.Size = Vector3.new(2, height + 2, 2)
truss.CFrame = ladderCf
truss.Material = Enum.Material.Wood
truss.Color = Color3.fromRGB(130, 90, 55)
truss.Anchored = true
truss.CanCollide = true
truss.Parent = model

-- 3. Side Guide Posts
local postL = Instance.new("Part")
postL.Name = "LadderPostL"
postL.Size = Vector3.new(0.6, height + 3, 0.6)
postL.CFrame = ladderCf * CFrame.new(-1.3, 0.5, 0)
postL.Material = Enum.Material.Wood
postL.Color = Color3.fromRGB(80, 55, 35)
postL.Anchored = true
postL.Parent = model

local postR = Instance.new("Part")
postR.Name = "LadderPostR"
postR.Size = Vector3.new(0.6, height + 3, 0.6)
postR.CFrame = ladderCf * CFrame.new(1.3, 0.5, 0)
postR.Material = Enum.Material.Wood
postR.Color = Color3.fromRGB(80, 55, 35)
postR.Anchored = true
postR.Parent = model

-- 4. Top Side Landing Platform connecting cleanly to the main TrailStep
local sideLanding = Instance.new("Part")
sideLanding.Name = "SideEscapeLanding"
sideLanding.Size = Vector3.new(3.6, 0.8, 4.0)
sideLanding.CFrame = platCf * CFrame.new(-4.8, 0, -1.5)
sideLanding.Material = Enum.Material.WoodPlanks
sideLanding.Color = Color3.fromRGB(120, 85, 55)
sideLanding.Anchored = true
sideLanding.Parent = model

-- Guard post on side landing
local guardPost = Instance.new("Part")
guardPost.Name = "LandingGuardPost"
guardPost.Size = Vector3.new(0.5, 4.5, 0.5)
guardPost.CFrame = sideLanding.CFrame * CFrame.new(-1.6, 2.4, 1.8)
guardPost.Material = Enum.Material.Wood
guardPost.Color = Color3.fromRGB(80, 55, 35)
guardPost.Anchored = true
guardPost.Parent = model

-- 5. Bottom Lantern & Sign
local lanternPost = Instance.new("Part")
lanternPost.Name = "LanternPost"
lanternPost.Size = Vector3.new(0.6, 6, 0.6)
lanternPost.CFrame = pitPlat.CFrame * CFrame.new(3.0, 3.6, 2.5)
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
sign.CFrame = lanternPost.CFrame * CFrame.new(-3.0, 1.0, 0)
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

return { success = true, sidePos = {sideTopPos.X, sideTopPos.Y, sideTopPos.Z} }
`;

  console.log('Repositioning Pillar Pit Ladder to the Side...');
  const res = await executeLuau(code);
  console.log('Result:', res.content[0].text);

  // Capture top view matching user's image angle
  console.log('Capturing top-down view matching user image...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_ladder_shifted_side.png',
    [-11, 186, -1652],
    [-22, 171, -1674]
  );
  console.log('Shifted ladder screenshot captured!');
}

main().catch(console.error);
