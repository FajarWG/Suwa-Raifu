const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  // Let us see what time of day it is at night during fireworks:
  // Fireworks show usually runs at night. Let us set ClockTime to 21.5
  await executeLuau(`
    game:GetService("Lighting").ClockTime = 21.5
  `, "Edit");

  // Capture near the swings/Ferris wheel
  // Swings are near workspace.SuwaLakesidePark.NaturalShorelineDetails
  // Let us find the swing and take a picture looking at the tree
  const swingRes = await executeLuau(`
    local swing = workspace:FindFirstChild("ParkSwing", true) or workspace:FindFirstChild("Swing", true) or workspace:FindFirstChild("RomanticSakuraCoupleSwing", true)
    if swing then
      local cf = swing:GetPivot()
      return string.format("%.1f,%.1f,%.1f", cf.X, cf.Y, cf.Z)
    end
    return "none"
  `, "Edit");
  console.log("Swing pos:", swingRes.content ? swingRes.content[0].text : swingRes);

  const out = "/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/.tempmediaStorage/sakura_night_time_test.png";
  // Looking at ParkTree6 from swing position
  await captureScreen(out, [70.0, 95.0, -30.0], [78.5, 97.0, -46.7]);
  console.log("Captured night preview to:", out);

  // Revert back to 17.45
  await executeLuau(`
    game:GetService("Lighting").ClockTime = 17.45
  `, "Edit");
}

main().catch(console.error);
