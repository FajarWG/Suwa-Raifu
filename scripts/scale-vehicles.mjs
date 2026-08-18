import fs from 'node:fs';

const jobs = [
  { file: 'maps/Bicycles.model.json', lengths: { ParkMamachari: 2.1, DormMamachari: 2.1, SchoolMamachari: 2.1 }, bottom: 0.25 },
  { file: 'maps/LakeCrafts.model.json', lengths: { DuckPedalBoat01: 6.5, DuckPedalBoat02: 6.5, LakeLeisureBoat: 6 }, bottom: 0.75, waterproofFloors: true },
];

function collectParts(node, output = []) {
  if (node.properties?.Size && node.properties?.CFrame) output.push(node);
  for (const child of node.children ?? []) collectParts(child, output);
  return output;
}

function round(value) {
  return Number(value.toFixed(6));
}

function scaleModel(model, targetLength, targetBottom) {
  const parts = collectParts(model);
  const bounds = parts.reduce((box, part) => {
    const [x, y, z] = part.properties.CFrame;
    const [sx, sy, sz] = part.properties.Size;
    box.minX = Math.min(box.minX, x - sx / 2);
    box.maxX = Math.max(box.maxX, x + sx / 2);
    box.minY = Math.min(box.minY, y - sy / 2);
    box.maxY = Math.max(box.maxY, y + sy / 2);
    box.minZ = Math.min(box.minZ, z - sz / 2);
    box.maxZ = Math.max(box.maxZ, z + sz / 2);
    return box;
  }, { minX: Infinity, maxX: -Infinity, minY: Infinity, maxY: -Infinity, minZ: Infinity, maxZ: -Infinity });

  const centerX = (bounds.minX + bounds.maxX) / 2;
  const centerZ = (bounds.minZ + bounds.maxZ) / 2;
  const factor = targetLength / (bounds.maxZ - bounds.minZ);

  for (const part of parts) {
    const cframe = part.properties.CFrame;
    const size = part.properties.Size;
    cframe[0] = round(centerX + (cframe[0] - centerX) * factor);
    cframe[1] = round(targetBottom + (cframe[1] - bounds.minY) * factor);
    cframe[2] = round(centerZ + (cframe[2] - centerZ) * factor);
    part.properties.Size = size.map((value) => round(value * factor));
  }
}

function ensureWaterproofFloor(model, targetBottom) {
  const parts = collectParts(model).filter((part) => part.name !== 'WaterproofCockpitFloor');
  const minX = Math.min(...parts.map((part) => part.properties.CFrame[0] - part.properties.Size[0] / 2));
  const maxX = Math.max(...parts.map((part) => part.properties.CFrame[0] + part.properties.Size[0] / 2));
  const minZ = Math.min(...parts.map((part) => part.properties.CFrame[2] - part.properties.Size[2] / 2));
  const maxZ = Math.max(...parts.map((part) => part.properties.CFrame[2] + part.properties.Size[2] / 2));
  const centerX = (minX + maxX) / 2;
  const centerZ = (minZ + maxZ) / 2;
  const isDuckBoat = model.name.startsWith('DuckPedalBoat');
  let floor = model.children.find((child) => child.name === 'WaterproofCockpitFloor');
  if (!floor) {
    floor = { className: 'Part', name: 'WaterproofCockpitFloor', properties: {} };
    model.children.push(floor);
  }
  floor.properties = {
    Anchored: true,
    CanCollide: false,
    Size: isDuckBoat ? [1.9, 0.25, 2.4] : [1.7, 0.25, 2.8],
    Color: isDuckBoat ? [0.922, 0.867, 0.71] : [0.871, 0.918, 0.937],
    Material: 'SmoothPlastic',
    CFrame: [centerX, targetBottom + 0.65, centerZ + (isDuckBoat ? 0.7 : -0.45), 1, 0, 0, 0, 1, 0, 0, 0, 1],
  };
}

for (const job of jobs) {
  const document = JSON.parse(fs.readFileSync(job.file, 'utf8'));
  for (const model of document.children ?? []) {
    const targetLength = job.lengths[model.name];
    if (targetLength) {
      scaleModel(model, targetLength, job.bottom);
      if (job.waterproofFloors) ensureWaterproofFloor(model, job.bottom);
    }
  }
  fs.writeFileSync(job.file, `${JSON.stringify(document, null, 2)}\n`);
}
