const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local bebeq = workspace:FindFirstChild("BebeqFireworkSystem")
local fw = bebeq and bebeq:FindFirstChild("Firework")
local att = fw and fw:FindFirstChild("Attachment")
if not att then return "No Attachment in Firework" end

local lines = {}
for _, child in ipairs(att:GetChildren()) do
    if child:IsA("ParticleEmitter") then
        table.insert(lines, string.format("Emitter: %s | Texture: %s | Lifetime: %s | Speed: %s | Size: %s",
            child.Name, child.Texture, tostring(child.Lifetime), tostring(child.Speed), tostring(child.Size)))
    elseif child:IsA("Sound") then
        table.insert(lines, string.format("Sound: %s | SoundId: %s", child.Name, child.SoundId))
    else
        table.insert(lines, string.format("Child: %s (%s)", child.Name, child.ClassName))
    end
end
return table.concat(lines, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content ? res.content[0].text : JSON.stringify(res, null, 2));
}

main().catch(console.error).finally(() => process.exit(0));
