
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KhodroYarApp());
}

class KhodroYarApp extends StatelessWidget {
  const KhodroYarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'خودرویار',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final carController = TextEditingController();
  final currentController = TextEditingController();
  final intervalController = TextEditingController();
  final lastServiceController = TextEditingController();

  int remaining = 0;
  bool saved = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      carController.text = prefs.getString('car') ?? '';
      currentController.text = prefs.getString('current') ?? '';
      intervalController.text = prefs.getString('interval') ?? '5000';
      lastServiceController.text = prefs.getString('last') ?? '0';
      calculate();
    });
  }

  void calculate() {
    final current = int.tryParse(currentController.text) ?? 0;
    final interval = int.tryParse(intervalController.text) ?? 5000;
    final last = int.tryParse(lastServiceController.text) ?? 0;
    remaining = interval - (current - last);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('car', carController.text);
    await prefs.setString('current', currentController.text);
    await prefs.setString('interval', intervalController.text);
    await prefs.setString('last', lastServiceController.text);

    setState(() {
      calculate();
      saved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اطلاعات با موفقیت ذخیره شد')),
    );
  }

  Future<void> registerService() async {
    lastServiceController.text = currentController.text;
    await saveData();
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (_) {
          setState(() {
            calculate();
            saved = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    carController.dispose();
    currentController.dispose();
    intervalController.dispose();
    lastServiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool due = remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خودرویار 🚗',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'یادآور هوشمند سرویس خودرو',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            inputField('نام خودرو', carController, hint: 'مثلاً پژو ۲۰۶'),
            inputField('کارکرد فعلی خودرو (کیلومتر)', currentController),
            inputField('فاصله تعویض روغن (کیلومتر)', intervalController),
            inputField('کیلومتر آخرین تعویض روغن', lastServiceController),
            const SizedBox(height: 10),
            Card(
              color: due ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'وضعیت سرویس بعدی',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      due
                          ? 'زمان تعویض روغن رسیده است!'
                          : '$remaining کیلومتر تا تعویض روغن',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: due ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: saveData,
              icon: const Icon(Icons.save),
              label: const Text('ذخیره اطلاعات خودرو'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: registerService,
              icon: const Icon(Icons.check_circle),
              label: const Text('ثبت انجام تعویض روغن'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'خودرویار | همراه نگهداری خودروی شما',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
