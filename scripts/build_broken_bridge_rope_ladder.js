const { executeLuau, captureScreen } = require('./mcp-exec.js');

async function main() {
  console.log('Building polished aesthetic rope ladder for broken bridge obstacle...');

  const code = `
local trail = workspace:WaitForChild("SuwaMountainTrail")

local bp = nil
local ts = nil

for _, c in ipairs(trail:GetChildren()) do
    if c.Name == "BrokenPlank" and (c.Position - Vector3.new(-127.2, 313.2, -1860.7)).Magnitude < 1 then
        bp = c
    end
    if c.Name == "TrailStep" and (c.Position - Vector3.new(-130.8, 322.4, -1863.8)).Magnitude < 1 then
        ts = c
    end
end

if not bp or not ts then
    return { error = "Could not find BrokenPlank or TrailStep" }
end

-- 1. Remove old rope ladder if exists
local oldModel = trail:FindFirstChild("BrokenBridgeRopeLadder")
if oldModel then oldModel:Destroy() end

local model = Instance.new("Model")
model.Name = "BrokenBridgeRopeLadder"
model.Parent = trail

-- Orientations & Anchors
local topFaceCf = ts.CFrame * CFrame.new(0, ts.Size.Y/2, -ts.Size.Z/2)
local topAnchor = topFaceCf * CFrame.new(0, 0, 0.4)

local botAnchor = bp.CFrame * CFrame.new(0, bp.Size.Y/2, -0.4)

local pTop = topAnchor.Position
local pBot = botAnchor.Position

local ladderVec = pTop - pBot
local ladderDist = ladderVec.Magnitude -- ~10.4 studs

local forwardDir = ts.CFrame.LookVector
local normalDir = -forwardDir

local ladderWidth = 4.0
local halfW = ladderWidth / 2

local ropeColor = Color3.fromRGB(165, 135, 95)  -- rustic twisted hemp
local woodColor = Color3.fromRGB(110, 78, 50)   -- mountain weathered timber
local ironColor = Color3.fromRGB(45, 45, 50)    -- forged iron

-- 2. Top Anchor Posts & Handrails on TrailStep
for _, sideX in ipairs({-halfW - 0.4, halfW + 0.4}) do
    local post = Instance.new("Part")
    post.Name = "TopAnchorPost"
    post.Size = Vector3.new(0.6, 3.8, 0.6)
    post.CFrame = topFaceCf * CFrame.new(sideX, 1.9, 0.9)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(75, 50, 32)
    post.Anchored = true
    post.Parent = model

    -- Forged iron ring
    local ring = Instance.new("Part")
    ring.Name = "IronAnchorRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.3, 0.8, 0.8)
    ring.CFrame = post.CFrame * CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, math.pi/2, 0)
    ring.Material = Enum.Material.Metal
    ring.Color = ironColor
    ring.Anchored = true
    ring.Parent = model
end

-- 3. Bottom Rope Cleats on BrokenPlank
for _, sideX in ipairs({-halfW, halfW}) do
    local cleat = Instance.new("Part")
    cleat.Name = "BottomCleat"
    cleat.Size = Vector3.new(0.6, 0.4, 0.8)
    cleat.CFrame = botAnchor * CFrame.new(sideX, 0.2, -0.3)
    cleat.Material = Enum.Material.Wood
    cleat.Color = Color3.fromRGB(65, 42, 28)
    cleat.Anchored = true
    cleat.Parent = model
end

-- 4. Heavy Side Suspension Ropes
for _, sideX in ipairs({-halfW, halfW}) do
    local pSideBot = (botAnchor * CFrame.new(sideX, 0.2, 0)).Position
    local pSideTop = (topAnchor * CFrame.new(sideX, 0, 0)).Position
    
    local ropeVec = pSideTop - pSideBot
    local ropeDist = ropeVec.Magnitude
    local ropeCf = CFrame.lookAt((pSideTop + pSideBot)/2, pSideTop)
    
    local sideRope = Instance.new("Part")
    sideRope.Name = "LadderRopeSide"
    sideRope.Shape = Enum.PartType.Cylinder
    sideRope.Size = Vector3.new(ropeDist + 0.4, 0.35, 0.35)
    sideRope.CFrame = ropeCf * CFrame.Angles(0, math.pi/2, 0)
    sideRope.Material = Enum.Material.Fabric
    sideRope.Color = ropeColor
    sideRope.Anchored = true
    sideRope.CanCollide = false
    sideRope.Parent = model
    
    -- Upper Safety Hand Ropes
    local topPostCf = topFaceCf * CFrame.new(sideX, 2.7, 0.9)
    local handVec = topPostCf.Position - pSideTop
    local handDist = handVec.Magnitude
    local handCf = CFrame.lookAt((topPostCf.Position + pSideTop)/2, topPostCf.Position)
    
    local handRope = Instance.new("Part")
    handRope.Name = "UpperHandRope"
    handRope.Shape = Enum.PartType.Cylinder
    handRope.Size = Vector3.new(handDist, 0.3, 0.3)
    handRope.CFrame = handCf * CFrame.Angles(0, math.pi/2, 0)
    handRope.Material = Enum.Material.Fabric
    handRope.Color = ropeColor
    handRope.Anchored = true
    handRope.CanCollide = false
    handRope.Parent = model
end

-- 5. Sturdy Wooden Rungs (Anak Tangga Kayu Balok)
local numRungs = 9
for i = 1, numRungs do
    local frac = (i - 0.5) / numRungs
    local rungCenter = pBot:Lerp(pTop, frac) + Vector3.new(0, 0.2, 0)
    local rungCf = CFrame.lookAt(rungCenter, rungCenter + forwardDir)
    
    local rung = Instance.new("Part")
    rung.Name = "LadderRung_" .. i
    rung.Size = Vector3.new(ladderWidth + 0.3, 0.45, 0.55)
    rung.CFrame = rungCf
    rung.Material = Enum.Material.Wood
    rung.Color = woodColor
    rung.Anchored = true
    rung.CanCollide = true
    rung.Parent = model
    
    -- Knots on ends
    for _, sideX in ipairs({-halfW, halfW}) do
        local knot = Instance.new("Part")
        knot.Name = "RopeKnot"
        knot.Size = Vector3.new(0.5, 0.55, 0.65)
        knot.CFrame = rungCf * CFrame.new(sideX, 0, 0)
        knot.Material = Enum.Material.Fabric
        knot.Color = ropeColor
        knot.Anchored = true
        knot.CanCollide = false
        knot.Parent = model
    end
end

-- 6. Functional Climbing TrussParts
local trussMid = (pTop + pBot) / 2
local trussHeight = 12.0
local trussCf = CFrame.new(trussMid.X, trussMid.Y, trussMid.Z) * ts.CFrame.Rotation

-- 2 parallel trusses to comfortably cover the full 4.0-stud ladder width
for _, xOff in ipairs({-0.9, 0.9}) do
    local truss = Instance.new("TrussPart")
    truss.Name = "ClimbTruss"
    truss.Size = Vector3.new(2, trussHeight, 2)
    truss.CFrame = trussCf * CFrame.new(xOff, 0, 0)
    truss.Transparency = 1 -- Invisible so only the gorgeous rope & timber rungs are seen
    truss.Anchored = true
    truss.CanCollide = true
    truss.Parent = model
end

-- 7. Adventure Sign Post on RIGHT side of BrokenPlank (facing approaching player)
local signPost = Instance.new("Part")
signPost.Name = "RopeLadderSignPost"
signPost.Size = Vector3.new(0.5, 4.2, 0.5)
signPost.CFrame = botAnchor * CFrame.new(-halfW - 1.8, 2.1, -1.0)
signPost.Material = Enum.Material.Wood
signPost.Color = Color3.fromRGB(75, 50, 32)
signPost.Anchored = true
signPost.Parent = model

local signBoard = Instance.new("Part")
signBoard.Name = "RopeLadderSign"
signBoard.Size = Vector3.new(3.8, 1.4, 0.3)
signBoard.CFrame = signPost.CFrame * CFrame.new(0, 0.8, 0)
signBoard.Material = Enum.Material.Wood
signBoard.Color = Color3.fromRGB(50, 35, 22)
signBoard.Anchored = true
signBoard.Parent = model

-- Warm lantern on top of signpost
local ltn = Instance.new("Part")
ltn.Name = "RopeLadderLantern"
ltn.Size = Vector3.new(0.8, 1.0, 0.8)
ltn.CFrame = signPost.CFrame * CFrame.new(0, 2.5, 0)
ltn.Material = Enum.Material.Neon
ltn.Color = Color3.fromRGB(255, 215, 140)
ltn.Anchored = true
ltn.Parent = model

local lgt = Instance.new("PointLight")
lgt.Color = Color3.fromRGB(255, 185, 100)
lgt.Brightness = 2.5
lgt.Range = 16
lgt.Parent = ltn

local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.Parent = signBoard

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, 0, 1, 0)
txt.BackgroundTransparency = 1
txt.Text = "🧗 縄梯子\\nROPE LADDER"
txt.TextColor3 = Color3.fromRGB(245, 225, 185)
txt.TextSize = 15
txt.Font = Enum.Font.GothamBold
txt.Parent = sg

local sgB = Instance.new("SurfaceGui")
sgB.Face = Enum.NormalId.Back
sgB.Parent = signBoard
local txtB = txt:Clone()
txtB.Parent = sgB

return {
    success = true,
    rungs = numRungs,
    topPos = tostring(pTop),
    botPos = tostring(pBot)
}
`;

  const res = await executeLuau(code, 'Server');
  console.log('Result:', res.content[0].text);
}

main().catch(console.error);
