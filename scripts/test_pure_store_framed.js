const { captureScreen } = require('./mcp-exec.js');

async function main() {
  const treePos = [-28.0, 16.0, -155.0];
  const camPos = [10.0, 14.0, -142.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/pure_creator_store_framed.png";

  await captureScreen(out, camPos, treePos);
  console.log("Captured framed pure store model to:", out);
}

main().catch(console.error);
