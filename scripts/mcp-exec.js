const { spawn } = require('child_process');

async function callMcp(toolName, args = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn('/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP');
    let buffer = '';
    let result = null;

    child.stdout.on('data', (d) => {
      buffer += d.toString();
      const lines = buffer.split('\n');
      buffer = lines.pop(); // keep last incomplete line

      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const msg = JSON.parse(line.trim());
          if (msg.id === 2) {
            result = msg.result;
            child.kill();
          }
        } catch (e) {}
      }
    });

    child.on('close', () => {
      if (result) resolve(result);
      else reject(new Error('No response received from StudioMCP'));
    });

    // 1. Initialize
    child.stdin.write(JSON.stringify({
      jsonrpc: '2.0',
      id: 1,
      method: 'initialize',
      params: { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'antigravity', version: '1.0' } }
    }) + '\n');

    // 2. Call tool
    setTimeout(() => {
      child.stdin.write(JSON.stringify({
        jsonrpc: '2.0',
        id: 2,
        method: 'tools/call',
        params: {
          name: toolName,
          arguments: args
        }
      }) + '\n');
    }, 200);

    // Timeout
    setTimeout(() => {
      child.kill();
    }, 8000);
  });
}

async function main() {
  const code = process.argv[2] || 'return "Hello from Studio"';
  const datamodel = process.argv[3] || 'Client';
  const studioId = '7ae32416-af7d-47e8-a79d-596c6017a6fb';

  try {
    const res = await callMcp('execute_luau', {
      studio_id: studioId,
      datamodel_type: datamodel,
      code: code
    });
    console.log(JSON.stringify(res, null, 2));
  } catch (err) {
    console.error(err);
  }
}

if (require.main === module) {
  main();
}

module.exports = { callMcp };
