const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
local sh = bebeq and bebeq:FindFirstChild("ServerHandler")
if not sh then return "No ServerHandler" end

local lines = string.split(sh.Source, "\\n")
return table.concat(lines, "\\n", 1, math.min(#lines, 120))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
