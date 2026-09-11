const { setPlayState, executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 7000));

  console.log('Querying character position & opening panel...');
  const setupCode = `
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local pGui = player:WaitForChild("PlayerGui")
local emoteGui = pGui:WaitForChild("EmoteSystemGui")
local mainFrame = emoteGui:WaitForChild("MainFrame")

-- Open panel cleanly
mainFrame.Visible = true
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = UDim2.new(1, -16, 0, 58)

local p = hrp.Position
return string.format("%.2f,%.2f,%.2f", p.X, p.Y, p.Z)
`;

  const res = await executeLuau(setupCode, 'Client');
  const posText = res.content?.[0]?.text || '0,10,0';
  console.log('Character RootPart pos:', posText);
  const [cx, cy, cz] = posText.split(',').map(Number);

  // Position camera 6 studs in front of character, slightly elevated
  const camPos = [cx, cy + 2, cz + 8];
  const lookPos = [cx, cy + 1, cz];

  console.log('Capturing panel with camera facing character...');
  const panelPath = '/Users/mac/.gemini/antigravity-ide/brain/f67f3009-9155-46a6-b434-629dcf04a553/emote_panel_verified.png';
  try {
    await captureScreen(panelPath, camPos, lookPos);
    console.log('Panel capture saved to:', panelPath);
  } catch (e) {
    console.error('Capture failed:', e.message);
  }

  // Now trigger Dance Brazil
  console.log('Triggering Dance Brazil...');
  const danceCode = `
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")
local rs = game:GetService("ReplicatedStorage")
local brazil = rs.Emotes:FindFirstChild("Dance Brazil")
if brazil then
    local t = animator:LoadAnimation(brazil)
    t.Looped = true
    t:Play()
    task.wait(0.5)
    return "Dance Brazil playing: " .. tostring(t.IsPlaying) .. ", timePos: " .. tostring(t.TimePosition)
end
return "Brazil not found"
`;
  const dRes = await executeLuau(danceCode, 'Client');
  console.log('Dance status:', dRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 1200));

  console.log('Capturing dancing character...');
  const dancePath = '/Users/mac/.gemini/antigravity-ide/brain/f67f3009-9155-46a6-b434-629dcf04a553/dance_brazil_active.png';
  try {
    await captureScreen(dancePath, camPos, lookPos);
    console.log('Dance capture saved to:', dancePath);
  } catch (e) {
    console.error('Dance capture failed:', e.message);
  }

  console.log('Stopping Play session...');
  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
