import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MajorExpressApp());
}

class MajorExpressApp extends StatefulWidget {
  const MajorExpressApp({super.key});

  @override
  State<MajorExpressApp> createState() => _MajorExpressAppState();
}

class _MajorExpressAppState extends State<MajorExpressApp> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('major_is_dark_theme') ?? true;
    });
  }

  Future<void> _toggleTheme() async {
    final next = !_isDark;
    setState(() => _isDark = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('major_is_dark_theme', next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Major Express — Электроконнект и Печатные платы',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: const Color(0xFF090D16),
      ),
      home: MajorWorkspaceScreen(
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class MajorWorkspaceScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const MajorWorkspaceScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<MajorWorkspaceScreen> createState() => _MajorWorkspaceScreenState();
}

class _MajorWorkspaceScreenState extends State<MajorWorkspaceScreen> {
  // 0 = Электроконнект, 1 = Печатные платы, 2 = Треки и копирование
  int _selectedNav = 0;
  bool _sumatraFound = false;
  Timer? _tracksWatcherTimer;

  // Электроконнект
  final TextEditingController _majorFirmController = TextEditingController();
  final TextEditingController _majorDateController = TextEditingController();
  final TextEditingController _majorTimeController =
      TextEditingController(text: '14:00-18:00');
  final TextEditingController _majorWeightController =
      TextEditingController(text: '1');
  final TextEditingController _majorPlacesController =
      TextEditingController(text: '1');
  final TextEditingController _majorDescController =
      TextEditingController(text: 'платы');
  final TextEditingController _majorInfoController =
      TextEditingController(text: 'УПД');
  final TextEditingController _majorFirmSearchController =
      TextEditingController();
  String _majorFirmFilter = '';
  List<String> _electroFirms = [];

  // Печатные платы
  final TextEditingController _platyFirmController = TextEditingController();
  final TextEditingController _platyDateController = TextEditingController();
  final TextEditingController _platyTimeController =
      TextEditingController(text: '14:00-18:00');
  final TextEditingController _platyWeightController =
      TextEditingController(text: '1');
  final TextEditingController _platyPlacesController =
      TextEditingController(text: '1');
  final TextEditingController _platyDescController =
      TextEditingController(text: 'платы');
  final TextEditingController _platyInfoController =
      TextEditingController(text: 'УПД');
  final TextEditingController _platyFirmSearchController =
      TextEditingController();
  String _platyFirmFilter = '';
  List<String> _platyFirms = [];

  // Список выписанных треков (формат: "Фирма Трек")
  List<String> _trackLines = [];

  static const List<String> _defaultElectroFirms = [
    'Судариков Петр Сергеевич',
    'ООО "ПТК "ЭДС"',
    'ООО "Сверх"',
    'Стародубцев Сергей Юрьевич',
    'ООО "ИТЭЛМА"',
    'ООО "Галс плюс"',
    'ООО "ЯМАТО СКЕЙЛ"',
    'АО "АНГСТРЕМ-ТЕЛЕКОМ"',
    'ООО "НПО "ОРК"',
    'АО "Группа Кремний Эл" Пронин Андрей',
    'ИП Роднов Константин Сергеевич',
    'ООО "СМИТ"',
    'ООО "Завод "Промприбор"',
    'ООО "КУБОМЕТР СВЕТА"',
    'ИП Усынин Кирилл Германович',
    'Кузавов Андрей Петрович',
    'ООО "Агрегатор"',
    'АО "МЗ"САПФИР" Балагур Евгений',
    'АО "МЗ"САПФИР" Максим Кондрашов',
    'ООО "ТПК "ВАРТОН"',
    'Ермаков Василий Игоревич',
    'Мышко Иван Игоревич',
    'ООО "ТЕПЛОМАРКЕТ"',
    'ООО "АРС" Иванов Алексей',
    'ООО "Пульс Электрик"',
    'ООО "ЦИФРОВАЯ НЕЗАВИСИМОСТЬ"',
    'ООО "ПРОТОН+"',
    'ООО "НИЦ Промышленная оптика"',
    'АО "МПОТК "ТЕХНОКОМПЛЕКТ"',
    'ООО "АНИМА ТРЕЙД"',
    'АО "Конструкторское бюро "Кунцево"',
    'ООО "Остек-Электро" Моргунова Ольга',
    'ООО "Остек-Электро" Мелянченко Сергей',
    'ООО "Нейрософт"',
    'ООО "РУТСТЕР"',
    'ООО "СТК"',
    'АО "Концерн Вега"',
    'АО "НИИСТТ"',
    'ООО "МЭЩ"',
    'ООО "ЭМУЛС"',
    'ООО "Техноресурс"',
    'ООО "РДВ-Технолоджи"',
    'ООО "ФОРВАРД-ВЕНТ"',
    'ИП Годына Александр Николаевич',
    'ООО « ЦЕНТР ИНЖЕНЕРНЫХ РАЗРАБОТОК « ПАРУС »',
    'ООО "КВ СИСТЕМЫ"',
    'ООО " НПК ИСКРА"',
    'ООО " Международный центр квантовой оптики',
    'ООО "Электроконнект"',
    'ООО "Электроконнект" завод',
    'ООО "Электроконнект" ЗАВОД',
    'ООО "ДИСТАНЦИЯ"',
    'АО "Мостком"',
    'ИП Лебедев Олег Александрович',
    'ООО "АТС Т"',
    'ООО "ПЛ ИНЖИНИРИНГ"',
    'АНО " Школа 21"',
    'ООО "АЙСИЭЛ ЭЛЕКТРОНИКС"',
    'ООО "КОМПАНИЯ "СТРИМ ЛАБС"',
    'ООО "Дельта Солюшнс"',
    'Упак-Лайнер',
    'ООО "Олл ин пром"',
    'ИП Гулин Станислав Евгеньевич',
    'АО "Научно-производственное "Рязаньприбор"',
    'АО"ГЗАС им Попова"',
    'ООО "Корд-группа"',
    'ООО "МИР-СПОРТ-ЦЕНТР"',
    'ЗАО "Сетевые Технологии"',
    'ООО Лигель',
    'ООО «АВТОМАТИКА плюс»',
    'Гидравлические Комплексные Системы',
    'ООО "РТЦ"',
    'ООО" Грош Торг"',
    'АО "ИНФОРМТЕХНИКА И СВЯЗЬ"',
    'ООО "НПО "ОРИГИНАЛЬНЫЕ РУССКИЕ КОНТРОЛЛЕРЫ"',
    'ООО "Деко-сервис"',
    'ИП Рухлов Дмитрий Сергеевич',
    'ООО"Натшелл"',
    'АО "НПО "Радиозавод им. А.С.Попова"',
    'ООО "Ателье Гончарова"',
    'АО "Электромеханика"',
    'ООО "РЭСТОК"',
    'ООО "МикроЭМ Технологии"',
    'ООО "Декаст"',
    'ООО "Технологии Света"',
    'АО ПФ "ЭЛВИРА"',
    'ООО "Гемодженикс"',
    'ООО "Комито"',
    'ООО "НПО "Вольт инжиниринг"',
    'ООО "Ревотех"',
    'ООО "Орион-Р"',
    'ООО "Трансаммиак"',
    'ООО "Промприбор-Р"',
    'ООО НПО "Грань"',
    'ИП Козин Дмитрий Владимирович',
    'ООО "Нетстелл"',
    'ООО "ТИОН"',
    'ИП Отчерцов Андрей Владимирович',
    'ИП Румянцев Андрей Александрович',
    'АО "РНТ"',
    'Бриз-Ал документы',
    'ООО "РТК-Технологии"',
    'ООО "Мотив НТ"',
    'ООО ПКФ "Экс-Форма"',
    'ООО "СД Группа"',
    'ООО "Элпром"',
    'АО "НПП "Исток" им. Шокина"',
    'ООО "Видар"',
    'АО "СИП РС"',
    'ООО "ИВК АИР ГРУПП"',
    'ООО ВНПЗ "Куб"',
    'ООО "Интегра Про"',
    'ООО "Смарт Групп"',
    'ООО "Максбионик"',
    'ООО "ЭН-ЭС-ДЖИ"',
    'ООО "ПЦРНИК"',
    'ООО "Катран-Интех"',
    'ООО "Энерготрейд"',
    'АО "Аэроэлектромаш"',
    'ООО "Фирма "Радиал"',
    'АО "АМТЕО М"',
    'ООО "Милти"',
    'ООО "Цезарь Системс"',
    'ООО "Лебер"',
    'ООО "НПО "Визит" им. В.Ф. Сотникова"',
    'ООО "РЭМО-Технологии"',
    'ПАО "Вектор"',
    'ООО НПФ "Радиосервис"',
    'МФТИ, ФИЗТЕХ',
    'ИП Рыбкина Светлана Александровна',
    'ООО "Парк Чудес"',
    'ПАКС',
    'ООО "Радиотехнологии"',
    'ООО "Эмеральд Экотехнологии"',
    'ООО "Лаборатория электроприводов "АДАПТТО"',
    'ООО "Фактор спецэлектроника"',
    'ООО "С-Компонент Дубна"',
    'АО "Росатом РДС"',
    'ООО "Чистое небо"',
    'ООО "НВС Навигационные Технологии"',
    'ООО "Панометрик"',
    'Аквариус Москва',
    'АО "КМК"',
    'ФГУП "ВНИИФТРИ"',
    'ООО "Интехпро"',
    'АО "Коралл-Телеком"',
    'АО "НИИП имени В.В. Тихомирова"',
    'ООО "Турков"',
    'ООО "НИИКАМ"',
    'ООО "Три точки мануфактуринг"',
    'ООО "Неовэлл"',
    'ООО "СГ-Терм"',
    'ИП Громов Андрей Васильевич',
    'ООО "ИРЗ"',
    'ООО "Динакор Силовые Технологии"',
    'ООО "ТД "Энергостандарт"',
    'ООО "Карат Рус"',
    'ООО "Амперка Роботс"',
    'АО "НИИМА "Прогресс"',
    'ООО "ПРОТОН"',
    'АО "БСЗ"',
    'АО "ПИК ПРОГРЕСС"',
    'ООО "Образование Будущего"',
    'ООО "ИНТ"',
    'ООО "Ольвия"',
    'ООО "Перспективная Электроника"',
    'ООО "Лиитс"',
    'ООО "Производственное предприятие КОНСТАР"',
    'АО "РНИЦ по Рязанской области"',
    'Аквариус Шуя',
    'Аквариус Тверь',
    'АО "НПО "Орион"',
    'АО "Лаборатория Электроники"',
    'АО "ОДК"',
    'ООО "Хьюман Филмс"',
    'ИП Кузьменко Лариса Юрьевна',
    'АО НПЦ "ЭЛВИС"',
    'ООО "Дантекс Рус"',
    'ООО "САУК"',
    'ООО "НТР"',
    'ООО "Вектор Электроника"',
    'ООО"Сварог"',
    'ООО "Эван"',
    'АО "ЭЛЕКТРУМ АВ"',
    'АО "Тулаэлектропривод"',
    'ООО "Компания "Объединенная энергия"',
  ];

  static const List<String> _defaultPlatyFirms = [
    'АО "ЦНИИ "Буревестник"',
    'ООО "ФИНКО"',
    'Владимир Бузовский',
    'ООО "СТС"',
    'АО"ГЗАС им Попова"',
    'Гетман Максим',
    'Сколковский институт науки и технологий Сколтех',
    'ООО "Синвайтес Инжиниринг"',
    'ООО СТС',
    'АО "ОКБ МЭИ"',
    'Калугаприбор',
    'АО "НИИМЭ"',
    'ООО "Сен-Гобен"',
    'ПП Минск',
    'ООО"КТЦ КЭБ"',
    'АО НПП ЦИФРОВЫЕ РЕШЕНИЯ',
    'МФТИ, ФИЗТЕХ',
    'ГАЗ-СИСТЕМА-СЕРВИС АО НПФ',
    'Документы ИАиЭ СО РАН',
    'Валерий Белоусов',
    'ЗАО НПП "Система"',
    'Сумин Евгений',
    'Ольга',
    'Черепанов Дмитрий',
    'Спирчагов Алексей Евгеньевич',
    'АО "НИИ "ЭЛПА"',
    'Черникова Ольга',
    'АО ПО "СЕВЕР"',
    'АО "ЭЗАН" ПП!!!',
    'УФК М.О (ИБП РАН)',
    'Документы в Интеррус',
    'Тепляков Пётр',
    'АО "ЭПМ"',
    'АО НИЦ "РЕЗОНАНС"',
    'ФГУП"ВНИИА"',
    'Валентин Дерябкин',
    'АО "НПО "РЯЗАНЬПРИБОР"',
    'Павел Титов',
    'Ленар Гимадиев',
    'ЗАО "ЭРАСИБ"',
    'эрасиб',
    'АО "ОДК"',
    'Ярыгин Александр Юрьевич',
    'АО "НПО "Орион"',
    'Козьменко Светлана Васильевна',
    'ЮРГПУ (НПИ)',
    'ЖЗЛ-Сервис',
    'Документы РусБИТех',
    'ЗАО "Полимерфильтр"',
    'ИПМТ ДВО РАН',
    'АО "Завод "Варяг-Техсервис"',
    'Блохина Ирина Валерьевна',
    'Валерий',
    'ООО "НЭК"',
    'Рощин Мстислав Александрович',
    'АО "НИИ "КУЛОН"',
    'АО "ЗАВОД" ЭЛЕКТРОМАШ"',
    'АО"КЗТМ"',
    'Филиал ИФП СО РАН "КТИПМ"',
    'ООО "НТП "Энергоконтроль"',
    'ОАО "Егоршинский радиозавод"',
    'АО "НПП "Пульсар"',
    'ООО "Рембаза"',
    'Ф+ тек Берсенева Ксения',
    'ООО "Джусто"',
    'ООО "РТС-БИТ"',
    'АО "766 УПТК"',
    'АО «НИИ НПО «ЛУЧ»',
    'АО "СПС"',
    'ООО "МГ-СЕРВИС"',
    'АО "Плазма"',
    'ООО "НИЦ СЭ И НК"',
    'АО "НПП"Геофизика-Космос',
    'АО «РДТ-Темп»',
    'АО "Радиозавод"',
    'ФГУП "Крыловский государственный научный центр"',
    'ООО "ОПТИМАЛЬНАЯ ФАБРИКА"',
    'АО "НИИЭМ"',
    'ООО "Тир Строй Монтаж"',
    'ПАО "НПП "Импульс"',
    'АО "Уральские Заводы"',
    'ОП "НИИ АЭМ ТУСУР"',
    'Доки_Завод',
    'ООО "Компания "Объединенная энергия"',
    'АО "РПЗ"',
    'ПАО ПЗ "Сигнал"',
    'АО "Корпорация "Фазотрон-НИИР"',
    'АО "АЛМАЗ"',
    'АО "ЦНИТИ "Техномаш"',
    'Приходько Сергей Викторович',
    'Самарский университет',
    'АО "НПП" РЕАКОНТ"',
    'АО "КБТочмаш им. А.Э. Нудельмана"',
    'ООО НППГА"ЛУЧ"',
    'АО "НПО "РусБИТех"',
    'АО "НПК "СПП"',
    'ОАО "Завод Электросигнал"',
    'ЮФУ, ЮФУ ЮЖНЫЙ ФЕДЕРАЛЬНЫЙ УНИВЕРСИТЕТ, ФГАОУ ВО',
    'ОАО "ПЯТИГОРСКИЙ ЗАВОД "ИМПУЛЬС"',
    'АО "НЦ ПЭ"',
    'АО "НТП "АВИАТЕСТ"',
    'ПАО "НПО "Алмаз"',
    'ООО "Электроконнект"',
    'РусБитех',
    'АО "НПП "КРАСНОЗНАМЁНЕЦ"',
    '18 ЦНИИ МО РФ МГУП',
    'АО "ЭВРИКА"',
    'ООО "ТПС"',
    'ООО "ПКФ ПОЛЁТ"',
    'АО "ЭРА Марин"',
    'АО "НПЦ" "АСПЕКТ"',
    'АО "Трансмаш"',
    'АО ВП "ЭРА"',
    'АО "Красный гидропресс"',
    'ООО "Наутилус"',
    'АО "ГНПП "Регион"',
    'ФГУП МОКБ "Марс"',
    'ЗАО "КоМЭНС"',
    'АО НИИПП',
    'ПАО НПО "Наука"',
    'АО "КИПЗ"',
    'АО "КЭТЗ"',
    'АО "Цнииаг"',
    'АО "КОБРА"',
    'АО Системы управления и приборы',
    'АО "Корпарация "Внииэм"',
    'АО "ЦНИИ "Волна"',
    'ОАО "НПП КП "Квант"',
    'АО "Обуховское"',
    'НП ЗАО "РЭКО-ВЕК"',
    'АО "АВЭКС"',
    'ПАО"Саратовский электроприборостроительный з-д им.',
    'ПАО "РЕАТОН"',
    'ООО «ЛЭМЗ-Т»',
    'АО "НИИПП"',
    'ООО "УРАРТУ"',
    'АО "Бета ир"',
    'АО "НИИ "Октава"',
    'ООО"РАДАРАВИАСЕРВИС"',
    'Шарапов Вадим',
    'АО "НИИТС"Синвент"',
    'ООО "БОРЕЙ"',
    'Беленькая Татьяна Ивановна',
    'ООО "Нейрософт"',
    'АО «ЗАВОД «ФИОЛЕНТ»',
    'ФГУП "ВНИИФТРИ"',
    'АО "КРАСНЫЙ ГИДРОПРЕСС"',
    'ООО "ИНДЖЕР"',
    'ПАО "КОРПОРАЦИЯ "ИРКУТ"',
    'ЗАО НПЦ ФИРМА "НЕЛК"',
    'АО МТЗ ТРАНСМАШ',
    'ООО "ТЭНСНАБ"',
    'АО "НИИ "Полюс" им.М.Ф.Стельм',
    'ООО "ОЛЕМАТ"',
    'АО "ОРКК"-"НИИ КП"',
    'ФГУП"ВНИИОФИ"',
    'ООО "ИСТОЧНИК"',
    'ООО "НИИ Энерготехнологий"',
    'ООО "Лотес ТМ"',
    'ООО "ЛазерСервис"',
    'ПАО АК "Рубин"',
    'ООО НПО " Горизонт"',
    'ООО "Сибаналитприбор"',
    'ЗАО "ЗЭТ"',
    'ЗАО "БИУС"',
    'ООО "Электропром"',
    'АО "Завод Кризо"',
    'ООО <НПП <ПАРК-ЦЕНТР>',
    'АО "МОРИНСИС-АГАТ-КИП"',
    'АО АНИТТ "РЕКОРД"',
    'АО АПЗ "РОТОР"',
    'ООО "Электроконнект" Санкт-Петербург',
    'АО "НПФ "Микран"',
    'АО "ДМЗ" им. Н.П. Федорова',
    'ООО "Николь"',
    'ОАО "Казанский завод "Электроприбор"',
    'ООО "Логические Системы"',
    'ООО "Вибратор"',
    'АО " Гирооптика"',
    'АО "НИИИТ-РК"',
    'АО " НИИАО"',
    'АО " Горизонт"',
    'АО "НИИ Проблем Автоматизации "Северэвмкомплекс"',
    'АО «РЗП»',
  ];

  @override
  void initState() {
    super.initState();
    _majorDateController.text = _todayFormatted();
    _platyDateController.text = _todayFormatted();
    _initApp();
    // Автообновление списка треков каждые 3 секунды
    _tracksWatcherTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadTracksFromDisk(silent: true),
    );
  }

  @override
  void dispose() {
    _tracksWatcherTimer?.cancel();
    super.dispose();
  }

  String _todayFormatted() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  Future<void> _initApp() async {
    await _checkSumatraPdf();
    await _loadFirmsFromDisk(isPlaty: false);
    await _loadFirmsFromDisk(isPlaty: true);
    await _loadTracksFromDisk(silent: true);
  }

  // На Windows работаем прямо из папки, где лежит .exe-файл
  Future<String> _getWorkDirPath() async {
    if (Platform.isWindows) {
      return File(Platform.resolvedExecutable).parent.path;
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  Future<void> _checkSumatraPdf() async {
    if (!Platform.isWindows) return;
    final workDir = await _getWorkDirPath();
    final found = File('$workDir\\SumatraPDF.exe').existsSync();
    setState(() => _sumatraFound = found);
  }

  Future<File> _getTracksFile() async {
    final dir = await _getWorkDirPath();
    return File('$dir${Platform.pathSeparator}tracks_today.txt');
  }

  Future<void> _loadTracksFromDisk({bool silent = false}) async {
    try {
      final file = await _getTracksFile();
      if (!file.existsSync()) {
        if (_trackLines.isNotEmpty) {
          setState(() => _trackLines = []);
        }
        return;
      }
      final lines = await file.readAsLines(encoding: utf8);
      final cleaned =
          lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (cleaned.length != _trackLines.length ||
          cleaned.join('\n') != _trackLines.join('\n')) {
        setState(() => _trackLines = cleaned);
      }
      if (!silent) {
        _showSnackbar('Список треков обновлён (${cleaned.length})');
      }
    } catch (_) {}
  }

  Future<void> _clearTracksFile() async {
    final file = await _getTracksFile();
    if (file.existsSync()) {
      await file.writeAsString('', encoding: utf8);
    }
    setState(() => _trackLines = []);
    _showSnackbar('Список треков очищен');
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackbar(message);
  }

  Future<File> _getFirmsFile({required bool isPlaty}) async {
    final dir = await _getWorkDirPath();
    final name = isPlaty ? 'platy_firms.txt' : 'electroconnect_firms.txt';
    final file = File('$dir${Platform.pathSeparator}$name');
    if (!file.existsSync()) {
      final defaults = isPlaty ? _defaultPlatyFirms : _defaultElectroFirms;
      await file.writeAsString(defaults.join('\n'), encoding: utf8);
    }
    return file;
  }

  Future<void> _loadFirmsFromDisk({required bool isPlaty}) async {
    try {
      final file = await _getFirmsFile(isPlaty: isPlaty);
      final lines = await file.readAsLines(encoding: utf8);
      final cleaned = lines
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        if (isPlaty) {
          _platyFirms = cleaned;
        } else {
          _electroFirms = cleaned;
        }
      });
    } catch (_) {}
  }

  Future<void> _addFirmToDictionary({
    required bool isPlaty,
    required String rawName,
  }) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      _showSnackbar('Сначала впиши название фирмы!');
      return;
    }
    final list = isPlaty ? _platyFirms : _electroFirms;
    if (!list.any((e) => e.toLowerCase() == name.toLowerCase())) {
      list.insert(0, name);
      final file = await _getFirmsFile(isPlaty: isPlaty);
      await file.writeAsString(list.join('\n'), encoding: utf8);
      setState(() {});
      _showSnackbar('«$name» добавлена в справочник!');
    } else {
      _showSnackbar('Эта компания уже есть в списке.');
    }
  }

  Future<void> _removeFirmFromDictionary({
    required bool isPlaty,
    required String firmName,
  }) async {
    final list = isPlaty ? _platyFirms : _electroFirms;
    list.remove(firmName);
    final file = await _getFirmsFile(isPlaty: isPlaty);
    await file.writeAsString(list.join('\n'), encoding: utf8);
    setState(() {});
  }

  Future<void> _openFirmsTxtInNotepad({required bool isPlaty}) async {
    final file = await _getFirmsFile(isPlaty: isPlaty);
    if (Platform.isWindows) {
      await Process.start('notepad.exe', [file.path]);
    } else {
      await OpenFilex.open(file.path);
    }
  }

  String _escapePy(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('\n', ' ');

  Future<void> _generateMajorExpressScript() async {
    final firm = _majorFirmController.text.trim();
    if (firm.isEmpty) {
      _showSnackbar('Укажи фирму-получателя!');
      return;
    }
    await _runMajorAutomation(
      isPlaty: false,
      login: 'Electroconnect',
      pass: 'Y2501212e4e5d62',
      firm: firm,
      date: _majorDateController.text.trim(),
      time: _majorTimeController.text.trim(),
      weight: _majorWeightController.text.trim(),
      places: _majorPlacesController.text.trim(),
      desc: _majorDescController.text.trim(),
      info: _majorInfoController.text.trim(),
    );
  }

  Future<void> _generatePlatyMajorExpressScript() async {
    final firm = _platyFirmController.text.trim();
    if (firm.isEmpty) {
      _showSnackbar('Укажи фирму-получателя!');
      return;
    }
    await _runMajorAutomation(
      isPlaty: true,
      login: 'Palat',
      pass: 'Z250121e9a7a762',
      firm: firm,
      date: _platyDateController.text.trim(),
      time: _platyTimeController.text.trim(),
      weight: _platyWeightController.text.trim(),
      places: _platyPlacesController.text.trim(),
      desc: _platyDescController.text.trim(),
      info: _platyInfoController.text.trim(),
    );
  }

  Future<void> _runMajorAutomation({
    required bool isPlaty,
    required String login,
    required String pass,
    required String firm,
    required String date,
    required String time,
    required String weight,
    required String places,
    required String desc,
    required String info,
  }) async {
    final workDir = await _getWorkDirPath();
    final prefix = isPlaty ? 'major_platy' : 'major_electro';
    final scriptPath = '$workDir${Platform.pathSeparator}${prefix}_auto.py';

    final pyCode = '''
# -*- coding: utf-8 -*-
import os
import re
import time
import subprocess
from playwright.sync_api import sync_playwright

LOGIN = '${_escapePy(login)}'
PASSWORD = '${_escapePy(pass)}'
FIRM_NAME = '${_escapePy(firm)}'
PICKUP_DATE = '${_escapePy(date)}'
PICKUP_TIME = '${_escapePy(time)}'
WEIGHT = '${_escapePy(weight)}'
PLACES = '${_escapePy(places)}'
DESCRIPTION = '${_escapePy(desc)}'
EXTRA_INFO = '${_escapePy(info)}'
WORK_DIR = r'$workDir'

def save_track_line(track_num):
    tracks_file = os.path.join(WORK_DIR, 'tracks_today.txt')
    line = f'{FIRM_NAME} {track_num}'.strip()
    try:
        with open(tracks_file, 'a', encoding='utf-8') as f:
            f.write(line + '\\n')
        print('Трек сохранён:', line)
    except Exception as e:
        print('Ошибка записи трека:', e)

def extract_track(suggested_filename, page_text):
    m = re.search(r'\\b(\\d{10})\\b', suggested_filename or '')
    if m:
        return m.group(1)
    m2 = re.search(r'\\b(20\\d{8})\\b', page_text or '')
    if m2:
        return m2.group(1)
    m3 = re.search(r'\\b(\\d{10})\\b', page_text or '')
    if m3:
        return m3.group(1)
    return 'БЕЗ_ТРЕКА'

def print_pdf_silent(pdf_path):
    sumatra_local = os.path.join(WORK_DIR, 'SumatraPDF.exe')
    sumatra_exe = sumatra_local if os.path.exists(sumatra_local) else 'SumatraPDF.exe'
    try:
        subprocess.run([sumatra_exe, '-print-to-default', '-silent', pdf_path], check=True)
        print('PDF отправлен на печать:', pdf_path)
    except Exception as e:
        print('Ошибка печати SumatraPDF:', e)

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(accept_downloads=True)
        page = context.new_page()
        page.goto('https://lk.major-express.ru/login.aspx?ReturnUrl=%2f', timeout=60000)

        page.locator('input[type="text"]').first.fill(LOGIN)
        page.locator('input[type="password"]').first.fill(PASSWORD)
        page.locator('input[type="submit"], button:has-text("Войти")').first.click()
        page.wait_for_load_state('networkidle')

        page.goto('https://lk.major-express.ru/Templates.aspx', timeout=60000)
        page.wait_for_timeout(1500)

        search_inputs = page.locator('input[type="text"]')
        if search_inputs.count() > 0:
            search_inputs.first.fill(FIRM_NAME)
            page.keyboard.press('Enter')
            page.wait_for_timeout(1500)

        create_btn = page.locator('a:has-text("Создать"), button:has-text("Создать")').first
        if create_btn.count() > 0:
            create_btn.click()
            page.wait_for_load_state('networkidle')
            page.wait_for_timeout(1200)

            inputs = page.locator('input[type="text"]')
            for idx in range(inputs.count()):
                el = inputs.nth(idx)
                name_attr = (el.get_attribute('name') or '').lower()
                id_attr = (el.get_attribute('id') or '').lower()
                if 'weight' in name_attr or 'weight' in id_attr or 'вес' in name_attr:
                    el.fill(WEIGHT)
                elif 'place' in name_attr or 'place' in id_attr or 'мест' in name_attr:
                    el.fill(PLACES)
                elif 'desc' in name_attr or 'cargo' in id_attr:
                    el.fill(DESCRIPTION)
                elif 'date' in name_attr or 'date' in id_attr:
                    el.fill(PICKUP_DATE)

            if EXTRA_INFO:
                areas = page.locator('textarea')
                if areas.count() > 0:
                    areas.first.fill(EXTRA_INFO)

        try:
            with page.expect_download(timeout=180000) as download_info:
                pass
            download = download_info.value
            suggested = download.suggested_filename or ''
            page_text = ''
            try:
                page_text = page.inner_text('body')
            except Exception:
                pass
            track_num = extract_track(suggested, page_text)
            save_track_line(track_num)

            pdf_target = os.path.join(WORK_DIR, f'major_{track_num}_{int(time.time())}.pdf')
            download.save_as(pdf_target)
            print_pdf_silent(pdf_target)
        except Exception:
            pass

        page.wait_for_timeout(15000)

if __name__ == '__main__':
    main()
''';

    await File(scriptPath).writeAsString(pyCode, encoding: utf8);

    if (Platform.isWindows) {
      try {
        await Process.start('python', [scriptPath], workingDirectory: workDir);
        _showSnackbar('Запущен робот Major Express для: $firm');
      } catch (e) {
        _showSnackbar('Скрипт сохранён: $scriptPath (ошибка python: $e)');
      }
    } else {
      await Share.shareXFiles([XFile(scriptPath)], text: 'Скрипт Major Express');
    }
  }

  void _showSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color get _cardBg => widget.isDark ? const Color(0xFF111827) : Colors.white;
  Color get _sidebarBg =>
      widget.isDark ? const Color(0xFF0D1320) : const Color(0xFFF8FAFC);
  Color get _borderCol =>
      widget.isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
  Color get _subtleText =>
      widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Widget _styledInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.5, color: _subtleText),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        filled: true,
        fillColor: widget.isDark
            ? const Color(0xFF182235)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderCol),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _selectedNav == 0
                      ? _buildMajorCourierWorkspace(isPlaty: false)
                      : (_selectedNav == 1
                          ? _buildMajorCourierWorkspace(isPlaty: true)
                          : _buildTracksTab()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final navItems = [
      (
        index: 0,
        title: 'Электроконнект',
        subtitle: 'Major Express',
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFFF59E0B),
      ),
      (
        index: 1,
        title: 'Печатные платы',
        subtitle: 'Major Express',
        icon: Icons.developer_board_rounded,
        color: const Color(0xFFA855F7),
      ),
      (
        index: 2,
        title: 'Треки (${_trackLines.length})',
        subtitle: 'Копировать фирмы и треки',
        icon: Icons.copy_all_rounded,
        color: const Color(0xFF10B981),
      ),
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _borderCol)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Major Express',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Выписка накладных',
                          style: TextStyle(fontSize: 11, color: _subtleText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _borderCol),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                children: navItems.map((item) {
                  final isSelected = _selectedNav == item.index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedNav = item.index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.color.withOpacity(0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? item.color.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              color: isSelected ? item.color : _subtleText,
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                      fontSize: 11, color: _subtleText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (Platform.isWindows)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: (_sumatraFound
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_sumatraFound
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B))
                          .withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sumatraFound
                            ? Icons.print_rounded
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: _sumatraFound
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _sumatraFound
                              ? 'Автопечать SumatraPDF готова'
                              : 'Нет SumatraPDF.exe',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _sumatraFound
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    const titles = [
      'Электроконнект — Major Express',
      'Печатные платы — Major Express',
      'Выписанные накладные (Фирма + Трек)',
    ];
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_selectedNav],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '● ONLINE • Windows',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildMajorCourierWorkspace({required bool isPlaty}) {
    final accent =
        isPlaty ? const Color(0xFFA855F7) : const Color(0xFFF59E0B);
    final firmCtrl = isPlaty ? _platyFirmController : _majorFirmController;
    final dateCtrl = isPlaty ? _platyDateController : _majorDateController;
    final timeCtrl = isPlaty ? _platyTimeController : _majorTimeController;
    final weightCtrl =
        isPlaty ? _platyWeightController : _majorWeightController;
    final placesCtrl =
        isPlaty ? _platyPlacesController : _majorPlacesController;
    final descCtrl = isPlaty ? _platyDescController : _majorDescController;
    final infoCtrl = isPlaty ? _platyInfoController : _majorInfoController;
    final searchCtrl =
        isPlaty ? _platyFirmSearchController : _majorFirmSearchController;
    final filter = isPlaty ? _platyFirmFilter : _majorFirmFilter;
    final fullList = isPlaty ? _platyFirms : _electroFirms;
    final filtered = filter.isEmpty
        ? fullList
        : fullList
            .where((f) => f.toLowerCase().contains(filter.toLowerCase()))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая часть — форма заказа
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPlaty
                                ? Icons.developer_board_rounded
                                : Icons.local_shipping_rounded,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPlaty
                                    ? 'ООО «Печатные платы» — Major Express'
                                    : 'ООО «ЭЛЕКТРОконнект» — Major Express',
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isPlaty
                                    ? 'Отправитель: ООО «Печатные платы» • Логин: Palat • Автопечать А4'
                                    : 'Отправитель: ООО «ЭЛЕКТРОконнект» Москва • Логин: Electroconnect • Автопечать А4',
                                style: TextStyle(
                                    fontSize: 11.5, color: _subtleText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _styledInputField(
                            controller: firmCtrl,
                            label: 'Фирма-получатель (выбери справа или впиши)',
                            icon: Icons.business_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.library_add_outlined, size: 18),
                          label: const Text('+ В базу'),
                          onPressed: () => _addFirmToDictionary(
                            isPlaty: isPlaty,
                            rawName: firmCtrl.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _styledInputField(
                            controller: dateCtrl,
                            label: 'Дата забора',
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _styledInputField(
                            controller: timeCtrl,
                            label: 'Интервал времени забора',
                            icon: Icons.access_time_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => dateCtrl.text = _todayFormatted()),
                          child: const Text('Сегодня'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => timeCtrl.text = '10:00-14:00'),
                          child: const Text('10:00-14:00'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => timeCtrl.text = '14:00-18:00'),
                          child: const Text('14:00-18:00'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _styledInputField(
                            controller: weightCtrl,
                            label: 'Вес, кг',
                            icon: Icons.scale_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _styledInputField(
                            controller: placesCtrl,
                            label: 'Кол-во мест',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _styledInputField(
                            controller: descCtrl,
                            label: 'Описание вложения',
                            icon: Icons.description_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _styledInputField(
                      controller: infoCtrl,
                      label: 'Информация для забора груза (примечание)',
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text(
                          'ОФОРМИТЬ И РАСПЕЧАТАТЬ НАКЛАДНУЮ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: isPlaty
                            ? _generatePlatyMajorExpressScript
                            : _generateMajorExpressScript,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Правая часть — Справочник получателей с поиском
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderCol),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_page_rounded, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Справочник получателей (${fullList.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        tooltip: 'Открыть файл базы в Блокноте',
                        onPressed: () =>
                            _openFirmsTxtInNotepad(isPlaty: isPlaty),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Обновить из файла',
                        onPressed: () =>
                            _loadFirmsFromDisk(isPlaty: isPlaty),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (val) => setState(() => isPlaty
                        ? _platyFirmFilter = val.trim()
                        : _majorFirmFilter = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Поиск компании (введи часть названия)...',
                      hintStyle: TextStyle(fontSize: 13, color: _subtleText),
                      prefixIcon: const Icon(Icons.search, size: 19),
                      suffixIcon: filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() => isPlaty
                                    ? _platyFirmFilter = ''
                                    : _majorFirmFilter = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: widget.isDark
                          ? const Color(0xFF182235)
                          : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _borderCol),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final name = filtered[idx];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 0),
                          leading: Icon(Icons.apartment_rounded,
                              size: 16, color: accent),
                          title: Text(name,
                              style: const TextStyle(fontSize: 13)),
                          onTap: () => setState(() => firmCtrl.text = name),
                          trailing: IconButton(
                            icon: Icon(Icons.close,
                                size: 14, color: _subtleText),
                            onPressed: () => _removeFirmFromDictionary(
                              isPlaty: isPlaty,
                              firmName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderCol),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Text(
                  'Выписанные накладные (${_trackLines.length})',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('КОПИРОВАТЬ ВСЁ'),
                  onPressed: _trackLines.isEmpty
                      ? null
                      : () => _copyText(
                            _trackLines.join('\n'),
                            'Скопированы все ${_trackLines.length} строк!',
                          ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Обновить из tracks_today.txt',
                  onPressed: () => _loadTracksFromDisk(silent: false),
                ),
                TextButton(
                  onPressed: _trackLines.isEmpty ? null : _clearTracksFile,
                  child: const Text('Очистить',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _trackLines.isEmpty
                  ? Center(
                      child: Text(
                        'После выписки накладных здесь автоматически появятся строки вида:\nООО "Галс плюс" 2071839662',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _subtleText, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _trackLines.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: _borderCol),
                      itemBuilder: (context, idx) {
                        final line = _trackLines[idx];
                        return ListTile(
                          title: SelectableText(
                            line,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Копировать строку',
                            onPressed: () =>
                                _copyText(line, 'Скопировано: $line'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
