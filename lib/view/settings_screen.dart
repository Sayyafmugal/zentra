import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool pushNotifications = true;
  bool emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final Color sectionTitle = Colors.grey.shade700;
    final Color cardColor = Colors.grey.shade100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Appearance
          _SectionTitle('Appearance', color: sectionTitle),
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile.adaptive(
              value: isDarkMode,
              onChanged: (v) {
                setState(() => isDarkMode = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dark Mode ${v ? 'enabled' : 'disabled'}')),
                );
              },
              secondary: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              activeColor: SettingsScreen.primaryColor,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Push notifications ${v ? 'enabled' : 'disabled'}')),
                    );
                  },
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive push notifications about orders and promotions'),
                  activeColor: SettingsScreen.primaryColor,
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: emailNotifications,
                  onChanged: (v) {
                    setState(() => emailNotifications = v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email notifications ${v ? 'enabled' : 'disabled'}')),
                    );
                  },
                  title: const Text('Email Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive email updates about your orders'),
                  activeColor: SettingsScreen.primaryColor,
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
                  leading: Icon(Icons.privacy_tip_outlined, color: SettingsScreen.primaryColor),
                  title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: SettingsScreen.primaryColor),
                  title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Read our terms of service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()));
                  },
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
              leading: Icon(Icons.info_outline, color: SettingsScreen.primaryColor),
              title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Your App',
                  applicationVersion: '1.0.0',
                  applicationIcon: const FlutterLogo(size: 40),
                  children: const [Text('Thanks for using our app!')],
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

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: false,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This is where your privacy policy content goes. You can replace this\n'
              'with a WebView or rich text as needed.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: false,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This is where your terms of service content goes. You can replace this\n'
              'with a WebView or rich text as needed.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}