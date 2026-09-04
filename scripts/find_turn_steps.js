const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local steps = {}
for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" then
        local d = (c.Position - Vector3.new(-196.0, 361.9, -1920.0)).Magnitude
        if d < 60 then
            table.insert(steps, {
                pos = { c.Position.X, c.Position.Y, c.Position.Z },
                rotY = c.Orientation.Y,
                dist = d
            })
        end
    end
end
table.sort(steps, function(a, b) return a.pos[2] < b.pos[2] end)
return steps
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
