import fs from 'node:fs';
import path from 'node:path';

const mapsDirectory = path.resolve('maps');
const entries = [];

function collect(node, instancePath) {
	if (node.properties?.CFrame) {
		entries.push({ instancePath, cframe: node.properties.CFrame });
	}

	for (const child of node.children ?? []) {
		collect(child, [...instancePath, child.name]);
	}
}

for (const file of fs.readdirSync(mapsDirectory).filter((name) => name.endsWith('.model.json')).sort()) {
	const rootName = file.replace('.model.json', '');
	const document = JSON.parse(fs.readFileSync(path.join(mapsDirectory, file), 'utf8'));
	for (const child of document.children ?? []) {
		collect(child, [rootName, child.name]);
	}
}

const lines = [
	'local ChangeHistoryService = game:GetService("ChangeHistoryService")',
	'local Workspace = game:GetService("Workspace")',
	'ChangeHistoryService:SetWaypoint("Before Suwa CFrame Repair")',
	'local entries = {',
];

for (const entry of entries) {
	const pathLiteral = entry.instancePath.map((part) => JSON.stringify(part)).join(', ');
	lines.push(`\t{{${pathLiteral}}, {${entry.cframe.join(', ')}}},`);
}

lines.push(
	'}',
	'local repaired = 0',
	'local missing = {}',
	'for _, entry in ipairs(entries) do',
	'\tlocal current = Workspace',
	'\tfor _, name in ipairs(entry[1]) do',
	'\t\tcurrent = current and current:FindFirstChild(name)',
	'\tend',
	'\tif current and current:IsA("BasePart") then',
	'\t\tcurrent.CFrame = CFrame.new(table.unpack(entry[2]))',
	'\t\trepaired += 1',
	'\telse',
	'\t\ttable.insert(missing, table.concat(entry[1], "."))',
	'\tend',
	'end',
	'for _, child in ipairs(Workspace:GetChildren()) do',
	'\tif child:IsA("Camera") and child ~= Workspace.CurrentCamera then',
	'\t\tchild:Destroy()',
	'\tend',
	'end',
	'Workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed',
	'Workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(420, 300, 420), Vector3.new(0, 0, -90))',
	'ChangeHistoryService:SetWaypoint("After Suwa CFrame Repair")',
	'return { repaired = repaired, missing = missing }',
);

process.stdout.write(lines.join('\n'));
