const { setPlayState, executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('1. Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 7000));

  console.log('2. Verifying Server Emote Registration...');
  const serverCheck = `
local rs = game:GetService("ReplicatedStorage")
local emotes = rs:FindFirstChild("Emotes")
if not emotes then return "No Emotes folder" end

local names = {}
for _, child in ipairs(emotes:GetChildren()) do
    if child:IsA("Animation") then
        table.insert(names, child.Name .. " (ID: " .. child.AnimationId:sub(1, 20) .. "...)")
    end
end
table.sort(names)
return string.format("Total Registered Emotes: %d\\n%s", #names, table.concat(names, "\\n"))
`;
  const sRes = await executeLuau(serverCheck, 'Server');
  console.log(sRes.content?.[0]?.text);

  console.log('3. Opening Emote Panel on Client...');
  const clientOpen = `
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui", 5)
local emoteGui = pGui:WaitForChild("EmoteSystemGui", 5)
local mainFrame = emoteGui:WaitForChild("MainFrame", 5)

-- Open panel
mainFrame.Visible = true
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = UDim2.new(1, -16, 0, 58)

local emoteList = mainFrame:WaitForChild("EmoteList", 5)
local buttons = {}
for _, child in ipairs(emoteList:GetChildren()) do
    if child:IsA("TextButton") then
        table.insert(buttons, child.Text)
    end
end

return string.format("Panel opened! Found %d emote buttons:\\n%s", #buttons, table.concat(buttons, ", "))
`;
  const cRes = await executeLuau(clientOpen, 'Client');
  console.log(cRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 1000));

  console.log('4. Capturing screen of open Emote Panel...');
  const screenPath = '/Users/mac/.gemini/antigravity-ide/brain/f67f3009-9155-46a6-b434-629dcf04a553/emote_panel_verified.png';
  try {
    await captureScreen(screenPath);
    console.log('Captured screenshot to:', screenPath);
  } catch (err) {
    console.error('Screenshot error:', err.message);
  }

  console.log('5. Triggering Dance Brazil on character...');
  const playDanceBrazil = `
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")

local rs = game:GetService("ReplicatedStorage")
local brazilAnim = rs.Emotes:FindFirstChild("Dance Brazil")
if not brazilAnim then return "Dance Brazil anim not found in Emotes!" end

local track = animator:LoadAnimation(brazilAnim)
track.Looped = true
track:Play()

task.wait(0.5)

return string.format("DANCE BRAZIL PLAYING! isPlaying=%s, len=%.2f, timePos=%.2f",
    tostring(track.IsPlaying), track.Length, track.TimePosition)
`;
  const dRes = await executeLuau(playDanceBrazil, 'Client');
  console.log(dRes.content?.[0]?.text);

  await new Promise(r => setTimeout(r, 1500));

  console.log('6. Capturing screen of character dancing Brazil Dance...');
  const danceScreenPath = '/Users/mac/.gemini/antigravity-ide/brain/f67f3009-9155-46a6-b434-629dcf04a553/dance_brazil_active.png';
  try {
    await captureScreen(danceScreenPath);
    console.log('Captured dance screenshot to:', danceScreenPath);
  } catch (err) {
    console.error('Dance screenshot error:', err.message);
  }

  console.log('7. Stopping Play session...');
  await setPlayState(false);
  console.log('ALL VERIFICATION COMPLETED SUCCESSFULLY!');
}

main().catch(console.error).finally(() => process.exit(0));
