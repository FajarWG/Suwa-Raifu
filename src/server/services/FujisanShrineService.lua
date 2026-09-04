--!strict

-- FujisanShrineService: Authentic Japanese summit shrine interactions at Mt. Fuji (Fujisan Jinja / Okumiya).
-- Features:
-- 1. Saisenbako: Prayer & Coin Offering with suzu bell sound, coin drop, golden blessing aura.
-- 2. Omikuji: Drawing authentic Japanese shrine fortunes (Daikichi, Chukichi, etc.).
-- 3. Ema Rack: Viewing climber wishes and hanging summit prayers.
-- 4. Goshuin: Official Mt. Fuji 3,776m Summit Stamp certification.
-- 5. Miko Saki: Interactive Shrine Maiden dialog and blessings.

local Players = game:GetService('Players')
local Debris = game:GetService('Debris')
local TweenService = game:GetService('TweenService')

local EconomyService = require(script.Parent:WaitForChild('EconomyService'))

local FujisanShrineService = {}

-- Sound Assets
local SOUND_SUZU_BELL = 'rbxassetid://9114223170' -- Resonant sacred bell chime
local SOUND_COIN = 'rbxassetid://9065303649'      -- Crisp coin clink
local SOUND_STAMP = 'rbxassetid://9114223190'     -- Stamp / seal sound
local SOUND_RATTLE = 'rbxassetid://9113644053'    -- Wooden fortune stick rattle

local OMIKUJI_RESULTS = {
	{
		rank = '大吉 (Daikichi - Great Blessing)',
		color = Color3.fromRGB(255, 215, 0),
		desc = '富士山頂の朝日の如く運気隆盛！願い事は速やかに叶うでしょう。\n"Like the summit sunrise, your fortune shines bright! Your highest wishes will flourish."',
	},
	{
		rank = '中吉 (Chukichi - Middle Blessing)',
		color = Color3.fromRGB(255, 170, 60),
		desc = '清らかな山風が雑念を払う。日々の努力が大きな実を結びます。\n"Pure mountain breezes clear the mind. Your steady efforts will yield sweet fruit."',
	},
	{
		rank = '小吉 (Shokichi - Small Blessing)',
		color = Color3.fromRGB(120, 220, 140),
		desc = '一歩一歩の歩みが頂へ続く。思わぬ良き出会いに恵まれるでしょう。\n"Step by step leads to the summit. An unexpected pleasant encounter awaits you."',
	},
	{
		rank = '吉 (Kichi - Good Blessing)',
		color = Color3.fromRGB(100, 200, 255),
		desc = '心身健やかにして平穏なり。道中の安全は神仏により守られています。\n"Body and soul remain tranquil. Divine protection watches over all your steps."',
	},
	{
		rank = '末吉 (Suekichi - Future Blessing)',
		color = Color3.fromRGB(200, 160, 255),
		desc = '富士の峰の如く泰然と構えよ。焦らず待てば晴天が広がります。\n"Stand calm and patient like Mount Fuji. Clear blue skies will follow any cloud."',
	},
}

local MIKO_DIALOGUES = {
	'こんにちは！霊峰富士の頂（3,776m）へようこそお参りくださいました。賽銭箱にて道中の無事をご祈念くださいませ。\n"Welcome to the sacred summit of Mt. Fuji (3,776m)! Please offer a prayer at the Saisenbako for safe travels."',
	'本日の運勢を占う「おみくじ」はいかがですか？大吉が出ますようにお祈りしております。\n"Would you like to draw an Omikuji fortune slip today? I pray you receive Daikichi!"',
	'登頂の記念に、ぜひ御朱印をお受け取りくださいね。一生の思い出になりますよ。\n"Be sure to stamp your official summit Goshuin proof seal as a lifelong memory of conquering Mt. Fuji!"',
	'ここから見渡す諏訪湖の景色は素晴らしいですね。清らかな山の風をお楽しみください。\n"The panoramic view of Lake Suwa and the clouds from up here is breathtaking. Enjoy the pure mountain breeze."',
}

local mikoDialogIndex = 1
local prayerCooldown: { [Player]: number } = {}
local fortuneCooldown: { [Player]: number } = {}

local function playSound(parent: BasePart, soundId: string, volume: number, pitch: number?)
	local snd = Instance.new('Sound')
	snd.SoundId = soundId
	snd.Volume = volume or 1.0
	snd.PlaybackSpeed = pitch or 1.0
	snd.Parent = parent
	snd:Play()
	Debris:AddItem(snd, 5)
end

local function showFloatingBanner(character: Model, headerText: string, subText: string, headerColor: Color3)
	local head = character:FindFirstChild('Head')
	if not head or not head:IsA('BasePart') then
		return
	end

	local existing = head:FindFirstChild('ShrineNoticeGui')
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new('BillboardGui')
	gui.Name = 'ShrineNoticeGui'
	gui.Size = UDim2.fromOffset(360, 85)
	gui.StudsOffset = Vector3.new(0, 4.3, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = head
	gui.Parent = head

	local frame = Instance.new('Frame')
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	frame.BackgroundTransparency = 0.15
	frame.Parent = gui

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new('UIStroke')
	stroke.Color = headerColor
	stroke.Thickness = 2
	stroke.Parent = frame

	local header = Instance.new('TextLabel')
	header.Size = UDim2.new(1, -20, 0.38, 0)
	header.Position = UDim2.new(0, 10, 0.08, 0)
	header.BackgroundTransparency = 1
	header.Text = headerText
	header.TextColor3 = headerColor
	header.Font = Enum.Font.SourceSansBold
	header.TextScaled = true
	header.Parent = frame

	local body = Instance.new('TextLabel')
	body.Size = UDim2.new(1, -20, 0.48, 0)
	body.Position = UDim2.new(0, 10, 0.46, 0)
	body.BackgroundTransparency = 1
	body.Text = subText
	body.TextColor3 = Color3.fromRGB(245, 245, 245)
	body.Font = Enum.Font.SourceSans
	body.TextScaled = true
	body.TextWrapped = true
	body.Parent = frame

	task.delay(6.0, function()
		if gui and gui.Parent then
			local fade = TweenService:Create(frame, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
			fade:Play()
			task.wait(0.6)
			gui:Destroy()
		end
	end)
end

-- Saisenbako Offering & Prayer
local function handleSaisen(player: Player, saisenBox: BasePart)
	local now = os.clock()
	if prayerCooldown[player] and (now - prayerCooldown[player]) < 4 then
		return
	end
	prayerCooldown[player] = now

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild('HumanoidRootPart')
	if not root or not root:IsA('BasePart') then return end

	-- Try to offer 100 Yen if available
	local yenDeducted = false
	local spendRes = EconomyService.spendYen(player.UserId, 100)
	if spendRes.ok then
		yenDeducted = true
	end

	-- Sound effects
	playSound(saisenBox, SOUND_COIN, 0.9, 1.05)
	task.delay(0.35, function()
		playSound(saisenBox, SOUND_SUZU_BELL, 1.2, 0.98)
	end)

	-- Visual Blessing Aura
	local aura = Instance.new('Highlight')
	aura.Name = 'FujisanBlessingAura'
	aura.FillColor = Color3.fromRGB(255, 220, 120)
	aura.OutlineColor = Color3.fromRGB(255, 245, 200)
	aura.FillTransparency = 0.6
	aura.OutlineTransparency = 0.2
	aura.Adornee = character
	aura.Parent = character
	Debris:AddItem(aura, 8)

	-- Sparkles on Torso
	local torso = character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso')
	if torso and torso:IsA('BasePart') then
		local sp = Instance.new('Sparkles')
		sp.SparkleColor = Color3.fromRGB(255, 225, 130)
		sp.Parent = torso
		Debris:AddItem(sp, 6)
	end

	local subMsg = if yenDeducted
		then '¥100 を奉納しました。富士山の神々のご加護がありますように。\n"You offered ¥100. May the sacred spirits of Mt. Fuji bless your journey!"'
		else '真心の祈りを捧げました。富士山頂の御神徳が授けられました。\n"Your sincere prayer has reached the summit gods. Be blessed!"'

	showFloatingBanner(
		character,
		'⛩️ 二礼二拍手一礼 • 富士山本宮の御加護',
		subMsg,
		Color3.fromRGB(255, 215, 80)
	)
end

-- Omikuji Fortune Drawing
local function handleOmikuji(player: Player, omikujiBox: BasePart)
	local now = os.clock()
	if fortuneCooldown[player] and (now - fortuneCooldown[player]) < 3 then
		return
	end
	fortuneCooldown[player] = now

	local character = player.Character
	if not character then return end

	playSound(omikujiBox, SOUND_RATTLE, 1.0, 1.0)
	task.wait(0.4)
	playSound(omikujiBox, SOUND_SUZU_BELL, 0.8, 1.15)

	local chosen = OMIKUJI_RESULTS[math.random(1, #OMIKUJI_RESULTS)]
	showFloatingBanner(
		character,
		`📜 おみくじ • {chosen.rank}`,
		chosen.desc,
		chosen.color
	)
end

-- Ema Wish Wall
local function handleEma(player: Player, emaRack: BasePart)
	local character = player.Character
	if not character then return end

	playSound(emaRack, SOUND_RATTLE, 0.7, 1.2)
	showFloatingBanner(
		character,
		'🎋 絵馬 (Ema) • 富士山頂祈願',
		'「富士山頂 3,776m 登頂達成！家内安全・心願成就」\n"Reached Mt. Fuji Summit 3,776m! Health, happiness, and peace to all."',
		Color3.fromRGB(255, 185, 120)
	)
end

-- Goshuin Summit Stamp
local function handleGoshuin(player: Player, goshuinBook: BasePart)
	local character = player.Character
	if not character then return end

	playSound(goshuinBook, SOUND_STAMP, 1.1, 1.0)
	showFloatingBanner(
		character,
		'🎖️ 富士山頂 登頂御朱印 (3,776m)',
		'霊峰富士登頂の証を授与しました。\n"Official Mt. Fuji Summit Proof Stamp collected (Fujisan Hongu Okumiya - 3,776m)."',
		Color3.fromRGB(230, 50, 50)
	)
end

-- Miko Saki Dialogue
local function handleMiko(player: Player, mikoPart: BasePart)
	local character = player.Character
	if not character then return end

	local dialogue = MIKO_DIALOGUES[mikoDialogIndex]
	mikoDialogIndex = (mikoDialogIndex % #MIKO_DIALOGUES) + 1

	playSound(mikoPart, SOUND_SUZU_BELL, 0.6, 1.3)
	showFloatingBanner(
		character,
		'🌸 巫女 咲 (Miko Saki)',
		dialogue,
		Color3.fromRGB(255, 150, 170)
	)
end

function FujisanShrineService.init()
	local trail = workspace:FindFirstChild('SuwaMountainTrail')
	local interior = trail and trail:FindFirstChild('JinjaInterior')
	if not interior then
		task.delay(1, function()
			trail = workspace:FindFirstChild('SuwaMountainTrail')
			interior = trail and trail:FindFirstChild('JinjaInterior')
			if interior then
				FujisanShrineService.bindPrompts(interior)
			end
		end)
		return
	end

	FujisanShrineService.bindPrompts(interior)
	print('[FujisanShrineService] Initialized authentic Japanese shrine interactions.')
end

function FujisanShrineService.bindPrompts(interior: Model)
	local saisenbako = interior:FindFirstChild('Saisenbako') :: BasePart?
	if saisenbako then
		local prompt = saisenbako:FindFirstChildOfClass('ProximityPrompt')
		if prompt then
			prompt.ActionText = 'Pray (二礼二拍手一礼)'
			prompt.ObjectText = 'Saisenbako (賽銭箱)'
			prompt.Triggered:Connect(function(player)
				handleSaisen(player, saisenbako)
			end)
		end
	end

	local omikujiBox = interior:FindFirstChild('OmikujiBox') :: BasePart?
	if omikujiBox then
		local prompt = omikujiBox:FindFirstChildOfClass('ProximityPrompt')
		if prompt then
			prompt.ActionText = 'Draw Fortune'
			prompt.ObjectText = 'Omikuji (おみくじ)'
			prompt.Triggered:Connect(function(player)
				handleOmikuji(player, omikujiBox)
			end)
		end
	end

	local emaRack = interior:FindFirstChild('EmaRack') :: BasePart?
	if emaRack then
		local prompt = emaRack:FindFirstChildOfClass('ProximityPrompt')
		if prompt then
			prompt.ActionText = 'Hang Prayer (絵馬)'
			prompt.ObjectText = 'Ema Wall (絵馬掛け)'
			prompt.Triggered:Connect(function(player)
				handleEma(player, emaRack)
			end)
		end
	end

	local goshuinBook = interior:FindFirstChild('GoshuinBook') :: BasePart?
	if goshuinBook then
		local prompt = goshuinBook:FindFirstChildOfClass('ProximityPrompt')
		if prompt then
			prompt.ActionText = 'Stamp Summit Seal'
			prompt.ObjectText = 'Goshuin (御朱印 3,776m)'
			prompt.Triggered:Connect(function(player)
				handleGoshuin(player, goshuinBook)
			end)
		end
	end

	local miko = interior:FindFirstChild('MikoSaki')
	local mikoRoot = miko and miko:FindFirstChild('HumanoidRootPart') :: BasePart?
	if mikoRoot then
		local prompt = mikoRoot:FindFirstChildOfClass('ProximityPrompt')
		if prompt then
			prompt.ActionText = 'Talk'
			prompt.ObjectText = 'Miko Saki (巫女 咲)'
			prompt.Triggered:Connect(function(player)
				handleMiko(player, mikoRoot)
			end)
		end
	end
end

return FujisanShrineService
