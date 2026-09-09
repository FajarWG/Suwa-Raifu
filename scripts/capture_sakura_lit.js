const { captureScreen } = require('./mcp-exec.js');

async function main() {
  const treePos = [-846.0, 24.0, -155.0];
  // Sun is at ~(-1, 0, 1), so looking from west/north-west with sun at back
  const camPos = [-865.0, 26.0, -135.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_sun_side.png";
  
  await captureScreen(out, camPos, treePos);
  console.log("Captured sunny side to:", out);
}

main().catch(console.error);
