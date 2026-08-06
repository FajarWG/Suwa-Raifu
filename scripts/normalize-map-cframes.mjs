import fs from 'node:fs';
import path from 'node:path';

const mapsDirectory = path.resolve('maps');

function multiply(left, right) {
	return left.map((row) =>
		right[0].map((_, column) =>
			row.reduce((sum, value, index) => sum + value * right[index][column], 0),
		),
	);
}

function rotationMatrix(orientation = [0, 0, 0]) {
	const [xDegrees, yDegrees, zDegrees] = orientation;
	const x = (xDegrees * Math.PI) / 180;
	const y = (yDegrees * Math.PI) / 180;
	const z = (zDegrees * Math.PI) / 180;
	const rx = [
		[1, 0, 0],
		[0, Math.cos(x), -Math.sin(x)],
		[0, Math.sin(x), Math.cos(x)],
	];
	const ry = [
		[Math.cos(y), 0, Math.sin(y)],
		[0, 1, 0],
		[-Math.sin(y), 0, Math.cos(y)],
	];
	const rz = [
		[Math.cos(z), -Math.sin(z), 0],
		[Math.sin(z), Math.cos(z), 0],
		[0, 0, 1],
	];

	return multiply(multiply(rx, ry), rz);
}

function normalizeNumber(value) {
	return Math.abs(value) < 1e-12 ? 0 : Number(value.toFixed(10));
}

function visit(value, stats) {
	if (Array.isArray(value)) {
		for (const item of value) visit(item, stats);
		return;
	}

	if (!value || typeof value !== 'object') return;

	if (value.properties?.Position) {
		const [x, y, z] = value.properties.Position;
		const matrix = rotationMatrix(value.properties.Orientation);
		value.properties.CFrame = [
			x,
			y,
			z,
			...matrix.flat().map(normalizeNumber),
		];
		delete value.properties.Position;
		delete value.properties.Orientation;
		stats.converted += 1;
	}

	for (const child of Object.values(value)) visit(child, stats);
}

const files = fs
	.readdirSync(mapsDirectory)
	.filter((file) => file.endsWith('.model.json'))
	.sort();

let total = 0;
for (const file of files) {
	const filePath = path.join(mapsDirectory, file);
	const document = JSON.parse(fs.readFileSync(filePath, 'utf8'));
	const stats = { converted: 0 };
	visit(document, stats);
	fs.writeFileSync(filePath, `${JSON.stringify(document, null, 2)}\n`);
	total += stats.converted;
	console.log(`${file}: ${stats.converted} CFrames`);
}

console.log(`Converted ${total} positioned instances.`);
