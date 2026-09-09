const { captureScreen } = require('./mcp-exec.js');

async function main() {
  const treePos = [-846.0, 22.0, -155.0];
  // Camera placed ~30 studs back
  const camPos = [-825.0, 26.0, -175.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_current_view.png";
  
  const res = await captureScreen(out, camPos, treePos);
  console.log("Captured:", res);
}

main().catch(console.error);
