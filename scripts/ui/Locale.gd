class_name Locale
extends RefCounted

# ============================================================================
# Lightweight localization scaffold.
#
# The UI is built in code, so instead of Godot's .po workflow we keep a simple
# key -> string registry per language. Call `Locale.t("key", "English fallback")`
# at build sites; unknown keys / untranslated languages fall back to the inline
# English default, so screens keep working while translations are filled in
# later. `set_language()` is persisted via GameState and triggers a rebuild.
# ============================================================================

const DEFAULT_LANGUAGE := "en"

# Ordered list of shippable languages (label shown in the picker).
const LANGUAGES := [
	{"code": "en", "label": "English"},
	{"code": "ru", "label": "Русский"},
]

static var _language: String = DEFAULT_LANGUAGE

# Per-language override tables. English uses inline fallbacks (empty table),
# other languages fill in keys over time; missing keys fall back to English.
static var _tables: Dictionary = {
	"en": {},
	"ru": {
		"common.cancel": "Отмена",
		"menu.play": "Играть",
		"menu.continue": "Продолжить",
		"menu.levels": "Уровни",
		"menu.settings": "Настройки",
		"levels.title": "Уровни",
		"levels.locked": "ЗАКРЫТО",
		"levels.howto.title": "Как играть",
		"levels.howto.sub": "Обучение · порядок, подсказки, операции",
		"levels.locked.title": "Уровень закрыт",
		"levels.locked.body": "Пройдите предыдущий уровень%s, чтобы открыть его.",
		"levels.locked.or_ad": " или посмотрите рекламу",
		"levels.locked.watch_ad": "Смотреть рекламу",
		"game.level": "УРОВЕНЬ %d",
		"game.tutorial": "ОБУЧЕНИЕ",
		"game.hint": "Подсказка",
		"game.restart": "Заново",
		"game.moves": "ХОДЫ %d",
		"game.info": "Нажимайте числа на орбите до цели.",
		"hint.title": "ПОДСКАЗКА",
		"hint.body": "Потратьте %d лампочек, чтобы открыть следующий верный ход.",
		"hint.balance": "Баланс: %d лампочек",
		"hint.balance_short": "Баланс: %d / %d лампочек",
		"hint.use": "Взять подсказку",
		"hint.tap_next": "Нажмите это число на орбите следующим.",
		"settings.title": "Настройки",
		"settings.music": "Музыка",
		"settings.sound": "Звук",
		"settings.appearance": "ОФОРМЛЕНИЕ",
		"settings.light": "Светлая",
		"settings.dark": "Тёмная",
		"settings.language": "ЯЗЫК",
		"settings.reset": "Сбросить прогресс",
		"settings.reset.title": "Сброс прогресса",
		"settings.reset.confirm": "Сбросить",
		"settings.reset.body": "Это удалит ваш прогресс, звёзды, лампочки и открытые уровни. Отменить нельзя.",
		"complete.title": "%s пройден!",
		"complete.excellent": "Отлично!",
		"complete.continue": "Продолжить",
		"complete.continue_idea": "Хорошо. Переходим к следующей идее.",
		"complete.moves": "Ходов: %d",
		"complete.reward": "Награда: +%d лампочек  •  Баланс: %d",
		"complete.reward_claimed": "Лучшая награда уже получена  •  Баланс: %d лампочек",
		"complete.next": "Дальше",
		"complete.back": "К уровням",
		"common.back": "Назад",
		"game.tap.moves_tut": "В обучении звёзд нет.",
		"game.tap.level_tut": "По одному шагу за раз.",
		"game.tap.level": "Пройдите — откроется следующий.",
		"game.tap.target": "Соберите %d из чисел орбиты.",
		"game.tap.center": "Ваше число. Ходы меняют его.",
		"game.stars.fewer": "Меньше ходов — больше звёзд.",
		"game.stars.three_in": "%d ходов — 3 звезды.",
		"game.stars.keep3": "Дойдите до цели ради 3 звёзд.",
		"game.progress.on3": "На пути к 3 звёздам.",
		"game.progress.on2": "2 звезды ещё возможны.",
		"game.progress.almost": "Почти — дойдите до цели.",
		"game.fail": "Ходов нет — «Заново».",
		"hint.none": "Отсюда не выиграть. Нажмите «Заново».",
		"hint.to_win": "Ходов до победы: %d.",
		"hint.insufficient": "Недостаточно лампочек для подсказки.",
		"op.info.add": "Зелёные прибавляются к центру.",
		"op.info.subtract": "Оранжевые вычитаются из центра.",
		"op.info.multiply": "Красные умножают центр.",
		"op.info.divide": "Синие делят, если ровно.",
		"op.info.unavailable": "Серые сейчас недоступны.",
		"op.chip.add": "Сум",
		"op.chip.subtract": "Выч",
		"op.chip.multiply": "Умн",
		"op.chip.divide": "Дел",
		"op.chip.unavailable": "Нед",
		"difficulty.easy": "Лёгкий",
		"difficulty.medium": "Средний",
		"difficulty.hard": "Сложный",
		"tut.add.start": "Зелёные прибавляют — нажимайте.",
		"tut.add.after": "Прибавляйте до цели.",
		"tut.add.teaser": "Отлично! Теперь научимся вычитать.",
		"tut.subtract.start": "Оранжевые вычитают из центра.",
		"tut.subtract.after": "Серое ушло бы ниже 1.",
		"tut.subtract.teaser": "Хорошо. Иногда лучше сначала увеличить число.",
		"tut.multiply.start": "Красные умножают центр.",
		"tut.multiply.after": "Выберите нужный множитель.",
		"tut.multiply.teaser": "Отлично. Дальше — деление только нацело.",
		"tut.divide.start": "Синие делят, только если ровно.",
		"tut.divide.after": "Серое сейчас не делится ровно.",
		"tut.divide.teaser": "Отлично. Последняя мысль: важен порядок ходов.",
		"tut.order.start": "Порядок важен — планируйте ход.",
		"tut.order.after": "Следите за центром, думайте.",
		"tut.order.teaser": "Готово! Уровни открыты.",
		"tut.order.teaser_replay": "Отличная практика. Возвращайтесь к уровням в любой момент.",
		"coach.add.center": "Фиолетовый круг — ваше число. Каждый ход его меняет.",
		"coach.add.target": "ЦЕЛЬ — число, которого нужно достичь точно.",
		"coach.add.orbit": "Зелёные круги — ваши ходы. Нажмите один — он исчезнет.",
		"coach.add.op": "Зелёный — сложение: увеличивает число в центре.",
		"coach.subtract.op": "Оранжевый — вычитание: уменьшает число в центре.",
		"coach.subtract.orbit": "Выбирайте оранжевые по порядку. Слишком большое вычитание станет серым.",
		"coach.subtract.grey": "Серые сейчас недоступны — центр ушёл бы ниже 1.",
		"coach.subtract.grey2": "Серый всегда значит: этот ход сейчас недоступен.",
		"coach.multiply.op": "Красный — умножение: маленькое число быстро растёт.",
		"coach.multiply.orbit": "Умножайте осторожно: одним ходом легко перескочить цель.",
		"coach.divide.op": "Синий — деление: работает, только если делится ровно.",
		"coach.divide.orbit": "Синие доступны, только пока делят центр ровно.",
		"coach.divide.grey": "Это синее число серое — сейчас не делится ровно.",
		"coach.order.orbit": "Теперь все четыре цвета вместе. Важно не только что, но и когда.",
	},
}

static func language() -> String:
	return _language

static func set_language(code: String) -> void:
	if _tables.has(code):
		_language = code
	else:
		_language = DEFAULT_LANGUAGE

static func available() -> Array:
	return LANGUAGES

static func label_for(code: String) -> String:
	for entry in LANGUAGES:
		if str(entry["code"]) == code:
			return str(entry["label"])
	return code

# Translate a key; `fallback` is the English source string used when the key is
# not present for the active language.
static func t(key: String, fallback: String) -> String:
	var table: Dictionary = _tables.get(_language, {})
	if table.has(key):
		return str(table[key])
	return fallback
