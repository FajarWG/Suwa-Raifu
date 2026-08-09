import fs from 'node:fs';
import path from 'node:path';

const mapsDir = path.resolve('maps');
const buildDir = path.resolve('build');

let refId = 8000;
function getRef() {
	return `BAKE_${refId++}`;
}

// 1. Generate 8 Mamachari Bicycles in maps/Bicycles.model.json
const bicyclesFilePath = path.join(mapsDir, 'Bicycles.model.json');

function createMamachariNode(name, slotIndex) {
	const slotX = 410 + (slotIndex - 1) * 5.5;
	const baseY = 0.68;
	const slotZ = -70;

	return {
		className: 'Model',
		name: name,
		children: [
			{
				className: 'MeshPart',
				name: 'BodyAndWheels',
				properties: {
					Anchored: true,
					CanCollide: false,
					Size: [0.719588, 2.081301, 3.6],
					CFrame: [slotX, baseY + 0.63, slotZ, 1, 0, 0, 0, 1, 0, 0, 0, 1],
					MeshId: 'rbxassetid://74673162001305',
					TextureID: 'rbxassetid://97309290475089',
				},
			},
			{
				className: 'MeshPart',
				name: 'Handlebars',
				properties: {
					Anchored: true,
					CanCollide: false,
					Size: [1.499221, 0.414858, 0.429092],
					CFrame: [slotX, baseY + 1.765, slotZ - 0.56, 1, 0, 0, 0, 1, 0, 0, 0, 1],
					MeshId: 'rbxassetid://83658583052874',
					TextureID: 'rbxassetid://112463237208712',
				},
			},
			{
				className: 'MeshPart',
				name: 'Pedals',
				properties: {
					Anchored: true,
					CanCollide: false,
					Size: [0.93486, 0.335472, 0.181331],
					CFrame: [slotX, baseY + 0.001, slotZ + 0.187, 1, 0, 0, 0, 1, 0, 0, 0, 1],
					MeshId: 'rbxassetid://103681995324668',
					TextureID: 'rbxassetid://91481322667336',
				},
			},
			{
				className: 'Part',
				name: 'SolidBicycleCollider',
				properties: {
					Anchored: true,
					CanCollide: true,
					CanTouch: true,
					CanQuery: true,
					Transparency: 1,
					Size: [0.85, 0.5, 3.06],
					CFrame: [slotX, baseY + 0.55, slotZ, 1, 0, 0, 0, 1, 0, 0, 0, 1],
				},
			},
			{
				className: 'VehicleSeat',
				name: 'RideSeat',
				properties: {
					Anchored: true,
					CanCollide: false,
					Transparency: 1,
					Size: [0.75, 0.3, 0.8],
					CFrame: [slotX, baseY + 0.55, slotZ + 0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1],
				},
			},
			{
				className: 'Seat',
				name: 'PassengerSeat',
				properties: {
					Anchored: true,
					CanCollide: false,
					Transparency: 1,
					Size: [0.75, 0.3, 0.75],
					CFrame: [slotX, baseY + 0.55, slotZ + 1.1, 1, 0, 0, 0, 1, 0, 0, 0, 1],
				},
			},
		],
	};
}

const bicyclesDoc = {
	className: 'Model',
	children: [],
};
for (let slot = 1; slot <= 8; slot++) {
	const name = slot === 1 ? 'ParkMamachari' : `ParkMamachari${String(slot).padStart(2, '0')}`;
	bicyclesDoc.children.push(createMamachariNode(name, slot));
}
fs.writeFileSync(bicyclesFilePath, `${JSON.stringify(bicyclesDoc, null, 2)}\n`);
console.log('Baked 8 Mamachari models into maps/Bicycles.model.json');

// Convert node tree to XML
function jsonToXml(node) {
	const referent = getRef();
	let xml = `<Item class="${node.className}" referent="${referent}">\n<Properties>\n`;
	const name = node.name || node.properties?.Name || 'Model';
	xml += `<string name="Name">${name}</string>\n`;

	if (node.properties) {
		for (const [key, val] of Object.entries(node.properties)) {
			if (key === 'Name') continue;
			if (typeof val === 'boolean') {
				xml += `<bool name="${key}">${val}</bool>\n`;
			} else if (typeof val === 'number') {
				xml += `<float name="${key}">${val}</float>\n`;
			} else if (key === 'Size' && Array.isArray(val)) {
				xml += `<Vector3 name="size"><X>${val[0]}</X><Y>${val[1]}</Y><Z>${val[2]}</Z></Vector3>\n`;
			} else if (key === 'CFrame' && Array.isArray(val)) {
				const r = val.length === 12 ? val.slice(3) : [1, 0, 0, 0, 1, 0, 0, 0, 1];
				xml += `<CoordinateFrame name="CFrame"><X>${val[0]}</X><Y>${val[1]}</Y><Z>${val[2]}</Z><R00>${r[0]}</R00><R01>${r[1]}</R01><R02>${r[2]}</R02><R10>${r[3]}</R10><R11>${r[4]}</R11><R12>${r[5]}</R12><R20>${r[6]}</R20><R21>${r[7]}</R21><R22>${r[8]}</R22></CoordinateFrame>\n`;
			} else if ((key === 'MeshId' || key === 'TextureID') && typeof val === 'string') {
				xml += `<Content name="${key}"><url>${val}</url></Content>\n`;
			}
		}
	}
	xml += `</Properties>\n`;
	if (node.children) {
		for (const child of node.children) {
			xml += jsonToXml(child);
		}
	}
	xml += `</Item>\n`;
	return xml;
}

const bicyclesXml = jsonToXml({ className: 'Model', name: 'Bicycles', children: bicyclesDoc.children });

function replaceItemInXml(xmlContent, targetName, replacementXml) {
	const searchStr = `<string name="Name">${targetName}</string>`;
	let idx = xmlContent.indexOf(searchStr);
	if (idx === -1) return xmlContent;

	// Find the opening <Item class="Model" ...> before this Name
	const openTagStr = '<Item ';
	let startIdx = xmlContent.lastIndexOf(openTagStr, idx);
	
	// Balance the tags to find the end
	let pos = startIdx;
	let depth = 1;
	while (pos < xmlContent.length && pos !== -1) {
		const nextOpen = xmlContent.indexOf('<Item ', pos + 1);
		const nextClose = xmlContent.indexOf('</Item>', pos + 1);

		if (nextOpen !== -1 && nextOpen < nextClose) {
			depth++;
			pos = nextOpen;
		} else if (nextClose !== -1) {
			depth--;
			pos = nextClose;
			if (depth === 0) {
				const endIdx = pos + '</Item>'.length;
				return xmlContent.slice(0, startIdx) + replacementXml + xmlContent.slice(endIdx);
			}
		} else {
			break;
		}
	}
	return xmlContent;
}

// Update place files XML for Workspace.Bicycles
for (const version of ['v19', 'v20']) {
	const placeFile = path.join(buildDir, `SuwaLife-SuwaLakeside-${version}.rbxlx`);
	if (!fs.existsSync(placeFile)) continue;
	let content = fs.readFileSync(placeFile, 'utf8');

	const newContent = replaceItemInXml(content, 'Bicycles', bicyclesXml);
	if (newContent !== content) {
		fs.writeFileSync(placeFile, newContent, 'utf8');
		console.log(`Updated Workspace.Bicycles in ${version}.rbxlx`);
	} else {
		console.warn(`Could not find Bicycles model in ${version}.rbxlx`);
	}
}

// 2. Re-run script update
import('./update-place-files.mjs');
