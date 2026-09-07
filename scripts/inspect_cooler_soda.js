const { executeLuau } = require('./mcp-exec.js');

(async () => {
  const code = `
    local seven = workspace.TownRoadNetwork.TownBlocks.Store_7ElevenClean.Model["Seven Eleven"]
    local cooler = seven:FindFirstChild("Cooler")
    local soda = seven:FindFirstChild("Soda Machine")
    local junk = seven:FindFirstChild("Drinks and Junk")
    
    local cCf, cSz = cooler and cooler:GetBoundingBox()
    local sCf, sSz = soda and soda:GetBoundingBox()
    local jCf, jSz = junk and junk:GetBoundingBox()

    return "Cooler bounds: pos=" .. tostring(cCf.Position) .. " sz=" .. tostring(cSz) ..
           "\\nSoda bounds: pos=" .. tostring(sCf.Position) .. " sz=" .. tostring(sSz) ..
           "\\nJunk bounds: pos=" .. tostring(jCf.Position) .. " sz=" .. tostring(jSz)
  `;
  const res = await executeLuau(code, 'Server');
  console.log(res?.content?.[0]?.text);
})();
