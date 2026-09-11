const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local StarterGui = game:GetService("StarterGui")
local emoteGui = StarterGui:FindFirstChild("EmoteSystemGui")
local clientScript = emoteGui and emoteGui:FindFirstChild("EmoteSystemClient")
if not clientScript then return "EmoteSystemClient not found" end

local src = clientScript.Source

-- 1. Ensure toggleFrame reloads emotes from folder
if not string.find(src, "loadEmotesFromFolder()\\n\\t\\tif showingFavorites then") then
    src = string.gsub(src, "if showingFavorites then%s+updateEmoteList%(favoriteEmotes%)", "loadEmotesFromFolder()\\n\\t\\tif showingFavorites then\\n\\t\\t\\tupdateEmoteList(favoriteEmotes)")
end

-- 2. Add folder listeners if not present
if not string.find(src, "emotesFolder.ChildAdded") then
    local listenerCode = [[
table.insert(globalConnections, emotesFolder.ChildAdded:Connect(function()
\tloadEmotesFromFolder()
\tif mainFrame.Visible and not showingFavorites then
\t\tupdateEmoteList(emoteAnimations)
\tend
end))
table.insert(globalConnections, emotesFolder.ChildRemoved:Connect(function()
\tloadEmotesFromFolder()
\tif mainFrame.Visible and not showingFavorites then
\t\tupdateEmoteList(emoteAnimations)
\tend
end))
]]
    src = src .. "\\n" .. listenerCode
end

clientScript.Source = src
return "Patched EmoteSystemClient successfully!"
`;

  console.log('Patching EmoteSystemClient...');
  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
