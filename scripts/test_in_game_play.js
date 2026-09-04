const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function waitMs(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('Starting Play mode...');
  await setPlayState(true);
  await waitMs(3000);

  // In Server datamodel, check player and test climbing CliffLadder
  const testCliffCode = `
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if not player or not player.Character then return "No player found in play mode" end
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart", 5)
local hum = char:WaitForChild("Humanoid", 5)

-- Teleport player to LedgeFoot right in front of CliffLadder
local trail = workspace.SuwaMountainTrail
local ladder = trail.CliffLadder
local startPos = ladder.CFrame:PointToWorldSpace(Vector3.new(0, -14, -2.5))
hrp.CFrame = CFrame.new(startPos, ladder.Position)
task.wait(0.5)

-- Move humanoid forward into the ladder
hum:MoveTo(ladder.Position + Vector3.new(0, 10, 0))

local states = {}
local startY = hrp.Position.Y
local maxY = startY

for i = 1, 25 do
    task.wait(0.1)
    local state = hum:GetState().Name
    table.insert(states, state)
    if hrp.Position.Y > maxY then maxY = hrp.Position.Y end
    -- Keep moving up
    hum:MoveTo(ladder.CFrame:PointToWorldSpace(Vector3.new(0, 14, 0)))
end

return {
    startY = startY,
    maxY = maxY,
    climbSuccess = (maxY - startY) > 5,
    states = states
}
`;

  console.log('Executing CliffLadder climb test...');
  let res;
  try {
    res = await executeLuau(testCliffCode, 'Server');
    console.log('Test Result:', res.content[0].text);
  } catch(e) {
    console.error('Server exec error:', e);
  }

  // Now test climbing the Scramble Pit escape ladder
  const testPitCode = `
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if not player or not player.Character then return "No player" end
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local trail = workspace.SuwaMountainTrail
local ladders = trail:FindFirstChild("ScramblePitEscapeLadders")
if not ladders then return "Pit ladders not found" end
local lower = ladders.LowerEscapeLadder
local truss = lower.ClimbTruss

-- Teleport player to bottom of pit escape ladder
local startPos = truss.CFrame:PointToWorldSpace(Vector3.new(0, -7, -2.5))
hrp.CFrame = CFrame.new(startPos, truss.Position)
task.wait(0.5)

hum:MoveTo(truss.Position + Vector3.new(0, 5, 0))
local startY = hrp.Position.Y
local maxY = startY

for i = 1, 20 do
    task.wait(0.1)
    if hrp.Position.Y > maxY then maxY = hrp.Position.Y end
    hum:MoveTo(truss.CFrame:PointToWorldSpace(Vector3.new(0, 8, 0)))
end

return {
    pitStartY = startY,
    pitMaxY = maxY,
    pitClimbSuccess = (maxY - startY) > 5
}
`;

  console.log('Executing Pit ladder climb test...');
  try {
    const pitRes = await executeLuau(testPitCode, 'Server');
    console.log('Pit Test Result:', pitRes.content[0].text);
  } catch(e) {
    console.error('Pit test error:', e);
  }

  console.log('Stopping Play mode...');
  await setPlayState(false);
  console.log('Finished testing.');
}

main().catch(console.error);
