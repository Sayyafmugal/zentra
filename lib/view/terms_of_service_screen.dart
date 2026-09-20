import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last updated: January 2026',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Acceptance of Terms',
            body:
                'By creating an account and using Zentra, you agree to these terms of service. '
                'If you do not agree, please discontinue use of the app.',
          ),
          _Section(
            title: 'Accounts',
            body:
                'You are responsible for maintaining the confidentiality of your account '
                'credentials and for all activity that occurs under your account.',
          ),
          _Section(
            title: 'Orders & Payments',
            body:
                'All orders are subject to product availability. Prices are shown at time of '
                'checkout and may change without notice for future orders. Zentra is a demo '
                'storefront — no real payments are processed.',
          ),
          _Section(
            title: 'Seller Accounts',
            body:
                'Accounts granted a seller/admin role may list, edit, and remove products. '
                'Sellers are responsible for the accuracy of their product listings.',
          ),
          _Section(
            title: 'Limitation of Liability',
            body:
                'Zentra is provided "as is" as a demonstration application, without warranties '
                'of any kind, express or implied.',
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
