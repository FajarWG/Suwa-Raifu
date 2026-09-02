const { spawn } = require('child_process');

async function callMcpRaw(toolName, args = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn('/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP');
    let buffer = '';
    let result = null;
    let error = null;

    child.stdout.on('data', (d) => {
      buffer += d.toString();
      const lines = buffer.split('\n');
      buffer = lines.pop(); // keep last incomplete line

      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const msg = JSON.parse(line.trim());
          if (msg.id === 2) {
            if (msg.error) {
              error = msg.error;
            } else {
              result = msg.result;
            }
            child.kill();
          }
        } catch (e) {}
      }
    });

    child.stderr.on('data', (d) => {
      // console.error('[MCP Stderr]:', d.toString());
    });

    child.on('close', () => {
      if (error) reject(new Error(JSON.stringify(error)));
      else if (result) resolve(result);
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
    }, 250);

    // Timeout
    setTimeout(() => {
      child.kill();
    }, 15000);
  });
}

async function getActiveStudioId() {
  const res = await callMcpRaw('list_roblox_studios', {});
  const text = res?.content?.[0]?.text;
  if (text) {
    const data = JSON.parse(text);
    if (data.studios && data.studios.length > 0) {
      return data.studios[0].id;
    }
  }
  throw new Error('No active Roblox Studio found: ' + JSON.stringify(res));
}

async function getStudioState() {
  const studioId = await getActiveStudioId();
  return callMcpRaw('get_studio_state', { studio_id: studioId });
}

async function setPlayState(isStart) {
  const studioId = await getActiveStudioId();
  return callMcpRaw('start_stop_play', {
    studio_id: studioId,
    is_start: isStart
  });
}

async function executeLuau(code, datamodel = 'Edit') {
  const studioId = await getActiveStudioId();
  return callMcpRaw('execute_luau', {
    studio_id: studioId,
    datamodel_type: datamodel,
    code: code
  });
}

async function main() {
  const action = process.argv[2] || 'exec';
  
  if (action === 'stop') {
    const res = await setPlayState(false);
    console.log('Stop Play Result:', JSON.stringify(res, null, 2));
  } else if (action === 'start') {
    const res = await setPlayState(true);
    console.log('Start Play Result:', JSON.stringify(res, null, 2));
  } else if (action === 'state') {
    const res = await getStudioState();
    console.log('Studio State:', JSON.stringify(res, null, 2));
  } else {
    const code = process.argv[3] || process.argv[2] || 'return "Hello from Studio"';
    const datamodel = process.argv[4] || 'Edit';
    const res = await executeLuau(code, datamodel);
    console.log(JSON.stringify(res, null, 2));
  }
}

if (require.main === module) {
  main().catch(err => {
    console.error('Execution error:', err);
    process.exit(1);
  });
}

module.exports = { callMcpRaw, getActiveStudioId, getStudioState, setPlayState, executeLuau };


