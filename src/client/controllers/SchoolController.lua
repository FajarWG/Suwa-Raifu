--!strict

-- SchoolController (client): menampilkan panel kelas (lesson list & quiz).

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local LocalizationService =
	require(ReplicatedStorage.Shared:WaitForChild('services'):WaitForChild('LocalizationService'))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

local currentLocale = 'en'
local schoolGui: ScreenGui?

local SchoolController = {}

local function createGui(): ScreenGui
	if schoolGui then
		return schoolGui
	end
	local gui = Instance.new('ScreenGui')
	gui.Name = 'SchoolGui'
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	local frame = Instance.new('Frame')
	frame.Name = 'SchoolFrame'
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui

	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.Text = 'Lessons'
	title.Parent = frame

	local content = Instance.new('ScrollingFrame')
	content.Name = 'Content'
	content.Position = UDim2.new(0, 10, 0, 50)
	content.Size = UDim2.new(1, -20, 1, -90)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 6
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Parent = frame

	local closeBtn = Instance.new('TextButton')
	closeBtn.Name = 'Close'
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -10, 0, 8)
	closeBtn.Size = UDim2.new(0, 60, 0, 28)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 60)
	closeBtn.Text = 'X'
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.Parent = frame
	closeBtn.Activated:Connect(function()
		frame.Visible = false
	end)

	schoolGui = gui
	return gui
end

local function clearContent()
	if not schoolGui then
		return
	end
	local content = schoolGui.SchoolFrame.Content
	for _, child in content:GetChildren() do
		child:Destroy()
	end
end

-- Tampilkan quiz lesson; tampilkan soal, kumpulkan jawaban, submit.
local function showQuiz(lessonId: string)
	if not schoolGui then
		return
	end
	clearContent()
	local content = schoolGui.SchoolFrame.Content

	local Items = require(ReplicatedStorage.Shared.data.Items)
	local lesson = Items.LESSONS[lessonId]
	if not lesson then
		return
	end

	local answers: { [number]: number } = {}

	local promptLabel = Instance.new('TextLabel')
	promptLabel.Name = 'Prompt'
	promptLabel.Size = UDim2.new(1, 0, 0, 80)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Font = Enum.Font.Gotham
	promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptLabel.TextWrapped = true
	promptLabel.TextXAlignment = Enum.TextXAlignment.Left
	promptLabel.TextYAlignment = Enum.TextYAlignment.Top
	promptLabel.Parent = content

	local choiceFrame = Instance.new('Frame')
	choiceFrame.Name = 'Choices'
	choiceFrame.Position = UDim2.new(0, 0, 0, 90)
	choiceFrame.Size = UDim2.new(1, 0, 0, 140)
	choiceFrame.BackgroundTransparency = 1
	choiceFrame.Parent = content

	local function showQuestion(index: number)
		local question = lesson.quiz[index]
		if not question then
			-- Submit
			RemoteController.fire('QuizSubmit', { lessonId = lessonId, answers = answers })
			schoolGui.SchoolFrame.Visible = false
			return
		end
		promptLabel.Text = LocalizationService.get(currentLocale, question.promptKey)
		-- Bersihkan pilihan lama
		for _, child in choiceFrame:GetChildren() do
			child:Destroy()
		end
		for ci, choiceKey in ipairs(question.choices) do
			local btn = Instance.new('TextButton')
			btn.Name = 'Choice' .. ci
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.Position = UDim2.new(0, 0, 0, (ci - 1) * 38)
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
			btn.Font = Enum.Font.Gotham
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Text = LocalizationService.get(currentLocale, choiceKey)
			btn.Parent = choiceFrame
			btn.Activated:Connect(function()
				answers[index] = ci - 1
				showQuestion(index + 1)
			end)
		end
	end
	showQuestion(1)
end

-- Tampilkan daftar lesson; klik untuk mulai quiz.
local function showLessonList()
	if not schoolGui then
		return
	end
	clearContent()
	local content = schoolGui.SchoolFrame.Content
	local lessons = RemoteController.invoke('LessonGet')
	if type(lessons) ~= 'table' then
		return
	end

	local y = 0
	for _, lesson in ipairs(lessons) do
		local row = Instance.new('TextButton')
		row.Name = 'Lesson_' .. lesson.id
		row.Size = UDim2.new(1, 0, 0, 36)
		row.Position = UDim2.new(0, 0, 0, y)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.Font = Enum.Font.Gotham
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = LocalizationService.get(currentLocale, lesson.titleKey)
		if lesson.completed then
			row.Text = '[OK] ' .. row.Text
		end
		row.Parent = content

		if not lesson.completed then
			row.Activated:Connect(function()
				showQuiz(lesson.id)
			end)
		end
		y += 40
	end
end

function SchoolController.open()
	if not schoolGui then
		createGui()
	end
	schoolGui.SchoolFrame.Visible = true
	showLessonList()
end

function SchoolController.setLocale(locale: string)
	currentLocale = locale
end

function SchoolController.init()
	-- Skeleton: tombol buka panel dipasang nanti / oleh input.
	createGui()
end

return SchoolController
