import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhodroyarApp());
}

class KhodroyarApp extends StatelessWidget {
  const KhodroyarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'خودرویار',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC247), brightness: Brightness.dark,
        surface: const Color(0xFF14243B)),
      scaffoldBackgroundColor: const Color(0xFF071426),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF071426), foregroundColor: Colors.white,
        elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(color: const Color(0xFF14243B), elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF31445F)))),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: const Color(0xFF0D1D32),
        indicatorColor: const Color(0xFF5B451C), labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFFFC247),
        foregroundColor: Color(0xFF172238)),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true,
        fillColor: const Color(0xFF1B2D46), labelStyle: const TextStyle(color: Colors.white70)),
      textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    ),
    home: const AppHome(),
  );
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
    width:size,height:size,
    decoration:BoxDecoration(
      shape:BoxShape.circle,
      gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:[Color(0xFFFFE29A),Color(0xFFD99A2B),Color(0xFF8D5B16)]),
      boxShadow:[BoxShadow(color:const Color(0xFFFFC247).withOpacity(.22),blurRadius:12)]),
    child:Stack(alignment:Alignment.center,children:[
      Icon(Icons.speed_rounded,size:size*.78,color:const Color(0xFF172238)),
      Positioned(bottom:size*.12,child:Icon(Icons.directions_car_filled_rounded,
        size:size*.38,color:const Color(0xFF172238))),
    ]),
  );
}

class Vehicle {
  String id, name, plate, vin;
  int odometer;
  Vehicle({required this.id, required this.name, required this.plate,
    required this.vin, required this.odometer});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'plate':plate,'vin':vin,'odometer':odometer};
  factory Vehicle.fromJson(Map<String,dynamic> j)=>Vehicle(
    id:j['id']??'', name:j['name']??'', plate:j['plate']??'',
    vin:j['vin']??'', odometer:j['odometer']??0);
}

class ServiceItem {
  String id, vehicleId, title, note;
  int odometer, intervalKm;
  DateTime date;
  DateTime? nextDate;
  ServiceItem({required this.id,required this.vehicleId,required this.title,
    required this.note,required this.odometer,required this.intervalKm,
    required this.date,this.nextDate});
  Map<String,dynamic> toJson()=>{'id':id,'vehicleId':vehicleId,'title':title,
    'note':note,'odometer':odometer,'intervalKm':intervalKm,
    'date':date.toIso8601String(),'nextDate':nextDate?.toIso8601String()};
  factory ServiceItem.fromJson(Map<String,dynamic> j)=>ServiceItem(
    id:j['id']??'',vehicleId:j['vehicleId']??'',title:j['title']??'',
    note:j['note']??'',odometer:j['odometer']??0,intervalKm:j['intervalKm']??0,
    date:DateTime.tryParse(j['date']??'')??DateTime.now(),
    nextDate:j['nextDate']==null?null:DateTime.tryParse(j['nextDate']));
}

class Shop {
  String id,name,phone,city;
  Shop({required this.id,required this.name,required this.phone,required this.city});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'phone':phone,'city':city};
  factory Shop.fromJson(Map<String,dynamic> j)=>Shop(
    id:j['id']??'',name:j['name']??'',phone:j['phone']??'',city:j['city']??'');
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});
  @override State<AppHome> createState()=>_AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int tab=0;
  bool businessMode=false, loading=true;
  List<Vehicle> vehicles=[];
  List<ServiceItem> services=[];
  List<Shop> shops=[];
  String activeShopId='shop-default';
  final categories=['تعویض روغن موتور','فیلتر روغن','فیلتر هوا','فیلتر کابین',
    'فیلتر سوخت','لنت ترمز','تسمه تایم','باتری','شمع موتور','بازدید فنی'];
  Shop get activeShop => shops.firstWhere((s)=>s.id==activeShopId,
    orElse:()=>Shop(id:'shop-default',name:'فروشگاه نمونه',phone:'',city:''));
  @override void initState(){super.initState();loadData();}

  Future<void> loadData() async {
    final p=await SharedPreferences.getInstance();
    try {
      vehicles=(jsonDecode(p.getString('ky_vehicles')??'[]') as List)
        .map((e)=>Vehicle.fromJson(e)).toList();
      services=(jsonDecode(p.getString('ky_services')??'[]') as List)
        .map((e)=>ServiceItem.fromJson(e)).toList();
      shops=(jsonDecode(p.getString('ky_shops')??'[]') as List)
        .map((e)=>Shop.fromJson(e)).toList();
    } catch (_) { vehicles=[]; services=[]; shops=[]; }
    if(shops.isEmpty) shops=[Shop(id:'shop-default',name:'فروشگاه نمونه',phone:'',city:'')];
    activeShopId=p.getString('ky_active_shop')??shops.first.id;
    if(!shops.any((s)=>s.id==activeShopId)) activeShopId=shops.first.id;
    if(mounted)setState(()=>loading=false);
  }

  Future<void> saveData() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('ky_vehicles',jsonEncode(vehicles.map((e)=>e.toJson()).toList()));
    await p.setString('ky_services',jsonEncode(services.map((e)=>e.toJson()).toList()));
    await p.setString('ky_shops',jsonEncode(shops.map((e)=>e.toJson()).toList()));
    await p.setString('ky_active_shop',activeShopId);
  }

  String uid()=>DateTime.now().microsecondsSinceEpoch.toString();
  Vehicle? vehicleById(String id){for(final v in vehicles){if(v.id==id)return v;}return null;}
  int dueCount(Vehicle v)=>services.where((s)=>s.vehicleId==v.id &&
    ((s.intervalKm>0 && s.odometer+s.intervalKm<=v.odometer) ||
     (s.nextDate!=null && !s.nextDate!.isAfter(DateTime.now())))).length;

  Future<void> addVehicle() async {
    final name=TextEditingController(), plate=TextEditingController(),
      vin=TextEditingController(), km=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('ثبت خودروی جدید'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        field(name,'برند و مدل خودرو'),field(plate,'شماره پلاک'),
        field(vin,'شماره شاسی (اختیاری)'),field(km,'کیلومتر فعلی',numeric:true)])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('انصراف')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ثبت خودرو'))]));
    if(ok==true && name.text.trim().isNotEmpty){
      setState(()=>vehicles.add(Vehicle(id:uid(),name:name.text.trim(),plate:plate.text.trim(),
        vin:vin.text.trim(),odometer:int.tryParse(km.text)??0)));
      await saveData();
    }
  }

  Future<void> updateOdometer(Vehicle v) async {
    final c=TextEditingController(text:v.odometer.toString());
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:Text('به‌روزرسانی کیلومتر ${v.name}'),
      content:field(c,'کیلومتر فعلی',numeric:true),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('لغو')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('ذخیره'))]));
    if(ok==true){final n=int.tryParse(c.text);if(n!=null && n>=v.odometer){
      setState(()=>v.odometer=n);await saveData();
    } else if(mounted){ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content:Text('کیلومتر جدید باید بیشتر یا مساوی مقدار قبلی باشد.')));}}
  }

  Future<void> addService() async {
    if(vehicles.isEmpty){await addVehicle();return;}
    String vehicleId=vehicles.first.id, title=categories.first;
    final km=TextEditingController(text:vehicles.first.odometer.toString());
    final interval=TextEditingController(text:'5000');
    final note=TextEditingController();
    DateTime? nextDate;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(
      builder:(ctx,dialogSet)=>AlertDialog(
        title:const Text('ثبت سرویس انجام‌شده'),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          DropdownButtonFormField<String>(value:vehicleId,decoration:const InputDecoration(labelText:'خودرو'),
            items:vehicles.map((v)=>DropdownMenuItem(value:v.id,child:Text(v.name))).toList(),
            onChanged:(x){if(x!=null)dialogSet(()=>vehicleId=x);}),
          const SizedBox(height:10),
          DropdownButtonFormField<String>(value:title,decoration:const InputDecoration(labelText:'نوع سرویس'),
            items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:(x){if(x!=null)dialogSet(()=>title=x);}),
          const SizedBox(height:10),field(km,'کیلومتر هنگام سرویس',numeric:true),
          field(interval,'فاصله پیشنهادی بعدی (کیلومتر)',numeric:true),
          field(note,'توضیحات / برند قطعه'),
          OutlinedButton.icon(onPressed:()async{
            final d=await showDatePicker(context:ctx,firstDate:DateTime.now(),
              lastDate:DateTime.now().add(const Duration(days:1500)),initialDate:DateTime.now().add(const Duration(days:180)));
            if(d!=null)dialogSet(()=>nextDate=d);
          },icon:const Icon(Icons.event),label:Text(nextDate==null?'تاریخ یادآوری (اختیاری)':'یادآوری: ${nextDate!.year}/${nextDate!.month}/${nextDate!.day}'))
        ])),
        actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('انصراف')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('ذخیره سرویس'))])));
    if(ok==true){
      final v=vehicleById(vehicleId);final value=int.tryParse(km.text)??v?.odometer??0;
      setState(()=>services.insert(0,ServiceItem(id:uid(),vehicleId:vehicleId,title:title,
        note:note.text.trim(),odometer:value,intervalKm:int.tryParse(interval.text)??0,
        date:DateTime.now(),nextDate:nextDate)));
      if(v!=null && value>v.odometer)v.odometer=value;
      await saveData();
    }
  }

  Future<void> addShop() async {
    final name=TextEditingController(),phone=TextEditingController(),city=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('افزودن فروشگاه همکار'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        field(name,'نام فروشگاه'),field(phone,'شماره تماس'),field(city,'شهر')]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('لغو')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('ثبت فروشگاه'))]));
    if(ok==true && name.text.trim().isNotEmpty){
      final s=Shop(id:uid(),name:name.text.trim(),phone:phone.text.trim(),city:city.text.trim());
      setState(()=>shops.add(s));await saveData();
    }
  }

  Widget field(TextEditingController c,String label,{bool numeric=false})=>Padding(
    padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,
      keyboardType:numeric?TextInputType.number:TextInputType.text,
      decoration:InputDecoration(labelText:label)));
  Widget metric(String title,String value,IconData icon)=>Card(child:Padding(
    padding:const EdgeInsets.all(14),child:Column(mainAxisAlignment:MainAxisAlignment.center,
      children:[Icon(icon,color:const Color(0xFFFFC247),size:27),
        const SizedBox(height:8),Text(value,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:22)),
        Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:12))])));

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final pages=[dashboard(),vehiclePage(),historyPage(),businessPage()];
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(
        title:Row(children:[const BrandMark(size:38),
          const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
            Text(businessMode?'خودرویار | ${activeShop.name}':'خودرویار',
              style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18,color:Color(0xFFFFD477))),
            const Text('همراه هوشمند نگهداری خودرو',style:TextStyle(fontSize:10,color:Colors.white60))])]),
        actions:[IconButton(onPressed:()=>setState(()=>businessMode=!businessMode),
          tooltip:'تغییر حالت مشتری / فروشگاه',icon:Icon(businessMode?Icons.person:Icons.storefront))]),
      body:pages[tab],
      floatingActionButton:(tab==1||tab==2)?FloatingActionButton.extended(
        onPressed:tab==1?addVehicle:addService,icon:const Icon(Icons.add),
        label:Text(tab==1?'افزودن خودرو':'ثبت سرویس')):null,
      bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),
        destinations:const[
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'خانه'),
          NavigationDestination(icon:Icon(Icons.directions_car_outlined),label:'خودروها'),
          NavigationDestination(icon:Icon(Icons.history),label:'سوابق'),
          NavigationDestination(icon:Icon(Icons.storefront_outlined),label:'فروشگاه‌ها')]),
    ));
  }

  Widget dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(
      gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,
        colors:[Color(0xFF203A5B),Color(0xFF0D1A2D),Color(0xFF17243A)]),
      borderRadius:BorderRadius.circular(26),border:Border.all(color:const Color(0xFFB88935),width:1.2),
      boxShadow:[BoxShadow(color:const Color(0xFFFFC247).withOpacity(.10),blurRadius:24)]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Row(children:[BrandMark(size:62),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('خودرویار',style:TextStyle(color:Color(0xFFFFD477),fontSize:27,fontWeight:FontWeight.w900)),
          Text('KHODROYAR  •  SMART CAR CARE',style:TextStyle(color:Colors.white60,fontSize:9,letterSpacing:1.1))]))]),
        const SizedBox(height:18),
        const Text('همیشه یک قدم جلوتر از سرویس بعدی',style:TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),Text('${vehicles.length} خودروی ثبت‌شده',style:const TextStyle(color:Color(0xFFFFD477),fontWeight:FontWeight.w700)),
        const SizedBox(height:14),const Text('همراه هوشمند نگهداری و مدیریت خودروی شما',style:TextStyle(color:Colors.white70))])),
    const SizedBox(height:16),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
      crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.45,children:[
        metric('خودروها','${vehicles.length}',Icons.directions_car),
        metric('سوابق سرویس','${services.length}',Icons.build_circle),
        metric('موارد سررسید','${vehicles.fold<int>(0,(a,v)=>a+dueCount(v))}',Icons.notifications_active),
        metric('فروشگاه همکار','${shops.length}',Icons.storefront),
      ]),
    const SizedBox(height:10),const Text('وضعیت سرویس خودروها',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    if(vehicles.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('برای شروع، خودروی خود را ثبت کنید.'))),
    ...vehicles.map((v){
      final last=services.where((s)=>s.vehicleId==v.id).toList();
      last.sort((a,b)=>b.date.compareTo(a.date));
      final latestOil=last.where((s)=>s.title=='تعویض روغن موتور').firstOrNull;
      final remaining=latestOil==null||latestOil.intervalKm==0?null:
        (latestOil.odometer+latestOil.intervalKm-v.odometer);
      return Card(child:ListTile(leading:const CircleAvatar(backgroundColor:Color(0xFF31445F),child:Icon(Icons.directions_car,color:Color(0xFFFFC247))),
        title:Text(v.name),subtitle:Text('کیلومتر فعلی: ${v.odometer}\n${remaining==null?'برای محاسبه، سرویس روغن را ثبت کنید':remaining<=0?'موعد تعویض روغن رسیده است':'$remaining کیلومتر تا تعویض روغن'}'),
        isThreeLine:true,trailing:Icon(remaining!=null&&remaining<=0?Icons.warning_amber:Icons.chevron_left,
          color:remaining!=null&&remaining<=0?Colors.red:null)));
    }),
    const SizedBox(height:8),const Text('یادآوری‌ها بر پایه آخرین سرویس ثبت‌شده و کیلومتر به‌روزشده محاسبه می‌شوند.',
      style:TextStyle(fontSize:12,color:Colors.white60))
  ]);

  Widget vehiclePage()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('خودروهای من',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
    const SizedBox(height:10),
    if(vehicles.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('هنوز خودرویی ثبت نشده است.'))),
    ...vehicles.map((v)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
      ListTile(leading:const Icon(Icons.directions_car,size:32),title:Text(v.name),
        subtitle:Text('پلاک: ${v.plate.isEmpty?'ثبت نشده':v.plate}\nشماره شاسی: ${v.vin.isEmpty?'ثبت نشده':v.vin}')),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text('کیلومتر: ${v.odometer}',style:const TextStyle(fontWeight:FontWeight.w600)),
        TextButton.icon(onPressed:()=>updateOdometer(v),icon:const Icon(Icons.edit),
          label:const Text('به‌روزرسانی کیلومتر'))])
    ])))),
  ]);

  Widget historyPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('تاریخچه سرویس‌ها',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
    const SizedBox(height:10),
    if(services.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('هنوز سرویسی ثبت نشده است.'))),
    ...services.map((s){final v=vehicleById(s.vehicleId);return Card(child:ListTile(
      leading:const CircleAvatar(child:Icon(Icons.build)),
      title:Text(s.title),subtitle:Text('${v?.name??'خودروی حذف‌شده'} • ${s.odometer} کیلومتر\n${s.note.isEmpty?'بدون توضیحات':s.note}\nفاصله بعدی: ${s.intervalKm>0?'${s.intervalKm} کیلومتر':'تعریف نشده'}'),
      isThreeLine:true,trailing:Text('${s.date.day}/${s.date.month}/${s.date.year}')));})
  ]);

  Widget businessPage()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('پنل فروشگاه‌های همکار',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
    const SizedBox(height:6),const Text('هر فروشگاه پروفایل مستقل خود را دارد. در این نسخه اطلاعات محلی است؛ اتصال حساب‌ها به سرور در مرحله استقرار انجام می‌شود.'),
    const SizedBox(height:14),
    Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('فروشگاه فعال',style:TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      DropdownButtonFormField<String>(value:activeShopId,decoration:const InputDecoration(labelText:'انتخاب فروشگاه'),
        items:shops.map((s)=>DropdownMenuItem(value:s.id,child:Text(s.name))).toList(),
        onChanged:(x)async{if(x!=null){setState(()=>activeShopId=x);await saveData();}}),
      const SizedBox(height:8),Text('شهر: ${activeShop.city.isEmpty?'ثبت نشده':activeShop.city}'),
      Text('تلفن: ${activeShop.phone.isEmpty?'ثبت نشده':activeShop.phone}')
    ]))),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
      crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.4,children:[
        metric('تعداد خودروها','${vehicles.length}',Icons.directions_car),
        metric('تعداد سرویس‌ها','${services.length}',Icons.receipt_long),
        metric('فروشگاه‌ها','${shops.length}',Icons.store),
        metric('سرویس‌های سررسید','${vehicles.fold<int>(0,(a,v)=>a+dueCount(v))}',Icons.notifications),
      ]),
    FilledButton.icon(onPressed:addShop,icon:const Icon(Icons.add_business),label:const Text('افزودن فروشگاه همکار')),
    const SizedBox(height:12),
    const Card(child:Padding(padding:EdgeInsets.all(14),child:Text(
      'نکته فنی: جداسازی چندفروشگاهی در این نمونه در سطح پروفایل‌های محلی نمایش داده شده است. برای استفاده واقعی چندفروشگاهی، احراز هویت، پایگاه داده ابری، سطح دسترسی کاربران و API امن باید راه‌اندازی شود.',
      style:TextStyle(fontSize:12,color:Colors.white60))))
  ]);
}
