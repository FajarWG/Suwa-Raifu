local MusicConfig = {}

---------------------------------------------------------
-- [ DAFTAR LAGU / PLAYLIST ]
---------------------------------------------------------
-- Tema: Suwa Nagano & Nuansa Pedesaan Jepang (Lake Suwa, Kimi no Na wa & Ghibli aesthetic)
MusicConfig.Playlist = {
	{ id = 1,  title = "Sparkle - RADWIMPS (Kimi no Na wa)", artist = "RADWIMPS", soundId = "rbxassetid://118270153851771" },
	{ id = 2,  title = "Floating Over Green Hills (Nagano Summer)", artist = "Anime Piano", soundId = "rbxassetid://78222794100906" },
	{ id = 3,  title = "Window Seat to Kyoto (Countryside Train)", artist = "Acoustic Anime", soundId = "rbxassetid://84633657295179" },
	{ id = 4,  title = "Shimmering Koto Dreams", artist = "Traditional Koto", soundId = "rbxassetid://107401137151251" },
	{ id = 5,  title = "Pure Shinto Peace (Suwa Shrine)", artist = "Shinto Shrine Ambient", soundId = "rbxassetid://108911841657614" },
	{ id = 6,  title = "Torii Gate Peace", artist = "Zen Temple Ambient", soundId = "rbxassetid://88579844437026" },
	{ id = 7,  title = "Lofi Garden Breeze", artist = "Japanese Lofi Chill", soundId = "rbxassetid://126770507384889" },
	{ id = 8,  title = "Sakura Petals Lofi Brew", artist = "Japanese Lofi", soundId = "rbxassetid://76038214145192" },
	{ id = 9,  title = "Yoru no Piano (夜のピアノ)", artist = "Serene Night Piano", soundId = "rbxassetid://82919687425012" },
	{ id = 10, title = "Lanterns on Silent Stone (Matsuri Evening)", artist = "Matsuri Atmosphere", soundId = "rbxassetid://119783344023286" },
	{ id = 11, title = "Zen Garden Lofi", artist = "Zen Tea House Vibe", soundId = "rbxassetid://139416870788012" },
	{ id = 12, title = "Hidden Lotus Pond (Lake Suwa Waters)", artist = "Lake Ambient Melody", soundId = "rbxassetid://82061470648013" },
}

---------------------------------------------------------
-- [ PENGATURAN UMUM ]
---------------------------------------------------------
MusicConfig.Settings = {
	DefaultVolume        = 0.75, -- Volume BGM nyaman
	AutoPlayOnStart      = true,
	LoopPlaylist         = true,
	Shuffle              = false,
	MaxPreload           = 12,
	SyncDriftTolerance   = 0.35,

	---------------------------------------------------------
	-- [ ANTI-SPAM REQUEST ]
	---------------------------------------------------------
	RequestCooldown      = 5,
	MaxQueuePerPlayer    = 2,
	AllowDuplicateInQueue = false,

	---------------------------------------------------------
	-- [ VOTE SKIP ]
	---------------------------------------------------------
	VoteSkipFraction     = 0.5,
	MinVotesToSkip       = 1, -- Diatur ke 1 agar pemain yang bermain sendiri (solo) bisa langsung skip!

	---------------------------------------------------------
	-- [ ADMIN / WHITELIST ]
	---------------------------------------------------------
	WhitelistOnly        = false,
}

---------------------------------------------------------
-- [ DAFTAR ADMIN / WHITELIST ]
---------------------------------------------------------
MusicConfig.Whitelist = {
	"fathurzoy7",
	9261166252,
	"BebeqSupreme",
	"GyroxIsWege",
	"Wegee"
}

return MusicConfig
