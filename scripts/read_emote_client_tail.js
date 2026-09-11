const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local StarterGui = game:GetService("StarterGui")
local emoteGui = StarterGui:FindFirstChild("EmoteSystemGui")
local clientScript = emoteGui and emoteGui:FindFirstChild("EmoteSystemClient")
if not clientScript then return "EmoteSystemClient not found" end

local lines = string.split(clientScript.Source, "\\n")
return table.concat(lines, "\\n", 440, math.min(#lines, 530))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
