const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local ladder = trail.CliffLadder
local cf = ladder.CFrame

-- Extend ladder downward by 4 studs so it firmly touches LedgeFoot floor
-- Current center Y: 697, height 28 -> extends 683 to 711
-- New height: 32, center Y: 695 -> extends 679 to 711
ladder.Size = Vector3.new(2, 32, 2)
ladder.CFrame = CFrame.new(cf.Position.X, 695, cf.Position.Z) * cf.Rotation

-- Also add 2 extra rungs at the bottom
local r1 = Instance.new("Part")
r1.Name = "CliffLadderRung"
r1.Size = Vector3.new(3.8, 0.4, 0.5)
r1.Material = Enum.Material.Wood
r1.Color = Color3.fromRGB(110, 80, 55)
r1.Anchored = true
r1.CanCollide = false
r1.CFrame = ladder.CFrame * CFrame.new(0, -14, 0)
r1.Parent = trail

local r2 = Instance.new("Part")
r2.Name = "CliffLadderRung"
r2.Size = Vector3.new(3.8, 0.4, 0.5)
r2.Material = Enum.Material.Wood
r2.Color = Color3.fromRGB(110, 80, 55)
r2.Anchored = true
r2.CanCollide = false
r2.CFrame = ladder.CFrame * CFrame.new(0, -12, 0)
r2.Parent = trail

-- Also ensure LedgeFoot extends slightly under ladder
local foot = trail.LedgeFoot
foot.Size = Vector3.new(16, 2.6, 16)

return "Ladder extended to ground successfully!"
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_cliff_ladder_grounded.png', [-419, 685, -2420], [-425, 695, -2425]);
  console.log('Saved verify_cliff_ladder_grounded.png');
}

main().catch(console.error);
