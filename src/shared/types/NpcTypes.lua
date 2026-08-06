--!strict

-- Definisi NPC & dialog.

-- Struktur satu baris dialog. Semua teks pakai localization key,
-- kecuali reading/romaji yang opsional untuk materi bahasa.
export type DialogLine = {
	key: string,
	reading: string?,
	romaji: string?,
}

export type DialogChoice = {
	textKey: string,
	next: string?,
	action: string?,
}

export type DialogNode = {
	id: string,
	lines: { DialogLine },
	choices: { DialogChoice }?,
	next: string?,
	action: string?,
}

export type DialogFlow = {
	id: string,
	rootNodeId: string,
	nodes: { [string]: DialogNode },
}

export type NPCDef = {
	id: string,
	displayNameKey: string,
	titleKey: string,
	dialogFlows: { [string]: DialogFlow },
	defaultIntent: string,
}

export type NPCs = { [string]: NPCDef }

return nil
