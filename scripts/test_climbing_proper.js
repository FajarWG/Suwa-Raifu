const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function waitMs(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('Starting Play mode...');
  await setPlayState(true);
  await waitMs(3500);

  const testCliffCode = `
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if not player or not player.Character then return "No player" end
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart", 5)
local hum = char:WaitForChild("Humanoid", 5)

local trail = workspace.SuwaMountainTrail
local foot = trail.LedgeFoot
local ladder = trail.CliffLadder

-- Spawn player on top of LedgeFoot platform safely above floor
hrp.CFrame = CFrame.new(foot.Position + Vector3.new(0, 4, 0), ladder.Position)
task.wait(1.0)

local startY = hrp.Position.Y
-- Walk towards ladder
hum:MoveTo(ladder.Position)

local climbed = false
local maxY = startY
local states = {}

for i = 1, 40 do
    task.wait(0.1)
    local st = hum:GetState().Name
    table.insert(states, st)
    if hrp.Position.Y > maxY then maxY = hrp.Position.Y end
    if st == "Climbing" then climbed = true end
    -- While near ladder, press forward / up
    if (hrp.Position - ladder.Position).Magnitude < 6 then
        hum:MoveTo(ladder.Position + Vector3.new(0, 15, 0))
    end
end

return {
    spawnY = startY,
    highestY = maxY,
    deltaY = maxY - startY,
    climbed = climbed,
    sampleStates = { states[1], states[10], states[20], states[30], states[#states] }
}
`;

  console.log('Testing CliffLadder walking and climbing...');
  try {
    const res = await executeLuau(testCliffCode, 'Server');
    console.log('Cliff Test Result:', res.content[0].text);
  } catch(e) {
    console.error('Error in test:', e);
  }

  // Also test Pit ladder climbing
  const testPitCode = `
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if not player or not player.Character then return "No player" end
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart", 5)
local hum = char:WaitForChild("Humanoid", 5)

local trail = workspace.SuwaMountainTrail
local ladders = trail.ScramblePitEscapeLadders.LowerEscapeLadder
local truss = ladders.ClimbTruss
local plat = ladders.BottomPlatform

-- Spawn player safely on the bottom platform of the escape ladder
hrp.CFrame = CFrame.new(plat.Position + Vector3.new(0, 3.5, 0), truss.Position)
task.wait(1.0)

local startY = hrp.Position.Y
hum:MoveTo(truss.Position)

local climbed = false
local maxY = startY

for i = 1, 30 do
    task.wait(0.1)
    local st = hum:GetState().Name
    if hrp.Position.Y > maxY then maxY = hrp.Position.Y end
    if st == "Climbing" then climbed = true end
    if (hrp.Position - truss.Position).Magnitude < 5 then
        hum:MoveTo(truss.Position + Vector3.new(0, 10, 0))
    end
end

return {
    pitSpawnY = startY,
    pitMaxY = maxY,
    pitDeltaY = maxY - startY,
    pitClimbed = climbed
}
`;

  console.log('Testing Pit escape ladder...');
  try {
    const pitRes = await executeLuau(testPitCode, 'Server');
    console.log('Pit Test Result:', pitRes.content[0].text);
  } catch(e) {
    console.error('Error in pit test:', e);
  }

  console.log('Stopping Play mode...');
  await setPlayState(false);
  console.log('Play mode tests completed.');
}

main().catch(console.error);
