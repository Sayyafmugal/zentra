import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class _FAQ {
  const _FAQ(this.question, this.answer);
  final String question;
  final String answer;
}

const _faqs = [
  _FAQ(
    'How do I track my order?',
    'You can track your order by going to My Orders and clicking on the order number.',
  ),
  _FAQ(
    'What is your return policy?',
    'We offer 30-day returns for all items in original condition with tags attached.',
  ),
  _FAQ(
    'How long does shipping take?',
    'Standard shipping takes 3-5 business days, while express shipping takes 1-2 business days.',
  ),
  _FAQ(
    'Can I change my shipping address?',
    'Yes, you can update your shipping address in the Shipping Address section of your account.',
  ),
  _FAQ(
    'How do I become a seller?',
    'Seller access is granted by an administrator. Contact support to request seller status.',
  ),
];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _query = '';

  List<_FAQ> get _filteredFaqs {
    if (_query.trim().isEmpty) return _faqs;
    final q = _query.trim().toLowerCase();
    return _faqs
        .where((f) => f.question.toLowerCase().contains(q) || f.answer.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help Center'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Text('Quick Help', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _HelpCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Order Issues',
              subtitle: 'Track orders, returns, and refunds',
              onTap: () => _showHelpDialog(context, 'Order Issues'),
            ),
            const SizedBox(height: 12),
            _HelpCard(
              icon: Icons.payment,
              title: 'Payment & Billing',
              subtitle: 'Payment methods and billing questions',
              onTap: () => _showHelpDialog(context, 'Payment & Billing'),
            ),
            const SizedBox(height: 12),
            _HelpCard(
              icon: Icons.local_shipping,
              title: 'Shipping & Delivery',
              subtitle: 'Delivery times and shipping options',
              onTap: () => _showHelpDialog(context, 'Shipping & Delivery'),
            ),
            const SizedBox(height: 12),
            _HelpCard(
              icon: Icons.account_circle,
              title: 'Account & Profile',
              subtitle: 'Manage your account and profile',
              onTap: () => _showHelpDialog(context, 'Account & Profile'),
            ),
            const SizedBox(height: 32),
            Text('Frequently Asked Questions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No results for "$_query"', style: TextStyle(color: theme.hintColor)),
              )
            else
              ..._filteredFaqs.map((f) => _FAQItem(question: f.question, answer: f.answer)),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent, color: theme.colorScheme.primary, size: 48),
                  const SizedBox(height: 16),
                  Text('Still need help?', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our support team for personalized assistance',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launch(
                            Uri(
                              scheme: 'mailto',
                              path: 'support@zentra.app',
                              query: 'subject=Zentra Support Request',
                            ),
                          ),
                          icon: const Icon(Icons.email, size: 16),
                          label: const Text('Email'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launch(Uri(scheme: 'tel', path: '+10000000000')),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(topic),
        content: Text('Help content for $topic would be displayed here.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  const _FAQItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
