const fs = require('fs');
const path = require('path');

const buildDir = path.resolve('build');

for (const version of ['v19', 'v20']) {
    const file = path.join(buildDir, `SuwaLife-SuwaLakeside-${version}.rbxlx`);
    if (!fs.existsSync(file)) continue;

    let content = fs.readFileSync(file, 'utf8');

    // The start of the Dormitory model
    const dormMarker = '<Item class="Model" referent="78">';
    const dormIndex = content.indexOf(dormMarker);

    if (dormIndex === -1) {
        console.log(`Could not find Dormitory in ${version}`);
        continue;
    }

    // Find the end of the newly injected Bicycles model.
    // We know it was injected before the junk.
    // The Bicycles model is BAKE_8000 (or similar) but let's just find the string Name Bicycles
    const bicyclesStart = content.lastIndexOf('<string name="Name">Bicycles</string>', dormIndex);
    
    // We need to find the matching </Item> for the NEW Bicycles model.
    // Since it's well-formed, we can just find the Bicycles opening tag:
    const bicyclesModelOpen = content.lastIndexOf('<Item class="Model"', bicyclesStart);
    
    // Count tags forward from bicyclesModelOpen to find its closing tag
    let pos = bicyclesModelOpen;
    let depth = 0;
    while (pos < dormIndex && pos !== -1) {
        const nextOpen = content.indexOf('<Item ', pos + 1);
        const nextClose = content.indexOf('</Item>', pos + 1);
        
        if (nextOpen !== -1 && nextOpen < nextClose) {
            depth++;
            pos = nextOpen;
        } else if (nextClose !== -1) {
            depth--;
            pos = nextClose;
            if (depth === 0) {
                // Found the matching close tag!
                const endOfBicycles = pos + '</Item>'.length;
                // Everything between endOfBicycles and dormIndex is junk
                const junk = content.slice(endOfBicycles, dormIndex);
                console.log(`Found junk in ${version} (length: ${junk.length})`);
                
                // Replace content
                content = content.slice(0, endOfBicycles) + '\n    ' + content.slice(dormIndex);
                fs.writeFileSync(file, content, 'utf8');
                console.log(`Fixed ${version}`);
                break;
            }
        } else {
            break;
        }
    }
}
