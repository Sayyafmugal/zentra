import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:zentra_0/Controllers/theme_controller.dart';
import 'package:zentra_0/Utils/app_themes.dart';
import 'package:zentra_0/bindings/initial_binding.dart';
import 'package:zentra_0/routes/app_routes.dart';
import 'package:zentra_0/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();

  // Registered eagerly (rather than via GetMaterialApp's initialBinding) so
  // that Get.find<ThemeController>() below is guaranteed to resolve on the
  // very first frame, before GetMaterialApp itself has mounted.
  InitialBinding().dependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Zentra',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: Get.find<ThemeController>().theme,
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      unknownRoute: AppPages.pages.firstWhere((p) => p.name == AppRoutes.notFound),
    );
  }
}
