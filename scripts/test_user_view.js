const { captureScreen } = require('./mcp-exec.js');

async function main() {
  // Step 16 is at pos=(-196, 361.9, -1920)
  // Step 14 is at pos=(-193.2, 360.2, -1917.6)
  // Let's place camera at step 12 (-187.7, 358.5, -1912.8) looking up toward step 16 and the floating rock
  const camPos = [-185, 359, -1908];
  const lookAt = [-196, 363, -1920];
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/view_stairs_turn.png', camPos, lookAt);
  console.log('Saved view_stairs_turn.png');
}

main().catch(console.error);
