const { captureScreen } = require('./mcp-exec.js');

async function main() {
  // Move camera close to TestOriginalFromStore
  const treePos = [-18.0, 16.0, -150.0];
  const camPos = [-18.0, 14.0, -135.0]; // Looking towards north
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/original_creator_store_closeup.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured closeup to:", out);
}

main().catch(console.error);
