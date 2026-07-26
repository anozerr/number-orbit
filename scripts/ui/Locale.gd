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
	"en": {
		"difficulty.easy": "Easy",
		"difficulty.medium": "Normal",
		"difficulty.hard": "Hard",
		"difficulty.extreme": "Extreme",
		"difficulty.impossible": "Impossible",
		"levels.locked.body_unlock": "Beat the previous level to open it — or unlock it now for %d Lumens.",
		"levels.locked.insufficient": "Unlocking this level costs %d Lumens. You don't have enough — watch an ad to get %d Lumens.",
		"levels.locked.unlock": "Unlock",
		"hint.use": "Use Hint",
		"hint.insufficient": "Not enough Lumens for a hint. Watch an ad to get %d Lumens.",
		"complete.triple_hint": "Tap ×3 to triple your reward — watch a short ad",
		"complete.triple_done": "Reward tripled!",
		"game.info": "Use orbit numbers to reach the target.",
		"game.tap.moves_tut": "Learn the basics — stars come later.",
		"game.tap.level_tut": "Learn step by step — there is no rush.",
		"game.tap.level": "Beat this level to unlock the next one.",
		"game.tap.target": "Use orbit numbers to reach %d.",
		"game.tap.center": "Your number changes with every move.",
		"game.stars.keep3": "Reach the target — ★★★ on completion.",
		"game.stars.only_three": "This level awards ★★★ only.",
		"game.stars.band_list": "%s moves = %s",
		"game.progress.on3": "On track for ★★★.",
		"game.progress.on2": "★★ still in reach.",
		"game.progress.on1": "★ still in reach.",
		"game.progress.finish": "Reach the target.",
		"game.fail": "No moves left — tap Restart to try again.",
		"game.placeholder": "This level is being prepared.",
		"hint.to_win.one": "To win: 1 move left.",
		"hint.to_win.other": "To win: %d moves left.",
		"op.info.add": "Green numbers add to the center.",
		"op.info.subtract": "Red numbers subtract from center.",
		"op.info.multiply": "Blue numbers multiply the center.",
		"op.info.divide": "Orange numbers divide the center exactly.",
		"op.info.unavailable": "Grey numbers are unavailable now.",
		"tut.add.start": "Green numbers add to the center.",
		"tut.add.after": "Keep adding until you reach the target.",
		"tut.subtract.start": "Red numbers subtract from center.",
		"tut.subtract.after": "Grey would take the center below 1.",
		"tut.multiply.start": "Blue numbers multiply the center.",
		"tut.multiply.after": "Pick a multiplier that reaches the target.",
		"tut.divide.start": "Orange numbers divide only when exact.",
		"tut.divide.after": "Grey cannot divide the center exactly.",
		"tut.order.start": "Order matters — plan before you tap.",
		"tut.order.after": "Watch the center and plan ahead.",
		"tutorial.wrong_move": "Tutorial is safe. Levels have traps.",
		"tutorial.hint.next": "The next winning move is highlighted.",
		"tutorial.hint.none": "No winning move is available. Restart the explanation.",
	},
	"ru": {
		"common.cancel": "Отмена",
		"menu.play": "Играть",
		"menu.continue": "Продолжить",
		"menu.levels": "Уровни",
		"menu.settings": "Настройки",
		"levels.title": "Уровни",
		"levels.locked": "ЗАКРЫТО",
		"levels.howto.title": "Как играть",
		"levels.howto.sub": "Обучение · операции и порядок",
		"levels.locked.title": "Уровень закрыт",
		"levels.locked.body": "Пройдите предыдущий уровень, чтобы открыть его.",
		"levels.locked.body_unlock": "Пройдите предыдущий уровень или откройте его сейчас за %d люменов.",
		"levels.locked.insufficient": "Для открытия нужно %d люменов. Люменов недостаточно — посмотрите рекламу и получите %d люменов.",
		"levels.locked.watch_ad": "Смотреть рекламу",
		"levels.locked.watch_ad_reward": "Реклама · +%d люменов",
		"levels.locked.unlock": "Открыть",
		"game.level": "УРОВЕНЬ %d",
		"game.tutorial": "ОБУЧЕНИЕ",
		"game.hint": "Подсказка",
		"game.restart": "Заново",
		"game.moves": "ХОДЫ %d",
		"game.info": "Нажимайте числа на орбите до цели.",
		"game.placeholder": "Этот уровень пока готовится.",
		"hint.title": "ПОДСКАЗКА",
		"hint.body": "Потратьте %d люменов, чтобы проверить эту позицию.",
		"hint.cost": "Цена: %d люменов",
		"hint.balance": "Баланс: %d люменов",
		"hint.balance_short": "Баланс: %d / %d люменов",
		"hint.use": "Использовать подсказку",
		"hint.tap_next": "Нажмите это число на орбите следующим.",
		"settings.title": "Настройки",
		"settings.music": "Музыка",
		"settings.sound": "Звук",
		"settings.haptics": "Виброотклик",
		"settings.appearance": "ОФОРМЛЕНИЕ",
		"settings.light": "Светлое",
		"settings.dark": "Тёмное",
		"settings.language": "ЯЗЫК",
		"settings.reset": "Сбросить прогресс",
		"settings.reset.title": "Сброс прогресса",
		"settings.reset.confirm": "Сбросить",
		"settings.reset.body": "Это удалит ваш прогресс, звёзды, люмены и открытые уровни.",
		"complete.title": "%s пройден!",
		"complete.excellent": "Отлично!",
		"complete.continue": "Продолжить",
		"complete.continue_idea": "Хорошо. Переходим к следующей идее.",
		"complete.moves": "Ходов: %d",
		"complete.reward": "%d люменов",
		"complete.triple_hint": "Нажмите ×3 — короткая реклама утроит награду",
		"complete.triple_done": "Награда утроена!",
		"complete.reward_claimed": "Награда получена",
		"complete.next": "Дальше",
		"complete.back": "К уровням",
		"common.back": "Назад",
		"game.tap.moves_tut": "Учимся ходам — звёзды будут позже.",
		"game.tap.level_tut": "Учитесь шаг за шагом, не спешите.",
		"game.tap.level": "Пройдите — откроется следующий.",
		"game.tap.target": "Соберите %d из чисел орбиты.",
		"game.tap.center": "Ваше число. Ходы меняют его.",
		"game.stars.keep3": "Дойдите до цели — получите ★★★.",
		"game.stars.only_three": "За уровень дают только ★★★.",
		"game.stars.band_list": "%s хода = %s",
		"game.progress.on3": "Пока идёте на ★★★.",
		"game.progress.on2": "Ещё можно получить ★★.",
		"game.progress.on1": "Ещё можно получить ★.",
		"game.progress.finish": "Дойдите до цели.",
		"game.fail": "Ходов нет — нажмите «Заново».",
		"hint.none": "Отсюда не выиграть. Нажмите «Заново».",
		"hint.to_win.one": "До победы: 1 ход.",
		"hint.to_win.other": "Ходов до победы: %d.",
		"hint.insufficient": "Недостаточно люменов для подсказки. Посмотрите рекламу и получите %d люменов.",
		"op.info.add": "Зелёные прибавляются к центру.",
		"op.info.subtract": "Красные вычитаются из центра.",
		"op.info.multiply": "Синие умножают центр.",
		"op.info.divide": "Оранжевые делят, если ровно.",
		"op.info.unavailable": "Серые числа сейчас недоступны.",
		"op.chip.add": "Сум",
		"op.chip.subtract": "Выч",
		"op.chip.multiply": "Умн",
		"op.chip.divide": "Дел",
		"op.chip.unavailable": "Нед",
		"difficulty.easy": "Легко",
		"difficulty.medium": "Нормально",
		"difficulty.hard": "Сложно",
		"difficulty.extreme": "Экстремально",
		"difficulty.impossible": "Невозможно",
		"tut.add.start": "Зелёные прибавляют — нажимайте.",
		"tut.add.after": "Прибавляйте, чтобы достичь цели.",
		"tut.add.teaser": "Отлично! Теперь научимся вычитать.",
		"tut.subtract.start": "Красные вычитают из центра.",
		"tut.subtract.after": "Серое число увело бы центр ниже 1.",
		"tut.subtract.teaser": "Хорошо. Иногда лучше сначала увеличить число.",
		"tut.multiply.start": "Синие числа умножают центр.",
		"tut.multiply.after": "Выберите множитель, ведущий к цели.",
		"tut.multiply.teaser": "Отлично. Дальше — деление только нацело.",
		"tut.divide.start": "Оранжевые делят, только если ровно.",
		"tut.divide.after": "Серое число не делит центр ровно.",
		"tut.divide.teaser": "Отлично. Последняя мысль: важен порядок ходов.",
		"tut.order.start": "Порядок важен — планируйте ход.",
		"tut.order.after": "Следите за центром и планируйте ход.",
		"tut.order.teaser": "Готово! Уровни открыты.",
		"tut.order.teaser_replay": "Отличная практика. Возвращайтесь к уровням в любой момент.",
		"tut.add.teaser_replay": "Хорошее повторение. Возвращайтесь к уровням когда угодно.",
		"tut.subtract.teaser_replay": "Хороший повтор. Возвращайтесь к уровням в любой момент.",
		"tut.multiply.teaser_replay": "Отличная тренировка. Возвращайтесь к уровням, когда будете готовы.",
		"tut.divide.teaser_replay": "Отработано. Возвращайтесь к уровням в любой момент.",
		"coach.move": "Нажмите подсвеченный спутник.",
		"coach.add.center": "Фиолетовый круг — ваше число. Каждый ход его меняет.",
		"coach.add.target": "Цель — число, которого нужно достичь точно.",
		"coach.add.orbit": "Зелёные круги — ваши ходы. Нажмите один — он исчезнет.",
		"coach.add.op": "Зелёный — сложение: увеличивает число в центре.",
		"coach.subtract.op": "Красный — вычитание: уменьшает число в центре.",
		"coach.subtract.orbit": "Выбирайте красные по порядку. Слишком большое вычитание станет серым.",
		"coach.subtract.grey": "Серые сейчас недоступны — центр ушёл бы ниже 1.",
		"coach.subtract.grey2": "Серый всегда значит: этот ход сейчас недоступен.",
		"coach.multiply.op": "Синий — умножение: маленькое число быстро растёт.",
		"coach.multiply.orbit": "Умножайте осторожно: одним ходом легко перескочить цель.",
		"coach.divide.op": "Оранжевый — деление: работает, только если делится ровно.",
		"coach.divide.orbit": "Оранжевые доступны, только пока делят центр ровно.",
		"coach.divide.grey": "Это оранжевое число серое — сейчас не делится ровно.",
		"coach.order.orbit": "Теперь все четыре цвета вместе. Важно не только что, но и когда.",
		"tutorial.wrong_move": "Здесь безопасно. Дальше — ловушки.",
		"tutorial.hint.next": "Следующий победный ход подсвечен.",
		"tutorial.hint.none": "Победных ходов нет. Перезапустите объяснение.",
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
