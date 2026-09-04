const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Erasing floating rock at (-128, 370, -1862)...');
  const code = `
local t = workspace.Terrain
-- Erase the floating rock chunk (bounds minX=-138, maxX=-118, minY=358, maxY=382, minZ=-1874, maxZ=-1850)
t:FillBlock(CFrame.new(-128, 370, -1862), Vector3.new(36, 36, 36), Enum.Material.Air)

-- Also smooth/clean the shard near stairs at (-196.5, 371.0, -1926.8)
t:FillBlock(CFrame.new(-196, 371, -1928), Vector3.new(8, 10, 8), Enum.Material.Air)

-- Verify no voxels remain in the floating rock zone
local region = Region3.new(Vector3.new(-145, 350, -1880), Vector3.new(-110, 390, -1840)):ExpandToGrid(4)
local mats, occs = t:ReadVoxels(region, 4)
local s = mats.Size
local remaining = 0
for x = 1, s.X do
    for y = 1, s.Y do
        for z = 1, s.Z do
            if occs[x][y][z] > 0 then remaining = remaining + 1 end
        end
    end
end
return "Remaining voxels in floating rock zone: " .. remaining
`;
  const res = await executeLuau(code);
  console.log(res.content[0].text);

  // Take verification screenshot from turn 229 looking at where the rock was!
  // Camera position from inspect_turn_229: [-198.99, 369.2, -1929.3], looking at [-178, 375, -1911]
  const outPath = '/Users/mac/.gemini/antigravity-ide/brain/22c45569-6175-48e7-9147-80193f1a7d9d/verify_floating_rock_removed.png';
  await captureScreen(outPath, [-198.99, 369.2, -1929.3], [-178, 375, -1911]);
  console.log('Saved verification screenshot to:', outPath);
}

main().catch(console.error);
