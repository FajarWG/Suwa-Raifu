const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
return string.format("_G.SuwaFireworks exists: %s", tostring(_G.SuwaFireworks ~= nil))
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
