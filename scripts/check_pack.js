const { executeLuau, defaultClient } = require('./mcp-exec.js');

async function main() {
  const code = `
local ss = game:GetService("ServerStorage")
local pack = ss:FindFirstChild("Pack_IndianCode")
if not pack then
    return "No Pack_IndianCode in ServerStorage"
end

local items = {}
local function scan(parent, prefix)
    for _, item in ipairs(parent:GetChildren()) do
        table.insert(items, prefix .. item.Name .. " (" .. item.ClassName .. ")")
        if #items < 40 and #item:GetChildren() > 0 then
            scan(item, prefix .. "  ")
        end
    end
end
scan(pack, "")
return "Total items in pack: " .. #pack:GetDescendants() .. "\\n" .. table.concat(items, "\\n", 1, math.min(#items, 50))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
