const { spawn } = require('child_process');
const fs = require('fs');

class StudioMCPClient {
  constructor() {
    this.child = null;
    this.buffer = '';
    this.nextId = 1;
    this.pending = new Map();
    this.connectedStudioId = null;
  }

  async start() {
    if (this.child) return;
    this.child = spawn('/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP');

    this.child.stdout.on('data', (d) => {
      this.buffer += d.toString();
      const lines = this.buffer.split('\n');
      this.buffer = lines.pop();

      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const msg = JSON.parse(line.trim());
          if (msg.id && this.pending.has(msg.id)) {
            const { resolve, reject } = this.pending.get(msg.id);
            this.pending.delete(msg.id);
            if (msg.error) reject(new Error(JSON.stringify(msg.error)));
            else resolve(msg.result);
          }
        } catch (e) {}
      }
    });

    this.child.on('close', () => {
      this.child = null;
      for (const { reject } of this.pending.values()) {
        reject(new Error('StudioMCP closed'));
      }
      this.pending.clear();
    });

    // Initialize
    await this.sendRequest('initialize', {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: 'antigravity', version: '1.0' }
    });
  }

  sendRequest(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = this.nextId++;
      const timer = setTimeout(() => {
        if (this.pending.has(id)) {
          this.pending.delete(id);
          reject(new Error(`Timeout waiting for response to ${method} (id ${id})`));
        }
      }, 25000);

      this.pending.set(id, {
        resolve: (val) => { clearTimeout(timer); resolve(val); },
        reject: (err) => { clearTimeout(timer); reject(err); }
      });

      this.child.stdin.write(JSON.stringify({
        jsonrpc: '2.0',
        id,
        method,
        params
      }) + '\n');
    });
  }

  async callTool(name, args = {}) {
    await this.start();
    return this.sendRequest('tools/call', { name, arguments: args });
  }

  async getStudioId() {
    if (this.connectedStudioId) return this.connectedStudioId;
    await this.start();
    // Poll list_roblox_studios until studio connects (up to 12s, checking every 600ms)
    for (let i = 0; i < 20; i++) {
      try {
        const res = await this.callTool('list_roblox_studios', {});
        const text = res?.content?.[0]?.text;
        if (text) {
          const data = JSON.parse(text);
          if (data.studios && data.studios.length > 0) {
            this.connectedStudioId = data.studios[0].id;
            return this.connectedStudioId;
          }
        }
      } catch (e) {}
      await new Promise(r => setTimeout(r, 600));
    }
    throw new Error('No active Roblox Studio connected after waiting 12s');
  }

  async executeLuau(code, datamodel = 'Edit') {
    const studioId = await this.getStudioId();
    return this.callTool('execute_luau', {
      studio_id: studioId,
      datamodel_type: datamodel,
      code
    });
  }

  async captureScreen(outputPath, cameraPos, lookAtPos) {
    const studioId = await this.getStudioId();
    if (cameraPos && !Array.isArray(cameraPos)) cameraPos = Object.values(cameraPos);
    if (lookAtPos && !Array.isArray(lookAtPos)) lookAtPos = Object.values(lookAtPos);
    const args = {
      studio_id: studioId,
      capture_id: 'capture_' + Date.now()
    };
    if (cameraPos && lookAtPos) {
      args.camera_position = cameraPos;
      args.look_at_position = lookAtPos;
    }
    const res = await this.callTool('screen_capture', args);
    const item = res?.content?.[0];
    if (item && item.data) {
      fs.writeFileSync(outputPath, Buffer.from(item.data, 'base64'));
      return { success: true, path: outputPath };
    }
    throw new Error('Capture failed: ' + JSON.stringify(res));
  }

  async getStudioState() {
    const studioId = await this.getStudioId();
    return this.callTool('get_studio_state', { studio_id: studioId });
  }

  async setPlayState(isStart) {
    const studioId = await this.getStudioId();
    return this.callTool('start_stop_play', {
      studio_id: studioId,
      is_start: isStart
    });
  }

  close() {
    if (this.child) {
      this.child.kill();
      this.child = null;
    }
  }
}

// Module-level singleton
const defaultClient = new StudioMCPClient();

async function callMcpRaw(toolName, args = {}) {
  return defaultClient.callTool(toolName, args);
}

async function getActiveStudioId() {
  return defaultClient.getStudioId();
}

async function getStudioState() {
  return defaultClient.getStudioState();
}

async function setPlayState(isStart) {
  return defaultClient.setPlayState(isStart);
}

async function executeLuau(code, datamodel = 'Edit') {
  return defaultClient.executeLuau(code, datamodel);
}

async function captureScreen(outputPath, cameraPos, lookAtPos) {
  return defaultClient.captureScreen(outputPath, cameraPos, lookAtPos);
}

async function main() {
  const action = process.argv[2] || 'exec';
  const client = new StudioMCPClient();
  
  try {
    if (action === 'stop') {
      const res = await client.setPlayState(false);
      console.log('Stop Play Result:', JSON.stringify(res, null, 2));
    } else if (action === 'start') {
      const res = await client.setPlayState(true);
      console.log('Start Play Result:', JSON.stringify(res, null, 2));
    } else if (action === 'state') {
      const res = await client.getStudioState();
      console.log('Studio State:', JSON.stringify(res, null, 2));
    } else if (action === 'capture') {
      const out = process.argv[3] || '/tmp/capture.png';
      const cam = process.argv[4] ? [parseFloat(process.argv[4]), parseFloat(process.argv[5]), parseFloat(process.argv[6])] : undefined;
      const look = process.argv[7] ? [parseFloat(process.argv[7]), parseFloat(process.argv[8]), parseFloat(process.argv[9])] : undefined;
      const res = await client.captureScreen(out, cam, look);
      console.log('Captured screen to:', res.path);
    } else {
      let code = process.argv[2];
      let datamodel = process.argv[3] || 'Edit';
      if (action === 'exec') {
        code = process.argv[3];
        datamodel = process.argv[4] || 'Edit';
      }
      const res = await client.executeLuau(code, datamodel);
      console.log(JSON.stringify(res, null, 2));
    }
  } finally {
    client.close();
  }
}

if (require.main === module) {
  main().catch(err => {
    console.error('Execution error:', err);
    process.exit(1);
  });
}

module.exports = {
  StudioMCPClient,
  callMcpRaw,
  getActiveStudioId,
  getStudioState,
  setPlayState,
  executeLuau,
  captureScreen
};
