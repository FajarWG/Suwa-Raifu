const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local is = game:GetService("InsertService")
local ids = {
    107225592032188,
    75284731618640,
    115405633925650,
    76599721751084,
    139067331291637,
    140034015099511,
    139340047877459
}

local lines = {}
for _, id in ipairs(ids) do
    local ok, model = pcall(function()
        return is:LoadAsset(id)
    end)
    if ok and model then
        table.insert(lines, string.format("LoadAsset(%d) SUCCESS! Children count: %d", id, #model:GetChildren()))
        for _, desc in ipairs(model:GetDescendants()) do
            table.insert(lines, string.format("  -> %s (%s) %s", desc.Name, desc.ClassName, desc:IsA("Animation") and desc.AnimationId or ""))
        end
        model:Destroy()
    else
        table.insert(lines, string.format("LoadAsset(%d) failed: %s", id, tostring(model)))
    end
end
return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
