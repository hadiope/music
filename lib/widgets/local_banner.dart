import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local promo banner stored in assets; taps open the channel link.
class LocalBanner extends StatelessWidget {
  const LocalBanner({super.key});

  static const String _link = 'shad://l.shad.ir/TextStory';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(_link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to https if shad:// not handled
          final web = Uri.parse('https://l.shad.ir/TextStory');
          if (await canLaunchUrl(web)) await launchUrl(web, mode: LaunchMode.externalApplication);
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
