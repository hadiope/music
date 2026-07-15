import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local promo banner stored in assets; taps open the channel link.
class LocalBanner extends StatelessWidget {
  const LocalBanner({super.key});

  // Deep link to the Shad.ir TextStory page.
  static const String _link = 'shad://l.shad.ir/TextStory';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Try the shad:// deep link first (opens the Shad app if installed),
        // fall back to the https version in a browser otherwise.
        final shadUri = Uri.parse(_link);
        if (await canLaunchUrl(shadUri)) {
          await launchUrl(shadUri, mode: LaunchMode.externalApplication);
        } else {
          final webUri = Uri.parse(_link.replaceFirst('shad://', 'https://'));
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/images/banner_main.png',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
