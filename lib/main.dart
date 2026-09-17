import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';
import 'services/push_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Push init — bloklamaydi (Firebase sozlanmagan bo'lsa jimgina o'chiq).
  StorePushService.instance.init();
  runApp(const OnlineStoreApp());
}

class OnlineStoreApp extends StatelessWidget {
  const OnlineStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Zootopiya",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
        scaffoldBackgroundColor: kBg,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          surfaceTintColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText),
          iconTheme: IconThemeData(color: kAccent),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
