import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/theme_controller.dart';
import '../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = Get.find<ThemeController>();
    final sectionTitle = theme.hintColor;
    final cardColor = theme.cardColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Appearance
          _SectionTitle('Appearance', color: sectionTitle),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: Obx(
              () => SwitchListTile.adaptive(
                value: themeController.isDarkMode,
                onChanged: (_) => themeController.toggleTheme(),
                secondary: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                activeColor: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notifications
          _SectionTitle('Notifications', color: sectionTitle),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: pushNotifications,
                  onChanged: (v) {
                    setState(() => pushNotifications = v);
                  },
                  title: const Text(
                    'Push Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Receive push notifications about orders and promotions'),
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: emailNotifications,
                  onChanged: (v) {
                    setState(() => emailNotifications = v);
                  },
                  title: const Text(
                    'Email Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Receive email updates about your orders'),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy
          _SectionTitle('Privacy', color: sectionTitle),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                  title: const Text(
                    'Terms of Service',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Read our terms of service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => Get.toNamed(AppRoutes.termsOfService),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About
          _SectionTitle('About', color: sectionTitle),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
              title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Zentra',
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(size: 40),
                  children: const [Text('Thanks for using Zentra!')],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
