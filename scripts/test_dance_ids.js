const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 6000));

  const testCode = `
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local candidateIds = {
    ["Brazil_FrPhxSuns"] = "102422651829022",
    ["Brazil_Aurelle"] = "84593715197740",
    ["Brazil_Linguinha"] = "116916777684513",
    ["Brazil_MBM"] = "94117880039127",
    ["Brazil_Jaxs"] = "121300673631453",
    ["Brazil_ZeEmote"] = "113482211171140",
    ["Kawaii_Working"] = "127118661424463"
}

local results = {}
for name, id in pairs(candidateIds) do
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local ok, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    if ok and track then
        track:Play()
        task.wait(0.2)
        local len = track.Length
        local isPlaying = track.IsPlaying
        table.insert(results, string.format("%s: ok=true, len=%.2f, isPlaying=%s", name, len, tostring(isPlaying)))
        track:Stop()
    else
        table.insert(results, string.format("%s: FAILED to load: %s", name, tostring(track)))
    end
end

return table.concat(results, "\\n")
`;

  console.log('Testing raw Animation IDs on Client...');
  const res = await executeLuau(testCode, 'Client');
  console.log('--- TEST RESULTS ---');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));

  console.log('Stopping Play session...');
  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
