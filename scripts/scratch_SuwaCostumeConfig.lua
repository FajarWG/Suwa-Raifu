local CostumeConfig = {}

CostumeConfig.Presets = {
	-- 👘 TRADITIONAL & CULTURAL
	{
		id = "yukata_navy",
		name = "Navy Summer Yukata (紺の夏浴衣)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 12557329485,
		pants = 12557348926,
		description = "Traditional summer yukata, ideal for peaceful evening strolls along Lake Suwa.\n諏訪湖の夕涼みや花火祭りにぴったりの伝統的な浴衣。"
	},
	{
		id = "yukata_sakura",
		name = "Sakura Floral Yukata (桜の浴衣)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 79326241303163,
		pants = 101332222597295,
		description = "Graceful soft pink sakura blossom yukata with an elegant obi sash.\n淡い桜模様が華やかな、優美な夏祭り用レディース浴衣。"
	},
	{
		id = "miko_shrine",
		name = "Suwa Shrine Maiden (諏訪の巫女装束)",
		category = "Traditional",
		categoryIcon = "⛩️",
		shirt = 89608123771601,
		pants = 79227464689155,
		description = "Sacred red hakama and pure white vestments of the Suwa Taisha shrine maidens.\n諏訪大社に仕える巫女の清らかな白衣と緋袴。"
	},
	{
		id = "haori_classic",
		name = "Nagano Heritage Haori (信州の羽織着物)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 4901968882,
		pants = 4901972583,
		description = "Classic outer haori robe inspired by traditional Nagano countryside craftsmanship.\n信州の豊かな自然と伝統が息づく気品ある羽織スタイル。"
	},

	-- 🎒 SCHOOL UNIFORMS
	{
		id = "gakuran_male",
		name = "Gakuran High School (男子学ラン制服)",
		category = "School",
		categoryIcon = "🎒",
		shirt = 6914550284,
		pants = 6914552071,
		description = "Classic Japanese high school boys uniform with golden buttons.\n金ボタンが引き締める、凛々しく伝統的な男子高校生詰襟制服。"
	},
	{
		id = "sailor_female",
		name = "Classic Sailor Uniform (セーラー女子制服)",
		category = "School",
		categoryIcon = "🎒",
		shirt = 8959935056,
		pants = 1770015436,
		description = "Iconic navy pleated skirt and crisp neckerchief Japanese sailor uniform.\n定番のネイビータイとプリーツスカートが清楚なセーラー服。"
	},

	-- 🌠 ANIME SPECIAL
	{
		id = "taki_tachibana",
		name = "Taki Tachibana - Your Name (立花 瀧)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 8047583641,
		pants = 8047585078,
		description = "Tokyo school uniform worn by Taki when searching for Itomori & Lake Suwa.\n糸守と諏訪湖の記憶を辿る瀧の東京学生制服スタイル。"
	},
	{
		id = "mitsuha_miyamizu",
		name = "Mitsuha Miyamizu - Your Name (宮水 三葉)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 8661711667,
		pants = 8661713338,
		description = "Itomori High School sailor uniform with the iconic braided red ribbon.\n組紐の赤リボンが心をつなぐ、三葉の糸守高校制服。"
	},
	{
		id = "tanjiro_kamado",
		name = "Tanjiro - Demon Slayer (竈門 炭治郎)",
		category = "Anime",
		categoryIcon = "⚔️",
		shirt = 3830911721,
		pants = 3830913164,
		description = "Iconic green & black checkered haori worn by the Demon Slayer Corps warrior.\n市松模様の羽織が象徴的な、心優しき鬼殺隊士の装束。"
	},
	{
		id = "nezuko_kamado",
		name = "Nezuko - Demon Slayer (竈門 禰豆子)",
		category = "Anime",
		categoryIcon = "🌸",
		shirt = 3833290635,
		pants = 3833292415,
		description = "Pink asanoha geometric kimono with dark haori and checkered sash.\n麻の葉文様の桜色着物と黒羽織を身に纏った可憐な姿。"
	},
	{
		id = "satoru_gojo",
		name = "Satoru Gojo - Jujutsu Kaisen (五条 悟)",
		category = "Anime",
		categoryIcon = "👁️",
		shirt = 6271928011,
		pants = 6271929319,
		description = "High-collar dark uniform worn by the strongest Jujutsu High teacher.\n現代最強の呪術師が着こなすスタイリッシュな高専制服。"
	},

	-- 🎃 EVENT & FESTIVALS
	{
		id = "halloween_vampire",
		name = "Halloween Gothic Kimono (宵闇の着物)",
		category = "Event",
		categoryIcon = "🦇",
		shirt = 5683226955,
		pants = 5683228198,
		description = "Enchanting gothic dark-red kimono for mysterious lakeside Halloween nights.\n諏訪の夜に映える妖美なゴシック・ハロウィン着物。"
	},
	{
		id = "halloween_pumpkin",
		name = "Pumpkin Festival Haori (南瓜の祭法被)",
		category = "Event",
		categoryIcon = "🎃",
		shirt = 7531776939,
		pants = 7531778216,
		description = "Vibrant orange & midnight black Jack-o'-Lantern festival festival coat.\n鮮やかなカボチャ色と黒が祝祭を彩るハロウィン法被。"
	},
	{
		id = "kitsune_guardian",
		name = "Kitsune Shrine Guardian (白狐の霊装)",
		category = "Event",
		categoryIcon = "🦊",
		shirt = 3450917036,
		pants = 3450917639,
		description = "Sacred white fox spirit robe blessed for night lantern processions.\n夜の灯籠祭りを清め守護する神聖な白狐の霊験装束。"
	},
}

CostumeConfig.Categories = {
	{ id = "All", label = "All / すべて" },
	{ id = "Traditional", label = "👘 Traditional / 和風" },
	{ id = "School", label = "🎒 School / 制服" },
	{ id = "Anime", label = "🌠 Anime / アニメ" },
	{ id = "Event", label = "🎃 Event / 祭" },
}

function CostumeConfig.GetById(id)
	for _, preset in ipairs(CostumeConfig.Presets) do
		if preset.id == id then
			return preset
		end
	end
	return nil
end

return CostumeConfig
