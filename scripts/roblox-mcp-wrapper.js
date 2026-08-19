#!/usr/bin/env node

const { spawn } = require('child_process');
const readline = require('readline');

const STUDIO_MCP_PATH = '/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP';

// Spawn StudioMCP subprocess
const child = spawn(STUDIO_MCP_PATH, process.argv.slice(2), {
  stdio: ['pipe', 'pipe', 'inherit']
});

child.on('error', (err) => {
  console.error(`[StudioMCP Wrapper Error]: ${err.message}`);
  process.exit(1);
});

child.on('exit', (code, signal) => {
  process.exit(code || 0);
});

// Forward StudioMCP stdout directly to process stdout
child.stdout.on('data', (data) => {
  process.stdout.write(data);
});

// Read incoming JSON-RPC requests from IDE stdin
const rl = readline.createInterface({
  input: process.stdin,
  terminal: false
});

rl.on('line', (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;

  try {
    const msg = JSON.parse(trimmed);

    // Intercept server/discover or non-standard probes that cause StudioMCP rmcp to panic
    if (msg.method === 'server/discover') {
      const response = {
        jsonrpc: '2.0',
        id: msg.id !== undefined ? msg.id : null,
        error: {
          code: -32601,
          message: 'Method not found'
        }
      };
      process.stdout.write(JSON.stringify(response) + '\n');
      return;
    }

    // Forward everything else to StudioMCP
    child.stdin.write(trimmed + '\n');
  } catch (e) {
    // If not JSON or parsing fails, pass through
    child.stdin.write(line + '\n');
  }
});
