const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  // Tree D is at X = 60, Y = 100, Z = 0
  const targetPos = [60.0, 100.0, 0.0];
  const camPos = [60.0, 103.0, 35.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_tree_d_closeup.png";

  await captureScreen(out, camPos, targetPos);
  console.log("Captured Tree D close-up to:", out);
}

main().catch(console.error);
