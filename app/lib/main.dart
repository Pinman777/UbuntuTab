import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ubuntutab/theme/droid_theme.dart';
import 'package:ubuntutab/state/app_state.dart';
import 'package:ubuntutab/services/platform_bridge.dart';
import 'package:ubuntutab/screens/welcome_screen.dart';
import 'package:ubuntutab/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UbuntuTabPlatform.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const UbuntuTabApp(),
    ),
  );
}

class UbuntuTabApp extends StatefulWidget {
  const UbuntuTabApp({super.key});

  @override
  State<UbuntuTabApp> createState() => _UbuntuTabAppState();
}

class _UbuntuTabAppState extends State<UbuntuTabApp> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    // Initialize platform bridge and load state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return MaterialApp(
      title: 'UbuntuTab',
      debugShowCheckedModeBanner: false,
      theme: DroidTheme.lightThemeData,
      darkTheme: DroidTheme.darkThemeData,
      themeMode: state.themeMode,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: state.isSetupComplete ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
