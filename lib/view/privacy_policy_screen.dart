import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last updated: January 2026',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Information We Collect',
            body:
                'When you create a Zentra account we collect your name, email address, and '
                'optional profile details such as a photo and phone number. When you place an '
                'order we also store your shipping address and a masked reference to your '
                'payment method — full card numbers are never stored on our servers.',
          ),
          _Section(
            title: 'How We Use Your Information',
            body:
                'We use your information to process orders, provide customer support, and '
                'personalize your shopping experience. We do not sell your personal data to '
                'third parties.',
          ),
          _Section(
            title: 'Data Security',
            body:
                'Your data is stored using Firebase\'s secure infrastructure, protected by '
                'authentication and per-user access rules that ensure you can only access your '
                'own orders, cart, addresses, and payment methods.',
          ),
          _Section(
            title: 'Your Rights',
            body:
                'You can review and update your profile information at any time from the '
                'Account tab, and request deletion of your account and associated data by '
                'contacting support from the Help Center.',
          ),
          _Section(
            title: 'Contact Us',
            body: 'Questions about this policy can be sent through the Help Center screen.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
