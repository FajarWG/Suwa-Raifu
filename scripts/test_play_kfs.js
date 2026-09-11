const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 6000));

  const testCode = `
local Players = game:GetService("Players")
local ksp = game:GetService("KeyframeSequenceProvider")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- Fetch FrPhxSuns Brazil Dance KeyframeSequence
local kfs = ksp:GetKeyframeSequenceAsync("rbxassetid://102422651829022")
local registeredAnimId = ksp:RegisterKeyframeSequence(kfs)

local anim = Instance.new("Animation")
anim.AnimationId = registeredAnimId
local track = animator:LoadAnimation(anim)
track.Looped = true
track:Play()

task.wait(0.5)

local isPlaying = track.IsPlaying
local length = track.Length
local timePos = track.TimePosition

return string.format("REGISTERED DANCE PLAY RESULT: animId=%s, isPlaying=%s, length=%.2f, timePos=%.2f",
    registeredAnimId, tostring(isPlaying), length, timePos)
`;

  console.log('Testing registered KeyframeSequence in Client datamodel...');
  const res = await executeLuau(testCode, 'Client');
  console.log('--- TEST RESULTS ---');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));

  console.log('Stopping Play session...');
  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
