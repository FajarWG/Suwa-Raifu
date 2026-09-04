const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local steps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name:find("TrailStep") and not c.Name:find("Post") and not c.Name:find("Railing") then
        local num = tonumber(c.Name:match("%d+"))
        if num and num >= 200 and num <= 245 then
            table.insert(steps, {
                num = num,
                name = c.Name,
                pos = { c.Position.X, c.Position.Y, c.Position.Z },
                rotY = c.Orientation.Y
            })
        end
    end
end
table.sort(steps, function(a, b) return a.num < b.num end)
return steps
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
