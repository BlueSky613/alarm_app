import 'package:flutter/material.dart';

enum LegalPageType { privacy, license, copyright }

const Color _kBg = Color(0xFF000000);

class LegalPage extends StatelessWidget {
  final String title;
  final LegalPageType type;

  const LegalPage({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 18)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          _content(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  String _content() {
    switch (type) {
      case LegalPageType.privacy:
        return _privacy;
      case LegalPageType.license:
        return _license;
      case LegalPageType.copyright:
        return _copyright;
    }
  }
}

const String _privacy = '''SolRise — Privacy Policy
Effective date: April 5, 2026

1. Introduction
Welcome to SolRise. We are committed to protecting your personal information. This Privacy Policy explains what data we collect, how we use it, and your rights with respect to that data.

2. Information We Collect
We may collect the following categories of information:
• Wallet address — your Solana public key used to verify SKR token balance and enable app access.
• Alarm settings — times, labels, ringtone preferences, snooze duration, and repeat schedules stored locally on your device.
• Zodiac sign — selected in Settings to personalise your daily horoscope.
• Location data — approximate location used solely to fetch local weather information. We do not store or transmit your precise location to our servers.
• Usage analytics — anonymous, aggregated data about feature usage to improve the app. No personally identifiable information is included.

3. How We Use Your Information
• To provide core alarm functionality.
• To display your daily horoscope based on your selected zodiac sign.
• To retrieve local weather forecasts.
• To verify SKR token holdings via the Solana blockchain for access control.
• To improve app performance and user experience through anonymised analytics.

4. Blockchain Data
When you connect your wallet, your public key is read from the Solana blockchain to verify your SKR token balance. We never request, store, or have access to your private key or seed phrase. Blockchain transactions are public by nature; we are not responsible for the public visibility of on-chain data.

5. Data Sharing
We do not sell, rent, or trade your personal data. We may share limited data with:
• Weather API providers — your approximate location to return a forecast. These providers have their own privacy policies.
• Horoscope API providers — only your selected zodiac sign.
• Solana RPC nodes — your wallet public key to read token balances.

6. Data Retention
Alarm settings and preferences are stored locally on your device and remain under your control. We retain anonymised analytics data for up to 12 months. You may delete all locally stored data by uninstalling the app.

7. Security
We implement industry-standard security measures to protect any data we process. However, no method of transmission or electronic storage is 100% secure. We encourage you to keep your device and wallet software up to date.

8. Children's Privacy
SolRise is not directed at children under the age of 13. We do not knowingly collect personal data from children. If you believe a child has provided us with personal data, please contact us so we can delete it.

9. Your Rights
Depending on your jurisdiction, you may have the right to access, correct, or delete personal data we hold about you. To exercise these rights, contact us at the email below.

10. Changes to This Policy
We may update this Privacy Policy from time to time. We will notify you of material changes by updating the effective date above. Continued use of the app after changes constitutes acceptance of the updated policy.

11. Contact
Questions or concerns? Contact us at: solrise613728@gmail.com''';

const String _license = '''SolRise — Software License Agreement
Effective date: April 5, 2026

1. Grant of License
Subject to the terms of this Agreement, SolRise Team grants you a limited, non-exclusive, non-transferable, revocable licence to install and use SolRise (the "App") on a Solana-compatible mobile device that you own or control, solely for your personal, non-commercial purposes.

2. Access Requirements
Use of the App requires a minimum balance of 20 SKR tokens in your connected Solana wallet. Access to Premium features requires 199 SKR tokens. These requirements may be updated by SolRise Team at any time with reasonable notice.

3. Restrictions
You may not:
• Copy, modify, merge, publish, distribute, sublicense, or sell copies of the App.
• Reverse engineer, decompile, or disassemble any portion of the App.
• Use the App for any unlawful purpose or in violation of any applicable law or regulation.
• Attempt to gain unauthorised access to any part of the App or its connected services.
• Use the App to transmit malware, spam, or any harmful content.

4. Intellectual Property
The App and all its original content, features, and functionality are and will remain the exclusive property of SolRise Team and its licensors. Our name, logo, and all related names, logos, product and service names, designs, and slogans are trademarks of SolRise Team.

5. Third-Party Services
The App integrates with third-party services including the Solana blockchain network, weather data providers, and horoscope data providers. Use of these services is subject to their respective terms and conditions. SolRise Team is not responsible for the availability or accuracy of third-party data.

6. Disclaimer of Warranties
The App is provided on an "AS IS" and "AS AVAILABLE" basis without any warranties of any kind, either express or implied. SolRise Team does not warrant that the App will be uninterrupted, error-free, or free of viruses or other harmful components.

7. Limitation of Liability
To the fullest extent permitted by applicable law, SolRise Team shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising out of or related to your use of the App.

8. Termination
This licence is effective until terminated. Your rights under this licence will terminate automatically without notice if you fail to comply with any of its terms. Upon termination, you must cease all use of the App and delete all copies.

9. Governing Law
This Agreement shall be governed by and construed in accordance with applicable laws, without regard to conflict-of-law principles.

10. Contact
For licensing enquiries, contact: solrise613728@gmail.com''';

const String _copyright = '''SolRise — Copyright Notice
Effective date: April 5, 2026

1. Copyright Statement
Copyright \u00a9 2026 SolRise Team. All rights reserved.

The SolRise mobile application, including but not limited to its source code, design, graphics, user interface, AI character assets, alarm sound recordings, and all associated documentation, is the exclusive intellectual property of SolRise Team.

2. Protected Elements
The following elements are protected under applicable copyright law:
• App source code and software architecture.
• User interface design, layouts, icons, and visual assets.
• AI virtual character illustrations and animations.
• Alarm music tracks and audio recordings branded as SolRise originals.
• All written content including descriptions, onboarding copy, and in-app text.
• The SolRise logo and brand identity.

3. Permitted Use
Users are permitted to use the App solely in accordance with the Software License Agreement. No portion of the App's content, code, or assets may be reproduced, distributed, publicly displayed, or used to create derivative works without prior written permission from SolRise Team.

4. Third-Party Content
Certain content within the App is sourced from third parties under licence. This includes weather data, horoscope content, and certain stock assets. Such content remains the property of its respective rights holders and is used in compliance with applicable licences.

5. Blockchain & Token Disclosure
The SKR token referenced within the App is used solely as an access mechanism. SolRise Team does not claim copyright over the Solana blockchain protocol or any open-source libraries used in the development of the App. All open-source components are used in compliance with their respective licences.

6. Infringement Notice
If you believe that any content within SolRise infringes your copyright, please contact us with the following information:
• A description of the copyrighted work you claim has been infringed.
• The location within the App where the allegedly infringing material appears.
• Your contact information including name and email address.
• A statement that you have a good-faith belief that the use is not authorised by the copyright owner.

7. Contact
Copyright enquiries: solrise613728@gmail.com''';
