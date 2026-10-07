import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF2E7D32), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '100% Offline & Private',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context: context,
              title: '1. Introduction',
              content:
                  'Welcome to PDF Scanner & Tools Offline. We respect your privacy and are committed to protecting it. This Privacy Policy explains how we handle your data when you use our application.',
            ),
            _buildSection(
              context: context,
              title: '2. Local Processing',
              content:
                  'PDF Scanner & Tools Offline is designed to be a fully offline tool. All PDF processing (including merging, splitting, converting, and compressing) is performed entirely locally on your device. We do not upload, store, or transmit your documents or images to any external servers.',
            ),
            _buildSection(
              context: context,
              title: '3. Data Collection',
              content:
                  'Because the app operates offline, we do not collect, share, or sell any personal information or document data. Your files remain strictly on your device.',
            ),
            _buildSection(
              context: context,
              title: '4. Third-Party Services (Advertising)',
              content:
                  'To support the development of this free app, we use Google AdMob to display advertisements. AdMob may collect certain non-personally identifiable information (such as your device\'s advertising ID and IP address) to serve relevant ads. You can opt out of personalized advertising in your device settings.',
            ),
            _buildSection(
              context: context,
              title: '5. Permissions',
              content:
                  'The app requests file access permissions solely for the purpose of allowing you to select documents from your device and save the processed results back to your storage.',
            ),
            _buildSection(
              context: context,
              title: '6. Changes to This Policy',
              content:
                  'We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. Changes are effective immediately after they are posted on this page.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last updated: August 2026',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© 2026 ABH Softworks. All Rights Reserved.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
