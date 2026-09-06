const { executeLuau } = require('./mcp-exec.js');

async function main() {
  console.log('=== APPLYING WATERTIGHT COCKPIT & ELEVATED WATERLINE TO ALL SWAN BOATS ===');

  const code = `
local crafts = workspace:FindFirstChild("LakeCrafts")
if not crafts then return "no LakeCrafts folder" end

local updatedBoats = {}

for _, boat in ipairs(crafts:GetChildren()) do
    if boat:IsA("Model") and boat.Name:lower():find("swan") then
        local root = boat.PrimaryPart or boat:FindFirstChild("HumanoidRootPart")
        if root then
            -- Clean previous additions if any
            for _, child in ipairs(boat:GetChildren()) do
                if child.Name:find("Watertight") or child.Name:find("Pedal") then
                    child:Destroy()
                end
            end

            -- Ensure boat is elevated so root Y is 4.45 (dry and buoyant) and shifted clear of pier (Z = -254.00)
            local currentPos = root.Position
            local targetY = 4.45
            local targetZ = -254.00
            local deltaY = targetY - currentPos.Y
            local deltaZ = targetZ - currentPos.Z
            if math.abs(deltaY) > 0.05 or math.abs(deltaZ) > 0.05 then
                boat:PivotTo(boat:GetPivot() + Vector3.new(0, deltaY, deltaZ))
            end

            root:SetAttribute("ParkedY", root.Position.Y)
            root:SetAttribute("WaterlineY", root.Position.Y)
            root:SetAttribute("WaterlineOffset", 4.45)

            local cf = root.CFrame
            local isPink = boat.Name:lower():find("pink") ~= nil
            local hullColor = isPink and Color3.new(1, 0.713726, 0.807843) or Color3.fromRGB(245, 245, 248)
            local trimColor = Color3.fromRGB(255, 255, 255)
            local floorColor = Color3.fromRGB(230, 233, 238)
            local pedalColor = Color3.fromRGB(65, 68, 75)

            local function createPart(name, size, localPos, color, material, canCollide)
                local p = Instance.new("Part")
                p.Name = name
                p.Size = size
                p.CFrame = cf * CFrame.new(localPos)
                p.Color = color
                p.Material = material or Enum.Material.SmoothPlastic
                p.CanCollide = canCollide or false
                p.Anchored = true
                p.TopSurface = Enum.SurfaceType.Smooth
                p.BottomSurface = Enum.SurfaceType.Smooth
                p.Parent = boat
                
                local w = Instance.new("WeldConstraint")
                w.Part0 = root
                w.Part1 = p
                w.Parent = p
                return p
            end

            -- 1. Solid Watertight Cockpit Floor (Covers entire floor, completely hides & blocks water)
            createPart("WatertightCockpitFloor", Vector3.new(4.8, 0.35, 4.4), Vector3.new(0, -3.2, -0.4), floorColor, Enum.Material.SmoothPlastic, true)

            -- 2. Left & Right Watertight Coamings (Elevated Gunwale side walls bridging front and rear)
            -- Left Side Wall & Top Trim
            createPart("WatertightCoaming_Left", Vector3.new(0.4, 2.3, 3.8), Vector3.new(-2.55, -2.0, -0.4), hullColor, Enum.Material.SmoothPlastic, true)
            createPart("WatertightCoamingTrim_Left", Vector3.new(0.55, 0.25, 3.85), Vector3.new(-2.55, -0.85, -0.4), trimColor, Enum.Material.SmoothPlastic, true)

            -- Right Side Wall & Top Trim
            createPart("WatertightCoaming_Right", Vector3.new(0.4, 2.3, 3.8), Vector3.new(2.55, -2.0, -0.4), hullColor, Enum.Material.SmoothPlastic, true)
            createPart("WatertightCoamingTrim_Right", Vector3.new(0.55, 0.25, 3.85), Vector3.new(2.55, -0.85, -0.4), trimColor, Enum.Material.SmoothPlastic, true)

            -- 3. Front and Back Watertight Bulkheads
            createPart("WatertightBulkhead_Front", Vector3.new(4.8, 2.4, 0.4), Vector3.new(0, -2.0, -2.4), hullColor, Enum.Material.SmoothPlastic, true)
            createPart("WatertightBulkhead_Back", Vector3.new(4.8, 2.4, 0.4), Vector3.new(0, -2.0, 1.6), hullColor, Enum.Material.SmoothPlastic, true)

            -- 4. Authentic Center Pedal Console and Foot Pedals
            createPart("PedalBox_Center", Vector3.new(0.8, 1.2, 1.6), Vector3.new(0, -2.4, -1.2), hullColor, Enum.Material.SmoothPlastic, false)
            -- Driver pedals
            createPart("Pedal_Driver_Crank", Vector3.new(0.15, 0.6, 0.15), Vector3.new(-1.1, -2.8, -1.3), pedalColor, Enum.Material.Metal, false)
            createPart("Pedal_Driver_PadL", Vector3.new(0.4, 0.15, 0.3), Vector3.new(-1.3, -2.5, -1.3), pedalColor, Enum.Material.Metal, false)
            createPart("Pedal_Driver_PadR", Vector3.new(0.4, 0.15, 0.3), Vector3.new(-0.9, -3.0, -1.3), pedalColor, Enum.Material.Metal, false)
            -- Passenger pedals
            createPart("Pedal_Pass_Crank", Vector3.new(0.15, 0.6, 0.15), Vector3.new(1.1, -2.8, -1.3), pedalColor, Enum.Material.Metal, false)
            createPart("Pedal_Pass_PadL", Vector3.new(0.4, 0.15, 0.3), Vector3.new(0.9, -2.5, -1.3), pedalColor, Enum.Material.Metal, false)
            createPart("Pedal_Pass_PadR", Vector3.new(0.4, 0.15, 0.3), Vector3.new(1.3, -3.0, -1.3), pedalColor, Enum.Material.Metal, false)

            table.insert(updatedBoats, boat.Name .. " (Y=" .. string.format("%.2f", root.Position.Y) .. ")")
        end
    end
end

return "Successfully updated " .. tostring(#updatedBoats) .. " swan boats:\\n" .. table.concat(updatedBoats, "\\n")
`;

  const res = await executeLuau(code, 'Edit');
  console.log(res.content[0].text);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
