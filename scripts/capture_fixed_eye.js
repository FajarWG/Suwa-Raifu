const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function testEyeLevel() {
  // Tree is at 0, 100, 0
  // Trunk base is at Y ~ 90, canopy is at Y ~ 100-120
  // Capture from ground path looking up at the tree
  const targetPos = [0.0, 97.0, 0.0];
  const camPos = [10.0, 93.0, 22.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_fixed_eye_level.png";

  await captureScreen(out, camPos, targetPos);
  console.log("Captured eye level to:", out);
}

testEyeLevel().catch(console.error);
