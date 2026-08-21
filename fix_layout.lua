local b = workspace.Bicycles:GetChildren()
local lc = workspace.LakeCrafts:GetChildren()

local bTemp = workspace.Bicycles:FindFirstChild("Bike")
local wbTemp = workspace.LakeCrafts:FindFirstChild("WoodBoat")
local fTemp = workspace.LakeCrafts:FindFirstChild("Fune")
local sbTemp = workspace.LakeCrafts:FindFirstChild("Speedboat")

for _, c in pairs(b) do if c ~= bTemp then c:Destroy() end end
for _, c in pairs(lc) do if c ~= wbTemp and c ~= fTemp and c ~= sbTemp then c:Destroy() end end

local function makeFloat(model)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = PhysicalProperties.new(0.15, 0.3, 0.5)
        end
    end
end
makeFloat(wbTemp)
makeFloat(fTemp)
makeFloat(sbTemp)

local SPAWN_DATA = {
    Bike = { t = bTemp, q = 10, pos = Vector3.new(285, 4.5, -120), spc = Vector3.new(5,0,0), y = 0 },
    WoodBoat = { t = wbTemp, q = 2, pos = Vector3.new(230, 4.0, -242), spc = Vector3.new(20,0,0), y = math.pi },
    Fune = { t = fTemp, q = 3, pos = Vector3.new(220, 4.0, -260), spc = Vector3.new(25,0,0), y = math.pi },
    Speedboat = { t = sbTemp, q = 2, pos = Vector3.new(230, 4.0, -280), spc = Vector3.new(30,0,0), y = math.pi }
}

for n, d in pairs(SPAWN_DATA) do
    if d.t then
        for i = 1, d.q do
            local ins = (i==1) and d.t or d.t:Clone()
            ins.Parent = d.t.Parent
            ins:PivotTo(CFrame.new(d.pos + (d.spc * (i-1))) * CFrame.Angles(0, d.y, 0))
        end
    end
end
