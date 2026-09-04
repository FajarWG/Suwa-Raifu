const { executeLuau } = require('./mcp-exec.js');

async function main() {
  const code = `
local trail = workspace.SuwaMountainTrail
local checks = {}

-- 1. Check AestheticCampfire
local camp = trail:FindFirstChild("AestheticCampfire")
local campUnanchored = 0
local seatCount = 0
if camp then
    for _, d in ipairs(camp:GetDescendants()) do
        if d:IsA("BasePart") and not d.Anchored then
            campUnanchored = campUnanchored + 1
        end
        if d:IsA("Seat") then
            seatCount = seatCount + 1
        end
    end
end
checks.camp = { exists = camp ~= nil, unanchored = campUnanchored, seats = seatCount }

-- 2. Check HutInteriorFurnishings
local hut = trail:FindFirstChild("HutInteriorFurnishings")
local hutUnanchored = 0
local hutSeats = 0
if hut then
    for _, d in ipairs(hut:GetDescendants()) do
        if d:IsA("BasePart") and not d.Anchored then
            hutUnanchored = hutUnanchored + 1
        end
        if d:IsA("Seat") then
            hutSeats = hutSeats + 1
        end
    end
end
checks.hut = { exists = hut ~= nil, unanchored = hutUnanchored, seats = hutSeats }

-- 3. Check CanyonInclineTunnel
local cTunnel = trail:FindFirstChild("CanyonInclineTunnel")
local cUnanchored = 0
if cTunnel then
    for _, d in ipairs(cTunnel:GetDescendants()) do
        if d:IsA("BasePart") and not d.Anchored then
            cUnanchored = cUnanchored + 1
        end
    end
end
checks.canyonTunnel = { exists = cTunnel ~= nil, unanchored = cUnanchored }

-- 4. Check StaircaseRockTunnel
local rTunnel = trail:FindFirstChild("StaircaseRockTunnel")
local rUnanchored = 0
if rTunnel then
    for _, d in ipairs(rTunnel:GetDescendants()) do
        if d:IsA("BasePart") and not d.Anchored then
            rUnanchored = rUnanchored + 1
        end
    end
end
checks.rockTunnel = { exists = rTunnel ~= nil, unanchored = rUnanchored }

-- 5. Check PillarPitEscapeLadder
local pitLadder = trail:FindFirstChild("PillarPitEscapeLadder")
local pitUnanchored = 0
if pitLadder then
    for _, d in ipairs(pitLadder:GetDescendants()) do
        if d:IsA("BasePart") and not d.Anchored then
            pitUnanchored = pitUnanchored + 1
        end
    end
end
checks.pitLadder = { exists = pitLadder ~= nil, unanchored = pitUnanchored }

-- 6. Check BridgeReturnTrail
local bridgeTrail = trail:FindFirstChild("BridgeReturnTrail")
local bUnanchored = 0
if bridgeTrail then
    for _, d in ipairs(bridgeTrail:GetDescendants()) do
        if d:IsA("BasePart") and not d.Anchored then
            bUnanchored = bUnanchored + 1
        end
    end
end
checks.bridgeTrail = { exists = bridgeTrail ~= nil, unanchored = bUnanchored }

return checks
`;

  const res = await executeLuau(code);
  console.log(res.content[0].text);
}

main().catch(console.error);
