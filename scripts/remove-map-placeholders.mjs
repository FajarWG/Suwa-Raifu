import fs from 'node:fs';

const filePath = 'maps/SuwaCentral.model.json';
const document = JSON.parse(fs.readFileSync(filePath, 'utf8'));
const placeholderNames = new Set(['LakeWater', 'NaturalShoreline', 'MountainBackdrop', 'ResidentialBlocks']);

document.children = document.children.filter((child) => !placeholderNames.has(child.name));

const cityGround = document.children.find((child) => child.name === 'CityGround');
if (cityGround) {
	cityGround.properties.Size = [760, 1, 430];
	cityGround.properties.CFrame = [0, -0.5, 65, 1, 0, 0, 0, 1, 0, 0, 0, 1];
}

fs.writeFileSync(filePath, `${JSON.stringify(document, null, 2)}\n`);
console.log('Removed terrain and residential Part placeholders; runtime services own the replacements.');
