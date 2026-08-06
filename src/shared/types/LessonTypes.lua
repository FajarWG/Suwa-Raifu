--!strict

-- Definisi tipe untuk sistem sekolah (lesson & quiz).

export type QuizQuestion = {
	promptKey: string,
	choices: { string }, -- localization keys
	answer: number, -- index jawaban benar
}

export type LessonDef = {
	id: string,
	titleKey: string,
	level: string,
	quiz: { QuizQuestion },
}

export type LessonDefs = { [string]: LessonDef }

-- Hasil submit quiz dari client.
export type QuizSubmission = {
	lessonId: string,
	answers: { [number]: number }, -- questionIndex -> answerIndex
}

-- Hasil penilaian quiz (server).
export type QuizResult = {
	lessonId: string,
	correct: number,
	total: number,
	passed: boolean,
	earnedXp: number,
}

return nil
