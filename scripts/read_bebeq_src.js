const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
if not bebeq then return "No BebeqFireworkSystem" end

local cfg = bebeq:FindFirstChild("Config")
local sh = bebeq:FindFirstChild("ServerHandler")
local fw = sh and sh:FindFirstChild("Fireworks")

local lines = {}
if cfg then
    table.insert(lines, "=== CONFIG ===")
    table.insert(lines, cfg.Source)
end
if fw then
    table.insert(lines, "=== SERVERHANDLER.FIREWORKS ===")
    local sLines = string.split(fw.Source, "\\n")
    table.insert(lines, table.concat(sLines, "\\n", 1, math.min(#sLines, 80)))
end

return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
