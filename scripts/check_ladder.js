const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local ladder = trail.CliffLadder
local cf = ladder.CFrame
local res = {}
for dy = -14, 14, 2 do
    local testPos = cf:PointToWorldSpace(Vector3.new(0, dy, 0))
    local pFront = workspace:Raycast(testPos, -cf.LookVector * 5)
    local pBack = workspace:Raycast(testPos, cf.LookVector * 5)
    local fStr = pFront and (pFront.Instance.Name .. ' mat=' .. tostring(pFront.Material)) or 'none'
    local bStr = pBack and (pBack.Instance.Name .. ' mat=' .. tostring(pBack.Material)) or 'none'
    table.insert(res, string.format("dy=%d y=%.1f frontHit=%s backHit=%s", dy, testPos.Y, fStr, bStr))
end
return table.concat(res, "\\n")
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
