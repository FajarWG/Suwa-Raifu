const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace:FindFirstChild("SuwaMountainTrail")
local steps = {}
if trail then
    for _, c in ipairs(trail:GetChildren()) do
        if c.Name:find("Step") or c.Name:find("Stair") then
            table.insert(steps, c)
        end
    end
end

-- Search for any floating parts in workspace or SuwaMountainTrail
local floatingParts = {}
for _, desc in ipairs(workspace:GetDescendants()) do
    if desc:IsA("BasePart") and not desc:IsA("Terrain") and not desc:IsDescendantOf(workspace:FindFirstChild("Terrain") or workspace) then
        local name = desc.Name:lower()
        if name:find("rock") or name:find("boulder") or name:find("stone") or desc.Material == Enum.Material.Rock or desc.Material == Enum.Material.Slate then
            -- check if it's near any trail step
            for _, s in ipairs(steps) do
                local dist = (desc.Position - s.Position).Magnitude
                if dist < 60 then
                    table.insert(floatingParts, {
                        name = desc:GetFullName(),
                        className = desc.ClassName,
                        pos = tostring(desc.Position),
                        size = tostring(desc.Size),
                        distToStep = dist,
                        step = s.Name
                    })
                    break
                end
            end
        end
    end
end

return {
    stepCount = #steps,
    floatingParts = floatingParts
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
