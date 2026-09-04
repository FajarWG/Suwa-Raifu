const { captureScreen } = require('./mcp-exec.js');

async function main() {
  // Capture view at BeamLanding looking up the wooden beam walkway
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/inspect_bridge_candidate.png', [-205, 380, -1935], [-220, 380, -1960]);
  console.log('Captured candidate 1');

  // Also candidate 2: Suspension bridge at (8, 160, -1550)
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/inspect_bridge_candidate2.png', [12, 165, -1530], [8, 161, -1560]);
  console.log('Captured candidate 2');
}

main().catch(console.error);
