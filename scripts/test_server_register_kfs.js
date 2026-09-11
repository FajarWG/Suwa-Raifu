const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 6000));

  const serverCode = `
local ksp = game:GetService("KeyframeSequenceProvider")
local ss = game:GetService("ServerStorage")
local rs = game:GetService("ReplicatedStorage")

local pack = ss:FindFirstChild("Pack_IndianCode")
local animSaves = pack and pack:FindFirstChild("Dummy") and pack.Dummy:FindFirstChild("AnimSaves")
local orange = animSaves and animSaves:FindFirstChild("Orange Justice")
if not orange then return "No Orange Justice KFS" end

local ok, animId = pcall(function()
    return ksp:RegisterKeyframeSequence(orange)
end)

if ok and animId then
    local anim = Instance.new("Animation")
    anim.Name = "Orange Justice"
    anim.AnimationId = animId
    anim.Parent = rs:WaitForChild("Emotes")
    return "SERVER REGISTERED SUCCESS: " .. animId
else
    return "SERVER REGISTER FAILED: " .. tostring(animId)
end
`;

  console.log('Executing on Server...');
  const sRes = await executeLuau(serverCode, 'Server');
  console.log('Server result:', sRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 1000));

  const clientCode = `
local rs = game:GetService("ReplicatedStorage")
local anim = rs:WaitForChild("Emotes"):WaitForChild("Orange Justice", 3)
if not anim then return "Client did not find Orange Justice" end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")

local track = animator:LoadAnimation(anim)
track:Play()
task.wait(0.3)
return string.format("CLIENT PLAYED SERVER-REGISTERED ANIM! isPlaying=%s, len=%.2f", tostring(track.IsPlaying), track.Length)
`;

  console.log('Executing on Client...');
  const cRes = await executeLuau(clientCode, 'Client');
  console.log('Client result:', cRes.content?.[0]?.text);

  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
