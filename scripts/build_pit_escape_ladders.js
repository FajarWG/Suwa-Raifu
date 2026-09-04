const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Building Scramble Pit Escape Ladders...');
  const code = `
local trail = workspace.SuwaMountainTrail

-- Find the lower step at the entrance of the scramble boulders
local lowerStep = nil
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" and (c.Position - Vector3.new(-249.5, 382.0, -2025.7)).Magnitude < 3 then
        lowerStep = c
        break
    end
end

local topLanding = trail:FindFirstChild("ScrambleTop")

-- 1. Create Lower Pit Escape Ladder
-- Lower step is at Y = 382.0. Pit floor below is at Y = 368.5.
-- Ladder will go from Y = 367.0 up to Y = 384.5 (height 18)
local lowerLadderModel = trail:FindFirstChild("ScrambleLowerEscapeLadder")
if lowerLadderModel then lowerLadderModel:Destroy() end

lowerLadderModel = Instance.new("Model")
lowerLadderModel.Name = "ScrambleLowerEscapeLadder"
lowerLadderModel.Parent = trail

local lowerTruss = Instance.new("TrussPart")
lowerTruss.Name = "EscapeLadderTruss"
lowerTruss.Size = Vector3.new(2, 16, 2)
lowerTruss.CFrame = CFrame.new(-251.5, 375.0, -2027.5) * CFrame.Angles(0, math.rad(-35), 0)
lowerTruss.Color = Color3.fromRGB(110, 80, 55)
lowerTruss.Material = Enum.Material.Wood
lowerTruss.Anchored = true
lowerTruss.CanCollide = true
lowerTruss.Parent = lowerLadderModel

-- Add wooden side posts / handrails for rustic trail aesthetic
local leftRail = Instance.new("Part")
leftRail.Name = "SideRailLeft"
leftRail.Size = Vector3.new(0.6, 18, 0.6)
leftRail.CFrame = lowerTruss.CFrame * CFrame.new(-1.3, 0.5, 0)
leftRail.Color = Color3.fromRGB(85, 60, 40)
leftRail.Material = Enum.Material.Wood
leftRail.Anchored = true
leftRail.CanCollide = true
leftRail.Parent = lowerLadderModel

local rightRail = Instance.new("Part")
rightRail.Name = "SideRailRight"
rightRail.Size = Vector3.new(0.6, 18, 0.6)
rightRail.CFrame = lowerTruss.CFrame * CFrame.new(1.3, 0.5, 0)
rightRail.Color = Color3.fromRGB(85, 60, 40)
rightRail.Material = Enum.Material.Wood
rightRail.Anchored = true
rightRail.CanCollide = true
rightRail.Parent = lowerLadderModel

-- Small wooden platform at bottom of ladder so player lands cleanly
local bottomPlat = Instance.new("Part")
bottomPlat.Name = "LadderFootPlatform"
bottomPlat.Size = Vector3.new(5, 1, 4)
bottomPlat.CFrame = CFrame.new(-251.5, 367.5, -2029.0) * CFrame.Angles(0, math.rad(-35), 0)
bottomPlat.Color = Color3.fromRGB(95, 70, 45)
bottomPlat.Material = Enum.Material.WoodPlanks
bottomPlat.Anchored = true
bottomPlat.CanCollide = true
bottomPlat.Parent = lowerLadderModel

-- 2. Create Upper Pit Escape Ladder (at ScrambleTop)
-- ScrambleTop is at Y = 387.0. Deep pit below is at Y = 352.0.
-- Height = 36 studs.
local upperLadderModel = trail:FindFirstChild("ScrambleUpperEscapeLadder")
if upperLadderModel then upperLadderModel:Destroy() end

upperLadderModel = Instance.new("Model")
upperLadderModel.Name = "ScrambleUpperEscapeLadder"
upperLadderModel.Parent = trail

local upperTruss = Instance.new("TrussPart")
upperTruss.Name = "EscapeLadderTruss"
upperTruss.Size = Vector3.new(2, 38, 2)
upperTruss.CFrame = CFrame.new(-260.0, 369.0, -2070.5) * CFrame.Angles(0, math.rad(145), 0)
upperTruss.Color = Color3.fromRGB(110, 80, 55)
upperTruss.Material = Enum.Material.Wood
upperTruss.Anchored = true
upperTruss.CanCollide = true
upperTruss.Parent = upperLadderModel

local upLeftRail = Instance.new("Part")
upLeftRail.Name = "SideRailLeft"
upLeftRail.Size = Vector3.new(0.6, 40, 0.6)
upLeftRail.CFrame = upperTruss.CFrame * CFrame.new(-1.3, 0.5, 0)
upLeftRail.Color = Color3.fromRGB(85, 60, 40)
upLeftRail.Material = Enum.Material.Wood
upLeftRail.Anchored = true
upLeftRail.CanCollide = true
upLeftRail.Parent = upperLadderModel

local upRightRail = Instance.new("Part")
upRightRail.Name = "SideRailRight"
upRightRail.Size = Vector3.new(0.6, 40, 0.6)
upRightRail.CFrame = upperTruss.CFrame * CFrame.new(1.3, 0.5, 0)
upRightRail.Color = Color3.fromRGB(85, 60, 40)
upRightRail.Material = Enum.Material.Wood
upRightRail.Anchored = true
upRightRail.CanCollide = true
upRightRail.Parent = upperLadderModel

local upBottomPlat = Instance.new("Part")
upBottomPlat.Name = "LadderFootPlatform"
upBottomPlat.Size = Vector3.new(5, 1, 4)
upBottomPlat.CFrame = CFrame.new(-260.0, 350.5, -2069.0) * CFrame.Angles(0, math.rad(145), 0)
upBottomPlat.Color = Color3.fromRGB(95, 70, 45)
upBottomPlat.Material = Enum.Material.WoodPlanks
upBottomPlat.Anchored = true
upBottomPlat.CanCollide = true
upBottomPlat.Parent = upperLadderModel

-- 3. Clear terrain in front of both ladders so climbing volume is unobstructed
local t = workspace.Terrain
t:FillBlock(lowerTruss.CFrame * CFrame.new(0, 0, -1.2), Vector3.new(4, 18, 3), Enum.Material.Air)
t:FillBlock(upperTruss.CFrame * CFrame.new(0, 0, -1.2), Vector3.new(4, 40, 3), Enum.Material.Air)

return "Successfully built escape ladders at both ends of Scramble Pit!"
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Capture verification screenshots:
  // 1. From above the pit looking down at the boulders and the new ladder (matching Image 3)
  console.log('Capturing pit views...');
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pit_overview.png', [-250, 402, -2020], [-258, 375, -2055]);
  
  // 2. From inside the pit looking up at the lower ladder
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pit_lower_ladder.png', [-254, 370, -2036], [-251.5, 376, -2027]);

  // 3. From inside the pit looking up at the upper ladder
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_pit_upper_ladder.png', [-256, 360, -2060], [-260, 375, -2071]);

  console.log('All verification captures completed!');
}

main().catch(console.error);
