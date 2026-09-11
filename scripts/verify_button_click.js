const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 7000));

  const testClickCode = `
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")

local pGui = player:WaitForChild("PlayerGui", 5)
local emoteGui = pGui:WaitForChild("EmoteSystemGui", 5)
local mainFrame = emoteGui:WaitForChild("MainFrame", 5)
local emoteList = mainFrame:WaitForChild("EmoteList", 5)

local brazilBtn = emoteList:FindFirstChild("Dance Brazil")
if not brazilBtn then
    return "Dance Brazil button NOT found in EmoteList!"
end

-- Simulate activating the button
brazilBtn.Activated:Fire()
task.wait(0.6)

-- Check what animation is currently playing on animator
local playingTracks = {}
for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
    table.insert(playingTracks, string.format("Track: %s, Length: %.2f, TimePos: %.2f, Speed: %.2f",
        track.Animation and track.Animation.Name or "Unknown", track.Length, track.TimePosition, track.Speed))
end

return string.format("BUTTON CLICK SUCCESS! Playing tracks count: %d\\n%s", #playingTracks, table.concat(playingTracks, "\\n"))
`;

  console.log('Testing button activation on Client...');
  const res = await executeLuau(testClickCode, 'Client');
  console.log('Client test result:');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));

  console.log('Stopping Play session...');
  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
