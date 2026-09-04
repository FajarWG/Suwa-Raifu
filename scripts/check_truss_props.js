const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local t = Instance.new("TrussPart")
t.Size = Vector3.new(2, 10, 2)
return {
    style = tostring(t.Style),
    className = t.ClassName
}
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
