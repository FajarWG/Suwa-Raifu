--!strict

-- LessonLogic (shared): logika grading quiz murni (tanpa dependensi Roblox).
-- Testable & dipakai SchoolService server.

export type QuizQuestion = {
	promptKey: string,
	choices: { string },
	answer: number,
}

-- Nilai jawaban player terhadap soal. Return benar/salah.
local function gradeAnswer(question: QuizQuestion, playerAnswer: number): boolean
	return question.answer == playerAnswer
end

-- Hitung jumlah benar dari semua soal.
local function countCorrect(questions: { QuizQuestion }, answers: { [number]: number }): number
	local correct = 0
	for index, question in questions do
		if gradeAnswer(question, answers[index] or -1) then
			correct += 1
		end
	end
	return correct
end

-- Ambang lulus: 60% benar (configurable).
local PASS_RATIO = 0.6

-- Cek lulus berdasarkan jumlah benar / total.
local function isPassed(correct: number, total: number): boolean
	if total <= 0 then
		return false
	end
	return correct / total >= PASS_RATIO
end

-- Hitung XP yang didapat dari hasil quiz.
-- Lulus: xp = baseXp * (benar/total). Gagal: xp kecil (partisipasi).
local function calculateXp(correct: number, total: number, baseXp: number): number
	if total <= 0 then
		return 0
	end
	local ratio = correct / total
	if isPassed(correct, total) then
		return math.floor(baseXp * ratio)
	end
	return math.floor(baseXp * 0.2)
end

return {
	gradeAnswer = gradeAnswer,
	countCorrect = countCorrect,
	isPassed = isPassed,
	calculateXp = calculateXp,
	PASS_RATIO = PASS_RATIO,
}
