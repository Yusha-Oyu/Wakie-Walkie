import 'package:flutter/material.dart';
import 'alarm_page.dart';
import 'home_page.dart';
import 'alarm_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmNotifications.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wakie Walkie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),

      initialRoute: '/',
      
      routes: {
        '/': (_) => const HomePage(),
      },
      onGenerateRoute: (settings){
        final name = settings.name ?? '' ;
        if(name.startsWith('/alarm')){
          final Uri uri= Uri.parse(name); //uri used to represent a route with extra data
          final alarmIDStr = uri.queryParameters['id'];
          final alarmId = int.tryParse(alarmIDStr ?? '');

          return MaterialPageRoute(
          builder: (_)=>AlarmPage(triggeredAlarmId: alarmId,),
          settings:settings,
          );
        }

          return MaterialPageRoute(
            settings:settings,
            builder: (_)=> const HomePage(),
          );
        },
    
         
      
      
    );
  }
}