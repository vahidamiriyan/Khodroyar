
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KhodroYar());
}

const navy = Color(0xFF101D32);
const gold = Color(0xFFD6AE62);
const bg = Color(0xFFF4F5F8);

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: gold,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
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
    String key,
    String title,
    List<String> fields,
  ) async {
    final controllers = fields.map((e) => TextEditingController()).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(fields.length, (i) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: fields[i],
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ذخیره'),
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

  Widget luxuryHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navy, Color(0xFF263D5C)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: gold, fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(
            color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget statCard(String title, String count, IconData icon) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: gold, size: 28),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.bold, color: navy)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget homePage() {
    final totalCars = records['cars']!.length;
    final totalServices = records['services']!.length;
    final totalExpenses = records['expenses']!.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        luxuryHeader(
          'خودرویار',
          'مدیریت هوشمند خودرو، سرویس و هزینه‌ها',
        ),
        const SizedBox(height: 18),
        const Text('داشبورد مدیریتی', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.45,
          children: [
            statCard('خودروهای من', '$totalCars', Icons.directions_car),
            statCard('سرویس‌های ثبت‌شده', '$totalServices',
                Icons.build_circle),
            statCard('هزینه‌های ثبت‌شده', '$totalExpenses',
                Icons.account_balance_wallet),
            statCard('فروشگاه‌ها', '${records['shops']!.length}',
                Icons.store),
          ],
        ),
        const SizedBox(height: 16),
        const Text('دسترسی سریع', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        quickButton('ثبت خودروی جدید', Icons.add_circle, 1),
        quickButton('ثبت سرویس خودرو', Icons.build, 2),
        quickButton('ثبت هزینه جدید', Icons.receipt_long, 4),
        quickButton('پرونده بیمه و معاینه فنی', Icons.description, 4),
        const SizedBox(height: 16),
        luxuryHeader('همراه مطمئن شما', 'تمام اطلاعات خودرو در یک برنامه'),
      ],
    );
  }

  Widget quickButton(String title, IconData icon, int destination) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: gold),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => setState(() => tab = destination),
      ),
    );
  }

  Widget recordsPage(
    String key,
    String title,
    IconData icon,
    List<String> fields,
  ) {
    final list = records[key]!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        luxuryHeader(title, 'مدیریت و ثبت اطلاعات در خودرویار'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => addRecord(key, 'افزودن $title', fields),
          icon: const Icon(Icons.add),
          label: Text('افزودن مورد جدید'),
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            padding: const EdgeInsets.all(15),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: Text('هنوز اطلاعاتی ثبت نشده است')),
            ),
          ),
        ...List.generate(list.length, (index) {
          final item = list[index];
          final summary = item.entries
              .where((e) => e.value.isNotEmpty)
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');

          return Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: navy,
                child: Icon(icon, color: gold),
              ),
              title: Text(
                item.values.firstWhere(
                  (v) => v.isNotEmpty,
                  orElse: () => title,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(summary.isEmpty ? 'بدون توضیحات' : summary),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                recordsPage('expenses', 'هزینه‌ها', Icons.payments,
                    ['عنوان هزینه', 'مبلغ (تومان)', 'تاریخ', 'توضیحات']),
                recordsPage('repairs', 'سوابق تعمیرات', Icons.handyman,
                    ['عنوان تعمیر', 'تاریخ', 'هزینه', 'توضیحات']),
                recordsPage('insurance', 'بیمه خودرو', Icons.security,
                    ['نوع بیمه', 'شرکت بیمه', 'تاریخ شروع', 'تاریخ پایان']),
                recordsPage('inspection', 'معاینه فنی',
                    Icons.fact_check,
                    ['تاریخ انجام', 'تاریخ انقضا', 'مرکز معاینه', 'توضیحات']),
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
            ['نام خودرو', 'مدل', 'سال ساخت', 'شماره پلاک', 'کارکرد فعلی']);
      case 2:
        return recordsPage('services', 'یادآوری سرویس',
            Icons.build,
            ['عنوان سرویس', 'نام خودرو', 'تاریخ سررسید',
             'کیلومتر سررسید', 'توضیحات']);
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
      appBar: AppBar(
        title: const Text('خودرویار | مدیریت خودرو'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('یادآوری خودکار هنوز فعال نشده است'),
                ),
              );
            },
          ),
        ],
      ),
      body: currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: gold.withValues(alpha: 0.2),
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'خودروها',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'سرویس',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'فروشگاه',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'پرونده',
          ),
        ],
      ),
    );
  }
}
