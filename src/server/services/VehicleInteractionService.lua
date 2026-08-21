--!strict
local VehicleInteractionService = {}

function VehicleInteractionService.init()
    local RunService = game:GetService("RunService")
    local activeDrives = {}

    local function setupSeat(seat: Seat | VehicleSeat)
        seat.Disabled = true

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = seat:IsA("VehicleSeat") and "Drive" or "Sit"
        prompt.ObjectText = "Vehicle"
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 8
        prompt.Parent = seat

        prompt.Triggered:Connect(function(player)
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    seat.Disabled = false
                    seat:Sit(humanoid)
                end
            end
        end)

        seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            if seat.Occupant then
                prompt.Enabled = false
                
                -- Start driving loop if it's a VehicleSeat
                if seat:IsA("VehicleSeat") then
                    local rootPart = seat.Parent and (seat.Parent.PrimaryPart or seat.Parent:FindFirstChildWhichIsA("BasePart"))
                    if rootPart then
                        -- Create Physics Constraints for butter-smooth client network replication
                        local attachment = Instance.new("Attachment")
                        attachment.Name = "DriveAttachment"
                        attachment.Parent = rootPart
                        
                        local lv = Instance.new("LinearVelocity")
                        lv.Name = "DriveLV"
                        lv.Attachment0 = attachment
                        lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
                        -- Massive force on X/Z to push the heavy boat, 0 on Y to let buoyancy work!
                        lv.MaxAxesForce = Vector3.new(500000, 0, 500000)
                        lv.RelativeTo = Enum.ActuatorRelativeTo.World
                        lv.VectorVelocity = Vector3.zero
                        lv.Parent = rootPart
                        
                        local av = Instance.new("AngularVelocity")
                        av.Name = "DriveAV"
                        av.Attachment0 = attachment
                        av.MaxTorque = 500000
                        av.RelativeTo = Enum.ActuatorRelativeTo.World
                        av.AngularVelocity = Vector3.zero
                        av.Parent = rootPart

                        activeDrives[seat] = RunService.Heartbeat:Connect(function()
                            local moveSpeed = 40
                            local turnSpeed = 1.0
                            
                            local steer = seat.SteerFloat
                            local throttle = seat.ThrottleFloat
                            
                            local forwardDir = seat.CFrame.LookVector
                            local targetVel = forwardDir * (throttle * moveSpeed)
                            
                            local moveLerp = (throttle == 0) and 0.015 or 0.03
                            local currentVel = lv.VectorVelocity
                            local newX = currentVel.X + (targetVel.X - currentVel.X) * moveLerp
                            local newZ = currentVel.Z + (targetVel.Z - currentVel.Z) * moveLerp
                            
                            local currentRot = av.AngularVelocity
                            local targetRotY = -steer * turnSpeed
                            local newRotY = currentRot.Y + (targetRotY - currentRot.Y) * 0.05
                            
                            lv.VectorVelocity = Vector3.new(newX, 0, newZ)
                            av.AngularVelocity = Vector3.new(0, newRotY, 0)
                        end)
                    end
                end
            else
                prompt.Enabled = true
                seat.Disabled = true
                
                if seat:IsA("VehicleSeat") then
                    seat.Throttle = 0
                    seat.Steer = 0
                    
                    if activeDrives[seat] then
                        activeDrives[seat]:Disconnect()
                        activeDrives[seat] = nil
                    end
                    
                    local rootPart = seat.Parent and (seat.Parent.PrimaryPart or seat.Parent:FindFirstChildWhichIsA("BasePart"))
                    if rootPart then
                        local att = rootPart:FindFirstChild("DriveAttachment")
                        if att then att:Destroy() end
                        local lv = rootPart:FindFirstChild("DriveLV")
                        if lv then lv:Destroy() end
                        local av = rootPart:FindFirstChild("DriveAV")
                        if av then av:Destroy() end

                        rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
                        rootPart.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        end)
    end

    local function ensureSeatExists(model: Model)
        local hasVehicleSeat = false
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("VehicleSeat") then
                hasVehicleSeat = true
                break
            end
        end

        if not hasVehicleSeat then
            local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if not rootPart then
                warn("VehicleInteractionService: No BasePart in " .. model.Name)
                return
            end

            local cf, size = model:GetBoundingBox()
            local centerHeight = cf.Position.Y
            
            -- Creator Store static props are often held together by Anchored=true instead of welds.
            -- We must weld everything to the rootPart before unanchoring, or the boat will collapse!
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part ~= rootPart then
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = rootPart
                    weld.Part1 = part
                    weld.Parent = rootPart
                    part.Anchored = false
                end
            end
            
            -- ULTIMATE STABILITY SYSTEM (Kunci Keseimbangan Absolut)
            -- This completely bypasses Roblox's glitchy water buoyancy!
            local floatAtt = Instance.new("Attachment")
            floatAtt.Name = "StabilityAttachment"
            floatAtt.Parent = rootPart
            -- VERY IMPORTANT: Set WorldAxis to World Up so the boat doesn't tilt to the sky!
            floatAtt.WorldAxis = Vector3.new(0, 1, 0)
            
            -- 1. LOCK TILT: Prevents the boat from ever wobbling or capsizing
            local alignOri = Instance.new("AlignOrientation")
            alignOri.Name = "StabilityOrientation"
            alignOri.Attachment0 = floatAtt
            alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
            alignOri.AlignType = Enum.AlignType.PrimaryAxisParallel
            alignOri.PrimaryAxisOnly = true -- Allows turning (yaw), but locks pitch and roll
            alignOri.PrimaryAxis = Vector3.new(0, 1, 0)
            alignOri.RigidityEnabled = true -- 100% rigid, feels like concrete!
            alignOri.Parent = rootPart
            
            rootPart.Anchored = false
            rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.15, 0.3, 0.5)

            -- Creator Store boats are often built facing backwards relative to their bounding box.
            local forwardRotation = cf.Rotation * CFrame.Angles(0, math.pi, 0)

            local function spawnSeat(isDriver, visualPart, rotation)
                local seat = Instance.new(isDriver and "VehicleSeat" or "Seat")
                seat.Name = isDriver and "AutoGeneratedVehicleSeat" or "AutoGeneratedPassengerSeat"
                seat.Size = Vector3.new(1, 0.2, 1)
                seat.Transparency = 1
                seat.CanCollide = false
                
                if visualPart then
                    seat.CFrame = CFrame.new(visualPart.Position) * rotation
                else
                    -- For boats with no seats (like WoodBoat), sit higher up from the floor
                    seat.CFrame = CFrame.new(cf.Position + Vector3.new(0, -size.Y/2 + 1.5, 0)) * rotation
                end
                
                seat.Parent = model
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = seat
                weld.Part1 = rootPart
                weld.Parent = seat
                
                -- Initialize prompt rules immediately for this newly created seat
                setupSeat(seat)
            end

            local foundHelm = false
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    local name = string.lower(part.Name)
                    -- Driver seat
                    if name == "helm_chair" or (string.match(name, "chair") and not foundHelm) then
                        spawnSeat(true, part, forwardRotation)
                        foundHelm = true
                    -- Passenger couches
                    elseif string.match(name, "couch_vinyl") or string.match(name, "passenger") or string.match(name, "bench") then
                        -- Intelligent seating for complex couches (like Pontoon L-couches)
                        local isPort = string.match(name, "port")
                        local isStbd = string.match(name, "stbd")
                        
                        local upVector = forwardRotation.UpVector
                        local forwardVector = forwardRotation.LookVector
                        
                        if isPort or isStbd then
                            -- Port (Left) couches face Physical Right (-90 deg)
                            -- Starboard (Right) couches face Physical Left (+90 deg)
                            local faceRot = forwardRotation * CFrame.Angles(0, isPort and -math.pi/2 or math.pi/2, 0)
                            
                            -- Default spacing for straight couches
                            local offsets = {1.2, -1.2}
                            
                            -- Specific override for the L-shaped back couch near the table
                            -- The center of this mesh is at the back corner, so we must push both seats FORWARD
                            -- along the long cushion to prevent clipping into the short backrest!
                            if name == "portstern_couch_vinyl_main" then
                                offsets = {0.8, 2.2}
                            -- Specific override for the smaller back-right couch
                            elseif name == "stbdstern_couch_vinyl" then
                                offsets = {0.8, -0.8}
                            end
                            
                            spawnSeat(false, {Position = part.Position + (forwardVector * offsets[1]) + (upVector * 0.25)}, faceRot)
                            spawnSeat(false, {Position = part.Position + (forwardVector * offsets[2]) + (upVector * 0.25)}, faceRot)
                        else
                            -- Generic fallback for any other simple bench
                            spawnSeat(false, {Position = part.Position + (upVector * 0.25)}, forwardRotation)
                        end
                    end
                end
            end

            if not foundHelm then
                spawnSeat(true, nil, forwardRotation)
            end
        end
    end

    local function scanForSeats(parent: Instance)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") then
                ensureSeatExists(child)
            end
        end

        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("VehicleSeat") or child:IsA("Seat") then
                setupSeat(child)
            end
        end
        -- Listen for dynamically added vehicles in the future
        parent.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                -- Yield slightly to allow vehicle parts to load
                task.delay(0.5, function()
                    ensureSeatExists(child)
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("VehicleSeat") or desc:IsA("Seat") then
                            setupSeat(desc)
                        end
                    end
                end)
            end
        end)
    end

    local bicycles = workspace:WaitForChild("Bicycles")
    local lakeCrafts = workspace:WaitForChild("LakeCrafts")

    scanForSeats(bicycles)
    scanForSeats(lakeCrafts)

    print("[VehicleInteractionService] Initialized custom rules for vehicles.")
end

return VehicleInteractionService
