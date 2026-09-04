const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Building authentic climbable rope ladder for the high walkway entrance...');

  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

local ts = nil -- lower TrailStep landing
local bp = nil -- upper BrokenPlank walkway overhang

for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "TrailStep" and (c.Position - Vector3.new(-87.25, 302.0, -1826.25)).Magnitude < 1.5 then
        ts = c
    elseif c.Name == "BrokenPlank" and (c.Position - Vector3.new(-90.82, 313.21, -1829.33)).Magnitude < 1.5 then
        bp = c
    end
end

if not ts or not bp then
    return { error = "Could not find ts or bp", ts = tostring(ts), bp = tostring(bp) }
end

-- 1. Remove old WalkwayRopeLadder if exists
local old = trail:FindFirstChild("WalkwayRopeLadder")
if old then old:Destroy() end

local model = Instance.new("Model")
model.Name = "WalkwayRopeLadder"
model.Parent = trail

-- Orientations & Edge Anchors
-- Direction from lower step towards upper walkway overhang:
local approachDir = (Vector3.new(bp.Position.X, 0, bp.Position.Z) - Vector3.new(ts.Position.X, 0, ts.Position.Z)).Unit
local ladderNormal = approachDir
local ladderRight = Vector3.new(-ladderNormal.Z, 0, ladderNormal.X)

-- Top anchor edge on bp (the approach edge of the overhang)
-- bp top surface is at bp.Position.Y + bp.Size.Y/2 = 313.21 + 0.7 = 313.91
local topPlankY = bp.Position.Y + bp.Size.Y / 2
-- The edge facing the lower step:
local bpEdge = bp.Position - approachDir * (bp.Size.Z / 2 - 0.5)
local pTop = Vector3.new(bpEdge.X, topPlankY, bpEdge.Z)

-- Bottom anchor edge on ts
-- ts top surface is at ts.Position.Y + ts.Size.Y/2 = 302.0 + 1.7 = 303.70
local botPlankY = ts.Position.Y + ts.Size.Y / 2
local tsEdge = ts.Position + approachDir * (ts.Size.Z / 2 - 1.2)
local pBot = Vector3.new(tsEdge.X, botPlankY, tsEdge.Z)

local ladderVec = pTop - pBot
local ladderDist = ladderVec.Magnitude
local ladderWidth = 4.2
local halfW = ladderWidth / 2

local ropeColor = Color3.fromRGB(165, 135, 95)  -- rustic twisted hemp
local woodColor = Color3.fromRGB(110, 78, 50)   -- weathered mountain timber
local ironColor = Color3.fromRGB(45, 45, 50)    -- forged iron

-- 2. Top Anchor Posts & Handrails on BrokenPlank
for _, sideMult in ipairs({-1, 1}) do
    local sideOffset = ladderRight * (halfW * sideMult)
    local postPos = pTop + sideOffset + approachDir * 0.8 + Vector3.new(0, 1.8, 0)
    
    local post = Instance.new("Part")
    post.Name = "TopAnchorPost"
    post.Size = Vector3.new(0.6, 3.8, 0.6)
    post.CFrame = CFrame.new(postPos, postPos + approachDir)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(75, 50, 32)
    post.Anchored = true
    post.Parent = model

    -- Iron Anchor Ring on post
    local ring = Instance.new("Part")
    ring.Name = "IronRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.25, 0.7, 0.7)
    ring.CFrame = CFrame.new(postPos - Vector3.new(0, 0.6, 0) - approachDir * 0.35) * CFrame.Angles(0, math.pi/2, 0)
    ring.Material = Enum.Material.Metal
    ring.Color = ironColor
    ring.Anchored = true
    ring.Parent = model
end

-- 3. Bottom Anchor Cleats on TrailStep
for _, sideMult in ipairs({-1, 1}) do
    local sideOffset = ladderRight * (halfW * sideMult)
    local cleatPos = pBot + sideOffset - approachDir * 0.5 + Vector3.new(0, 0.2, 0)
    
    local cleat = Instance.new("Part")
    cleat.Name = "BottomCleat"
    cleat.Size = Vector3.new(0.6, 0.4, 0.8)
    cleat.CFrame = CFrame.new(cleatPos, cleatPos + approachDir)
    cleat.Material = Enum.Material.Wood
    cleat.Color = Color3.fromRGB(65, 42, 28)
    cleat.Anchored = true
    cleat.Parent = model
end

-- 4. Heavy Suspension Side Ropes
for _, sideMult in ipairs({-1, 1}) do
    local sideOffset = ladderRight * (halfW * sideMult)
    local pSideBot = pBot + sideOffset + Vector3.new(0, 0.2, 0)
    local pSideTop = pTop + sideOffset
    
    local ropeVec = pSideTop - pSideBot
    local ropeLen = ropeVec.Magnitude
    local ropeCf = CFrame.lookAt((pSideTop + pSideBot)/2, pSideTop)
    
    local rope = Instance.new("Part")
    rope.Name = "LadderRopeSide"
    rope.Shape = Enum.PartType.Cylinder
    rope.Size = Vector3.new(ropeLen + 0.3, 0.35, 0.35)
    rope.CFrame = ropeCf * CFrame.Angles(0, math.pi/2, 0)
    rope.Material = Enum.Material.Fabric
    rope.Color = ropeColor
    rope.Anchored = true
    rope.CanCollide = false
    rope.Parent = model
    
    -- Upper safety grab ropes on the overhang
    local pGrabEnd = pSideTop + approachDir * 2.0 + Vector3.new(0, 1.8, 0)
    local grabVec = pGrabEnd - pSideTop
    local grabCf = CFrame.lookAt((pGrabEnd + pSideTop)/2, pGrabEnd)
    
    local grabRope = Instance.new("Part")
    grabRope.Name = "SafetyGrabRope"
    grabRope.Shape = Enum.PartType.Cylinder
    grabRope.Size = Vector3.new(grabVec.Magnitude, 0.25, 0.25)
    grabRope.CFrame = grabCf * CFrame.Angles(0, math.pi/2, 0)
    grabRope.Material = Enum.Material.Fabric
    grabRope.Color = ropeColor
    grabRope.Anchored = true
    grabRope.CanCollide = false
    grabRope.Parent = model
end

-- 5. Ladder Rungs (Mountain Timber with rope binding knots)
local numRungs = 8
for i = 1, numRungs do
    local frac = (i - 0.3) / (numRungs + 0.4)
    local rungCenter = pBot:Lerp(pTop, frac)
    local rungCf = CFrame.lookAt(rungCenter, rungCenter + approachDir)
    
    local rung = Instance.new("Part")
    rung.Name = "LadderRung_" .. i
    rung.Size = Vector3.new(ladderWidth + 0.4, 0.45, 0.55)
    rung.CFrame = rungCf
    rung.Material = Enum.Material.Wood
    rung.Color = woodColor
    rung.Anchored = true
    rung.CanCollide = true
    rung.Parent = model
    
    -- Rope knots on each rung end
    for _, sideMult in ipairs({-1, 1}) do
        local knot = Instance.new("Part")
        knot.Name = "RopeKnot"
        knot.Size = Vector3.new(0.45, 0.55, 0.65)
        knot.CFrame = rungCf * CFrame.new(halfW * sideMult, 0, 0)
        knot.Material = Enum.Material.Fabric
        knot.Color = ropeColor
        knot.Anchored = true
        knot.CanCollide = false
        knot.Parent = model
    end
end

-- 6. Functional Climbing TrussParts (Roblox Humanoid Climbable!)
local trussMid = (pTop + pBot) / 2
local trussHeight = 11.5
local trussCf = CFrame.lookAt(trussMid, trussMid + approachDir)

for _, xOff in ipairs({-1.0, 1.0}) do
    local truss = Instance.new("TrussPart")
    truss.Name = "ClimbTruss"
    truss.Size = Vector3.new(2, trussHeight, 2)
    truss.CFrame = trussCf * CFrame.new(xOff, 0, 0)
    truss.Transparency = 1 -- Invisible: authentic rope & wooden rungs are visible
    truss.Anchored = true
    truss.CanCollide = true
    truss.Parent = model
end

-- 7. Trail Signboard & Warm Lantern on the lower platform
local signPos = pBot + ladderRight * (halfW + 1.8) + Vector3.new(0, 1.9, 0)
local signPost = Instance.new("Part")
signPost.Name = "RopeLadderSignPost"
signPost.Size = Vector3.new(0.5, 3.8, 0.5)
signPost.CFrame = CFrame.new(signPos, signPos + approachDir)
signPost.Material = Enum.Material.Wood
signPost.Color = Color3.fromRGB(75, 50, 32)
signPost.Anchored = true
signPost.Parent = model

local signBoard = Instance.new("Part")
signBoard.Name = "RopeLadderSign"
signBoard.Size = Vector3.new(3.6, 1.3, 0.3)
signBoard.CFrame = signPost.CFrame * CFrame.new(0, 0.6, 0)
signBoard.Material = Enum.Material.Wood
signBoard.Color = Color3.fromRGB(50, 35, 22)
signBoard.Anchored = true
signBoard.Parent = model

local ltn = Instance.new("Part")
ltn.Name = "RopeLadderLantern"
ltn.Size = Vector3.new(0.8, 0.9, 0.8)
ltn.CFrame = signPost.CFrame * CFrame.new(0, 2.3, 0)
ltn.Material = Enum.Material.Neon
ltn.Color = Color3.fromRGB(255, 215, 140)
ltn.Anchored = true
ltn.Parent = model

local lgt = Instance.new("PointLight")
lgt.Color = Color3.fromRGB(255, 185, 100)
lgt.Brightness = 2.4
lgt.Range = 16
lgt.Parent = ltn

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Back
sg.Parent = signBoard

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "🧗 縄梯子\\nROPE LADDER"
txt.TextColor3 = Color3.fromRGB(245, 225, 185)
txt.TextSize = 14
txt.Font = Enum.Font.SourceSansBold
txt.Parent = sg

return {
    success = true,
    rungs = numRungs,
    height = ladderDist,
    pBot = tostring(pBot),
    pTop = tostring(pTop)
}
`;

  const res = await executeLuau(code, 'Server');
  console.log('Build result:', JSON.stringify(res, null, 2));

  // 1. Capture user perspective matching the uploaded screenshot!
  console.log('Capturing user view matching uploaded screenshot...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/scratch/walkway_rope_ladder_user_view.png',
    [-84, 303.8, -1821],
    [-89, 308.0, -1828]
  );

  // 2. Capture front view of the rope ladder
  console.log('Capturing front view of ladder...');
  await captureScreen(
    '/Users/mac/.gemini/antigravity-ide/brain/116514da-f216-49e0-98d4-f72bc8c41816/scratch/walkway_rope_ladder_front_view.png',
    [-85, 307.0, -1823],
    [-90, 309.0, -1828]
  );

  console.log('Done!');
}

main().catch(console.error);
