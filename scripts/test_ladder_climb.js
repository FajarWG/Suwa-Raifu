const { executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Testing dummy climbing on CliffLadder...');
  const code = `
local trail = workspace.SuwaMountainTrail
local ladder = trail.CliffLadder
local foot = trail.LedgeFoot

-- Create a temporary test dummy
local dummy = Instance.new("Model")
dummy.Name = "ClimbTestDummy"

local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Size = Vector3.new(2, 2, 1)
root.Position = ladder.CFrame:PointToWorldSpace(Vector3.new(0, -13, -1.5))
root.CanCollide = true
root.Anchored = false
root.Parent = dummy
dummy.PrimaryPart = root

local torso = Instance.new("Part")
torso.Name = "Torso"
torso.Size = Vector3.new(2, 2, 1)
torso.Position = root.Position
torso.CanCollide = false
torso.Parent = dummy

local head = Instance.new("Part")
head.Name = "Head"
head.Size = Vector3.new(1.2, 1.2, 1.2)
head.Position = root.Position + Vector3.new(0, 1.5, 0)
head.CanCollide = false
head.Parent = dummy

local hum = Instance.new("Humanoid")
hum.Parent = dummy

dummy.Parent = workspace

-- Move towards ladder
hum:MoveTo(ladder.Position)

-- Check after a moment if it can touch and detect climb
local ladderTouched = false
local c = ladder.Touched:Connect(function(hit)
    if hit:IsDescendantOf(dummy) then
        ladderTouched = true
    end
end)

task.wait(0.2)
c:Disconnect()
dummy:Destroy()

return {
    ladderTouched = ladderTouched,
    ladderCanCollide = ladder.CanCollide,
    ladderSize = tostring(ladder.Size),
    ladderPos = tostring(ladder.Position)
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
