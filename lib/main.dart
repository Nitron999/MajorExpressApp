import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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

class MajorLogEntry {
  final String company;
  final String firm;
  final String details;
  final String time;

  MajorLogEntry({
    required this.company,
    required this.firm,
    required this.details,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'firm': firm,
        'details': details,
        'time': time,
      };

  factory MajorLogEntry.fromJson(Map<String, dynamic> json) => MajorLogEntry(
        company: json['company']?.toString() ?? '',
        firm: json['firm']?.toString() ?? '',
        details: json['details']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
      );
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
  // 0 = Электроконнект, 1 = Печатные платы, 2 = Журнал
  int _selectedTab = 0;
  bool _sumatraFound = false;

  // Электроконнект
  final TextEditingController _majorFirmController = TextEditingController();
  final TextEditingController _majorDateController = TextEditingController();
  final TextEditingController _majorTimeController =
      TextEditingController(text: '10:00-14:00');
  final TextEditingController _majorWeightController =
      TextEditingController(text: '1');
  final TextEditingController _majorPlacesController =
      TextEditingController(text: '1');
  final TextEditingController _majorDescController =
      TextEditingController(text: 'Документы');
  final TextEditingController _majorInfoController = TextEditingController();
  final TextEditingController _majorFirmSearchController =
      TextEditingController();
  String _majorFirmFilter = '';
  List<String> _electroFirms = [];
  String _lastMajorAction = 'Готов к оформлению';

  // Печатные платы
  final TextEditingController _platyFirmController = TextEditingController();
  final TextEditingController _platyDateController = TextEditingController();
  final TextEditingController _platyTimeController =
      TextEditingController(text: '10:00-14:00');
  final TextEditingController _platyWeightController =
      TextEditingController(text: '1');
  final TextEditingController _platyPlacesController =
      TextEditingController(text: '1');
  final TextEditingController _platyDescController =
      TextEditingController(text: 'Платы');
  final TextEditingController _platyInfoController = TextEditingController();
  final TextEditingController _platyFirmSearchController =
      TextEditingController();
  String _platyFirmFilter = '';
  List<String> _platyFirms = [];
  String _lastPlatyAction = 'Готов к оформлению';

  List<MajorLogEntry> _logs = [];

  static const List<String> _defaultElectroFirms = [
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
    'ООО "ДИСТАНЦИЯ"',
    'АО "Мостком"',
    'ООО "АТС Т"',
    'ООО "ПЛ ИНЖИНИРИНГ"',
    'АНО " Школа 21"',
    'ООО "АЙСИЭЛ ЭЛЕКТРОНИКС"',
    'ООО "КОМПАНИЯ "СТРИМ ЛАБС"',
    'ООО "Дельта Солюшнс"',
    'Упак-Лайнер',
    'ООО "Олл ин пром"',
    'АО "Научно-производственное "Рязаньприбор"',
    'АО"ГЗАС им Попова"',
    'ООО "Корд-группа"',
    'ООО "МИР-СПОРТ-ЦЕНТР"',
    'ЗАО "Сетевые Технологии"',
    'ООО Лигель',
    'ООО «АВТОМАТИКА плюс»',
    'Гидравлические Комплексные Системы',
    'ООО "РТЦ"',
    'АО "ИНФОРМТЕХНИКА И СВЯЗЬ"',
    'ООО "НПО "ОРИГИНАЛЬНЫЕ РУССКИЕ КОНТРОЛЛЕРЫ"',
    'ООО "Деко-сервис"',
    'АО "НПО "Радиозавод им. А.С.Попова"',
    'АО "Электромеханика"',
    'ООО "РЭСТОК"',
    'ООО "МикроЭМ Технологии"',
    'ООО "Декаст"',
    'ООО "Технологии Света"',
    'АО ПФ "ЭЛВИРА"',
    'ООО "Комито"',
    'ООО "НПО "Вольт инжиниринг"',
    'ООО "Ревотех"',
    'ООО "Орион-Р"',
    'ООО "Трансаммиак"',
    'ООО "Промприбор-Р"',
    'ООО "Галсплюс"',
    'ООО НПО "Грань"',
    'ООО "ТИОН"',
    'АО "РНТ"',
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
    'АО НПЦ "ЭЛВИС"',
    'ООО "Дантекс Рус"',
    'ООО "САУК"',
    'ООО "НТР"',
    'АО "Микрон"',
    'АО "ЭЗАН"',
    'АО НПП "Пульсар"',
    'АО "Плазма"',
  ];

  static const List<String> _defaultPlatyFirms = [
    '18 ЦНИИ МО РФ МГУП',
    'OOO "АПС"',
    'Агарков Алексей Сергеевич',
    'Антон Киструга',
    'АО " Гирооптика"',
    'АО " Горизонт"',
    'АО " НИИАО"',
    'АО "766 УПТК"',
    'АО "АВЭКС"',
    'АО "АЛМАЗ"',
    'АО "Бета ир"',
    'АО "Вибратор"',
    'АО "ГНПП "Регион"',
    'АО "ДМЗ" им. Н.П. Федорова',
    'АО "Завод Кризо"',
    'АО "ЗАВОД" ЭЛЕКТРОМАШ"',
    'АО "КБТочмаш им. А.Э. Нудельмана"',
    'АО "КИПЗ"',
    'АО "КОБРА"',
    'АО "Концерн Вега"',
    'АО "Корпарация "Внииэм"',
    'АО "Корпорация "ВНИИЭМ"',
    'АО "Корпорация "Фазотрон-НИИР"',
    'АО "Красный гидропресс"',
    'АО "КЭТЗ"',
    'АО "МОРИНСИС-АГАТ-КИП"',
    'АО "МПОТК"Технокомплект"',
    'АО "НАНОТРОНИКА"',
    'АО "НИИ "КУЛОН"',
    'АО "НИИ "Октава"',
    'АО "НИИ "Полюс" им.М.Ф.Стельм',
    'АО "НИИ "ЭЛПА"',
    'АО "НИИ КП"',
    'АО "НИИ Проблем Автоматизации "Северэвмкомплекс"',
    'АО "НИИИ',
    'АО "НИИИТ-Опытный завод"',
    'АО "НИИИТ-РК"',
    'АО "НИИМЭ"',
    'АО "НИИПП"',
    'АО "НИИЭМ"',
    'АО "НПК "СПП"',
    'АО "НПО "КИС"',
    'АО "НПО "ОРИОН"',
    'АО "НПО "РусБИТех"',
    'АО "НПО "РЯЗАНЬПРИБОР"',
    'АО "НПП "КРАСНОЗНАМЁНЕЦ"',
    'АО "НПП "Пульсар"',
    'АО "НПП" РЕАКОНТ"',
    'АО "НПП"Геофизика-Космос',
    'АО "НПФ "Микран"',
    'АО "НПЦ" "АСПЕКТ"',
    'АО "НТП "АВИАТЕСТ"',
    'АО "НЦ ПЭ"',
    'АО "Обуховское"',
    'АО "ОДК"',
    'АО "ОКБ МЭИ"',
    'АО "Плазма"',
    'АО "ПО "СЕВЕР"',
    'АО "ПО "СЕВЕР" Михеев',
    'АО "Радиозавод"',
    'АО "РПЗ"',
    'АО "Рязанский радиозавод"',
    'АО "Серпуховский Завод "Металлист"',
    'АО "СПС"',
    'АО "СУП"',
    'АО "ТехПромИмпорт"',
    'АО "Трансмаш"',
    'АО "Уральские Заводы"',
    'АО "ЦНИИ "Буревестник"',
    'АО "ЦНИИ "Волна"',
    'АО "Цнииаг"',
    'АО "ЦНИТИ "Техномаш"',
    'АО "ЭВРИКА"',
    'АО "ЭЗАН"',
    'АО "ЭПМ"',
    'АО "ЭРА Марин"',
    'АО «ЗАВОД «ФИОЛЕНТ»',
    'АО «НИИ НПО «ЛУЧ»',
    'АО «РДТ-Темп»',
    'АО «РЗП»',
    'АО АНИТТ "РЕКОРД"',
    'АО АПЗ "РОТОР"',
    'АО ВП "ЭРА"',
    'АО Корпорация "ВНИИЭМ"',
    'АО МТЗ ТРАНСМАШ',
    'АО МТЗ ТРАНСМАШ ИМ. А.А. ЕГОРЕНКОВА',
    'АО НИИПП',
    'АО НИЦ "РЕЗОНАНС"',
    'АО НПП ЦИФРОВЫЕ РЕШЕНИЯ',
    'АО"ГЗАС им Попова"',
    'АО"КЗТМ"',
    'Беленькая Татьяна Ивановна',
    'Блохина Ирина Валерьевна',
    'Валентин Дерябкин',
    'Валерий Белоусов',
    'Владимир Бузовский',
    'ГАЗ-СИСТЕМА-СЕРВИС АО НПФ',
    'Гетман Максим',
    'Жиляев Александр Владимирович',
    'ЗАО "БИУС"',
    'ЗАО "ЗЭТ"',
    'ЗАО "КоМЭНС"',
    'ЗАО "Полимерфильтр"',
    'ЗАО "ЭРАСИБ"',
    'ЗАО НПП "Система"',
    'ЗАО НПЦ ФИРМА "НЕЛК"',
    'ИКИ РАН',
    'ИП Артемьев Евгений Александрович',
    'ИПМТ ДВО РАН',
    'Калугаприбор',
    'Ленар Гимадиев',
    'Максимов Алексей',
    'МОКБ "Марс"',
    'НП ЗАО "РЭКО-ВЕК"',
    'ОАО "Егоршинский радиозавод"',
    'ОАО "Завод Электросигнал"',
    'ОАО "Казанский завод "Электроприбор"',
    'ОАО "НПП КП "Квант"',
    'ОАО "ПЯТИГОРСКИЙ ЗАВОД "ИМПУЛЬС"',
    'Ольга',
    'ООО "Арматех"',
    'ООО "Беспилотные Системы"',
    'ООО "БОРЕЙ"',
    'ООО "Вибратор"',
    'ООО "ГЕТМОБИТ"',
    'ООО "ДЖИ-ТЭК"',
    'ООО "Джусто"',
    'ООО "ИНДЖЕР"',
    'ООО "ИНИТЕЛ"',
    'ООО "ИСТОЧНИК"',
    'ООО "КИНОТЕАТРАЛЬНЫЕ ТЕХНОЛОГИИ"',
    'ООО "Компания "Объединенная энергия"',
    'ООО "ЛазерСервис"',
    'ООО "ЛОГИС"',
    'ООО "Логические Системы"',
    'ООО "Лотес ТМ"',
    'ООО "МГ-СЕРВИС"',
    'ООО "Наутилус"',
    'ООО "Нейрософт"',
    'ООО "НИИ Энерготехнологий"',
    'ООО "Николь"',
    'ООО "НИЦ СЭ И НК"',
    'ООО "НТП "Энергоконтроль"',
    'ООО "НЭК"',
    'ООО "ОПТИМАЛЬНАЯ ФАБРИКА"',
    'ООО "ПК" АЛЛЕГРИ"',
    'ООО "ПКФ ПОЛЁТ"',
    'ООО "ПЛАЗ"',
    'ООО "Рембаза"',
    'ООО "РТС-БИТ"',
    'ООО "РТСОФТ-ВС"',
    'ООО "Сибаналитприбор"',
    'ООО "Сигналатомприбор"',
    'ООО "СМТ ФЛЕКС"',
    'ООО "СТС"',
    'ООО "Тир Строй Монтаж"',
    'ООО "ТПС"',
    'ООО "ТЭНСНАБ"',
    'ООО "УРАРТУ"',
    'ООО "Фабметалл"',
    'ООО "ФИНКО"',
    'ООО "Электроконнект"',
    'ООО "Электроконнект" Санкт-Петербург',
    'ООО "Электропром"',
    'ООО <НПП <ПАРК-ЦЕНТР>',
    'ООО «ЛЭМЗ-Т»',
    'ООО НПО " Горизонт"',
    'ООО НПП "ЭЛЕКТРОМАШ"',
    'ООО НППГА"ЛУЧ"',
    'ООО"КТЦ КЭБ"',
    'ООО"РАДАРАВИАСЕРВИС"',
    'ООО«Печатные платы»',
    'ОП "НИИ АЭМ ТУСУР"',
    'Павел Титов',
    'ПАО "НПО "Алмаз"',
    'ПАО "НПП "Импульс"',
    'ПАО "РЕАТОН"',
    'ПАО "Яковлев"',
    'ПАО АК "Рубин"',
    'ПАО НПО "Наука"',
    'ПАО ПЗ "Сигнал"',
    'ПАО"ГЗАС им Попова"',
    'ПАО"Саратовский электроприборостроительный з-д им.',
    'Поляков Олег',
    'Приходько Сергей Викторович',
    'РусБитех',
    'Самарский университет',
    'Симакина Екатерина Михайловна',
    'Синвайтес Инжиниринг',
    'Сколковский институт науки и технологий Сколтех',
    'Соколов Павел Андреевич',
    'Стас',
    'Степанова Марина',
    'Сумин Евгений',
    'Сушецкий Велес',
    'Татьяна',
    'Тепляков Пётр',
    'Терёхина Галина Александровна',
    'Толстова Татьяна',
    'УФК М.О (ИБП РАН)',
    'Ф+ тек Берсенева Ксения',
    'ФГБОУ ВО "ВГУ"',
    'ФГБУ ФНЦ ВНИИФК',
    'ФГКУ В/Ч "45187"',
    'ФГУП "ВНИИФТРИ"',
    'ФГУП "Крыловский государственный научный центр"',
    'ФГУП "НАМИ"',
    'ФГУП"ВНИИА"',
    'Филиал ИФП СО РАН "КТИПМ"',
    'Черникова Ольга',
    'ЧТУП "Печатные платы"',
    'ЮРГПУ (НПИ)',
    'ЮФУ, ЮФУ ЮЖНЫЙ ФЕДЕРАЛЬНЫЙ УНИВЕРСИТЕТ, ФГАОУ ВО',
  ];

  @override
  void initState() {
    super.initState();
    _majorDateController.text = _todayFormatted();
    _platyDateController.text = _todayFormatted();
    _initApp();
  }

  String _todayFormatted() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final logsRaw = prefs.getString('major_operation_logs');
    if (logsRaw != null) {
      setState(() {
        _logs = (jsonDecode(logsRaw) as List)
            .map((e) => MajorLogEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    }
    await _checkSumatraPdf();
    await _loadFirmsFromDisk(isPlaty: false);
    await _loadFirmsFromDisk(isPlaty: true);
  }

  Future<String> _getWorkDirPath() async {
    if (Platform.isWindows) {
      const customPath = r'C:\PechatnyePlaty';
      final dir = Directory(customPath);
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (_) {}
      }
      if (dir.existsSync()) return customPath;
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  Future<void> _checkSumatraPdf() async {
    if (!Platform.isWindows) return;
    final workDir = await _getWorkDirPath();
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final found = File('$workDir\\SumatraPDF.exe').existsSync() ||
        File('$exeDir\\SumatraPDF.exe').existsSync();
    setState(() => _sumatraFound = found);
  }

  Future<void> _addLog(String company, String firm, String details) async {
    final now = DateTime.now();
    final timeStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _logs.insert(
        0,
        MajorLogEntry(
          company: company,
          firm: firm,
          details: details,
          time: timeStr,
        ),
      );
      if (_logs.length > 100) {
        _logs = _logs.sublist(0, 100);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'major_operation_logs',
      jsonEncode(_logs.map((e) => e.toJson()).toList()),
    );
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
            with page.expect_download(timeout=120000) as download_info:
                pass
            download = download_info.value
            pdf_target = os.path.join(WORK_DIR, f'major_{int(time.time())}.pdf')
            download.save_as(pdf_target)
            print_pdf_silent(pdf_target)
        except Exception:
            pass

        page.wait_for_timeout(15000)

if __name__ == '__main__':
    main()
''';

    await File(scriptPath).writeAsString(pyCode, encoding: utf8);

    setState(() {
      if (isPlaty) {
        _lastPlatyAction = 'Оформлено: $firm';
      } else {
        _lastMajorAction = 'Оформлено: $firm';
      }
    });

    await _addLog(
      isPlaty ? 'Печатные платы' : 'Электроконнект',
      firm,
      'Дата: $date ($time), Вес: $weight кг, Мест: $places',
    );

    if (Platform.isWindows) {
      try {
        await Process.start('python', [scriptPath], workingDirectory: workDir);
        _showSnackbar('Запущен робот Major Express для: $firm');
      } catch (e) {
        _showSnackbar('Скрипт сохранён: $scriptPath (ошибка python: $e)');
      }
    } else {
      await Share.shareXFiles([XFile(path: scriptPath)], text: 'Скрипт Major Express');
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
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (
        title: 'Электроконнект',
        subtitle: _lastMajorAction,
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFFF59E0B),
      ),
      (
        title: 'Печатные платы',
        subtitle: _lastPlatyAction,
        icon: Icons.developer_board_rounded,
        color: const Color(0xFFA855F7),
      ),
      (
        title: 'Журнал (${_logs.length})',
        subtitle: 'История выписок',
        icon: Icons.history_rounded,
        color: const Color(0xFF10B981),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Major Express — Выписка накладных'),
        actions: [
          if (Platform.isWindows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    _sumatraFound
                        ? Icons.print_rounded
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: _sumatraFound
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sumatraFound ? 'SumatraPDF OK' : 'Нет SumatraPDF',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: List.generate(tabs.length, (idx) {
                final t = tabs[idx];
                final active = _selectedTab == idx;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedTab = idx),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: active ? t.color.withOpacity(0.16) : _cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? t.color : _borderCol,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(t.icon, color: t.color, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    t.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _subtleText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildMajorCourierWorkspace(isPlaty: false)
                : (_selectedTab == 1
                    ? _buildMajorCourierWorkspace(isPlaty: true)
                    : _buildLogsTab()),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
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
                    Text(
                      isPlaty
                          ? 'ООО «Печатные платы» — Major Express'
                          : 'ООО «ЭЛЕКТРОконнект» — Major Express',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _styledInputField(
                            controller: firmCtrl,
                            label: 'Фирма-получатель',
                            icon: Icons.business_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('В базу'),
                          onPressed: () => _addFirmToDictionary(
                            isPlaty: isPlaty,
                            rawName: firmCtrl.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                            label: 'Интервал времени',
                            icon: Icons.access_time_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                            label: 'Мест',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _styledInputField(
                            controller: descCtrl,
                            label: 'Описание',
                            icon: Icons.description_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _styledInputField(
                      controller: infoCtrl,
                      label: 'Примечание для курьера',
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text(
                          'ОФОРМИТЬ И РАСПЕЧАТАТЬ НАКЛАДНУЮ',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
          const SizedBox(width: 16),
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
                      Expanded(
                        child: Text(
                          'Справочник (${fullList.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded),
                        tooltip: 'Открыть в Блокноте',
                        onPressed: () =>
                            _openFirmsTxtInNotepad(isPlaty: isPlaty),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Обновить из файла',
                        onPressed: () =>
                            _loadFirmsFromDisk(isPlaty: isPlaty),
                      ),
                    ],
                  ),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (val) => setState(() => isPlaty
                        ? _platyFirmFilter = val.trim()
                        : _majorFirmFilter = val.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Поиск фирмы...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final name = filtered[idx];
                        return ListTile(
                          dense: true,
                          title: Text(name, style: const TextStyle(fontSize: 13)),
                          onTap: () => setState(() => firmCtrl.text = name),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 14),
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

  Widget _buildLogsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                const Text(
                  'Журнал выписок Major Express',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    setState(() => _logs.clear());
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('major_operation_logs');
                  },
                  child: const Text(
                    'Очистить',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'Выписок пока не было',
                        style: TextStyle(color: _subtleText),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: _borderCol),
                      itemBuilder: (context, idx) {
                        final item = _logs[idx];
                        return ListTile(
                          title: Text(
                            '[${item.company}] ${item.firm} (${item.time})',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.details,
                            style: const TextStyle(fontSize: 12),
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
