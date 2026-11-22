
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhodroYarApp());
}

const navy = Color(0xFF101B35);
const navyLight = Color(0xFF263B63);
const gold = Color(0xFFD6AD60);
const bg = Color(0xFFF3F5F9);
const white = Colors.white;

class KhodroYarApp extends StatelessWidget {
  const KhodroYarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'خودرویار',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: gold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// مدل خودرو
class Vehicle {
  String name, model, plate, km;

  Vehicle(this.name, this.model, this.plate, this.km);

  Map<String, dynamic> toJson() => {
    'name': name,
    'model': model,
    'plate': plate,
    'km': km,
  };

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
    j['name'] ?? '',
    j['model'] ?? '',
    j['plate'] ?? '',
    j['km'] ?? '0',
  );
}

// مدل سوابق و هزینه‌ها
class Entry {
  String title, detail, date, amount, type;

  Entry(this.title, this.detail, this.date, this.amount, this.type);

  Map<String, dynamic> toJson() => {
    'title': title,
    'detail': detail,
    'date': date,
    'amount': amount,
    'type': type,
  };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
    j['title'] ?? '',
    j['detail'] ?? '',
    j['date'] ?? '',
    j['amount'] ?? '',
    j['type'] ?? 'سرویس',
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  int selectedVehicle = 0;

  List<Vehicle> vehicles = [];
  List<Entry> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    final vs = p.getString('vehicles_v1');
    final es = p.getString('entries_v1');

    if (!mounted) return;

    setState(() {
      vehicles = vs == null
          ? [
              Vehicle(
                'خودروی من',
                'سمند',
                'ایران ۱۲ - ۳۴۵ ب ۶۷',
                '۱۲۵۰۰۰',
              )
            ]
          : (jsonDecode(vs) as List)
              .map((e) => Vehicle.fromJson(e))
              .toList();

      entries = es == null
          ? [
              Entry(
                'تعویض روغن موتور',
                'یادآوری سرویس بعدی در ۱۳۰٬۰۰۰ کیلومتر',
                '۱۴۰۵/۰۹/۱۵',
                '۱٬۸۰۰٬۰۰۰',
                'یادآور',
              ),
              Entry(
                'بیمه شخص ثالث',
                'تاریخ تمدید را بررسی کنید',
                '۱۴۰۵/۱۰/۲۰',
                '۰',
                'مدارک',
              ),
            ]
          : (jsonDecode(es) as List)
              .map((e) => Entry.fromJson(e))
              .toList();

      loading = false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      'vehicles_v1',
      jsonEncode(vehicles.map((e) => e.toJson()).toList()),
    );

    await p.setString(
      'entries_v1',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Vehicle? get current {
    if (vehicles.isEmpty) return null;
    final index = selectedVehicle.clamp(0, vehicles.length - 1).toInt();
    return vehicles[index];
  }

  Future<void> _addVehicle() async {
    final result = await showDialog<Vehicle>(
      context: context,
      builder: (c) => const VehicleDialog(),
    );

    if (result != null) {
      setState(() {
        vehicles.add(result);
        selectedVehicle = vehicles.length - 1;
      });
      await _save();
    }
  }

  Future<void> _addEntry() async {
    final result = await showDialog<Entry>(
      context: context,
      builder: (c) => const EntryDialog(),
    );

    if (result != null) {
      setState(() => entries.insert(0, result));
      await _save();
    }
  }

  Future<void> _deleteVehicle(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف خودرو'),
        content: const Text('آیا از حذف این خودرو مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      vehicles.removeAt(index);

      if (vehicles.isEmpty) {
        selectedVehicle = 0;
      } else if (selectedVehicle >= vehicles.length) {
        selectedVehicle = vehicles.length - 1;
      }
    });

    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: gold),
        ),
      );
    }

    final pages = [
      _dashboard(),
      _vehiclesPage(),
      _recordsPage(),
      _documentsPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/khodroyar_logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خودرویار',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'همراه هوشمند نگهداری خودرو',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showAbout,
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: IndexedStack(
          index: tab,
          children: pages,
        ),
        floatingActionButton: tab == 2
            ? FloatingActionButton.extended(
                onPressed: _addEntry,
                backgroundColor: gold,
                foregroundColor: navy,
                icon: const Icon(Icons.add),
                label: const Text('ثبت مورد جدید'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          backgroundColor: white,
          indicatorColor: gold.withOpacity(.25),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_car),
              label: 'خودروها',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long),
              label: 'سوابق',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              label: 'مدارک',
            ),
          ],
        ),
      ),
    );
  }

  // داشبورد اصلی
  Widget _dashboard() {
    final v = current;

    final total = entries
        .where((e) => e.type == 'هزینه')
        .fold<int>(
          0,
          (sum, e) => sum +
              (int.tryParse(
                    e.amount.replaceAll(',', '').replaceAll('٬', ''),
                  ) ??
                  0),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Center(
          child: Image.asset(
            'assets/khodroyar_logo.png',
            height: 125,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),

        // کارت خودرو
        Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, navyLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: navy.withOpacity(.20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'خودروی انتخاب‌شده',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'مدیریت خودرو',
                      style: TextStyle(color: gold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                v?.name ?? 'هنوز خودرویی ثبت نشده',
                style: const TextStyle(
                  color: white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                v == null ? 'برای شروع خودرو اضافه کنید' : '${v.model}  •  ${v.plate}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Icon(Icons.speed, color: gold, size: 21),
                  const SizedBox(width: 8),
                  Text(
                    '${v?.km ?? '۰'} کیلومتر کارکرد',
                    style: const TextStyle(
                      color: white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (vehicles.length > 1)
                    DropdownButton<int>(
                      value: selectedVehicle,
                      dropdownColor: navy,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: gold,
                      ),
                      items: List.generate(
                        vehicles.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            vehicles[i].name,
                            style: const TextStyle(color: white),
                          ),
                        ),
                      ),
                      onChanged: (i) {
                        if (i != null) {
                          setState(() => selectedVehicle = i);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 19),
        _sectionTitle('خلاصه وضعیت'),
        const SizedBox(height: 11),

        Row(
          children: [
            Expanded(
              child: _statCard(
                'تعداد خودروها',
                '${vehicles.length}',
                Icons.directions_car,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'تعداد سوابق',
                '${entries.length}',
                Icons.history,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _statCard(
          'مجموع هزینه‌های ثبت‌شده',
          '${_money(total)} تومان',
          Icons.payments_outlined,
          wide: true,
        ),

        const SizedBox(height: 23),
        _sectionTitle('دسترسی سریع'),
        const SizedBox(height: 11),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: 1.8,
          children: [
            _quick(
              'افزودن خودرو',
              Icons.add_circle_outline,
              _addVehicle,
            ),
            _quick(
              'ثبت هزینه یا سرویس',
              Icons.edit_note,
              _addEntry,
            ),
            _quick(
              'مشاهده سوابق',
              Icons.history,
              () => setState(() => tab = 2),
            ),
            _quick(
              'مدارک خودرو',
              Icons.folder_open,
              () => setState(() => tab = 3),
            ),
          ],
        ),

        const SizedBox(height: 23),
        _sectionTitle('آخرین فعالیت‌ها'),
        const SizedBox(height: 11),

        if (entries.isEmpty)
          _empty('هنوز موردی ثبت نشده است')
        else
          ...entries.take(3).map(_entryTile),

        const SizedBox(height: 20),
        const Center(
          child: Text(
            'خودرویار  •  مدیریت هوشمند خودرو',
            style: TextStyle(
              color: Colors.black38,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // صفحه خودروها
  Widget _vehiclesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _pageHeading(
          'خودروهای من',
          'تمام خودروهای خود را در یک مکان مدیریت کنید',
        ),
        const SizedBox(height: 16),

        if (vehicles.isEmpty)
          _empty('هنوز خودرویی ثبت نکرده‌اید'),

        ...vehicles.asMap().entries.map((e) {
          final selected = e.key == selectedVehicle;

          return Card(
            elevation: 0,
            color: white,
            margin: const EdgeInsets.only(bottom: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
              side: BorderSide(
                color: selected ? gold : Colors.transparent,
                width: 1.3,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: gold.withOpacity(.20),
                child: const Icon(
                  Icons.directions_car,
                  color: navy,
                ),
              ),
              title: Text(
                e.value.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${e.value.model}\nپلاک: ${e.value.plate}\nکارکرد: ${e.value.km} کیلومتر',
                  style: const TextStyle(height: 1.7),
                ),
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (x) {
                  if (x == 'select') {
                    setState(() {
                      selectedVehicle = e.key;
                      tab = 0;
                    });
                  }

                  if (x == 'delete') {
                    _deleteVehicle(e.key);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'select',
                    child: Text('انتخاب خودرو'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف خودرو'),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _addVehicle,
          icon: const Icon(Icons.add),
          label: const Text('افزودن خودروی جدید'),
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            padding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }

  // صفحه سوابق
  Widget _recordsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _pageHeading(
          'سوابق و هزینه‌ها',
          'سرویس‌ها، تعمیرات و مخارج خودرو',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _statCard(
                'تعداد ثبت‌ها',
                '${entries.length}',
                Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'هزینه‌ها',
                '${entries.where((e) => e.type == 'هزینه').length}',
                Icons.payments,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (entries.isEmpty)
          _empty('هنوز سابقه‌ای ثبت نشده است')
        else
          ...entries.map(_entryTile),

        const SizedBox(height: 85),
      ],
    );
  }

  // صفحه مدارک
  Widget _documentsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _pageHeading(
          'مدارک و یادآورها',
          'مدارک مهم خودرو را فراموش نکنید',
        ),
        const SizedBox(height: 17),

        _documentCard(
          'بیمه شخص ثالث',
          'ثبت تاریخ انقضا و یادآوری تمدید بیمه',
          Icons.shield_outlined,
        ),
        _documentCard(
          'بیمه بدنه',
          'پیگیری اعتبار بیمه بدنه خودرو',
          Icons.verified_user_outlined,
        ),
        _documentCard(
          'معاینه فنی',
          'پیگیری زمان اعتبار معاینه فنی',
          Icons.verified_outlined,
        ),
        _documentCard(
          'گواهی و مدارک خودرو',
          'نگهداری اطلاعات مدارک و تاریخ‌های مهم',
          Icons.folder_outlined,
        ),
        _documentCard(
          'گواهینامه رانندگی',
          'یادآوری زمان تمدید گواهینامه',
          Icons.badge_outlined,
        ),

        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: gold.withOpacity(.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'برای ثبت تاریخ یا هزینه مربوط به مدارک، از بخش سوابق گزینه ثبت مورد جدید را انتخاب کنید.',
            style: TextStyle(
              color: navy,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentCard(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      color: white,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: gold.withOpacity(.20),
          child: Icon(icon, color: navy),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.chevron_left,
          color: navy,
        ),
      ),
    );
  }

  // کارت هر سابقه
  Widget _entryTile(Entry e) {
    IconData icon;

    if (e.type == 'هزینه') {
      icon = Icons.payments_outlined;
    } else if (e.type == 'یادآور') {
      icon = Icons.notifications_active_outlined;
    } else if (e.type == 'مدارک') {
      icon = Icons.folder_outlined;
    } else if (e.type == 'تعمیرات') {
      icon = Icons.build_outlined;
    } else {
      icon = Icons.car_repair;
    }

    return Card(
      elevation: 0,
      color: white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(13),
        leading: CircleAvatar(
          backgroundColor: gold.withOpacity(.20),
          child: Icon(icon, color: navy),
        ),
        title: Text(
          e.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${e.detail}\n${e.date}  •  ${e.type}',
            style: const TextStyle(height: 1.7),
          ),
        ),
        isThreeLine: true,
        trailing: e.amount == '0'
            ? null
            : Text(
                '${e.amount}\nتومان',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
      ),
    );
  }

  // کارت آمار
  Widget _statCard(
    String title,
    String value,
    IconData icon, {
    bool wide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: gold.withOpacity(.20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: navy),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w900,
                    fontSize: wide ? 15 : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دسترسی سریع
  Widget _quick(
    String title,
    IconData icon,
    VoidCallback action,
  ) {
    return Material(
      color: white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: navy.withOpacity(.04)),
          ),
          child: Row(
            children: [
              Icon(icon, color: gold, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) {
    return Text(
      s,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: navy,
      ),
    );
  }

  Widget _pageHeading(String a, String b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          b,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _empty(String s) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Center(
        child: Text(
          s,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  String _money(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'خودرویار',
      applicationVersion: 'نسخه ۲.۰',
      children: const [
        Text(
          'همراه هوشمند مدیریت خودرو، سرویس‌ها، هزینه‌ها و مدارک.',
        ),
      ],
    );
  }
}

// فرم افزودن خودرو
class VehicleDialog extends StatefulWidget {
  const VehicleDialog({super.key});

  @override
  State<VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<VehicleDialog> {
  final name = TextEditingController();
  final model = TextEditingController();
  final plate = TextEditingController();
  final km = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    model.dispose();
    plate.dispose();
    km.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('افزودن خودرو'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'نام خودرو',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: model,
                decoration: const InputDecoration(
                  labelText: 'مدل خودرو',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: plate,
                decoration: const InputDecoration(
                  labelText: 'شماره پلاک',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: km,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'کارکرد فعلی (کیلومتر)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;

              Navigator.pop(
                context,
                Vehicle(
                  name.text.trim(),
                  model.text.trim(),
                  plate.text.trim(),
                  km.text.trim().isEmpty ? '0' : km.text.trim(),
                ),
              );
            },
            child: const Text('ذخیره خودرو'),
          ),
        ],
      ),
    );
  }
}

// فرم ثبت سابقه
class EntryDialog extends StatefulWidget {
  const EntryDialog({super.key});

  @override
  State<EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<EntryDialog> {
  final title = TextEditingController();
  final detail = TextEditingController();
  final date = TextEditingController();
  final amount = TextEditingController();

  String type = 'سرویس';

  @override
  void dispose() {
    title.dispose();
    detail.dispose();
    date.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ثبت سابقه جدید'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: 'نوع ثبت',
                ),
                items: const [
                  'سرویس',
                  'تعمیرات',
                  'هزینه',
                  'یادآور',
                  'مدارک',
                ].map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => type = v ?? 'سرویس');
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'عنوان',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detail,
                decoration: const InputDecoration(
                  labelText: 'توضیحات',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: date,
                decoration: const InputDecoration(
                  labelText: 'تاریخ (مثلاً ۱۴۰۵/۰۹/۲۲)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ به تومان (اختیاری)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;

              Navigator.pop(
                context,
                Entry(
                  title.text.trim(),
                  detail.text.trim(),
                  date.text.trim().isEmpty ? '—' : date.text.trim(),
                  amount.text.trim().isEmpty ? '0' : amount.text.trim(),
                  type,
                ),
              );
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}
