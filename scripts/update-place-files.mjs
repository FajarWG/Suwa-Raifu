import fs from 'node:fs';
import path from 'node:path';

const srcDir = path.resolve('src');
const buildDir = path.resolve('build');

function getLuaFiles(dir, map = new Map()) {
	const entries = fs.readdirSync(dir, { withFileTypes: true });
	for (const entry of entries) {
		const fullPath = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			getLuaFiles(fullPath, map);
		} else if (entry.name.endsWith('.lua')) {
			const basename = entry.name.split('.')[0];
			map.set(basename, fs.readFileSync(fullPath, 'utf8'));
		}
	}
	return map;
}

const luaMap = getLuaFiles(srcDir);
console.log(`Loaded ${luaMap.size} Lua source files:`, Array.from(luaMap.keys()));

const v19Path = path.join(buildDir, 'SuwaLife-SuwaLakeside-v19.rbxlx');
const v20Path = path.join(buildDir, 'SuwaLife-SuwaLakeside-v20.rbxlx');

let xmlContent = fs.readFileSync(v19Path, 'utf8');
let updatedCount = 0;

for (const [moduleName, code] of luaMap.entries()) {
	const pattern = new RegExp(
		`(<string name="Name">${moduleName}</string>\\s*<string name="Source"><!\\[CDATA\\[)([\\s\\S]*?)(]]></string>)`,
		'g'
	);

	if (pattern.test(xmlContent)) {
		xmlContent = xmlContent.replace(pattern, (match, p1, oldCode, p3) => {
			updatedCount++;
			return `${p1}${code}${p3}`;
		});
		console.log(`Updated module script: ${moduleName}`);
	} else {
		console.warn(`Module script ${moduleName} not matched in XML`);
	}
}

fs.writeFileSync(v19Path, xmlContent, 'utf8');
fs.writeFileSync(v20Path, xmlContent, 'utf8');

console.log(`Successfully synced ${updatedCount} scripts into v19.rbxlx and created v20.rbxlx!`);
