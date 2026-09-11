const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local ms = game:GetService("MarketplaceService")
local ids = {
    127118661424463, -- Kawaii
    138647889956297, -- Jumpstyle
    110204898807330, -- Snoop
    107225592032188, -- Brazil
    75284731618640   -- Brazil
}

local lines = {}
for _, id in ipairs(ids) do
    local ok, info = pcall(function()
        return ms:GetProductInfo(id, Enum.InfoType.Asset)
    end)
    if ok and info then
        table.insert(lines, string.format("ID %d: Name=%s, Creator=%s (Id: %s), AssetTypeId=%s",
            id, tostring(info.Name), tostring(info.Creator and info.Creator.Name), tostring(info.Creator and info.Creator.CreatorTargetId), tostring(info.AssetTypeId)))
    else
        table.insert(lines, string.format("ID %d: GetProductInfo failed (%s)", id, tostring(info)))
    end
end
return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
