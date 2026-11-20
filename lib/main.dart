
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const KhodroYar());

const navy = Color(0xFF101A2B);
const gold = Color(0xFFD7B16D);
const bg = Color(0xFFF3F5F9);
const muted = Color(0xFF8993A5);

class KhodroYar extends StatelessWidget {
  const KhodroYar({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'خودرویار',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int tab = 0;
  bool loading = true;

  final Map<String, List<Map<String, String>>> records = {
    'cars': [],
    'services': [],
    'shops': [],
    'expenses': [],
    'repairs': [],
    'insurance': [],
    'inspection': [],
  };

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('khodroyar_data');
    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      for (final key in records.keys) {
        final list = decoded[key] as List<dynamic>? ?? [];
        records[key] = list.map((e) =>
            Map<String, String>.from(e as Map)).toList();
      }
    }
    setState(() => loading = false);
  }

  Future<void> saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('khodroyar_data', jsonEncode(records));
    setState(() {});
  }

  Future<void> addRecord(
      String key, String title, List<String> fields) async {
    final controllers =
        fields.map((e) => TextEditingController()).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(fields.length, (i) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: fields[i],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ذخیره اطلاعات'),
          ),
        ],
      ),
    );

    if (result == true) {
      final item = <String, String>{};
      for (int i = 0; i < fields.length; i++) {
        item[fields[i]] = controllers[i].text.trim();
      }
      records[key]!.add(item);
      await saveRecords();
    }

    for (final c in controllers) {
      c.dispose();
    }
  }

  Future<void> deleteRecord(String key, int index) async {
    records[key]!.removeAt(index);
    await saveRecords();
  }

  Widget sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: navy,
          )),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(
              color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget premiumHeader() {
    final cars = records['cars']!;
    final carName = cars.isEmpty
        ? 'خودروی خود را ثبت کنید'
        : cars.last.values.firstWhere(
            (v) => v.isNotEmpty,
            orElse: () => 'خودروی من',
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF263B59), navy, Color(0xFF0A1423)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gold.withOpacity(.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.directions_car,
                    color: gold, size: 25),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('خودرویار',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    )),
                  Text('مدیریت هوشمند خودروی شما',
                    style: TextStyle(
                      color: Colors.white60, fontSize: 11)),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => tab = 2),
                icon: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 27),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text('خودروی منتخب شما',
            style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 7),
          Text(carName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            )),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.09),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: gold, size: 25),
                SizedBox(width: 10),
                Expanded(
                  child: Text('همه اطلاعات خودروی شما در یک مکان',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                Icon(Icons.arrow_back_ios_new,
                    color: gold, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 13),
          Text(value, style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: navy,
          )),
          Text(title, style: const TextStyle(
            fontSize: 11, color: muted)),
        ],
      ),
    );
  }

  Widget actionTile(String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: gold.withOpacity(.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: navy, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: navy,
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(
                    fontSize: 10, color: muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: muted),
          ],
        ),
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        premiumHeader(),
        Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle('نمای کلی', subtitle: 'خلاصه وضعیت خودرویار'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                childAspectRatio: 1.3,
                children: [
                  statCard('خودروهای من',
                      '${records['cars']!.length}',
                      Icons.directions_car, const Color(0xFF426DAB)),
                  statCard('سرویس‌ها',
                      '${records['services']!.length}',
                      Icons.build_circle, const Color(0xFF209A80)),
                  statCard('هزینه‌ها',
                      '${records['expenses']!.length}',
                      Icons.account_balance_wallet,
                      const Color(0xFFD49A38)),
                  statCard('فروشگاه‌ها',
                      '${records['shops']!.length}',
                      Icons.store, const Color(0xFF8064B5)),
                ],
              ),
              const SizedBox(height: 17),
              sectionTitle('دسترسی سریع',
                  subtitle: 'امکانات پرکاربرد خودرو'),
              actionTile('افزودن خودروی جدید',
                  'مدیریت خودروهای شخصی',
                  Icons.add_circle_outline,
                  () => setState(() => tab = 1)),
              const SizedBox(height: 9),
              actionTile('ثبت سرویس جدید',
                  'تعویض روغن و نگهداری خودرو',
                  Icons.build_outlined,
                  () => setState(() => tab = 2)),
              const SizedBox(height: 9),
              actionTile('فروشگاه‌های خودرو',
                  'ثبت اطلاعات فروشگاه‌ها',
                  Icons.storefront_outlined,
                  () => setState(() => tab = 3)),
              const SizedBox(height: 9),
              actionTile('هزینه و مدارک خودرو',
                  'هزینه‌ها، تعمیرات و بیمه',
                  Icons.folder_open_outlined,
                  () => setState(() => tab = 4)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium,
                        color: gold, size: 34),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('خودرویار',
                            style: TextStyle(
                              color: gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            )),
                          SizedBox(height: 4),
                          Text('همراه مطمئن نگهداری خودرو',
                            style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget recordsPage(String key, String title,
      IconData icon, List<String> fields) {
    final list = records[key]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: gold, size: 35),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    )),
                    const Text('مدیریت اطلاعات و سوابق',
                      style: TextStyle(
                        color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              Text('${list.length}',
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                )),
            ],
          ),
        ),
        const SizedBox(height: 17),
        FilledButton.icon(
          onPressed: () => addRecord(key, 'افزودن $title', fields),
          icon: const Icon(Icons.add),
          label: const Text('ثبت مورد جدید'),
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            padding: const EdgeInsets.all(15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 45, color: muted),
                SizedBox(height: 10),
                Text('هنوز اطلاعاتی ثبت نشده است',
                    style: TextStyle(color: muted)),
              ],
            ),
          ),
        ...List.generate(list.length, (index) {
          final item = list[index];
          final summary = item.entries
              .where((e) => e.value.isNotEmpty)
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: gold.withOpacity(.17),
                child: Icon(icon, color: navy),
              ),
              title: Text(
                item.values.firstWhere(
                  (v) => v.isNotEmpty,
                  orElse: () => title,
                ),
                style: const TextStyle(
                  color: navy, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                summary.isEmpty ? 'بدون توضیحات' : summary,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red),
                onPressed: () => deleteRecord(key, index),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget filePage() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: navy,
            child: const TabBar(
              isScrollable: true,
              labelColor: gold,
              unselectedLabelColor: Colors.white70,
              indicatorColor: gold,
              tabs: [
                Tab(text: 'هزینه‌ها'),
                Tab(text: 'تعمیرات'),
                Tab(text: 'بیمه'),
                Tab(text: 'معاینه فنی'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                recordsPage('expenses', 'هزینه‌ها',
                    Icons.payments,
                    ['عنوان هزینه', 'مبلغ (تومان)', 'تاریخ', 'توضیحات']),
                recordsPage('repairs', 'سوابق تعمیرات',
                    Icons.handyman,
                    ['عنوان تعمیر', 'تاریخ', 'هزینه', 'توضیحات']),
                recordsPage('insurance', 'بیمه خودرو',
                    Icons.security,
                    ['نوع بیمه', 'شرکت بیمه',
                     'تاریخ شروع', 'تاریخ پایان']),
                recordsPage('inspection', 'معاینه فنی',
                    Icons.fact_check,
                    ['تاریخ انجام', 'تاریخ انقضا',
                     'مرکز معاینه', 'توضیحات']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget currentPage() {
    switch (tab) {
      case 0:
        return homePage();
      case 1:
        return recordsPage('cars', 'خودروهای من',
            Icons.directions_car,
            ['نام خودرو', 'مدل', 'سال ساخت',
             'شماره پلاک', 'کارکرد فعلی']);
      case 2:
        return recordsPage('services', 'یادآوری سرویس',
            Icons.build,
            ['عنوان سرویس', 'نام خودرو',
             'تاریخ سررسید', 'کیلومتر سررسید', 'توضیحات']);
      case 3:
        return recordsPage('shops', 'فروشگاه‌ها',
            Icons.store,
            ['نام فروشگاه', 'نوع خدمات', 'شماره تماس', 'آدرس']);
      default:
        return filePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: currentPage(),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: gold.withOpacity(.2),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: navy),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car, color: navy),
            label: 'خودروها',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build, color: navy),
            label: 'سرویس',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: navy),
            label: 'فروشگاه',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: navy),
            label: 'پرونده',
          ),
        ],
      ),
    );
  }
}
