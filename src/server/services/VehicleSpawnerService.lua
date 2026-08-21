--!strict
local InsertService = game:GetService("InsertService")

local VehicleSpawnerService = {}

local ASSETS = {
    Bike = { id = 6950939813, pos = CFrame.new(-32, 2.5, -99), folder = "Bicycles" },
    WoodBoat = { id = 9617142471, pos = CFrame.new(-105, 1.2, -180), folder = "LakeCrafts" },
    Fune = { id = 14379374652, pos = CFrame.new(245, 1.2, -220), folder = "LakeCrafts" },
    SpeedBoat = { id = 4921496603, pos = CFrame.new(-35, 1.2, -180), folder = "LakeCrafts" }
}

function VehicleSpawnerService.init()
    for name, data in pairs(ASSETS) do
        local success, model = pcall(function()
            return InsertService:LoadAsset(data.id)
        end)
        
        if success and model then
            -- LoadAsset returns a Model containing the requested asset(s)
            for _, child in ipairs(model:GetChildren()) do
                if child:IsA("Model") or child:IsA("Part") then
                    local targetFolder = workspace:FindFirstChild(data.folder)
                    if not targetFolder then
                        targetFolder = Instance.new("Folder")
                        targetFolder.Name = data.folder
                        targetFolder.Parent = workspace
                    end
                    child.Parent = targetFolder
                    
                    -- Pivot to approximate position
                    if child:IsA("Model") then
                        child:PivotTo(data.pos)
                    elseif child:IsA("Part") then
                        child.CFrame = data.pos
                    end
                end
            end
            model:Destroy()
            print("[VehicleSpawnerService] Spawned " .. name)
        else
            warn("[VehicleSpawnerService] Failed to spawn " .. name .. " (Asset ID " .. data.id .. "):", model)
        end
    end
end

return VehicleSpawnerService
