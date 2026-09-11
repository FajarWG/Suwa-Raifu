const { setPlayState, executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('Starting Play session...');
  await setPlayState(true);
  await new Promise(r => setTimeout(r, 6000));

  const logCode = `
local LogService = game:GetService("LogService")
local logs = LogService:GetLogHistory()
local relevant = {}
for _, item in ipairs(logs) do
    local msg = item.message
    if msg:find("Server") or msg:find("Firework") or msg:find("Error") or msg:find("error") or msg:find("fail") then
        table.insert(relevant, string.format("[%s] %s", tostring(item.messageType), msg))
    end
end
return "Server logs count: " .. #relevant .. "\\n" .. table.concat(relevant, "\\n", math.max(1, #relevant - 40), #relevant)
`;

  const res = await executeLuau(logCode, 'Server');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));

  await setPlayState(false);
}

main().catch(console.error).finally(() => process.exit(0));
