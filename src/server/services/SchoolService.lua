--!strict

-- SchoolService (server): check-in kelas, lesson, quiz, reward XP & attendance.
-- Remote: SchoolCheckIn (event), LessonGet (function), QuizSubmit (event).

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local Items = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Items'))
local Math = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('Math'))
local LessonLogic = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('LessonLogic'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))
local LessonTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('LessonTypes'))

-- XP dasar per lesson (MVP).
local BASE_LESSON_XP = 50

local SchoolService = {}

-- Check-in kelas: tambah attendance, beri XP kecil.
function SchoolService.checkIn(playerId: number): ProfileTypes.Result<number>
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	profile.school.attendance += 1
	profile.progress.japaneseXp += 10
	profile.progress.japaneseLevel = Math.levelFromXp(profile.progress.japaneseXp)
	return { ok = true, data = profile.school.attendance }
end

-- Cek apakah player sudah menyelesaikan lesson.
function SchoolService.isLessonCompleted(playerId: number, lessonId: string): boolean
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return false
	end
	for _, id in profile.school.completedLessons do
		if id == lessonId then
			return true
		end
	end
	return false
end

-- Ambil daftar lesson yang tersedia (untuk client).
function SchoolService.getAvailableLessons(playerId: number): { any }
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return {}
	end
	local lessons: { any } = {}
	for id, def in Items.LESSONS do
		table.insert(lessons, {
			id = def.id,
			titleKey = def.titleKey,
			level = def.level,
			completed = SchoolService.isLessonCompleted(playerId, id),
		})
	end
	return lessons
end

-- Submit quiz; nilai server-side, beri reward bila lulus.
-- answers: { questionIndex = answerIndex }.
function SchoolService.submitQuiz(
	playerId: number,
	lessonId: string,
	answers: { [number]: number }
): ProfileTypes.Result<LessonTypes.QuizResult>
	local lesson = Items.LESSONS[lessonId]
	if not lesson then
		return { ok = false, error = 'Lesson not found' }
	end
	local profile = ProfileService.getProfile(playerId)
	if not profile then
		return { ok = false, error = 'Profile not loaded' }
	end
	if SchoolService.isLessonCompleted(playerId, lessonId) then
		return { ok = false, error = 'Lesson already completed' }
	end

	local correct = LessonLogic.countCorrect(lesson.quiz, answers)
	local total = #lesson.quiz
	local passed = LessonLogic.isPassed(correct, total)
	local xp = LessonLogic.calculateXp(correct, total, BASE_LESSON_XP)

	-- Beri reward & tandai selesai (hanya bila lulus)
	if passed then
		profile.progress.japaneseXp += xp
		profile.progress.japaneseLevel = Math.levelFromXp(profile.progress.japaneseXp)
		table.insert(profile.school.completedLessons, lessonId)
		profile.school.examResults[lessonId] = correct
	end

	return {
		ok = true,
		data = {
			lessonId = lessonId,
			correct = correct,
			total = total,
			passed = passed,
			earnedXp = passed and xp or 0,
		},
	}
end

function SchoolService.init()
	RemoteRegistry.registerEvent('SchoolCheckIn', function(player: Player)
		local result = SchoolService.checkIn(player.UserId)
		if result.ok then
			local profile = ProfileService.getProfile(player.UserId)
			if profile then
				RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
			end
		end
	end)

	RemoteRegistry.registerFunction('LessonGet', function(player: Player)
		return SchoolService.getAvailableLessons(player.UserId)
	end)

	RemoteRegistry.registerEvent('QuizSubmit', function(player: Player, payload: unknown)
		if type(payload) ~= 'table' then
			return
		end
		local lessonId = payload.lessonId
		local answers = payload.answers
		if type(lessonId) ~= 'string' or type(answers) ~= 'table' then
			return
		end
		local result = SchoolService.submitQuiz(player.UserId, lessonId, answers)
		if result.ok and result.data then
			RemoteRegistry.fireClient(player, 'QuizResult', result.data)
			local profile = ProfileService.getProfile(player.UserId)
			if profile then
				RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
			end
		end
	end)
end

return SchoolService
