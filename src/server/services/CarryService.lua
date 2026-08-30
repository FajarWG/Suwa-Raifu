--!strict

-- Piggyback carry ("gendong-gendong"): hold E on a nearby player to hoist
-- them onto your back. They ride welded there, frozen in place, until you
-- press X (CarryController fires CarryRelease) or either of you disconnects,
-- dies, or gets in a seat.

local Players = game:GetService('Players')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))

local CarryService = {}

local PROMPT_NAME = 'CarryPrompt'
-- Behind and above the carrier's back, facing the same way they are.
local CARRY_OFFSET = CFrame.new(0, 1.15, -0.65) * CFrame.Angles(0, math.rad(180), 0)

local carrying: { [Player]: Player } = {} -- rider -> the player on their back
local carriedBy: { [Player]: Player } = {} -- passenger -> the player carrying them
local welds: { [Player]: Weld } = {} -- keyed by passenger

local function findAnchorPart(character: Model): BasePart?
	return (character:FindFirstChild('UpperTorso') :: BasePart?)
		or (character:FindFirstChild('Torso') :: BasePart?)
		or character:FindFirstChild('HumanoidRootPart') :: BasePart?
end

local function findPrompt(character: Model): ProximityPrompt?
	local root = character:FindFirstChild('HumanoidRootPart')
	return root and root:FindFirstChild(PROMPT_NAME) :: ProximityPrompt?
end

local function setPromptEnabled(player: Player, enabled: boolean)
	local character = player.Character
	local prompt = character and findPrompt(character)
	if prompt then
		prompt.Enabled = enabled
	end
end

local function releaseCarry(rider: Player)
	local passenger = carrying[rider]
	if not passenger then
		return
	end
	carrying[rider] = nil
	carriedBy[passenger] = nil

	local weld = welds[passenger]
	welds[passenger] = nil
	if weld then
		weld:Destroy()
	end

	local passengerCharacter = passenger.Character
	local humanoid = passengerCharacter and passengerCharacter:FindFirstChildOfClass('Humanoid')
	if humanoid then
		humanoid.PlatformStand = false
	end

	setPromptEnabled(rider, true)
	setPromptEnabled(passenger, true)
end

local function canBeInvolved(player: Player): (boolean, Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return false, nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	local root = character:FindFirstChild('HumanoidRootPart') :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart then
		return false, nil, nil, nil
	end
	if carrying[player] or carriedBy[player] then
		return false, nil, nil, nil
	end
	return true, character, humanoid, root
end

local function startCarry(rider: Player, passenger: Player)
	local riderOk, riderCharacter = canBeInvolved(rider)
	local passengerOk, passengerCharacter, passengerHumanoid, passengerRoot = canBeInvolved(passenger)
	if not riderOk or not passengerOk or not riderCharacter or not passengerCharacter then
		return
	end

	local anchor = findAnchorPart(riderCharacter)
	if not anchor or not passengerRoot or not passengerHumanoid then
		return
	end

	local weld = Instance.new('Weld')
	weld.Name = 'CarryWeld'
	weld.Part0 = anchor
	weld.Part1 = passengerRoot
	weld.C0 = CARRY_OFFSET
	weld.Parent = anchor

	passengerHumanoid.PlatformStand = true

	carrying[rider] = passenger
	carriedBy[passenger] = rider
	welds[passenger] = weld

	setPromptEnabled(rider, false)
	setPromptEnabled(passenger, false)
end

local function releaseInvolving(player: Player)
	if carrying[player] then
		releaseCarry(player)
	end
	local carrier = carriedBy[player]
	if carrier then
		releaseCarry(carrier)
	end
end

local function setupPrompt(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid', 5)
	if player and humanoid and humanoid:IsA('Humanoid') then
		humanoid.Died:Connect(function()
			releaseInvolving(player)
		end)
	end

	local root = character:WaitForChild('HumanoidRootPart', 5)
	if not root or root:FindFirstChild(PROMPT_NAME) then
		return
	end

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = PROMPT_NAME
	prompt.ActionText = 'Carry'
	prompt.ObjectText = if player then player.DisplayName else 'Player'
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.4
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 7
	prompt.Parent = root

	prompt.Triggered:Connect(function(riderPlayer: Player)
		local passenger = Players:GetPlayerFromCharacter(character)
		if not passenger or riderPlayer == passenger then
			return
		end
		startCarry(riderPlayer, passenger)
	end)
end

function CarryService.init()
	for _, player in Players:GetPlayers() do
		if player.Character then
			setupPrompt(player.Character)
		end
		player.CharacterAdded:Connect(setupPrompt)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(setupPrompt)
	end)

	RemoteRegistry.registerEvent('CarryRelease', function(player: Player)
		releaseCarry(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		releaseInvolving(player)
		carrying[player] = nil
		carriedBy[player] = nil
	end)
end

return CarryService
