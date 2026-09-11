const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
local cr = bebeq and bebeq:FindFirstChild("ClientRenderer")
if not cr then return "No ClientRenderer" end

local lines = string.split(cr.Source, "\\n")
return table.concat(lines, "\\n", 1, math.min(#lines, 120))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
