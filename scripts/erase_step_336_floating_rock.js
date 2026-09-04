const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Erasing floating rock near step 336...');
  const code = `
local t = workspace.Terrain
-- Erase the floating rock (bounds: minX=-334, maxX=-290, minY=546, maxY=590, minZ=-2286, maxZ=-2250)
t:FillBlock(CFrame.new(-310, 568, -2268), Vector3.new(50, 50, 45), Enum.Material.Air)

-- Check remaining voxels in the region
local region = Region3.new(Vector3.new(-336, 544, -2290), Vector3.new(-288, 592, -2248)):ExpandToGrid(4)
local mats, occs = t:ReadVoxels(region, 4)
local s = mats.Size
local remaining = 0
for x = 1, s.X do
    for y = 1, s.Y do
        for z = 1, s.Z do
            if occs[x][y][z] > 0 then
                remaining = remaining + 1
            end
        end
    end
end
return "Remaining voxels: " .. remaining
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Take verification screenshot from the exact same angle as inspect_rock_step_336.png
  console.log('Capturing verification screenshot...');
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_step_336_rock_deleted.png', [-322, 545, -2255], [-308, 565, -2260]);
  
  // Also capture the stair view matching User's Image 2 (looking up the stairs with the cliff on the left and the sky on the right)
  await captureScreen('/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_step_336_user_view.png', [-326, 540, -2250], [-315, 555, -2265]);
  console.log('Finished capturing verification screenshots!');
}

main().catch(console.error);
