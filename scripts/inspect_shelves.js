const { executeLuau } = require('./mcp-exec.js');

(async () => {
  const code = `
    local seven = workspace.TownRoadNetwork.TownBlocks.Store_7ElevenClean.Model["Seven Eleven"]
    local s1 = seven:FindFirstChild("Shelf")
    local s2 = seven:FindFirstChild("Shelf 2")
    local parts1, parts2 = {}, {}
    for _, d in ipairs(s1:GetDescendants()) do
      if d:IsA("BasePart") then
        table.insert(parts1, d.Name .. " pos=" .. tostring(d.Position) .. " size=" .. tostring(d.Size))
      end
    end
    for _, d in ipairs(s2:GetDescendants()) do
      if d:IsA("BasePart") then
        table.insert(parts2, d.Name .. " pos=" .. tostring(d.Position) .. " size=" .. tostring(d.Size))
      end
    end
    return "SHELF 1 (Bento):\\n" .. table.concat(parts1, "\\n") .. "\\n\\nSHELF 2 (Window):\\n" .. table.concat(parts2, "\\n")
  `;
  const res = await executeLuau(code, 'Server');
  console.log(res?.content?.[0]?.text);
})();
