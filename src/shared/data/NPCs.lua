--!strict

-- Definisi NPC statis.
-- Referensi tipe: shared/types/NpcTypes.lua (NPCDef).

local NPCS: {
	[string]: NPCDef,
} = {
	teacher_sakura = {
		id = 'teacher_sakura',
		displayNameKey = 'npc.teacher_sakura.name',
		titleKey = 'npc.teacher_sakura.title',
		defaultIntent = 'greeting',
		dialogFlows = {
			greeting = {
				id = 'greeting',
				rootNodeId = 'start',
				nodes = {
					start = {
						id = 'start',
						lines = {
							{ key = 'dialog.sakura.greet1' },
							{ key = 'dialog.sakura.greet2' },
						},
						choices = {
							{ textKey = 'dialog.sakura.choice.intro', next = 'intro' },
							{ textKey = 'dialog.sakura.choice.bye', next = nil },
						},
					},
					intro = {
						id = 'intro',
						lines = {
							{ key = 'dialog.sakura.intro1' },
							{ key = 'dialog.sakura.intro2' },
						},
						next = 'quest_offer',
					},
					quest_offer = {
						id = 'quest_offer',
						lines = {
							{ key = 'dialog.sakura.quest_offer' },
						},
						choices = {
							{
								textKey = 'dialog.sakura.choice.accept',
								next = nil,
								action = 'quest_accept:quest_intro',
							},
							{ textKey = 'dialog.sakura.choice.decline', next = nil },
						},
					},
				},
			},
		},
	},
}

return NPCS
