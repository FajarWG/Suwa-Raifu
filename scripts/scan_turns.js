const { captureScreen, executeLuau } = require('./mcp-exec.js');

async function main() {
  const turns = [
    { name: 'turn_229', stepNum: 229, pos: [-196.0, 361.9, -1920.0] },
    { name: 'turn_295', stepNum: 295, pos: [-332.8, 463.5, -2184.9] },
    { name: 'turn_336', stepNum: 336, pos: [-318.0, 536.1, -2262.0] },
    { name: 'turn_377', stepNum: 377, pos: [-404.0, 607.1, -2318.0] },
    { name: 'turn_404', stepNum: 404, pos: [-392.0, 653.6, -2404.0] },
    { name: 'turn_425', stepNum: 425, pos: [-470.0, 707.9, -2452.0] },
  ];

  for (const t of turns) {
    // We want camera slightly behind the turn position looking forward and up at the stairs
    // Let's get the exact CFrame of the step from Roblox
    const stepCF = await executeLuau(`
      local trail = workspace.SuwaMountainTrail
      local step = trail:FindFirstChild("TrailStep_${t.stepNum}") or trail:FindFirstChild("TrailStep")
      for _, c in ipairs(trail:GetChildren()) do
        if c.Name:find("Step") and (c.Position - Vector3.new(${t.pos[0]}, ${t.pos[1]}, ${t.pos[2]})).Magnitude < 8 then
          step = c
          break
        end
      end
      if step then
        local cf = step.CFrame
        local back = cf.Position - cf.LookVector * 12 + Vector3.new(0, 5, 0)
        local target = cf.Position + cf.LookVector * 15 + Vector3.new(0, 6, 0)
        return {
          back = { back.X, back.Y, back.Z },
          target = { target.X, target.Y, target.Z }
        }
      end
      return nil
    `);
    
    let info;
    try {
      info = JSON.parse(stepCF.content[0].text);
    } catch(e) {}

    if (info && info.back && info.target) {
      const outPath = `/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/inspect_${t.name}.png`;
      console.log(`Capturing ${t.name}...`);
      await captureScreen(outPath, info.back, info.target);
    }
  }
  console.log('All turn captures finished!');
}

main().catch(console.error);
