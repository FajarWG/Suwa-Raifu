const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Fixing CliffLadder...');
  const code = `
local trail = workspace.SuwaMountainTrail
local top = trail.LedgeTop
local foot = trail.LedgeFoot
local ladder = trail.CliffLadder
local cf = top.CFrame

-- 1. Adjust LedgeTop so its front edge ends cleanly at local Z = -9.5
-- Original size: (17, 2.6, 24). Local Z ran from -12 to +12.
-- We adjust size in Z to 20, and shift center in local Z by +2
-- New local Z bounds: (-10 + 2 = -8) to (+10 + 2 = +12)
top.Size = Vector3.new(17, 2.6, 20)
top.CFrame = cf * CFrame.new(0, 0, 2)

-- 2. Position CliffLadder so it attaches directly to the front rim of LedgeTop
-- Ladder is centered horizontally on the ledge (local X = 0)
-- Rim is at local Z = -10.0 (in the old frame) which is flush with the ladder at -10.4
-- Ladder extends from foot (Y = 683.0) up to Y = 711.0 (height 28)
local ladderCenterPos = (cf * CFrame.new(0, 0, -10.2)).Position
local newLadderCF = CFrame.new(ladderCenterPos.X, 697.0, ladderCenterPos.Z) * CFrame.Angles(0, math.rad(-121.608), 0)

ladder.Size = Vector3.new(2, 28, 2)
ladder.CFrame = newLadderCF
ladder.CanCollide = true

-- 3. Clear any terrain intersecting the ladder climbing volume
local t = workspace.Terrain
-- Clear a box in front of the ladder where the player climbs
t:FillBlock(newLadderCF * CFrame.new(0, 0, -1.5), Vector3.new(6, 30, 4), Enum.Material.Air)
-- Clear slightly behind the ladder so rungs aren't buried
t:FillBlock(newLadderCF * CFrame.new(0, 0, 1.0), Vector3.new(4, 30, 2), Enum.Material.Air)

-- 4. Set CanCollide = false on all decorative CliffLadderRung
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "CliffLadderRung" then
        c.CanCollide = false
        -- align rung with new ladder position
        local dy = c.Position.Y - 697.0
        c.CFrame = newLadderCF * CFrame.new(0, dy, 0)
    end
end

-- 5. Add safety handrails / extension posts at the top of the ledge
local leftPost = trail:FindFirstChild("LadderHandrailLeft")
if not leftPost then
    leftPost = Instance.new("Part")
    leftPost.Name = "LadderHandrailLeft"
    leftPost.Material = Enum.Material.Wood
    leftPost.Color = Color3.fromRGB(110, 80, 55)
    leftPost.Anchored = true
    leftPost.CanCollide = true
    leftPost.Parent = trail
end
leftPost.Size = Vector3.new(0.5, 5, 0.5)
leftPost.CFrame = newLadderCF * CFrame.new(-1.4, 13, 0.5)

local rightPost = trail:FindFirstChild("LadderHandrailRight")
if not rightPost then
    rightPost = Instance.new("Part")
    rightPost.Name = "LadderHandrailRight"
    rightPost.Material = Enum.Material.Wood
    rightPost.Color = Color3.fromRGB(110, 80, 55)
    rightPost.Anchored = true
    rightPost.CanCollide = true
    rightPost.Parent = trail
end
rightPost.Size = Vector3.new(0.5, 5, 0.5)
rightPost.CFrame = newLadderCF * CFrame.new(1.4, 13, 0.5)

return "CliffLadder updated successfully!"
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Take top-down and front screenshots to verify the fix
  console.log('Capturing verification screenshots...');
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_cliff_ladder_top.png', [-424, 715, -2415], [-425, 705, -2425]);
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_cliff_ladder_front.png', [-410, 696, -2410], [-424.7, 696.2, -2424.1]);
  console.log('Finished capturing CliffLadder verifications.');
}

main().catch(console.error);
