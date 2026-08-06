--!strict

-- LocalizationService (shared): resolve localization key ke string.
-- Prototype saat ini English-only; tabel lain disimpan untuk phase localization nanti.

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local localizationFolder = ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('localization')

local tables: { [string]: { [string]: string } } = {}

-- Load semua bahasa dari folder.
for _, module in localizationFolder:GetChildren() do
	if module:IsA('ModuleScript') then
		tables[module.Name] = require(module)
	end
end

local LocalizationService = {}

-- Resolve key untuk bahasa tertentu (fallback en, lalu key asli).
function LocalizationService.get(locale: string, key: string): string
	local table_ = tables[locale]
	if table_ and table_[key] then
		return table_[key]
	end
	local enTable = tables['en']
	if enTable and enTable[key] then
		return enTable[key]
	end
	return key
end

local function isLocaleEnabled(locale: string): boolean
	for _, enabledLocale in Config.availableLocales do
		if locale == enabledLocale then
			return true
		end
	end
	return false
end

-- Ambil locale dari profile hanya jika locale tersebut aktif pada build saat ini.
function LocalizationService.getLocaleForProfile(profile: ProfileTypes.Profile): string
	local locale = profile.settings.translationLanguage or Config.defaultLocale
	if isLocaleEnabled(locale) and tables[locale] then
		return locale
	end
	return Config.defaultLocale
end

function LocalizationService.getAvailableLocales(): { string }
	local locales: { string } = {}
	for _, locale in Config.availableLocales do
		if tables[locale] then
			table.insert(locales, locale)
		end
	end
	return locales
end

return LocalizationService
