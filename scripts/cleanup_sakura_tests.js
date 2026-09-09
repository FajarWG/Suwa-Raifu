const { executeLuau } = require('./mcp-exec.js');

async function cleanup() {
  const code = `
local rep = {}

-- Clean up test models in workspace
local toClean = {
  "CreatorStorePreview",
  "ComparisonTrees",
  "TestProperPBRTree",
  "🌸 Sakura Cherry Blossom Spring Tree Realistic"
}
for _, name in ipairs(toClean) do
  local obj = workspace:FindFirstChild(name)
  if obj then
    obj:Destroy()
    table.insert(rep, "Destroyed " .. name)
  end
end

-- Restore ParkTree6
local park = workspace:FindFirstChild("SuwaLakesidePark")
local natural = park and park:FindFirstChild("NaturalShorelineDetails")
if natural then
  local preview = natural:FindFirstChild("ParkTree6_FixedPreview")
  if preview then
    preview:Destroy()
    table.insert(rep, "Destroyed ParkTree6_FixedPreview")
  end
  local stashed = game.ReplicatedStorage:FindFirstChild("ParkTree6")
  if stashed then
    stashed.Parent = natural
    table.insert(rep, "Restored ParkTree6 to NaturalShorelineDetails")
  end
end

return table.concat(rep, "\\n")
`;

  const res = await executeLuau(code, "Edit");
  console.log(res.content ? res.content[0].text : res);
}

cleanup().catch(console.error);
