const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  await executeLuau(`game:GetService("Lighting").ClockTime = 21.5`, "Edit");

  // Camera looking at the swing with CoupleSwingSakuraTree in background
  const camPos = [-310.0, 15.5, -120.0];
  const targetPos = [-308.0, 16.0, -138.0];
  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/real_swing_matching_user.png";

  await captureScreen(out, camPos, targetPos);
  console.log("Captured matching swing screenshot to:", out);

  // Restore
  await executeLuau(`game:GetService("Lighting").ClockTime = 17.45`, "Edit");
}

main().catch(console.error);
