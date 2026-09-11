const { setPlayState, executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Testing new Hanabi burst in Edit/Client...');
  // Let's test emitting a prototype burst in Studio
  const testBurstCode = `
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local function testHanabi(pos)
    local host = Instance.new("Part")
    host.Name = "HanabiTestOrigin"
    host.Size = Vector3.new(1, 1, 1)
    host.Position = pos
    host.Transparency = 1
    host.Anchored = true
    host.CanCollide = false
    host.Parent = workspace

    -- 1. Main Stars (Round, glowing pyrotechnic embers)
    local stars = Instance.new("ParticleEmitter")
    stars.Name = "HanabiStars"
    stars.Texture = "rbxassetid://14365285883"
    stars.LightEmission = 0.75
    stars.LightInfluence = 0
    stars.Brightness = 1.8
    stars.Orientation = Enum.ParticleOrientation.FacingCamera
    stars.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 220)),
        ColorSequenceKeypoint.new(0.08, Color3.fromRGB(255, 110, 160)), -- Sakura Pink
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 90, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 60, 220))     -- Violet fade
    })
    stars.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2.8),
        NumberSequenceKeypoint.new(0.6, 2.2),
        NumberSequenceKeypoint.new(1, 0)
    })
    stars.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.75, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    })
    stars.Lifetime = NumberRange.new(2.2, 2.8)
    stars.Speed = NumberRange.new(55, 68)
    stars.SpreadAngle = Vector2.new(180, 180)
    stars.Drag = 6.2
    stars.Acceleration = Vector3.new(0, -12, 0)
    stars.Rate = 0
    stars.Parent = host
    stars:Emit(240)

    -- 2. Golden Willow Streamers (Kamuro trailing embers)
    local willow = Instance.new("ParticleEmitter")
    willow.Name = "HanabiWillow"
    willow.Texture = "rbxassetid://14365285883"
    willow.LightEmission = 0.8
    willow.LightInfluence = 0
    willow.Brightness = 1.6
    willow.Orientation = Enum.ParticleOrientation.VelocityParallel
    willow.Squash = NumberSequence.new({
        NumberSequenceKeypoint.new(0, -0.6),
        NumberSequenceKeypoint.new(0.7, -0.4),
        NumberSequenceKeypoint.new(1, 0)
    })
    willow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 230)),
        ColorSequenceKeypoint.new(0.15, Color3.fromRGB(255, 210, 100)), -- Rich Gold
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 150, 40)),   -- Warm Amber
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 80, 20))
    })
    willow.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.8),
        NumberSequenceKeypoint.new(0.8, 1.2),
        NumberSequenceKeypoint.new(1, 0)
    })
    willow.Lifetime = NumberRange.new(3.2, 4.4)
    willow.Speed = NumberRange.new(35, 48)
    willow.SpreadAngle = Vector2.new(180, 180)
    willow.Drag = 3.2
    willow.Acceleration = Vector3.new(0, -20, 0)
    willow.Rate = 0
    willow.Parent = host
    willow:Emit(160)

    Debris:AddItem(host, 6)
    return "Hanabi test burst spawned at " .. tostring(pos)
end

return testHanabi(Vector3.new(0, 120, -480))
`;

  const res = await executeLuau(testBurstCode, 'Edit');
  console.log('Result:', res.content?.[0]?.text);
}

main().catch(console.error).finally(() => process.exit(0));
