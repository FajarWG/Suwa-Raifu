const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
-- Check which faces of TrussPart trigger Humanoid Climbing
local truss = workspace.SuwaMountainTrail.CliffLadder

-- In Studio Edit mode, let's test raycasting or checking geometry
local cf = truss.CFrame
local look = cf.LookVector
local right = cf.RightVector
local up = cf.UpVector

return {
    pos = tostring(cf.Position),
    look = tostring(look),
    right = tostring(right),
    up = tostring(up),
    size = tostring(truss.Size)
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
